import importlib.util
import contextlib
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
import subprocess
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("manage", Path(__file__).parents[1] / "manage.py")
manage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manage)


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.shell = self.root / "system" / manage.SHELL_ID
        (self.shell / "contents/lockscreen").mkdir(parents=True)
        (self.shell / "contents/views").mkdir()
        (self.shell / "contents/logout").mkdir()
        (self.shell / "contents/logout/Logout.qml").write_text("logout")
        (self.shell / "contents/main.js").write_text("// desktop shell")
        (self.shell / "contents/lockscreen/LockScreen.qml").write_text("system locker")
        (self.shell / "contents/lockscreen/LockScreenUi.qml").write_text("startAuthenticating authenticator.respond")
        (self.shell / "metadata.json").write_text(json.dumps({
            "KPlugin": {"Id": manage.SHELL_ID}, "X-Plasma-APIVersion": "2"
        }))
        self.env = patch.dict(os.environ, {"XDG_DATA_HOME": str(self.root / "user"),
                                         "XDG_CONFIG_HOME": str(self.root / "config")})
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_build_copies_shell_components_inside_the_package(self):
        destination = self.root / "package"
        manage.build(destination, self.shell, "nier-automata")
        self.assertFalse((destination / "contents/views").is_symlink())
        self.assertFalse((destination / "contents/logout").is_symlink())
        self.assertFalse((destination / "metadata.json").is_symlink())
        self.assertEqual((destination / "contents/logout/Logout.qml").read_text(), "logout")
        self.assertEqual((destination / "contents/main.js").read_text(), "// desktop shell")
        self.assertEqual(manage.escaping_symlinks(destination), [])
        self.assertFalse((destination / "contents/lockscreen").is_symlink())
        self.assertEqual((self.shell / "contents/lockscreen/LockScreen.qml").read_text(), "system locker")
        locker = destination / "contents/lockscreen"
        self.assertTrue((locker / "theme/bg.png").is_file())
        self.assertIn('import "../compat"', (locker / "theme/Main.qml").read_text())
        self.assertIn('"background": "bg.png"', (locker / "ThemeConfig.qml").read_text())
        marker = json.loads((destination / manage.MARKER).read_text())
        self.assertEqual(marker["system_fingerprint"], manage.shell_fingerprint(self.shell))

    def test_build_dereferences_linked_shell_components(self):
        outside = self.root / "elsewhere"
        (outside / "views").mkdir(parents=True)
        (outside / "views/Desktop.qml").write_text("desktop")
        (self.shell / "contents/views").rmdir()
        (self.shell / "contents/views").symlink_to(outside / "views")
        destination = self.root / "package"
        manage.build(destination, self.shell, "nier-automata")
        self.assertFalse((destination / "contents/views").is_symlink())
        self.assertEqual((destination / "contents/views/Desktop.qml").read_text(), "desktop")
        self.assertEqual(manage.escaping_symlinks(destination), [])

    def test_install_update_uninstall(self):
        manage.install(self.shell, "nier-automata")
        target = manage.install_path()
        self.assertTrue(manage.owned(target))
        manage.install(self.shell, "nier-automata")
        with patch("sys.argv", ["manage", "uninstall"]):
            self.assertEqual(manage.main(), 0)
        self.assertFalse(target.exists())
        self.assertTrue(self.shell.exists())

    def test_install_switches_to_another_theme(self):
        manage.install(self.shell, "nier-automata")
        manage.install(self.shell, "material-you")
        self.assertEqual(manage.current_theme(), "material-you")
        marker = json.loads((manage.install_path() / manage.MARKER).read_text())
        self.assertEqual(marker["theme"], "material-you")

    def test_status_and_theme_follow_system_default_without_a_profile_overlay(self):
        package = self.root / "system-default"
        manage.build(package, self.shell, "material-you")
        (package / ".qylock-system.json").write_text('{"owner":"qylock-system-lock"}')
        with patch.object(manage, "SYSTEM_PACKAGE", package):
            self.assertEqual(manage.active_install_path(), package)
            self.assertEqual(manage.current_theme(), "material-you")
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                manage.main(["status"])
            self.assertIn("system-wide", output.getvalue())

    def test_explicit_profile_install_is_marked_as_an_override(self):
        manage.install(self.shell, "nier-automata")
        marker = json.loads((manage.install_path() / manage.MARKER).read_text())
        self.assertTrue(marker["profileOverride"])

    def test_generic_port_preserves_source_and_adds_locker_contract(self):
        original = (manage.REPO / "themes/material-you/Main.qml").read_text()
        destination = self.root / "material"
        manage.build(destination, self.shell, "material-you")
        generated = (destination / "contents/lockscreen/theme/Main.qml").read_text()
        self.assertIn("property alias kdePasswordControl: pwd", generated)
        self.assertIn("enabled: qylockBackend.canSubmit", generated)
        self.assertIn("function onClearRequested()", generated)
        self.assertIn("root.errorMessage = message", generated)
        self.assertIn("property bool isQuickshell: true", generated)
        self.assertEqual((manage.REPO / "themes/material-you/Main.qml").read_text(), original)

    def test_discovery_includes_nested_variants(self):
        self.assertIn("clockwork/tape", manage.available_themes())
        self.assertNotIn("clockwork", manage.available_themes())
        self.assertEqual(set(manage.THEMES), set(manage.available_themes()))

    def test_unported_and_path_traversal_rejected_before_build(self):
        for theme in ("../material-you", "/tmp", "does-not-exist"):
            with self.subTest(theme=theme):
                with self.assertRaises(ValueError):
                    manage.build(self.root / "rejected", self.shell, theme)
        self.assertFalse((self.root / "rejected").exists())

    def test_changed_password_field_rejected(self):
        with self.assertRaises(ValueError):
            manage.adapt_theme("import QtQuick\nItem { id: root }", {"passwordId": "missing"})

    def test_changed_message_target_rejected(self):
        source = (manage.REPO / "themes/material-you/Main.qml").read_text()
        port = dict(manage.THEMES["material-you"], messageTarget="root.missing")
        with self.assertRaisesRegex(ValueError, "Message property"):
            manage.adapt_theme(source, port)

    def test_all_username_selectors_are_adapted_without_changing_source(self):
        for theme, port in manage.THEMES.items():
            with self.subTest(theme=theme):
                path = manage.REPO / "themes" / theme / "Main.qml"
                original = path.read_text()
                generated = manage.adapt_theme(original, port)
                self.assertEqual(generated.count('"qylockUserSwitch"'), 1)
                self.assertIn("sddm.switchUser();", generated)
                self.assertIn("sddm.canSwitchUser", generated)
                self.assertIn("Accessible.onPressAction:", generated)
                self.assertEqual(path.read_text(), original)

    def test_changed_or_ambiguous_username_action_rejected(self):
        source = 'Item { MouseArea { onClicked: { root.userIndex = 1; } } }'
        with self.assertRaisesRegex(ValueError, "Username selector changed"):
            manage.adapt_user_switch(source, {"userSwitchAction": "missing()"})
        with self.assertRaisesRegex(ValueError, "Username selector changed"):
            manage.adapt_user_switch(source + source, {"userSwitchAction": "root.userIndex ="})
        with self.assertRaisesRegex(ValueError, "userSwitchAction is required"):
            manage.adapt_user_switch(source, {})

    def test_username_selector_is_included_in_custom_tab_loop(self):
        source = (manage.REPO / "themes/minecraft/Main.qml").read_text()
        generated = manage.adapt_theme(source, manage.THEMES["minecraft"])
        self.assertIn("KeyNavigation.tab: userMouse", generated)
        self.assertNotIn("KeyNavigation.tab: passInput", generated)

    def test_numbered_picker_retries_and_selects(self):
        choices = [theme for theme in manage.available_themes() if theme in manage.THEMES]
        number = str(choices.index("material-you") + 1)
        with patch("sys.stdin.isatty", return_value=True), patch.object(manage.shutil, "which", return_value=None), \
                patch("builtins.input", side_effect=["invalid", "999", number]), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(manage.choose_theme(), "material-you")

    def test_fzf_selects_and_cancel_is_not_defaulted(self):
        def select(command, **kwargs):
            line = next(line for line in kwargs["input"].splitlines() if line.startswith("pixel-coffee "))
            return subprocess.CompletedProcess(command, 0, line + "\n")

        with patch("sys.stdin.isatty", return_value=True), patch.object(manage.shutil, "which", return_value="/bin/fzf"):
            with patch.object(manage.subprocess, "run", side_effect=select):
                self.assertEqual(manage.choose_theme(), "pixel-coffee")
            with patch.object(manage.subprocess, "run", return_value=subprocess.CompletedProcess([], 130, "")):
                self.assertIsNone(manage.choose_theme())

    def test_cancel_never_installs(self):
        with patch.object(manage, "choose_theme", return_value=None), patch.object(manage, "install") as install:
            self.assertEqual(manage.main(["select"]), 0)
            install.assert_not_called()

    def test_picker_rejects_noninteractive_input(self):
        with patch("sys.stdin.isatty", return_value=False):
            with self.assertRaises(ValueError):
                manage.choose_theme()

    def test_themes_command_lists_every_theme_as_ported(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(manage.main(["themes", "--all"]), 0)
        self.assertNotIn("needs KDE port", output.getvalue())
        self.assertIn("clockwork/tape", output.getvalue())

    def test_doctor_detects_disabled_password_and_legacy_shortcut(self):
        config = self.root / "config"
        config.mkdir()
        (config / "kscreenlockerrc").write_text("[Daemon]\nRequirePassword=false\n")
        (config / "kglobalshortcutsrc").write_text("[services][net.local.qylock.desktop]\n_launch=Meta+L\n")
        launcher = self.root / "user/applications/net.local.qylock.desktop"
        launcher.parent.mkdir(parents=True)
        launcher.write_text("[Desktop Entry]\nExec=qylock\n")
        with patch.object(manage.shutil, "which", return_value=None):
            password, resume, issues = manage.setup_diagnostics()
        self.assertFalse(password)
        self.assertTrue(resume)
        self.assertEqual(len(issues), 2)
        self.assertIn("old qylock", issues[1])

        with patch.object(manage.shutil, "which", return_value=str(manage.REPO / "kde-lockscreen/lock.sh")):
            self.assertEqual(len(manage.setup_diagnostics()[2]), 1)

    def test_doctor_accepts_native_shortcut_and_default_settings(self):
        self.assertEqual(manage.setup_diagnostics(), (True, True, []))

    def test_overlay_diagnostics_flags_links_outside_the_package(self):
        manage.install(self.shell, "nier-automata")
        target = manage.install_path()
        self.assertEqual(manage.overlay_diagnostics(target), [])
        (target / "contents/views-link").symlink_to(self.shell / "contents/views", target_is_directory=True)
        issues = manage.overlay_diagnostics(target)
        self.assertEqual(len(issues), 1)
        self.assertIn("link outside the package", issues[0])

    def test_overlay_diagnostics_flags_stale_snapshot(self):
        manage.install(self.shell, "nier-automata")
        target = manage.install_path()
        marker = json.loads((target / manage.MARKER).read_text())
        marker["system_fingerprint"] = "0" * 64
        (target / manage.MARKER).write_text(json.dumps(marker))
        issues = manage.overlay_diagnostics(target)
        self.assertEqual(len(issues), 1)
        self.assertIn("older Plasma shell", issues[0])

    def test_doctor_reports_overlay_problems(self):
        manage.install(self.shell, "nier-automata")
        target = manage.install_path()
        (target / "contents/views-link").symlink_to(self.shell / "contents/views", target_is_directory=True)
        with contextlib.redirect_stdout(io.StringIO()) as output:
            manage.doctor()
        self.assertIn("link outside the package", output.getvalue())
        self.assertIn("Reinstall the KDE theme", output.getvalue())

    def test_lock_requests_native_immediate_lock(self):
        with patch.object(manage, "dbus_client", return_value="qdbus6"), \
                patch.object(manage.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "", "")) as run:
            self.assertEqual(manage.main(["lock"]), 0)
            self.assertEqual(run.call_args.args[0], ["qdbus6", "org.freedesktop.ScreenSaver", "/ScreenSaver",
                                                     "org.freedesktop.ScreenSaver.Lock"])

    def test_lock_reports_native_service_failure(self):
        with patch.object(manage, "dbus_client", return_value="qdbus6"), \
                patch.object(manage.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "", "No session bus")):
            with self.assertRaisesRegex(ValueError, "No session bus"):
                manage.lock_session()

    def test_unrelated_overlay_preserved(self):
        target = manage.install_path()
        target.mkdir(parents=True)
        existing = target / "custom.qml"
        existing.write_text("user content")
        with self.assertRaises(ValueError):
            manage.install(self.shell, "nier-automata")
        with patch("sys.argv", ["manage", "uninstall"]):
            with self.assertRaises(ValueError):
                manage.main()
        self.assertEqual(existing.read_text(), "user content")

    def test_symlink_overlay_preserved(self):
        target = manage.install_path()
        target.parent.mkdir(parents=True)
        target.symlink_to(self.shell, target_is_directory=True)
        with self.assertRaises(ValueError):
            manage.install(self.shell, "nier-automata")
        self.assertTrue(target.is_symlink())

    def test_failed_activation_restores_previous(self):
        manage.install(self.shell, "nier-automata")
        rename = Path.rename

        def fail_activation(path, target):
            if path.name == "new":
                raise OSError("simulated activation failure")
            return rename(path, target)

        with patch.object(Path, "rename", fail_activation):
            with self.assertRaises(OSError):
                manage.install(self.shell, "nier-automata")
        self.assertTrue(manage.owned(manage.install_path()))

    def test_build_refuses_nonempty_directory(self):
        destination = self.root / "existing"
        destination.mkdir()
        (destination / "keep").write_text("keep")
        with self.assertRaises(ValueError):
            manage.build(destination, self.shell, "nier-automata")

    def test_incompatible_shell_rejected(self):
        (self.shell / "metadata.json").write_text("{}")
        with self.assertRaises(ValueError):
            manage.system_shell(str(self.shell))

    def test_shell_discovery_skips_qylock_overlays(self):
        overlay = self.root / "overlay/plasma/shells" / manage.SHELL_ID
        shutil.copytree(self.shell, overlay)
        (overlay / manage.MARKER).write_text(json.dumps({"owner": "qylock-kde", "schema": 1}))
        distro = self.root / "distro/plasma/shells" / manage.SHELL_ID
        shutil.copytree(self.shell, distro)
        with patch.dict(os.environ, {"XDG_DATA_DIRS": f"{self.root}/overlay:{self.root}/distro"}):
            self.assertEqual(manage.system_shell(), distro.resolve())


if __name__ == "__main__":
    unittest.main()
