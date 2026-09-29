#!/usr/bin/env python3
"""Focus one existing Hyprland window; hover previews must never warp the pointer."""

import argparse
import json
import os
import re
import socket


CURSOR_OVERRIDES = {
    "no_warps": True,
    "warp_on_change_workspace": 0,
    "warp_on_monitor_change": 0,
    "warp_on_toggle_special": 0,
}


def request(command):
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        raise RuntimeError("Hyprland session is unavailable")
    path = f"{runtime}/hypr/{signature}/.socket.sock"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(2)
        connection.connect(path)
        connection.sendall(command.encode())
        chunks = []
        while chunk := connection.recv(65536):
            chunks.append(chunk)
    return b"".join(chunks).decode()


def option_value(raw):
    """Hyprland's Lua parser reports bools separately from integer options."""
    try:
        data = json.loads(raw)
    except ValueError:
        return None
    if not isinstance(data, dict):
        return None
    for key in ("bool", "int", "value"):
        value = data.get(key)
        if type(value) in (bool, int):
            return value
    return None


def lua_string(value):
    # Lua long strings also handle custom workspace names with quotes/unicode.
    marker = "="
    while "]" + marker + "]" in str(value):
        marker += "="
    return "[" + marker + "[" + str(value) + "]" + marker + "]"


def cursor_config(values):
    fields = []
    for key, value in values.items():
        literal = ("true" if value else "false") if type(value) is bool else str(value)
        fields.append(f"{key} = {literal}")
    return "hl.config({ cursor = { " + ", ".join(fields) + " } })"


def focus_program(client, workspace, previous_options):
    selector = lua_string("address:" + client["address"])
    commands = []
    if str(client.get("workspace", {}).get("name", "")).startswith("special:"):
        commands.append("hl.dispatch(hl.dsp.window.move({ window = " + selector
                        + ", workspace = " + lua_string(workspace) + " }))")
    group = [str(address).lower() for address in client.get("grouped", [])]
    if client["address"].lower() in group:
        index = group.index(client["address"].lower()) + 1
        commands.append(f"hl.dispatch(hl.dsp.group.active({{ window = {selector}, index = {index} }}))")
    commands.append("hl.dispatch(hl.dsp.focus({ window = " + selector + " }))")
    action = "; ".join(commands)
    if previous_options is None:
        return action
    temporary = {key: CURSOR_OVERRIDES[key] for key in previous_options}
    # One synchronous Lua evaluation: other preview processes cannot interleave
    # a config save/restore, and pcall restores options even if focusing fails.
    return ("local ok, err = pcall(function() " + cursor_config(temporary) + "; "
            + action + " end); " + cursor_config(previous_options)
            + "; if not ok then error(err) end")


def focus_window(address, preview=False, ipc=request):
    if not re.fullmatch(r"0x[0-9a-fA-F]+", address):
        raise ValueError("Invalid window address")
    clients = json.loads(ipc("j/clients"))
    target = next((c for c in clients if str(c.get("address", "")).lower() == address.lower()), None)
    if target is None:
        raise RuntimeError("The window has closed")
    workspace = "1"
    if str(target.get("workspace", {}).get("name", "")).startswith("special:"):
        for monitor in json.loads(ipc("j/monitors")):
            if monitor.get("focused"):
                ws = monitor.get("activeWorkspace", {})
                workspace = str(ws.get("name") or ws.get("id") or "1")
                break
    previous = None
    if preview:
        previous = {}
        for name in CURSOR_OVERRIDES:
            value = option_value(ipc("j/getoption cursor:" + name))
            if value is not None:
                previous[name] = value
        if "no_warps" not in previous:
            # Do not fall back to a normal activation, which ejects the pointer.
            raise RuntimeError("Pointer-preserving preview is unavailable; click to choose")
    result = ipc("eval " + focus_program(target, workspace, previous)).strip()
    if result != "ok":
        raise RuntimeError(result or "Hyprland did not respond")
    active = json.loads(ipc("j/activewindow"))
    if str(active.get("address", "")).lower() != address.lower():
        raise RuntimeError("Hyprland did not focus the requested window")
    return {"ok": True, "address": address, "preview": preview}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("address")
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args()
    try:
        result = focus_window(args.address, args.preview)
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
