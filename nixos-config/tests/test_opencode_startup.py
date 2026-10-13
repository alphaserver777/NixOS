"""Regression checks for first-launch catalog races and preserved user settings."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]


class StartupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.env = dict(os.environ)
        for key in list(self.env):
            if key.startswith("OPENCODE_"):
                del self.env[key]
        self.env.update(
            HOME=str(self.directory),
            XDG_CONFIG_HOME=str(self.directory / "config"),
            XDG_CACHE_HOME=str(self.directory / "cache"),
            XDG_STATE_HOME=str(self.directory / "state"),
            STARTUP_CALLS=str(self.directory / "calls"),
        )
        self.cache = self.directory / "cache/opencode/models.json"
        self.config = self.directory / "config/opencode/opencode.json"
        fake = self.directory / "client"
        fake.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['STARTUP_CALLS'], 'a') as f:\n"
            " f.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "if '--refresh' in sys.argv:\n"
            " sys.exit(int(os.environ.get('STARTUP_REFRESH_FAILURE', '0')))\n"
        )
        fake.chmod(0o700)
        script = (ROOT / "packages/opencode-launcher.sh").read_text()
        for key, value in {
            "bash": shutil.which("bash"),
            "opencode": fake,
            "python": sys.executable,
            "initializer": ROOT / "home-manager/modules/opencode-default.py",
            "coreutils": Path(shutil.which("stat")).parent,
        }.items():
            script = script.replace(f"@{key}@", str(value))
        self.launcher = self.directory / "launcher"
        self.launcher.write_text(script)
        self.launcher.chmod(0o700)

    def launch(self, *args):
        subprocess.run([self.launcher, *args], env=self.env, check=True, timeout=5)
        return [json.loads(line) for line in (self.directory / "calls").read_text().splitlines()]

    def test_first_launch_refreshes_before_client_and_sets_both_models(self):
        self.assertEqual(self.launch("run", "text with spaces"),
                         [["--pure", "models", "--refresh"], ["run", "text with spaces"]])
        settings = json.loads(self.config.read_text())
        self.assertEqual(settings["model"], "opencode/space-bunny-free")
        self.assertEqual(settings["small_model"], settings["model"])
        self.assertEqual(self.config.stat().st_mode & 0o777, 0o600)

    def test_fresh_cache_skips_refresh(self):
        self.cache.parent.mkdir(parents=True)
        self.cache.write_text("{}")
        self.assertEqual(self.launch(), [[]])

    def test_stale_cache_refreshes(self):
        self.cache.parent.mkdir(parents=True)
        self.cache.write_text("{}")
        old = time.time() - 600
        os.utime(self.cache, (old, old))
        self.assertEqual(self.launch("web")[0], ["--pure", "models", "--refresh"])

    def test_offline_refresh_keeps_client_available(self):
        self.env["STARTUP_REFRESH_FAILURE"] = "1"
        self.assertEqual(self.launch("serve")[-1], ["serve"])

    def test_custom_catalog_and_disabled_fetch_are_respected(self):
        for key, value in [("OPENCODE_MODELS_PATH", "/custom/models.json"),
                           ("OPENCODE_MODELS_URL", "https://example.invalid"),
                           ("OPENCODE_DISABLE_MODELS_FETCH", "true"),
                           ("OPENCODE_DISABLE_MODELS_FETCH", "1")]:
            with self.subTest(key=key, value=value):
                self.env[key] = value
                self.assertEqual(self.launch("run")[-1], ["run"])
                self.assertNotIn(["--pure", "models", "--refresh"], self.launch("run"))
                del self.env[key]

    def test_version_does_not_initialize_or_fetch(self):
        self.assertEqual(self.launch("--version"), [["--version"]])
        self.assertFalse(self.config.exists())

    def test_explicit_model_and_provider_are_preserved(self):
        self.config.parent.mkdir(parents=True)
        settings = {"model": "a6api/custom", "provider": {"a6api": {"models": {"custom": {}}}}}
        self.config.write_text(json.dumps(settings))
        self.launch("run")
        self.assertEqual(json.loads(self.config.read_text()), settings)

    def test_second_launch_preserves_subsequent_user_selection(self):
        self.launch("run")
        settings = json.loads(self.config.read_text())
        settings["model"] = "other/choice"
        self.config.write_text(json.dumps(settings))
        self.launch("run")
        self.assertEqual(json.loads(self.config.read_text()), settings)


if __name__ == "__main__":
    unittest.main()
