#!/usr/bin/env python3
"""Build and manage a reversible Plasma 6 shell overlay for Qylock."""

import argparse
import configparser
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parent.parent
PACKAGE = Path(__file__).resolve().parent / "package"
SHELL_ID = "org.kde.plasma.desktop"
MARKER = ".qylock.json"
THEMES = json.loads((Path(__file__).resolve().parent / "themes.json").read_text())
DEFAULT_THEME = "nier-automata"
SYSTEM_PACKAGE = Path("/usr/local/share/plasma/shells") / SHELL_ID


def available_themes():
    """Discover real theme entries, including nested Clockwork variants."""
    return sorted(p.parent.relative_to(REPO / "themes").as_posix()
                  for p in (REPO / "themes").rglob("Main.qml")
                  if (p.parent / "theme.conf").is_file() or (p.parent / "metadata.desktop").is_file())


def theme_port(theme):
    if theme not in THEMES or theme not in available_themes():
        raise ValueError(f"Theme {theme!r} has no KDE port. Run './kde.sh themes' for supported themes.")
    return THEMES[theme]


def adapt_user_switch(source, port):
    """Replace one reviewed username action in the KDE build copy only."""
    action = port.get("userSwitchAction")
    if not isinstance(action, str) or not action.strip():
        raise ValueError("A userSwitchAction is required for the KDE theme port")
    # Reviewed selectors have at most one nested block in their click handler.
    # Reject changed structures instead of rewriting unrelated theme actions.
    pattern = r"MouseArea\s*\{(?P<attributes>(?:[^{}]|\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\})*?)\bonClicked\s*:\s*(?P<handler>\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|[^;{}\n]+);?"
    matches = [m for m in re.finditer(pattern, source, re.S) if action in m["handler"]]
    if len(matches) != 1:
        raise ValueError("Username selector changed; review this theme's KDE port.")
    match = matches[0]
    hooks = """
        objectName: "qylockUserSwitch"
        enabled: sddm.canSwitchUser
        activeFocusOnTab: true
        opacity: enabled ? 1 : 0.5
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Switch User")
        Accessible.description: qsTr("Choose another account while keeping this session locked.")
        Accessible.onPressAction: sddm.switchUser()
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                sddm.switchUser();
                event.accepted = true;
            }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            color: "transparent"
            border.color: "#b9b5a3"
            radius: 2
            visible: parent.activeFocus
        }
"""
    condition = port.get("userSwitchCondition")
    handler = "{ sddm.switchUser(); }"
    if condition:
        hooks = hooks.replace('objectName: "qylockUserSwitch"', f'objectName: ({condition}) ? "qylockUserSwitch" : ""')
        hooks = hooks.replace('enabled: sddm.canSwitchUser', f'enabled: !({condition}) || sddm.canSwitchUser')
        hooks = hooks.replace('activeFocusOnTab: true', f'activeFocusOnTab: ({condition})')
        hooks = hooks.replace('Accessible.name: qsTr("Switch User")', f'Accessible.name: ({condition}) ? qsTr("Switch User") : ""\n        Accessible.ignored: !({condition})')
        hooks = hooks.replace('Accessible.onPressAction: sddm.switchUser()', f'Accessible.onPressAction: {{ if ({condition}) sddm.switchUser(); }}')
        hooks = hooks.replace('if (event.key === Qt.Key_Return', f'if (!({condition})) {{ event.accepted = false; return; }}\n            if (event.key === Qt.Key_Return')
        original = match["handler"]
        handler = f"{{ if ({condition}) sddm.switchUser(); else {original} }}"
    opening = source.index("{", match.start()) + 1
    source = (source[:opening] + hooks + source[opening:match.start("handler")]
              + handler + source[match.end():])
    # Include the selector in themes with an explicit Tab loop back to password.
    selector_id = re.search(r"\bid:\s*([A-Za-z_][A-Za-z0-9_]*)", match["attributes"])
    if selector_id and port.get("passwordId"):
        source = re.sub(rf"(KeyNavigation\.tab\s*:)\s*{re.escape(port['passwordId'])}\b",
                        rf"\1 {selector_id[1]}", source)
    return source


def adapt_theme(source, port):
    """Add the same locker contract to reviewed SDDM themes in the build copy."""
    for old, new in port.get("replacements", []):
        if source.count(old) != 1:
            raise ValueError(f"Reviewed theme hook changed: {old!r}")
        source = source.replace(old, new)
    password = port["passwordId"]
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", password):
        raise ValueError("Invalid passwordId in KDE theme registry")
    pattern = rf"(TextInput\s*\{{\s*id:\s*{re.escape(password)}\b)(\s*;?)"
    if len(re.findall(pattern, source)) != 1:
        raise ValueError(f"Password field {password!r} changed; review this theme's KDE port.")
    hooks = f"\n    property alias kdePasswordControl: {password}\n"
    if not port.get("nativeHooks"):
        source = re.sub(pattern, lambda m: m[1] + "; "
                        'objectName: "qylockPassword"; '
                        'enabled: qylockBackend.canSubmit; activeFocusOnTab: true; '
                        'Accessible.name: qylockBackend.promptLabel;\n' + m[2].replace(";", ""), source)
        # Use the lock window's logical size.
        source = re.sub(r"((?:readonly\s+)?property\s+real\s+s\s*:)\s*\(?[ \t]*(?:Screen\.height|height)[ \t]*/[ \t]*(768|1080)[ \t]*\)?",
                        lambda m: m[1] + (" Math.min(width / 1366, height / 768)" if m[2] == "768"
                                              else " Math.min(width / 1920, height / 1080)"), source)
        source = re.sub(r"((?:readonly\s+)?property\s+real\s+s\s*:)\s*width\s*/\s*1920",
                        r"\1 Math.min(width / 1920, height / 1080)", source)
        # A lock screen has only the existing session, not a login-session picker.
        source = re.sub(r"(property\s+bool\s+isQuickshell\s*:)[^\n]+", r"\1 true", source)
        hooks += f"""
    function clearPassword() {{ {password}.text = ""; }}
    function focusPassword() {{ {port.get('passwordFocus', '')} {password}.forceActiveFocus(); }}
    Connections {{
        target: qylockBackend
        function onClearRequested() {{ root.clearPassword(); }}
        function onCanSubmitChanged() {{
            if (qylockBackend.canSubmit) Qt.callLater(root.focusPassword);
        }}
    }}
"""
    if not re.search(r"\bid:\s*root\b", source) or not source.rstrip().endswith("}"):
        raise ValueError("Theme root changed; review this theme's KDE port.")
    message_target = port.get("messageTarget")
    if port.get("inlineStatus"):
        message_target = "kdeStatusText.text"
        status = f"""
    Text {{
        id: kdeStatusText
        parent: {password}.parent
        x: {password}.x
        y: {password}.y + {password}.height + 4
        width: {password}.width
        z: 100
        text: ""
        visible: text.length > 0
        wrapMode: Text.Wrap
        color: "#ffffff"
        style: Text.Outline
        styleColor: "#000000"
        font.family: {password}.font.family
        font.pixelSize: Math.max(12, {password}.font.pixelSize * 0.75)
        Accessible.name: text
    }}
"""
        source = source[:source.rfind("}")] + status + source[source.rfind("}"):]
    if message_target:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*", message_target):
            raise ValueError("Invalid messageTarget in KDE theme registry")
        owner, prop = message_target.split(".")
        if not re.search(rf"\bid:\s*{re.escape(owner)}\b", source):
            raise ValueError(f"Message target {owner!r} changed; review this theme's KDE port.")
        if owner == "root" and not re.search(rf"property\s+string\s+{re.escape(prop)}\s*:", source):
            raise ValueError(f"Message property {prop!r} changed; review this theme's KDE port.")
        opacity = port.get("messageOpacity")
        if opacity and (not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", opacity) or opacity != owner):
            raise ValueError("messageOpacity must reference the registered message target")
        hooks += f"\n    function setKdeMessage(message) {{ {message_target} = message;"
        if opacity:
            hooks += f" {opacity}.opacity = message.length > 0 ? 1 : 0;"
        hooks += " }\n"
        hooks += f"\n    readonly property string kdeMessageText: {message_target}\n"
        hooks += """
    Connections {
        target: qylockBackend
        function onStatusTextChanged() { root.setKdeMessage(qylockBackend.statusText); }
    }
"""
    # Existing invisible session delegates can evaluate before their model exists.
    source = source.replace("sessionHelper.currentItem.sName", '(sessionHelper.currentItem ? sessionHelper.currentItem.sName : "Current session")')
    source = adapt_user_switch(source, port)
    end = source.rfind("}")
    return source[:end] + hooks + source[end:]


def system_shell(value=None):
    explicit = value is not None
    if explicit:
        candidates = [Path(value)]
    else:
        candidates = [Path(p) / "plasma/shells" / SHELL_ID
                      for p in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if p]
    for candidate in candidates:
        if not (candidate / "metadata.json").is_file():
            continue
        if not explicit and ((candidate / MARKER).is_file() or (candidate / ".qylock-system.json").is_file()):
            # Never snapshot a Qylock overlay as the distribution shell.
            continue
        metadata = json.loads((candidate / "metadata.json").read_text())
        locker = candidate / "contents/lockscreen/LockScreenUi.qml"
        if (metadata.get("KPlugin", {}).get("Id") == SHELL_ID
                and str(metadata.get("X-Plasma-APIVersion")) == "2"
                and locker.is_file()
                and "startAuthenticating" in locker.read_text()
                and "authenticator.respond" in locker.read_text()):
            return candidate.resolve()
    raise ValueError("Compatible Plasma 6 desktop shell not found. This backend targets Plasma 6.8's authenticator API.")


def copy_shell_entry(source, destination):
    """Copy a shell entry so KPackage finds it inside the overlay package."""
    if source.is_dir():
        # Dereference links. KPackage rejects package files whose canonical
        # path leaves the package root, which breaks symlinked components.
        shutil.copytree(source, destination)
    else:
        shutil.copy2(source, destination)


def shell_fingerprint(shell):
    """Cheap snapshot of the system shell, used to detect Plasma updates."""
    digest = hashlib.sha256()
    for path in sorted(shell.rglob("*")):
        if not path.is_file() and not path.is_symlink():
            continue
        stat = path.stat()
        digest.update(f"{path.relative_to(shell).as_posix()}\0{stat.st_size}\0{stat.st_mtime_ns}\n".encode())
    return digest.hexdigest()


def escaping_symlinks(package):
    """Entries whose resolved target leaves the package root; KPackage rejects them."""
    root = package.resolve()
    escaped = []
    for path in package.rglob("*"):
        if path.is_symlink():
            target = path.resolve()
            if target != root and root not in target.parents:
                escaped.append(path.relative_to(package).as_posix())
    return escaped


def verify_overlay(destination):
    escaped = escaping_symlinks(destination)
    if escaped:
        raise ValueError("Overlay entries link outside the package: " + ", ".join(escaped))


def build(destination, shell, theme):
    port = theme_port(theme)
    if destination.is_symlink() or (destination.exists() and any(destination.iterdir())):
        raise ValueError(f"Build destination must be an empty directory: {destination}")
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "contents").mkdir()
    # Copy every component instead of linking it. Plasma 6.8's KPackage rejects
    # package files that resolve outside the package root, so a symlink into the
    # distro shell makes ksmserver-logout-greeter lose the Shutdown/Logout dialog.
    # Rebuilding the overlay refreshes this snapshot after a Plasma update.
    for entry in shell.iterdir():
        if entry.name not in ("contents", MARKER):
            copy_shell_entry(entry, destination / entry.name)
    for entry in (shell / "contents").iterdir():
        if entry.name != "lockscreen":
            copy_shell_entry(entry, destination / "contents" / entry.name)
    locker = destination / "contents/lockscreen"
    shutil.copytree(PACKAGE / "contents/lockscreen", locker)
    shutil.copytree(REPO / "themes" / theme, locker / "theme")
    # Only this import needs translating; KDE has no SDDM QML module.
    main = locker / "theme/Main.qml"
    source = main.read_text()
    old_import = "import SddmComponents 2.0"
    if source.count(old_import) != (0 if port.get("sddmImport") is False else 1):
        raise ValueError("Theme's SDDM import changed; review the KDE port before building.")
    main.write_text(adapt_theme(source.replace(old_import, 'import "../compat"'), port))
    (locker / "compat").mkdir()
    shutil.copy2(REPO / "quickshell-lockscreen/imports/SddmComponents/TextConstants.qml", locker / "compat")
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(REPO / "themes" / theme / "theme.conf")
    values = dict(config["General"]) if config.has_section("General") else {}
    values.update(port.get("configOverrides", {}))
    # Read configuration at build time: the greeter restricts file/network access.
    (locker / "ThemeConfig.qml").write_text(
        "import QtQml\nQtObject {\n"
        f"    readonly property var values: ({json.dumps(values)})\n"
        f"    readonly property url fallbackUrl: {json.dumps((shell / 'contents/lockscreen/LockScreen.qml').as_uri())}\n"
        "}\n"
    )
    (destination / MARKER).write_text(json.dumps({
        "owner": "qylock-kde", "schema": 1, "theme": theme, "system_shell": str(shell),
        "system_fingerprint": shell_fingerprint(shell),
    }, indent=2) + "\n")
    verify_overlay(destination)


def install_path():
    data = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    if not data.is_absolute():
        raise ValueError("XDG_DATA_HOME must be an absolute path")
    return data / "plasma/shells" / SHELL_ID


def owned(path):
    if path.is_symlink():
        return False
    try:
        metadata = json.loads((path / MARKER).read_text())
        return metadata.get("owner") == "qylock-kde" and metadata.get("schema") == 1
    except (OSError, ValueError):
        return False


def active_install_path():
    target = install_path()
    if target.exists() or target.is_symlink():
        return target if owned(target) else None
    try:
        system = json.loads((SYSTEM_PACKAGE / ".qylock-system.json").read_text())
        if system.get("owner") == "qylock-system-lock" and owned(SYSTEM_PACKAGE):
            return SYSTEM_PACKAGE
    except (OSError, ValueError):
        pass
    return None


def current_theme():
    target = active_install_path()
    if target:
        theme = json.loads((target / MARKER).read_text()).get("theme")
        if theme in THEMES:
            return theme
    return DEFAULT_THEME


def setup_diagnostics():
    config_dir = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    data_dir = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    settings = configparser.ConfigParser(interpolation=None, strict=False)
    settings.read(config_dir / "kscreenlockerrc")
    password = settings.getboolean("Daemon", "RequirePassword", fallback=True)
    resume = settings.getboolean("Daemon", "LockOnResume", fallback=True)
    shortcuts = configparser.ConfigParser(interpolation=None, strict=False)
    shortcuts.read(config_dir / "kglobalshortcutsrc")
    launcher = data_dir / "applications/net.local.qylock.desktop"
    desktop = configparser.ConfigParser(interpolation=None, strict=False)
    desktop.read(launcher)
    command = desktop.get("Desktop Entry", "Exec", fallback="")
    shortcut = shortcuts.get("services][net.local.qylock.desktop", "_launch", fallback="")
    qylock = shutil.which("qylock")
    native_launcher = qylock and Path(qylock).resolve() == (REPO / "kde-lockscreen/lock.sh").resolve()
    legacy = ("Meta+L" in shortcut.split(",")[0].split(r"\t")
              and command.split()[:1] == ["qylock"] and not native_launcher)
    issues = []
    if not password:
        issues.append("KDE has RequirePassword=false: its lock shortcut can return to the desktop without a password.")
    if not resume:
        issues.append("KDE has LockOnResume=false: waking from sleep does not request a lock screen.")
    if legacy:
        issues.append(f"Meta+L launches the old qylock application ({launcher}), bypassing native KScreenLocker.")
    return password, resume, issues


def overlay_diagnostics(target):
    """Problems with an installed overlay that break Plasma or go stale."""
    if target is None:
        return []
    issues = []
    escaped = escaping_symlinks(target)
    if escaped:
        issues.append(f"{len(escaped)} overlay entries link outside the package, which KPackage "
                      "rejects (this breaks the Shutdown/Logout dialog).")
    try:
        marker = json.loads((target / MARKER).read_text())
    except (OSError, ValueError):
        marker = {}
    shell = Path(marker.get("system_shell", ""))
    fingerprint = marker.get("system_fingerprint")
    if shell.is_dir() and fingerprint and fingerprint != shell_fingerprint(shell):
        issues.append(f"The overlay was copied from an older Plasma shell ({shell}); "
                      "its components need refreshing.")
    return issues


def doctor():
    password, resume, setup_issues = setup_diagnostics()
    target = active_install_path()
    overlay_issues = overlay_diagnostics(target)
    issues = setup_issues + overlay_issues
    print(f"Theme: {current_theme()} ({'system-wide' if target == SYSTEM_PACKAGE else 'profile'})"
          if target else "Theme: no Qylock KDE overlay installed")
    print(f"Require password: {'yes' if password else 'no'}")
    print(f"Lock after sleep: {'yes' if resume else 'no'}")
    for issue in issues:
        print(f"Check: {issue}")
    if not issues:
        print("No known lock-settings, shortcut, or overlay conflicts found.")
    else:
        if setup_issues:
            print("Use KDE System Settings → Screen Locking to require a password.\n"
                  "Bind the lock shortcut to KDE's Lock Session action or 'kde.sh lock'.")
        if overlay_issues:
            if target == SYSTEM_PACKAGE:
                print("Rebuild the shared overlay: sudo ./install.sh")
            else:
                print(f"Reinstall the KDE theme to rebuild the overlay: ./kde.sh install --theme {current_theme()}")


def dbus_client():
    for name in ("qdbus6", "qdbus"):
        binary = shutil.which(name)
        if binary:
            return binary
    for candidate in ("/usr/lib/qt6/bin/qdbus", "/usr/lib64/qt6/bin/qdbus"):
        if Path(candidate).is_file():
            return candidate
    raise ValueError("qdbus6 not found; install the Qt D-Bus command-line tools")


def lock_session():
    # The D-Bus Lock method establishes an immediate lock, including when the
    # desktop's delayed-lock/password preference is disabled. Never launch a
    # separate greeter or Quickshell instance to lock a Plasma session.
    result = subprocess.run([dbus_client(), "org.freedesktop.ScreenSaver", "/ScreenSaver",
                             "org.freedesktop.ScreenSaver.Lock"], capture_output=True, text=True)
    if result.returncode:
        raise ValueError(f"KDE did not accept the lock request: {result.stderr.strip() or result.stdout.strip()}")


def list_themes(include_unported=False):
    installed = current_theme() if active_install_path() else None
    for theme in available_themes():
        if theme in THEMES:
            label = THEMES[theme]["name"]
            status = "installed" if theme == installed else "available"
        elif include_unported:
            label, status = theme, "needs KDE port"
        else:
            continue
        print(f"{theme:26} {label:28} {status}")


def choose_theme():
    choices = [theme for theme in available_themes() if theme in THEMES]
    if not choices:
        raise ValueError("No KDE theme ports found")
    if not sys.stdin.isatty():
        raise ValueError("The theme picker needs a terminal. Use --theme NAME or run './kde.sh themes'.")
    current = current_theme()
    lines = [f"{theme:26} {THEMES[theme]['name']}" + (" [current]" if theme == current else "")
             for theme in choices]
    if shutil.which("fzf"):
        result = subprocess.run(["fzf", "--prompt=KDE theme: ", "--height=70%", "--reverse", "--border",
                                 "--header=Choose a theme • Esc cancels"],
                                input="\n".join(lines) + "\n", text=True, stdout=subprocess.PIPE)
        if result.returncode in (1, 130):
            return None
        if result.returncode:
            raise ValueError("fzf theme picker failed")
        selected = result.stdout.rstrip("\n")
        if selected not in lines:
            raise ValueError("Theme picker returned an unknown selection")
        return choices[lines.index(selected)]
    for index, line in enumerate(lines, 1):
        print(f"  {index:2}. {line}")
    while True:
        selected = input("Theme number (Enter or q cancels): ").strip()
        if not selected or selected.lower() == "q":
            return None
        if selected.isdecimal() and 1 <= int(selected) <= len(choices):
            return choices[int(selected) - 1]
        print(f"Choose a number from 1 to {len(choices)}.")


def install(shell, theme):
    target = install_path()
    if target.is_symlink() or (target.exists() and not owned(target)):
        raise ValueError(f"Refusing to replace an unrelated Plasma shell overlay: {target}")
    if shell == target.resolve():
        raise ValueError("The system shell must be separate from the user overlay")
    target.parent.mkdir(parents=True, exist_ok=True)
    # Stage on the same filesystem so activation uses an atomic rename.
    with tempfile.TemporaryDirectory(prefix=".qylock-stage-", dir=target.parent) as temporary:
        stage = Path(temporary) / "new"
        backup = Path(temporary) / "previous"
        build(stage, shell, theme)
        marker = json.loads((stage / MARKER).read_text())
        marker["profileOverride"] = True
        (stage / MARKER).write_text(json.dumps(marker, indent=2) + "\n")
        if target.exists():
            target.rename(backup)
        try:
            stage.rename(target)
        except OSError:
            if backup.exists():
                backup.rename(target)
            raise
    print(f"Installed {theme}: {target}\nThe next normal KDE screen lock will use Qylock.")
    for issue in setup_diagnostics()[2]:
        print(f"Setup check: {issue}\nRun './kde.sh doctor' for details.")


def greeter():
    for path in (shutil.which("kscreenlocker_greet"), "/usr/lib/kscreenlocker_greet",
                 "/usr/libexec/kscreenlocker_greet", "/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet"):
        if path and Path(path).is_file():
            return path
    raise ValueError("kscreenlocker_greet not found; install your distribution's kscreenlocker package")


def menu(shell_override=None):
    if not sys.stdin.isatty():
        raise ValueError("The menu needs a terminal. Use './kde.sh --help' for scriptable commands.")
    print("\nQylock • KDE Plasma lock screen\n")
    for index, label in enumerate(("Choose and install a theme", "Preview a theme",
                                   "List supported themes", "Show installed theme", "Uninstall"), 1):
        print(f"  {index}. {label}")
    choice = input("\nAction (1–5, Enter or q exits): ").strip()
    commands = {"1": "select", "2": "preview", "3": "themes", "4": "status", "5": "uninstall"}
    if choice in ("", "q", "Q"):
        return 0
    if choice not in commands:
        raise ValueError("Choose an action from 1 to 5")
    prefix = ["--system-shell", shell_override] if shell_override else []
    return main(prefix + [commands[choice]])


def main(argv=None):
    parser = argparse.ArgumentParser(prog="kde.sh", description=__doc__)
    parser.add_argument("--system-shell", help="system Plasma shell package (normally auto-detected)")
    sub = parser.add_subparsers(dest="command")
    for name in ("build", "preview", "install"):
        child = sub.add_parser(name)
        child.add_argument("--theme", choices=sorted(THEMES), help="theme ID (opens a picker in a terminal when omitted)")
        if name == "build":
            child.add_argument("--output", required=True, type=Path)
    sub.add_parser("uninstall")
    sub.add_parser("status")
    sub.add_parser("doctor", help="check KDE lock settings and conflicting legacy shortcuts")
    sub.add_parser("lock", help="lock the current session through KDE's native locker")
    sub.add_parser("select", help="choose and install a KDE theme interactively")
    sub.add_parser("menu", help="open the interactive setup menu")
    catalog = sub.add_parser("themes", help="list themes with KDE ports")
    catalog.add_argument("--all", action="store_true", help="also show themes still needing a KDE port")
    args = parser.parse_args(argv)
    if args.command is None:
        if not sys.stdin.isatty():
            parser.print_help()
            return 0
        return menu(args.system_shell)
    if args.command == "menu":
        return menu(args.system_shell)
    if args.command == "doctor":
        doctor()
    elif args.command == "lock":
        lock_session()
    elif args.command == "themes":
        list_themes(args.all)
    elif args.command == "uninstall":
        target = install_path()
        if not target.exists() and not target.is_symlink():
            print("Qylock KDE overlay is not installed.")
            if active_install_path() == SYSTEM_PACKAGE:
                print("The system-wide theme remains active. Remove it with:\n"
                      "sudo python3 scripts/system-lock.py uninstall --backend kde")
            return 0
        if not owned(target):
            raise ValueError(f"Refusing to remove an unrelated Plasma shell overlay: {target}")
        shutil.rmtree(target)
        print("Removed Qylock KDE overlay. The next lock uses the system lock screen.")
    elif args.command == "status":
        target = active_install_path()
        if target:
            print(f"Installed ({'system-wide' if target == SYSTEM_PACKAGE else 'profile'}): {target}\n"
                  + (target / MARKER).read_text())
        else:
            print(f"Qylock KDE overlay is not installed at {install_path()}")
    else:
        if args.command == "select":
            theme = choose_theme()
        else:
            theme = args.theme
            if theme is None:
                theme = choose_theme() if args.command != "build" and sys.stdin.isatty() else current_theme()
        if theme is None:
            print("Cancelled.")
            return 0
        shell = system_shell(args.system_shell)
        if args.command == "build":
            build(args.output.resolve(), shell, theme)
            print(f"Built {theme}: {args.output.resolve()}")
        elif args.command in ("install", "select"):
            install(shell, theme)
        else:
            binary = greeter()
            with tempfile.TemporaryDirectory(prefix="qylock-kde-preview-") as temporary:
                package = Path(temporary) / SHELL_ID
                build(package, shell, theme)
                print(f"Previewing {theme} in KScreenLocker testing mode; your session is not being locked.", flush=True)
                return subprocess.call([binary, "--testing", "--shell", str(package)])
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, configparser.Error) as error:
        print(f"qylock-kde: {error}", file=sys.stderr)
        sys.exit(1)
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.", file=sys.stderr)
        sys.exit(130)
