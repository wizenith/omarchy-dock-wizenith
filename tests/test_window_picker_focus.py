"""Regression coverage for a preview that retains pointer position and settings."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import unittest

spec = importlib.util.spec_from_file_location("window_focus", Path(__file__).parents[1] / "scripts/dock-window-focus.py")
focus = importlib.util.module_from_spec(spec)
spec.loader.exec_module(focus)


class PreviewFocusTests(unittest.TestCase):
    def test_observed_hyprland_boolean_response(self):
        self.assertIs(focus.option_value('{"option":"cursor:no_warps","bool":false,"set":false}'), False)
        self.assertEqual(focus.option_value('{"int":2}'), 2)
        self.assertIsNone(focus.option_value("no such option"))

    def test_closed_window_never_focuses_a_sibling_or_launches_an_app(self):
        calls = []
        def ipc(command):
            calls.append(command)
            return '[{"address":"0xbbbb"}]'
        with self.assertRaisesRegex(RuntimeError, "closed"):
            focus.focus_window("0xaaaa", True, ipc)
        self.assertEqual(calls, ["j/clients"])

    def test_preview_fails_safely_if_cursor_protection_is_unavailable(self):
        calls = []
        def ipc(command):
            calls.append(command)
            return '[{"address":"0xaaaa"}]' if command == "j/clients" else "no such option"
        with self.assertRaisesRegex(RuntimeError, "unavailable"):
            focus.focus_window("0xaaaa", True, ipc)
        self.assertFalse(any(c.startswith("eval ") for c in calls))

    def test_focus_failure_is_reported(self):
        def ipc(command):
            if command == "j/clients": return '[{"address":"0xaaaa"}]'
            if command.startswith("eval "): return "error: compositor rejected focus"
            self.fail(command)
        with self.assertRaisesRegex(RuntimeError, "rejected"):
            focus.focus_window("0xaaaa", False, ipc)

    def test_success_requires_the_requested_window_to_be_active(self):
        def ipc(command):
            if command == "j/clients": return '[{"address":"0xaaaa"}]'
            if command.startswith("eval "): return "ok"
            if command == "j/activewindow": return '{"address":"0xbbbb"}'
            self.fail(command)
        with self.assertRaisesRegex(RuntimeError, "did not focus"):
            focus.focus_window("0xaaaa", False, ipc)

    @unittest.skipUnless(shutil.which("lua"), "Lua interpreter unavailable")
    def test_lua_restores_settings_on_success_and_dispatch_error(self):
        previous = {"no_warps": False, "warp_on_change_workspace": 2, "warp_on_toggle_special": 1}
        client = {"address": "0xaaaa", "workspace": {"name": "2"}}
        program = focus.focus_program(client, "1", previous)
        for fail in (False, True):
            with self.subTest(fail=fail):
                script = '''
local state = { no_warps = false, warp_on_change_workspace = 2, warp_on_toggle_special = 1 }
local actions = 0
hl = {
  config = function(values) for k,v in pairs(values.cursor) do state[k] = v end end,
  dsp = { focus = function(args) return args end },
  dispatch = function(args)
    assert(state.no_warps == true)
    assert(state.warp_on_change_workspace == 0)
    assert(state.warp_on_toggle_special == 0)
    assert(args.window == "address:0xaaaa")
    actions = actions + 1
    if FAIL then error("expected focus failure") end
  end
}
local ok = pcall(function() PROGRAM end)
assert(ok == not FAIL)
assert(actions == 1)
assert(state.no_warps == false)
assert(state.warp_on_change_workspace == 2)
assert(state.warp_on_toggle_special == 1)
'''.replace("FAIL", "true" if fail else "false").replace("PROGRAM", program)
                result = subprocess.run(["lua", "-"], input=script, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(shutil.which("lua"), "Lua interpreter unavailable")
    def test_minimized_group_target_and_unusual_workspace_name(self):
        workspace = '工程 ]=] ]] " ; error("injected") --'
        client = {"address": "0xaaaa", "workspace": {"name": "special:minimized"}, "grouped": ["0xbbbb", "0xaaaa"]}
        program = focus.focus_program(client, workspace, None)
        script = '''
local calls = {}
hl = { dsp = {
  window = { move = function(a) return {kind="move", a=a} end },
  group = { active = function(a) return {kind="group", a=a} end },
  focus = function(a) return {kind="focus", a=a} end
}, dispatch = function(a) table.insert(calls, a) end }
PROGRAM
assert(#calls == 3)
assert(calls[1].kind == "move" and calls[1].a.workspace == EXPECTED)
assert(calls[2].kind == "group" and calls[2].a.index == 2)
assert(calls[3].kind == "focus" and calls[3].a.window == "address:0xaaaa")
'''.replace("PROGRAM", program).replace("EXPECTED", focus.lua_string(workspace))
        result = subprocess.run(["lua", "-"], input=script, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
