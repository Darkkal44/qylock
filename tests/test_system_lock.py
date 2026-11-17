"""System packages, multi-profile migration and restoration in temporary roots."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


REPO = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("system_lock", REPO / "scripts/system-lock.py")
system = importlib.util.module_from_spec(spec)
spec.loader.exec_module(system)


class SystemLockTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="qylock system ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for name, value in {
            "DATA": self.root / "usr/local/share",
            "HELPER": self.root / "usr/local/libexec/qylock/system-lock.py",
            "AUTOSTART": self.root / "etc/xdg/autostart/qylock-profile-sync.desktop",
            "LAUNCHER": self.root / "usr/local/bin/qylock-lock",
        }.items():
            override = patch.object(system, name, value)
            override.start()
            self.addCleanup(override.stop)
        self.home = self.root / "home/alice"
        self.home.mkdir(parents=True)
        environment = patch.dict(os.environ, HOME=str(self.home),
                                 XDG_DATA_HOME=str(self.home / ".local/share"),
                                 XDG_STATE_HOME=str(self.home / ".local/state"))
        environment.start()
        self.addCleanup(environment.stop)
        self.shell = self.root / "distribution/plasma/shells" / system.SHELL_ID
        (self.shell / "contents/lockscreen").mkdir(parents=True)
        (self.shell / "contents/views").mkdir()
        (self.shell / "contents/lockscreen/LockScreen.qml").write_text("import QtQuick\nItem {}\n")
        (self.shell / "metadata.json").write_text(json.dumps({
            "KPackageStructure": "Plasma/Shell", "KPlugin": {"Id": system.SHELL_ID}, "X-Plasma-APIVersion": "2",
        }))
        original_run = system.runpy.run_path

        def native_fixture(path):
            module = original_run(path)
            module["system_shell"] = lambda: self.shell
            return module

        native = patch.object(system.runpy, "run_path", side_effect=native_fixture)
        native.start()
        self.addCleanup(native.stop)

    def package(self, backend="kde", theme="nier-automata"):
        output = Path(tempfile.mkdtemp(dir=self.root))
        system.prepare(output, backend, theme)
        return output

    def local_kde(self, home=None, override=False):
        path = (home or self.home) / ".local/share/plasma/shells" / system.SHELL_ID
        path.mkdir(parents=True)
        (path / ".qylock.json").write_text(json.dumps({
            "owner": "qylock-kde", "schema": 1, "theme": "material-you", "profileOverride": override,
        }))
        (path / "personal-data").write_text("keep me")
        return path

    def local_quickshell(self):
        path = self.home / ".local/share/quickshell-lockscreen"
        shutil.copytree(REPO / "quickshell-lockscreen", path)
        return path

    def test_kde_system_package_is_self_contained_and_readable_by_other_users(self):
        old_umask = os.umask(0o077)
        try:
            package = self.package()
            system.apply(package)
        finally:
            os.umask(old_umask)
        target = system.target_for("kde")
        shutil.rmtree(package)
        self.assertTrue(system.managed(target, "kde"))
        self.assertTrue((target / "contents/lockscreen/theme/bg.png").is_file())
        self.assertFalse((target / "contents/views").is_symlink())
        self.assertTrue((target / "contents/views").is_dir())
        self.assertEqual(target.stat().st_mode & 0o777, 0o755)
        self.assertEqual(target.parent.stat().st_mode & 0o777, 0o755)
        self.assertEqual(system.HELPER.parent.stat().st_mode & 0o777, 0o755)
        self.assertEqual((target / "contents/lockscreen/LockScreen.qml").stat().st_mode & 0o777, 0o644)
        self.assertIn("sync-profile", system.AUTOSTART.read_text())

    def test_two_profiles_migrate_then_share_updates_without_reinstalling(self):
        bob = self.root / "home/bob"
        bob.mkdir()
        first = self.local_kde()
        second = self.local_kde(bob)
        system.apply(self.package())
        for home in (self.home, bob):
            with patch.dict(os.environ, HOME=str(home), XDG_DATA_HOME=str(home / ".local/share"),
                            XDG_STATE_HOME=str(home / ".local/state")):
                system.sync_profile()
                state = home / ".local/state/qylock/system-sync/kde.json"
                record = json.loads(state.read_text())
                self.assertEqual((Path(record["backup"]) / "personal-data").read_text(), "keep me")
        self.assertFalse(first.exists())
        self.assertFalse(second.exists())
        system.apply(self.package(theme="material-you"))
        self.assertEqual(system.metadata(system.target_for("kde") / system.MARKER)["theme"], "material-you")
        # A new account has no profile overlay; it uses the same system package.
        self.assertFalse((self.root / "home/new/.local/share/plasma/shells" / system.SHELL_ID).exists())
        system.sync_profile()
        self.assertFalse(first.exists())

    def test_unrelated_and_explicit_profile_overrides_are_preserved(self):
        local = self.local_kde(override=True)
        system.apply(self.package())
        system.sync_profile()
        self.assertTrue(local.exists())
        (local / ".qylock.json").unlink()
        system.sync_profile()
        self.assertEqual((local / "personal-data").read_text(), "keep me")

    def test_symlink_profile_override_is_preserved(self):
        destination = self.root / "custom"
        destination.mkdir()
        (destination / ".qylock.json").write_text('{"owner":"qylock-kde","schema":1}')
        local = self.home / ".local/share/plasma/shells" / system.SHELL_ID
        local.parent.mkdir(parents=True)
        local.symlink_to(destination)
        system.apply(self.package())
        system.sync_profile()
        self.assertTrue(local.is_symlink())
        self.assertTrue(destination.exists())

    def test_uninstall_restores_previous_profile_overlay(self):
        local = self.local_kde()
        system.apply(self.package())
        system.sync_profile()
        with patch.object(system, "sync_accounts", side_effect=lambda restore: system.sync_profile(restore)):
            system.uninstall("kde")
        self.assertEqual((local / "personal-data").read_text(), "keep me")
        self.assertFalse(system.target_for("kde").exists())
        self.assertTrue(system.AUTOSTART.exists())

    def test_profile_changes_after_migration_are_not_overwritten_during_restore(self):
        local = self.local_kde()
        system.apply(self.package())
        system.sync_profile()
        local.mkdir()
        (local / "new-theme").write_text("mine")
        system.sync_profile(restore="kde")
        self.assertEqual((local / "new-theme").read_text(), "mine")

    def test_failed_backup_record_restores_profile_immediately(self):
        local = self.local_kde()
        system.apply(self.package())
        with patch.object(system, "atomic_file", side_effect=OSError("disk full")):
            with self.assertRaises(OSError):
                system.sync_profile()
        self.assertEqual((local / "personal-data").read_text(), "keep me")

    def test_unrelated_system_package_is_refused(self):
        target = system.target_for("kde")
        target.mkdir(parents=True)
        (target / "mine").write_text("unchanged")
        with self.assertRaisesRegex(ValueError, "unrelated system package"):
            system.apply(self.package())
        self.assertEqual((target / "mine").read_text(), "unchanged")
        self.assertFalse(system.AUTOSTART.exists())

    def test_unrelated_helper_and_dangling_launcher_are_refused(self):
        system.HELPER.parent.mkdir(parents=True)
        system.HELPER.write_text("someone else's helper")
        with self.assertRaisesRegex(ValueError, "unrelated helper"):
            system.apply(self.package())
        system.HELPER.unlink()
        system.LAUNCHER.parent.mkdir(parents=True)
        system.LAUNCHER.symlink_to("/missing/unrelated")
        with self.assertRaisesRegex(ValueError, "unrelated launcher"):
            system.apply(self.package("quickshell"))

    def test_profile_sync_drops_root_and_passes_current_xdg_paths(self):
        users = [SimpleNamespace(pw_name="alice", pw_uid=1000, pw_gid=1000, pw_dir=str(self.home)),
                 SimpleNamespace(pw_name="bob", pw_uid=1001, pw_gid=1001, pw_dir=str(self.root / "home/bob"))]
        with patch.object(system, "accounts", return_value=users), \
                patch.dict(os.environ, SUDO_UID="1000"), \
                patch.object(system.subprocess, "run", return_value=SimpleNamespace(returncode=0, stdout="", stderr="")) as run:
            system.sync_accounts(data_home="/custom/data", state_home="/custom/state")
        self.assertEqual([call.kwargs["user"] for call in run.call_args_list], [1000, 1001])
        self.assertEqual([call.kwargs["group"] for call in run.call_args_list], [1000, 1001])
        self.assertEqual(run.call_args_list[0].kwargs["env"]["XDG_DATA_HOME"], "/custom/data")
        self.assertNotIn("XDG_DATA_HOME", run.call_args_list[1].kwargs["env"])

    def test_profile_sync_failure_is_reported(self):
        user = SimpleNamespace(pw_name="alice", pw_uid=1000, pw_gid=1000, pw_dir=str(self.home))
        with patch.object(system, "accounts", return_value=[user]), \
                patch.object(system.subprocess, "run", return_value=SimpleNamespace(returncode=1, stdout="", stderr="disk full")):
            with self.assertRaisesRegex(ValueError, "alice: disk full"):
                system.sync_accounts()

    def test_quickshell_global_launcher_and_legacy_profile_follow_same_package(self):
        local = self.local_quickshell()
        system.apply(self.package("quickshell"))
        system.sync_profile()
        self.assertTrue(system.forwarding(local))
        self.assertEqual(system.LAUNCHER.resolve(), (system.target_for("quickshell") / "lock.sh").resolve())
        system.sync_profile()
        system.apply(self.package("quickshell", "material-you"))
        self.assertEqual((system.target_for("quickshell") / "theme").read_text().strip(), "material-you")
        binary = self.root / "bin"
        binary.mkdir()
        quickshell = binary / "quickshell"
        quickshell.write_text('#!/bin/sh\nprintf "%s\\n%s\\n" "$QS_THEME" "$QS_THEME_PATH"\n')
        quickshell.chmod(0o755)
        result = subprocess.run(["bash", str(local / "lock.sh")], text=True, capture_output=True,
                                env=dict(os.environ, PATH=str(binary) + ":" + os.environ["PATH"], XDG_SESSION_TYPE="wayland"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines()[0], "material-you")
        self.assertTrue(Path(result.stdout.splitlines()[1]).is_dir())

    def test_quickshell_restore_removes_forwarder_and_recovers_old_package(self):
        local = self.local_quickshell()
        original = (local / "lock.sh").read_text()
        system.apply(self.package("quickshell"))
        system.sync_profile()
        system.sync_profile(restore="quickshell")
        self.assertFalse((local / "lock.sh").is_symlink())
        self.assertEqual((local / "lock.sh").read_text(), original)

    def test_prepare_invalid_theme_is_rejected_without_output(self):
        output = self.root / "invalid"
        with self.assertRaises(ValueError):
            system.prepare(output, "kde", "../themes/nier-automata")
        self.assertFalse(output.exists())

    def test_failed_activation_restores_previous_system_package(self):
        system.apply(self.package())
        target = system.target_for("kde")
        original_rename = Path.rename

        def fail_new(path, destination):
            if path.name == "new" and destination == target:
                raise OSError("activation failed")
            return original_rename(path, destination)

        package = self.package(theme="material-you")
        with patch.object(Path, "rename", fail_new):
            with self.assertRaises(OSError):
                system.apply(package)
        self.assertEqual(system.metadata(target / system.MARKER)["theme"], "nier-automata")

    def test_quickshell_uninstall_preserves_added_profile_files(self):
        local = self.local_quickshell()
        system.apply(self.package("quickshell"))
        system.sync_profile()
        (local / "my-settings").write_text("preserve")
        system.sync_profile(restore="quickshell")
        self.assertEqual((local / "my-settings").read_text(), "preserve")
        self.assertTrue((self.home / ".local/state/qylock/system-sync/quickshell.json").is_file())

    def test_uninstall_failure_keeps_system_package_for_retry(self):
        system.apply(self.package())
        with patch.object(system, "sync_accounts", side_effect=ValueError("profile unavailable")):
            with self.assertRaises(ValueError):
                system.uninstall("kde")
        self.assertTrue(system.managed(system.target_for("kde"), "kde"))

    def test_accounts_excludes_root_services_and_unavailable_homes(self):
        users = [SimpleNamespace(pw_uid=1000, pw_dir=str(self.home), pw_shell="/bin/bash"),
                 SimpleNamespace(pw_uid=0, pw_dir=str(self.home), pw_shell="/bin/bash"),
                 SimpleNamespace(pw_uid=200, pw_dir=str(self.home), pw_shell="/bin/bash"),
                 SimpleNamespace(pw_uid=1002, pw_dir=str(self.home), pw_shell="/usr/bin/nologin"),
                 SimpleNamespace(pw_uid=1003, pw_dir=str(self.root / "absent"), pw_shell="/bin/bash")]
        with patch.object(system.pwd, "getpwall", return_value=users):
            self.assertEqual(system.accounts(), [users[0]])

    def test_offline_profile_restores_automatically_on_its_next_login(self):
        local = self.local_kde()
        system.apply(self.package())
        system.sync_profile()
        with patch.object(system, "sync_accounts"):
            system.uninstall("kde")
        self.assertFalse(local.exists())
        system.sync_profile()
        self.assertEqual((local / "personal-data").read_text(), "keep me")

    def test_qt_discovers_shared_package_from_different_profiles(self):
        qtpaths = shutil.which("qtpaths6") or "/usr/lib/qt6/bin/qtpaths"
        if not Path(qtpaths).is_file():
            self.skipTest("Qt path-query utility is not installed")
        system.apply(self.package())
        for name in ("alice", "bob", "new-profile"):
            home = self.root / "home" / name
            result = subprocess.run([qtpaths, "--locate-dir", "GenericDataLocation",
                                     "plasma/shells/" + system.SHELL_ID], capture_output=True, text=True,
                                    env=dict(os.environ, HOME=str(home), XDG_DATA_HOME=str(home / ".local/share"),
                                             XDG_DATA_DIRS=str(system.DATA) + ":" + str(self.shell.parents[2])))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(Path(result.stdout.strip()), system.target_for("kde"))


if __name__ == "__main__":
    unittest.main()
