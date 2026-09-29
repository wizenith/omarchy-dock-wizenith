import importlib.util
import json
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('move', Path(__file__).parents[1] / 'scripts/dock-window-move.py')
move = importlib.util.module_from_spec(spec)
spec.loader.exec_module(move)

class MoveTests(unittest.TestCase):
    def test_batch_uses_one_destination_skips_other_monitor_and_occupied_workspace(self):
        calls=[]
        def ipc(command):
            calls.append(command)
            if command=='j/clients':
                name='4' if any(c.startswith('eval ') for c in calls) else '1'
                return json.dumps([{'address':a, 'workspace':{'id':int(name), 'name':name}} for a in ['0xaa','0xbb']])
            if command=='j/workspaces': return '[{"id":2,"windows":1}]'
            if command=='j/monitors': return '[{"activeWorkspace":{"id":3}}]'
            if command.startswith('eval '): return 'ok'
            self.fail(command)
        result=move.move_windows(['0xaa','0xbb'],'1','new',False,ipc)
        self.assertEqual(result['workspace'],'4')
        program=next(c for c in calls if c.startswith('eval '))
        self.assertEqual(program.count('workspace = [=[4]=], follow = false'),2)
        self.assertIn('hl.dsp.focus({ workspace = [=[1]=] })',program)

    def test_partial_group_rejected_before_any_mutation(self):
        calls=[]
        def ipc(command):
            calls.append(command)
            return '[{"address":"0xaa","grouped":["0xaa","0xbb"]}]'
        with self.assertRaisesRegex(RuntimeError,'群組'):
            move.move_windows(['0xaa'],'1','here',ipc=ipc)
        self.assertEqual(calls,['j/clients'])

    def test_closed_selection_rejected_before_any_mutation(self):
        calls=[]
        def ipc(command):
            calls.append(command)
            return '[]'
        with self.assertRaisesRegex(RuntimeError,'關閉'):
            move.move_windows(['0xaa'],'1','here',ipc=ipc)
        self.assertEqual(calls,['j/clients'])

    def test_compositor_silent_failure_is_detected(self):
        def ipc(command):
            return 'ok' if command.startswith('eval ') else '[{"address":"0xaa","workspace":{"name":"2"}}]'
        with self.assertRaisesRegex(RuntimeError,'未能移動'):
            move.move_windows(['0xaa'],'1','here',ipc=ipc)

if __name__=='__main__': unittest.main()
