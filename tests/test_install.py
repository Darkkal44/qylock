"""Exercise detection and multi-backend dispatch without touching the desktop."""

import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


INSTALLER = Path(__file__).resolve().parents[1] / "install.sh"


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="qylock setup ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.script = self.root / "install.sh"
        shutil.copy2(INSTALLER, self.script)
        (self.root / "scripts").mkdir()
        shutil.copy2(INSTALLER.parent / "scripts/themes.sh", self.root / "scripts/themes.sh")
        (self.root / "scripts/system-lock.py").write_text('''import json, os, pathlib, sys
args = sys.argv
if args[1] == "prepare":
    folder = pathlib.Path(args[args.index("--output") + 1])
    backend = args[args.index("--backend") + 1]
    theme = args[args.index("--theme") + 1]
    (folder / "test-package.json").write_text(json.dumps([backend, theme]))
    sys.exit(int(os.environ.get("PREPARE_STATUS", "0")))
folder = pathlib.Path(args[args.index("--package") + 1])
backend, theme = json.loads((folder / "test-package.json").read_text())
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(f"system {backend} --theme {theme}\\n")
sys.exit(int(os.environ.get(backend.upper() + "_STATUS", "0")))
''')
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.bash = shutil.which("bash")
        for name in ("bash", "dirname", "readlink", "cat", "python3", "mktemp", "rm"):
            (self.bin / name).symlink_to(shutil.which(name))
        for name in ("sddm", "quickshell", "sudo"):
            self.executable(self.bin / name, 'exit "${PREFLIGHT_STATUS:-0}"\n')
        self.executable(self.bin / "sudo", 'exec "$@"\n')
        for name in ("sddm", "quickshell", "kde"):
            self.executable(self.root / f"{name}.sh",
                            f'printf "%s\\n" "{name} $*" >> "$CALL_LOG"\n'
                            f'exit "${{{name.upper()}_STATUS:-0}}"\n')
        (self.root / "kde-lockscreen").mkdir()
        (self.root / "kde-lockscreen/manage.py").write_text(
            'import os\ndef system_shell():\n'
            '    if os.environ.get("PREFLIGHT_STATUS") == "1": raise ValueError("incompatible shell")\n'
            'def greeter(): pass\n')
        themes = ["nier-automata", "material-you", "clockwork/tape"]
        (self.root / "kde-lockscreen/themes.json").write_text(json.dumps({theme: {} for theme in themes}))
        for theme in [*themes, "sddm-only"]:
            folder = self.root / "themes" / theme
            folder.mkdir(parents=True)
            (folder / "Main.qml").write_text("import QtQuick\nItem {}\n")
            (folder / "theme.conf").write_text("[General]\n")
        self.log = self.root / "calls"
        self.env = {key: value for key, value in os.environ.items()
                    if key not in ("XDG_CURRENT_DESKTOP", "XDG_SESSION_DESKTOP", "DESKTOP_SESSION",
                                   "XDG_SESSION_TYPE", "HYPRLAND_INSTANCE_SIGNATURE", "SWAYSOCK")}
        self.env.update(PATH=str(self.bin), CALL_LOG=str(self.log), TEST_DM="sddm",
                        XDG_CURRENT_DESKTOP="KDE", XDG_SESSION_TYPE="wayland")

    @staticmethod
    def executable(path, body):
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def run_installer(self, *args, interactive=False, answers="", env=None):
        setup = 'source "$1"; shift; detect_display_manager() { printf "%s\\n" "$TEST_DM"; }; '
        if interactive:
            setup += 'interactive() { return 0; }; '
        return subprocess.run([self.bash, "-c", setup + 'main "$@"', "test", str(self.script), *args],
                              input=answers, env=dict(self.env, **(env or {})),
                              text=True, capture_output=True, cwd="/tmp")

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_kde_and_sddm_detection_is_read_only(self):
        result = self.run_installer("--detect")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Recommended login: sddm", result.stdout)
        self.assertIn("Recommended lock: kde", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_installed_binaries_do_not_override_another_desktop(self):
        for desktop in ("GNOME", "ubuntu:GNOME", "X-Cinnamon", "XFCE", "unknown"):
            with self.subTest(desktop=desktop):
                result = self.run_installer("--dry-run", env={"XDG_CURRENT_DESKTOP": desktop,
                                                            "TEST_DM": "gdm"})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Selected login: none", result.stdout)
                self.assertIn("Selected lock: none", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_sddm_is_independent_of_session(self):
        result = self.run_installer("--dry-run", env={"XDG_CURRENT_DESKTOP": "GNOME"})
        self.assertIn("Run: ./sddm.sh", result.stdout)
        self.assertIn("Selected lock: none", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_wayland_compositors_choose_quickshell(self):
        for desktop in ("Hyprland", "sway", "sway:wlroots"):
            with self.subTest(desktop=desktop):
                result = self.run_installer("--dry-run", env={"XDG_CURRENT_DESKTOP": desktop})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("install system-wide quickshell theme", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_session_fallbacks_and_stale_compositor_hints(self):
        for hints, expected in (({"XDG_SESSION_DESKTOP": "plasma"}, "kde"),
                                ({"HYPRLAND_INSTANCE_SIGNATURE": "test"}, "quickshell"),
                                ({"SWAYSOCK": "/tmp/test"}, "quickshell"),
                                ({"XDG_CURRENT_DESKTOP": "Hyprland", "XDG_SESSION_DESKTOP": "plasma"}, "quickshell"),
                                ({"XDG_CURRENT_DESKTOP": "KDE", "XDG_SESSION_DESKTOP": "sway"}, "kde"),
                                ({"XDG_CURRENT_DESKTOP": "unknown", "SWAYSOCK": "stale"}, "none"),
                                ({"XDG_CURRENT_DESKTOP": "KDE", "SWAYSOCK": "stale"}, "kde"),
                                ({"XDG_CURRENT_DESKTOP": "GNOME", "SWAYSOCK": "stale"}, "none")):
            with self.subTest(hints=hints):
                result = self.run_installer("--detect", env={"XDG_CURRENT_DESKTOP": "", **hints})
                self.assertIn(f"Recommended lock: {expected}", result.stdout)

    def test_x11_does_not_automatically_choose_quickshell(self):
        result = self.run_installer("--detect", env={"XDG_CURRENT_DESKTOP": "sway", "XDG_SESSION_TYPE": "x11"})
        self.assertIn("Recommended lock: none", result.stdout)

    def test_display_manager_from_system_files(self):
        system = self.root / "system"
        service = system / "etc/systemd/system/display-manager.service"
        service.parent.mkdir(parents=True)
        service.symlink_to("/usr/lib/systemd/system/sddm.service")
        default = system / "etc/X11/default-display-manager"
        default.parent.mkdir(parents=True)
        default.write_text("/usr/sbin/lightdm\n")
        command = [self.bash, "-c", 'source "$1"; detect_display_manager "$2"',
                   "test", str(self.script), str(system)]
        self.assertEqual(subprocess.check_output(command, text=True, env=self.env).strip(), "sddm")
        service.unlink()
        self.assertEqual(subprocess.check_output(command, text=True, env=self.env).strip(), "lightdm")
        default.unlink()
        self.assertEqual(subprocess.check_output(command, text=True, env=self.env).strip(), "unknown")

    def test_default_selection_runs_both_installers_in_order(self):
        result = self.run_installer(interactive=True, answers="\n\n\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sddm --theme nier-automata", "system kde --theme nier-automata"])
        self.assertEqual(result.stdout.count("Shared login and lock theme"), 1)

    def test_manual_selection_can_skip_login(self):
        result = self.run_installer("--login", "none", "--lock", "quickshell", "--theme", "material-you", interactive=True,
                                    env={"XDG_CURRENT_DESKTOP": "Hyprland"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["system quickshell --theme material-you"])

    def test_picker_retries_invalid_input(self):
        result = self.run_installer(interactive=True, answers="invalid\nsddm/none\nnone\nkde\n\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["system kde --theme nier-automata"])

    def test_cancel_before_dispatch_changes_nothing(self):
        for answers in ("q\n", "sddm\nq\n", "\n\nq\n", ""):
            with self.subTest(answers=answers):
                result = self.run_installer(interactive=True, answers=answers)
                self.assertEqual(result.returncode, 130, result.stderr)
        self.assertEqual(self.calls(), [])

    def test_missing_lock_dependency_prevents_partial_sddm_install(self):
        (self.bin / "quickshell").unlink()
        result = self.run_installer("--login", "sddm", "--lock", "quickshell", interactive=True,
                                    env={"XDG_CURRENT_DESKTOP": "sway"})
        self.assertEqual(result.returncode, 1)
        self.assertIn("Missing Quickshell", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_incompatible_kde_package_prevents_partial_install(self):
        result = self.run_installer("--login", "sddm", "--lock", "kde", interactive=True,
                                    env={"PREFLIGHT_STATUS": "1"})
        self.assertEqual(result.returncode, 1)
        self.assertIn("compatible Plasma shell", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_first_installer_failure_stops_second(self):
        result = self.run_installer(interactive=True, answers="\n\n\n", env={"SDDM_STATUS": "7"})
        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.calls(), ["sddm --theme nier-automata"])
        self.assertIn("Lock-screen setup was not started", result.stderr)

    def test_missing_second_script_prevents_partial_install(self):
        (self.root / "kde.sh").unlink()
        result = self.run_installer(interactive=True, answers="\n\n")
        self.assertEqual(result.returncode, 1)
        self.assertIn("complete Qylock checkout", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_second_installer_failure_reports_completed_work(self):
        result = self.run_installer(interactive=True, answers="\n\n\n", env={"KDE_STATUS": "8"})
        self.assertEqual(result.returncode, 8)
        self.assertEqual(self.calls(), ["sddm --theme nier-automata", "system kde --theme nier-automata"])
        self.assertIn("Completed installers: sddm", result.stderr)

    def test_quickshell_on_plasma_is_rejected(self):
        result = self.run_installer("--dry-run", "--lock", "quickshell")
        self.assertEqual(result.returncode, 2)
        self.assertIn("--lock kde", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_quickshell_on_gnome_or_x11_is_rejected(self):
        for desktop, session_type in (("GNOME", "wayland"), ("i3", "x11")):
            with self.subTest(desktop=desktop):
                result = self.run_installer("--dry-run", "--lock", "quickshell",
                                            env={"XDG_CURRENT_DESKTOP": desktop, "XDG_SESSION_TYPE": session_type})
                self.assertEqual(result.returncode, 2)
                self.assertIn("compatible Wayland session", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_noninteractive_install_and_invalid_arguments_are_read_only(self):
        for args in ((), ("--login",), ("--login", "gdm"), ("--lock", "hyprlock"), ("--bad",)):
            with self.subTest(args=args):
                result = self.run_installer(*args)
                self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(self.calls(), [])

    def test_executable_entry_point_without_sourcing(self):
        result = subprocess.run([self.bash, str(self.script), "--dry-run", "--login", "none", "--lock", "none"],
                                env=self.env, text=True, capture_output=True, cwd="/tmp")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Nothing changed", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_explicit_shared_theme_skips_all_theme_pickers(self):
        result = self.run_installer("--login", "sddm", "--lock", "kde", "--theme", "clockwork/tape", interactive=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sddm --theme clockwork/tape", "system kde --theme clockwork/tape"])
        self.assertNotIn("Shared login and lock theme", result.stdout)

    def test_separate_themes_are_opt_in_within_the_same_setup(self):
        result = self.run_installer("--separate-themes", interactive=True,
                                    answers="\n\nmaterial-you\nclockwork/tape\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sddm --theme material-you", "system kde --theme clockwork/tape"])

    def test_cancelling_second_theme_changes_nothing(self):
        result = self.run_installer("--separate-themes", interactive=True, answers="\n\nmaterial-you\nq\n")
        self.assertEqual(result.returncode, 130, result.stderr)
        self.assertEqual(self.calls(), [])

    def test_unported_theme_is_hidden_from_shared_kde_picker(self):
        result = self.run_installer(interactive=True, answers="\n\nclockwork/tape\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("sddm-only", result.stdout)
        self.assertEqual(self.calls(), ["sddm --theme clockwork/tape", "system kde --theme clockwork/tape"])

    def test_invalid_shared_theme_is_rejected_before_either_install(self):
        for theme in ("sddm-only", "../themes/material-you", "missing", "/tmp"):
            with self.subTest(theme=theme):
                result = self.run_installer("--theme", theme, interactive=True, answers="\n\n")
                self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(self.calls(), [])

    def test_shared_and_separate_theme_options_conflict(self):
        result = self.run_installer("--theme", "material-you", "--separate-themes", interactive=True)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_qt5_setting_only_affects_sddm(self):
        result = self.run_installer("--theme", "material-you", "--qt5", interactive=True, answers="\n\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sddm --theme material-you --qt5", "system kde --theme material-you"])

    def test_fzf_shared_selection_and_cancellation(self):
        self.executable(self.bin / "fzf", 'cat > /dev/null\nprintf "%s\\n" "$TEST_THEME"\nexit "${FZF_STATUS:-0}"\n')
        result = self.run_installer(interactive=True, answers="\n\n", env={"TEST_THEME": "material-you"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sddm --theme material-you", "system kde --theme material-you"])
        self.log.unlink()
        for status in ("1", "130"):
            result = self.run_installer(interactive=True, answers="\n\n",
                                        env={"TEST_THEME": "", "FZF_STATUS": status})
            self.assertEqual(result.returncode, 130, result.stderr)
            self.assertEqual(self.calls(), [])

    def test_lock_build_failure_prevents_sddm_install(self):
        result = self.run_installer("--theme", "material-you", interactive=True, answers="\n\n",
                                    env={"PREPARE_STATUS": "9"})
        self.assertEqual(result.returncode, 9)
        self.assertIn("No installation was started", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_lock_only_still_requires_system_privileges(self):
        (self.bin / "sudo").unlink()
        result = self.run_installer("--login", "none", "--theme", "material-you", interactive=True, answers="\n")
        self.assertEqual(result.returncode, 1)
        self.assertIn("system-wide theme installation", result.stderr)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
