"""Run the real backend installers with isolated theme and home directories."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class BackendThemeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="qylock backend ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "scripts").mkdir()
        shutil.copy2(REPO / "scripts/themes.sh", self.root / "scripts/themes.sh")
        shutil.copy2(REPO / "quickshell.sh", self.root / "quickshell.sh")
        source = (REPO / "sddm.sh").read_text()
        self.sddm_themes = self.root / "system/themes"
        self.sddm_config = self.root / "system/config"
        source = source.replace('SYSTEM_THEMES_DIR="/usr/share/sddm/themes"',
                                f"SYSTEM_THEMES_DIR={shlex.quote(str(self.sddm_themes))}")
        source = source.replace('SDDM_CONF_DIR="/etc/sddm.conf.d"',
                                f"SDDM_CONF_DIR={shlex.quote(str(self.sddm_config))}")
        (self.root / "sddm.sh").write_text(source)
        for theme in ("terraria", "clockwork/tape"):
            folder = self.root / "themes" / theme
            folder.mkdir(parents=True)
            (folder / "Main.qml").write_text("import QtQuick\nItem {}\n")
            (folder / "theme.conf").write_text("[General]\nbackground_mode=time\nthemeMode=light\n")
        wrapper = self.root / "quickshell-lockscreen"
        wrapper.mkdir()
        shutil.copy2(REPO / "quickshell-lockscreen/lock.sh", wrapper / "lock.sh")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("sddm", "quickshell"):
            self.executable(self.bin / name, "exit 0\n")
        # All SDDM paths in this fixture point inside its temporary directory.
        # Execute the file operations there without requesting actual privilege.
        self.executable(self.bin / "sudo", 'if [ "$1" = -n ]; then exit 0; fi\nexec "$@"\n')
        self.env = dict(os.environ, HOME=str(self.root / "home"),
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"])

    @staticmethod
    def executable(path, body):
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def run_backend(self, backend, *args):
        return subprocess.run(["bash", str(self.root / f"{backend}.sh"), *args],
                              stdin=subprocess.DEVNULL, text=True, capture_output=True,
                              env=self.env, cwd="/tmp", timeout=10)

    def test_sddm_uses_shared_variant_without_prompts_and_updates_selection(self):
        for theme in ("clockwork/tape", "terraria"):
            with self.subTest(theme=theme):
                original = (self.root / "themes" / theme / "theme.conf").read_text()
                result = self.run_backend("sddm", "--theme", theme)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue((self.sddm_themes / theme.split("/")[-1] / "Main.qml").is_file())
                self.assertIn(f"Current={theme.split('/')[-1]}", (self.sddm_config / "theme.conf").read_text())
                self.assertEqual((self.root / "themes" / theme / "theme.conf").read_text(), original)
                self.assertNotIn("Choice", result.stdout)
                self.assertNotIn("Select SDDM Backend Version", result.stdout)

    def test_quickshell_uses_shared_variant_without_prompts_or_config_edits(self):
        for theme in ("clockwork/tape", "terraria"):
            with self.subTest(theme=theme):
                original = (self.root / "themes" / theme / "theme.conf").read_text()
                result = self.run_backend("quickshell", "--theme", theme)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                preference = self.root / "home/.config/qylock/theme"
                self.assertEqual(preference.read_text().strip(), theme)
                installed = self.root / "home/.local/share/quickshell-lockscreen"
                self.assertTrue((installed / "themes_link" / theme / "Main.qml").is_file())
                self.assertIn(f'${{1:-{theme}}}', (installed / "lock.sh").read_text())
                self.assertEqual((self.root / "themes" / theme / "theme.conf").read_text(), original)
                self.assertNotIn("Choice", result.stdout)
                self.assertNotIn("Do you want to proceed?", result.stdout)

    def test_both_backends_reject_invalid_theme_before_writing(self):
        for backend in ("sddm", "quickshell"):
            for args in (("--theme", "../themes/terraria"), ("--theme", "missing"), ("--theme",), ("--theme", "")):
                with self.subTest(backend=backend, args=args):
                    result = self.run_backend(backend, *args)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertFalse(self.sddm_themes.exists())
        self.assertFalse((self.root / "home").exists())

    def test_sddm_qt5_keeps_the_shared_variant(self):
        shutil.copytree(self.root / "themes", self.root / "themes-qt5")
        legacy_main = self.root / "themes-qt5/clockwork/tape/Main.qml"
        legacy_main.write_text("import QtQuick 2.15\nItem {}\n")
        result = self.run_backend("sddm", "--theme", "clockwork/tape", "--qt5")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.sddm_themes / "tape/Main.qml").read_text(), legacy_main.read_text())
        self.assertNotIn("Choice", result.stdout)


if __name__ == "__main__":
    unittest.main()
