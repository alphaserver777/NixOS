"""Проверки задержки запуска и сохранения выбора без настоящего systemd."""

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("shell_switch", Path(__file__).with_name("shell-switch.py"))
shell = importlib.util.module_from_spec(spec)
spec.loader.exec_module(shell)


class ShellSelectionTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.state = patch.object(shell, "STATE", self.root / "state")
        self.active = patch.object(shell, "ACTIVE_FILE", self.root / "active")
        self.state.start()
        self.active.start()
        self.addCleanup(self.state.stop)
        self.addCleanup(self.active.stop)
        shell.save("dms")

    def test_late_panel_response_is_accepted(self):
        elapsed = [0.0]

        def sleep(seconds):
            elapsed[0] += seconds

        def probe(*args, **kwargs):
            return subprocess.CompletedProcess(args, 0, "visible" if elapsed[0] >= 35 else "not ready", "")

        with patch.object(shell, "systemctl", return_value=subprocess.CompletedProcess([], 0)), \
                patch.object(shell.subprocess, "run", side_effect=probe), \
                patch.object(shell.time, "monotonic", side_effect=lambda: elapsed[0]), \
                patch.object(shell.time, "sleep", side_effect=sleep):
            shell.activate("dms")
        self.assertGreaterEqual(elapsed[0], 35)
        self.assertEqual(shell.read_choice(), "dms")

    def test_failed_resume_keeps_preference_and_allows_fallback(self):
        real_activate = shell.activate

        def activate(choice):
            if choice == "dms":
                raise RuntimeError("Не удалось запустить панель")
            real_activate(choice)

        with patch.object(shell, "active_choice", return_value="original"), \
                patch.object(shell, "systemctl", return_value=subprocess.CompletedProcess([], 0)), \
                patch.object(shell, "activate", side_effect=activate):
            with self.assertRaises(RuntimeError):
                shell.switch("dms", remember=False)
        self.assertEqual(shell.read_choice(), "dms")
        self.assertEqual(shell.ACTIVE_FILE.read_text().strip(), "original")
        with patch.object(shell.sys, "argv", ["cosmic-shell", "allow-original"]):
            with self.assertRaises(SystemExit) as result:
                shell.main()
        self.assertEqual(result.exception.code, 0)

    def test_explicit_original_is_remembered(self):
        with patch.object(shell, "active_choice", return_value="dms"), \
                patch.object(shell, "systemctl", return_value=subprocess.CompletedProcess([], 0)):
            shell.switch("original")
        self.assertEqual(shell.read_choice(), "original")
        self.assertEqual(shell.read_choice("shell-previous"), "dms")

    def test_emergency_restore_does_not_overwrite_preference(self):
        with patch.object(shell, "systemctl", return_value=subprocess.CompletedProcess([], 0)):
            shell.restore("original")
        self.assertEqual(shell.read_choice(), "dms")

    def test_new_session_uses_saved_preference_for_original_condition(self):
        with patch.object(shell.sys, "argv", ["cosmic-shell", "allow-original"]):
            with self.assertRaises(SystemExit) as result:
                shell.main()
        self.assertEqual(result.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
