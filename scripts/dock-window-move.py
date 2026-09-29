#!/usr/bin/env python3
"""Move an explicit selection of existing windows to one fixed workspace."""
import argparse
import importlib.util
import json
from pathlib import Path
import re

spec = importlib.util.spec_from_file_location('dock_focus', Path(__file__).with_name('dock-window-focus.py'))
focus = importlib.util.module_from_spec(spec)
spec.loader.exec_module(focus)


def move_windows(addresses, origin, mode, follow=False, ipc=focus.request):
    addresses = list(dict.fromkeys(a.lower() for a in addresses))
    if not addresses or any(not re.fullmatch(r'0x[0-9a-f]+', a) for a in addresses):
        raise ValueError('請選取有效的視窗')
    if not origin or origin.startswith('special:'):
        raise ValueError('請從一般工作區開啟選單')
    clients = json.loads(ipc('j/clients'))
    selected = [c for c in clients if c['address'].lower() in addresses]
    if len(selected) != len(addresses):
        raise RuntimeError('部分視窗已關閉，請重新選取')
    # Moving a Hyprland group can move unselected siblings. Reject that case
    # before dispatching anything; never silently broaden the user's selection.
    for c in selected:
        if any(a.lower() not in addresses for a in c.get('grouped', [])):
            raise RuntimeError('視窗屬於分頁群組，請選取整個群組或先將它拆開')
        if c.get('pinned'):
            raise RuntimeError('請先取消所選視窗的釘選，再移動工作區')
    target = origin
    if mode == 'new':
        workspaces = json.loads(ipc('j/workspaces'))
        monitors = json.loads(ipc('j/monitors'))
        used = {w['id'] for w in workspaces if w.get('windows', 0) or w.get('ispersistent')}
        used.update(c.get('workspace', {}).get('id', 0) for c in clients)
        used.update(m.get('activeWorkspace', {}).get('id', 0) for m in monitors)
        candidate = int(origin) + 1 if origin.isdecimal() else 1
        while candidate in used:
            candidate += 1
        if candidate > 2147483647:
            raise RuntimeError('沒有可用的工作區編號')
        target = str(candidate)
    elif mode != 'here':
        raise ValueError('未知的搬移操作')
    target_selector = target if target.isdecimal() else 'name:' + target
    commands = []
    for client in selected:
        selector = focus.lua_string('address:' + client['address'])
        commands.append('hl.dispatch(hl.dsp.window.move({ window = ' + selector
                        + ', workspace = ' + focus.lua_string(target_selector) + ', follow = false }))')
    # Returning to origin also undoes workspace changes made by hover previews.
    destination = target_selector if mode == 'here' or follow else (origin if origin.isdecimal() else 'name:' + origin)
    commands.append('hl.dispatch(hl.dsp.focus({ workspace = ' + focus.lua_string(destination) + ' }))')
    result = ipc('eval ' + '; '.join(commands)).strip()
    if result != 'ok':
        raise RuntimeError(result or 'Hyprland 未回應；部分視窗可能已移動')
    after = {c['address'].lower(): c for c in json.loads(ipc('j/clients'))}
    failed = [a for a in addresses if a not in after or str(after[a].get('workspace', {}).get('name')) != target]
    if failed:
        raise RuntimeError('部分視窗未能移動，請檢查工作區後重試')
    return {'ok': True, 'workspace': target, 'count': len(addresses)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['here', 'new'])
    parser.add_argument('origin')
    parser.add_argument('addresses', nargs='+')
    parser.add_argument('--follow', action='store_true')
    args = parser.parse_args()
    try:
        result = move_windows(args.addresses, args.origin, args.mode, args.follow)
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print(json.dumps({'ok': False, 'error': str(error)}, ensure_ascii=False))
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
