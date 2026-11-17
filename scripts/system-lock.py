#!/usr/bin/env python3
"""Qylock system lock manager: shared packages and reversible profile migration."""

import argparse
import json
import os
from pathlib import Path
import pwd
import re
import runpy
import shutil
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parent.parent
DATA = Path("/usr/local/share")
HELPER = Path("/usr/local/libexec/qylock/system-lock.py")
AUTOSTART = Path("/etc/xdg/autostart/qylock-profile-sync.desktop")
LAUNCHER = Path("/usr/local/bin/qylock-lock")
SHELL_ID = "org.kde.plasma.desktop"
MARKER = ".qylock-system.json"
OWNER = "qylock-system-lock"


def metadata(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def target_for(backend):
    return (DATA / "plasma/shells" / SHELL_ID if backend == "kde"
            else DATA / "qylock/quickshell-lockscreen")


def managed(path, backend):
    value = metadata(path / MARKER)
    return (not path.is_symlink() and value.get("owner") == OWNER
            and value.get("schema") == 1 and value.get("backend") == backend)


def atomic_file(path, value, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(value.encode())
            stream.flush()
            temporary.chmod(mode)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def prepare(output, backend, theme):
    if not re.fullmatch(r"[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*", theme):
        raise ValueError("Invalid theme ID")
    source = REPO / "themes" / theme
    if not (source / "Main.qml").is_file():
        raise ValueError(f"Unknown theme: {theme}")
    if output.is_symlink() or (output.exists() and any(output.iterdir())):
        raise ValueError("Package output must be a new or empty directory")
    output.mkdir(parents=True, exist_ok=True)
    package = output / "payload"
    if backend == "kde":
        native = runpy.run_path(str(REPO / "kde-lockscreen/manage.py"))
        native["build"](package, native["system_shell"](), theme)
    else:
        shutil.copytree(REPO / "quickshell-lockscreen", package)
        shutil.copytree(source, package / "themes" / theme)
        (package / "theme").write_text(theme + "\n")
        (package / "lock.sh").write_text('''#!/usr/bin/env bash
set -euo pipefail
DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export QML2_IMPORT_PATH="$DIR/imports:${QML2_IMPORT_PATH:-}"
export QML_XHR_ALLOW_FILE_READ=1
if [[ "${XDG_SESSION_TYPE:-}" != wayland ]]; then
    echo 'Qylock requires a compatible Wayland session.' >&2
    exit 1
fi
IFS= read -r QS_THEME < "$DIR/theme"
export QS_THEME
export QS_THEME_PATH="$DIR/themes/$QS_THEME"
exec quickshell -p "$DIR/lock_shell.qml"
''')
    (package / MARKER).write_text(json.dumps({
        "owner": OWNER, "schema": 1, "backend": backend, "theme": theme,
    }) + "\n")


def public_tree(path):
    for item in [path, *path.rglob("*")]:
        if not item.is_symlink():
            item.chmod(0o755 if item.is_dir() or item.name == "lock.sh" else 0o644)


def public_directory(path):
    missing = []
    current = path
    while not current.exists():
        missing.append(current)
        current = current.parent
    path.mkdir(parents=True, exist_ok=True)
    for directory in missing:
        directory.chmod(0o755)


def check_support_files(backend):
    if HELPER.is_symlink() or (HELPER.exists() and "Qylock system lock manager" not in HELPER.read_text()):
        raise ValueError(f"Refusing to replace unrelated helper: {HELPER}")
    if AUTOSTART.is_symlink() or (AUTOSTART.exists() and "X-Qylock-Managed=true" not in AUTOSTART.read_text()):
        raise ValueError(f"Refusing to replace unrelated autostart: {AUTOSTART}")
    if backend == "quickshell" and (LAUNCHER.exists() or LAUNCHER.is_symlink()):
        if not LAUNCHER.is_symlink() or LAUNCHER.readlink() != target_for(backend) / "lock.sh":
            raise ValueError(f"Refusing to replace unrelated launcher: {LAUNCHER}")


def apply(package):
    value = metadata(package / "payload" / MARKER)
    backend = value.get("backend")
    if backend not in ("kde", "quickshell") or not managed(package / "payload", backend):
        raise ValueError("Not a prepared Qylock system package")
    target = target_for(backend)
    if target.is_symlink() or (target.exists() and not managed(target, backend)):
        raise ValueError(f"Refusing to replace unrelated system package: {target}")
    check_support_files(backend)
    public_directory(target.parent)
    # Copy to the destination filesystem before atomically switching packages.
    with tempfile.TemporaryDirectory(prefix=".qylock-system-", dir=target.parent) as temporary:
        stage = Path(temporary) / "new"
        previous = Path(temporary) / "previous"
        shutil.copytree(package / "payload", stage, symlinks=True)
        public_tree(stage)
        # Supporting files have no per-theme state. Write them first so a write
        # failure cannot remove the previously active package.
        public_directory(HELPER.parent)
        public_directory(AUTOSTART.parent)
        atomic_file(HELPER, Path(__file__).read_text())
        atomic_file(AUTOSTART, "[Desktop Entry]\nType=Application\nName=Qylock profile sync\n"
                    f"Exec={sys.executable} {HELPER} sync-profile\n"
                    "NoDisplay=true\nX-Qylock-Managed=true\n")
        if target.exists():
            target.rename(previous)
        try:
            stage.rename(target)
        except OSError:
            if previous.exists():
                previous.rename(target)
            raise
    if backend == "quickshell" and not LAUNCHER.is_symlink():
        public_directory(LAUNCHER.parent)
        LAUNCHER.symlink_to(target / "lock.sh")
    return backend, value["theme"]


def user_paths():
    home = Path.home()
    data = Path(os.environ.get("XDG_DATA_HOME") or home / ".local/share")
    state = Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state")
    if not data.is_absolute() or not state.is_absolute():
        raise ValueError("Profile data and state directories must be absolute")
    return data, state / "qylock/system-sync"


def local_quickshell(path):
    if path.is_symlink():
        return False
    try:
        launcher = (path / "lock.sh").read_text()
        qml = (path / "lock_shell.qml").read_text()
    except OSError:
        return False
    return 'exec quickshell -p "$DIR/lock_shell.qml"' in launcher and "WlSessionLock" in qml


def forwarding(path):
    launcher = path / "lock.sh"
    return (not path.is_symlink() and launcher.is_symlink()
            and launcher.readlink() == target_for("quickshell") / "lock.sh"
            and metadata(path / MARKER).get("owner") == OWNER)


def backup(path, state, backend):
    state.mkdir(parents=True, exist_ok=True)
    # Keep previous backups across repeated installs instead of overwriting them.
    directory = Path(tempfile.mkdtemp(prefix=backend + "-", dir=state))
    destination = directory / "original"
    shutil.move(str(path), str(destination))
    try:
        atomic_file(state / f"{backend}.json", json.dumps({"target": str(path), "backup": str(destination)}))
    except OSError:
        shutil.move(str(destination), str(path))
        raise


def sync_profile(restore=None):
    data, state = user_paths()
    for backend in ("kde", "quickshell"):
        local = (data / "plasma/shells" / SHELL_ID if backend == "kde" else data / "quickshell-lockscreen")
        if restore:
            if backend != restore:
                continue
            record = metadata(state / f"{backend}.json")
            if forwarding(local) and backend == "quickshell":
                (local / "lock.sh").unlink()
                (local / MARKER).unlink()
                try:
                    local.rmdir()
                except OSError:
                    print(f"Kept additional profile files: {local}")
            if not local.exists() and not local.is_symlink() and record:
                # The saved target can differ after a user's XDG directory change.
                original = Path(record["target"])
                saved = Path(record["backup"])
                if original == local and saved.is_dir():
                    local.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(saved), str(local))
                    (state / f"{backend}.json").unlink()
            continue
        if not managed(target_for(backend), backend):
            # Unavailable profiles can recover after the system theme is removed.
            if metadata(state / f"{backend}.json") or (backend == "quickshell" and forwarding(local)):
                sync_profile(restore=backend)
            continue
        if backend == "kde":
            value = metadata(local / ".qylock.json")
            if value.get("profileOverride"):
                print(f"Kept explicit profile theme: {local}")
            elif not local.is_symlink() and value.get("owner") == "qylock-kde" and value.get("schema") == 1:
                backup(local, state, backend)
                print("KDE profile now follows the system theme; previous overlay backed up.")
            elif local.exists() or local.is_symlink():
                print(f"Kept custom KDE override: {local}")
        else:
            if forwarding(local):
                continue
            if metadata(local / ".qylock-profile.json").get("profileOverride"):
                print(f"Kept explicit profile theme: {local}")
                continue
            if local.exists() or local.is_symlink():
                if not local_quickshell(local):
                    print(f"Kept custom lock launcher: {local}")
                    continue
                backup(local, state, backend)
            local.mkdir(parents=True)
            (local / "lock.sh").symlink_to(target_for(backend) / "lock.sh")
            (local / MARKER).write_text(json.dumps({"owner": OWNER}) + "\n")
            print("Quickshell profile now follows the system theme.")


def accounts():
    limits = {"UID_MIN": 1000, "UID_MAX": 60000}
    try:
        for key, value in re.findall(r"^(UID_MIN|UID_MAX)\s+(\d+)", Path("/etc/login.defs").read_text(), re.M):
            limits[key] = int(value)
    except OSError:
        pass
    return [user for user in pwd.getpwall()
            if limits["UID_MIN"] <= user.pw_uid <= limits["UID_MAX"]
            and Path(user.pw_dir).is_absolute() and Path(user.pw_dir).is_dir()
            and Path(user.pw_shell).name not in ("nologin", "false")]


def sync_accounts(restore=None, data_home=None, state_home=None):
    failures = []
    for user in accounts():
        environment = {"HOME": user.pw_dir, "USER": user.pw_name, "LOGNAME": user.pw_name,
                       "PATH": "/usr/local/bin:/usr/bin:/bin"}
        if str(user.pw_uid) == os.environ.get("SUDO_UID"):
            if data_home:
                environment["XDG_DATA_HOME"] = data_home
            if state_home:
                environment["XDG_STATE_HOME"] = state_home
        command = [sys.executable, str(HELPER), "sync-profile"]
        if restore:
            command += ["--restore", restore]
        # Never edit a user's home as root: drop credentials before reading it.
        result = subprocess.run(command, env=environment, cwd="/", user=user.pw_uid,
                                group=user.pw_gid, extra_groups=[], capture_output=True, text=True)
        print(f"Profile {user.pw_name}: {result.stdout.strip() or 'uses system defaults'}")
        if result.returncode:
            failures.append(f"{user.pw_name}: {result.stderr.strip()}")
    if failures:
        raise ValueError("Profile sync needs attention:\n" + "\n".join(failures))


def uninstall(backend):
    target = target_for(backend)
    if not managed(target, backend):
        raise ValueError(f"No managed system package to remove: {target}")
    sync_accounts(restore=backend)
    shutil.rmtree(target)
    if backend == "quickshell" and LAUNCHER.is_symlink() and LAUNCHER.readlink() == target / "lock.sh":
        LAUNCHER.unlink()
    # Retain the small login-time recovery helper for unavailable profiles.


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    create = sub.add_parser("prepare")
    create.add_argument("--backend", choices=("kde", "quickshell"), required=True)
    create.add_argument("--theme", required=True)
    create.add_argument("--output", type=Path, required=True)
    activate = sub.add_parser("apply")
    activate.add_argument("--package", type=Path, required=True)
    activate.add_argument("--profile-data-home")
    activate.add_argument("--profile-state-home")
    profile = sub.add_parser("sync-profile")
    profile.add_argument("--restore", choices=("kde", "quickshell"))
    remove = sub.add_parser("uninstall")
    remove.add_argument("--backend", choices=("kde", "quickshell"), required=True)
    args = parser.parse_args()
    if args.command in ("apply", "uninstall") and os.geteuid() != 0:
        raise ValueError("System installation requires sudo")
    if args.command == "prepare":
        prepare(args.output, args.backend, args.theme)
    elif args.command == "sync-profile":
        sync_profile(args.restore)
    elif args.command == "apply":
        backend, theme = apply(args.package)
        sync_accounts(data_home=args.profile_data_home, state_home=args.profile_state_home)
        print(f"Installed system-wide {backend} theme: {theme}. New profiles inherit it automatically.")
    else:
        uninstall(args.backend)
        print(f"Removed system-wide {args.backend} theme. Previous profile installs are restored when available.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"qylock-system: {error}", file=sys.stderr)
        sys.exit(1)
