#!/usr/bin/env python3
"""Render the native locker; switching is mocked, credentials are never submitted."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

spec = importlib.util.spec_from_file_location("manage", Path(__file__).parents[1] / "manage.py")
manage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manage)


def check(directory, shell, width, height, fallback=False, theme="nier-automata", renderer="software"):
    name = f"{theme.replace('/', '-')}-{'fallback' if fallback else 'theme'}-{width}x{height}"
    package = directory / name
    manage.build(package, shell, theme)
    locker = package / "contents/lockscreen"
    if fallback:
        (locker / "theme/Main.qml").write_text("import QtQuick\nMissingThemeType {}\n")
    wrapper = locker / "LockScreen.qml"
    source = "import QtTest\n" + wrapper.read_text()
    login = "function login(user, password, sessionIndex) { authBridge.login(user, password, sessionIndex); }"
    assert source.count(login) == 1, "Review the native probe's credential-submission guard"
    source = source.replace(login, "function login(user, password, sessionIndex) { root.unexpectedLogins++; }")
    probe = """
    property int unexpectedLogins: 0
    TestCase { id: inputEvents; name: "NativeControlsProbe"; when: false }
    QtObject {
        id: switchProbe
        property bool canSwitchUser: true
        property bool canLock: true
        property int calls: 0
        property bool clearedBeforeSwitch: true
        function switchUser() {
            const field = themeLoader.item.kdePasswordControl;
            clearedBeforeSwitch = clearedBeforeSwitch && field.text === "";
            calls++;
        }
    }
    property bool optionsInitiallyHidden: true
    property bool optionsOpenedForCheck: false
    Component.onCompleted: Qt.callLater(function() {
        root.Window.window.width = WIDTH;
        root.Window.window.height = HEIGHT;
        root.optionsInitiallyHidden = !optionsPopup.visible;
    })
    Timer {
        interval: 1200; running: true
        onTriggered: { if (!root.useFallback) root.toggleOptions(); }
    }
    Timer {
        interval: 1800; running: true
        onTriggered: {
            root.optionsOpenedForCheck = optionsPopup.opened;
            optionsPopup.close();
        }
    }
    Timer {
        interval: 2500; running: true
        onTriggered: {
            const field = themeLoader.item ? themeLoader.item.kdePasswordControl : null;
            if (field) field.text = "preview-clear-check";
            authBridge.reset();
            const cleared = field ? field.text === "" : false;
            const previousMessage = authBridge.message;
            authBridge.message = "One-time code required";
            const inlineFeedback = themeLoader.item ? themeLoader.item.kdeMessageText === authBridge.statusText : false;
            authBridge.message = previousMessage;
            let userSwitchClicked = false;
            let userSwitchTab = false;
            let userSwitchKeyboard = false;
            let userSwitchAccessible = false;
            let userSwitchDisabled = false;
            let passwordSubmitted = false;
            if (!root.useFallback) {
                // Exercise real pointer/key events, with no actual session switch.
                const selector = inputEvents.findChild(themeLoader.item, "qylockUserSwitch");
                const previousBackend = userSwitch.backend;
                userSwitch.backend = switchProbe;
                inputEvents.wait(50);
                if (selector && selector.enabled && selector.width > 0 && selector.height > 0) {
                    field.text = "clear-before-user-switch";
                    inputEvents.mouseClick(selector);
                    userSwitchClicked = switchProbe.calls === 1;
                    field.forceActiveFocus();
                    for (let attempt = 0; attempt < 8 && !selector.activeFocus; attempt++) {
                        inputEvents.keyClick(Qt.Key_Tab);
                    }
                    userSwitchTab = selector.activeFocus;
                    if (userSwitchTab) {
                        for (const key of [Qt.Key_Space, Qt.Key_Return, Qt.Key_Enter]) {
                            field.text = "clear-before-keyboard-switch";
                            inputEvents.keyClick(key);
                        }
                    }
                    userSwitchKeyboard = switchProbe.calls === 4;
                    field.text = "clear-before-accessible-switch";
                    selector.Accessible.pressAction();
                    userSwitchAccessible = switchProbe.calls === 5;
                    switchProbe.canSwitchUser = false;
                    inputEvents.mouseClick(selector);
                    selector.Accessible.pressAction();
                    userSwitchDisabled = !selector.enabled && switchProbe.calls === 5;
                    field.text = "";
                }
                userSwitch.backend = previousBackend;
                themeLoader.item.focusPassword();
            }
            root.grabToImage(function(result) {
            result.saveToFile(SCREENSHOT);
            // Capture the idle theme before triggering any login animation.
            if (!root.useFallback) {
                field.text = "";
                inputEvents.keyClick("x");
                inputEvents.keyClick(Qt.Key_Return);
                for (let attempt = 0; attempt < 40 && root.unexpectedLogins === 0; attempt++) {
                    inputEvents.wait(100);
                }
                passwordSubmitted = root.unexpectedLogins === 1;
                field.text = "";
            }
            console.warn("QYLOCK_CHECK " + JSON.stringify({
                fallback: root.useFallback,
                loaderStatus: themeLoader.status,
                fallbackStatus: fallbackLoader.status,
                viewVisible: root.viewVisible,
                prompt: authBridge.awaitingPrompt,
                canSubmit: authBridge.canSubmit,
                inputEnabled: field ? field.enabled : false,
                inputCleared: cleared,
                inlineFeedback: inlineFeedback,
                themeWidth: themeLoader.width, themeHeight: themeLoader.height,
                optionsInitiallyHidden: root.optionsInitiallyHidden,
                optionsOpened: root.optionsOpenedForCheck,
                optionsVisible: optionsPopup.visible,
                userSwitchClicked: userSwitchClicked,
                userSwitchTab: userSwitchTab,
                userSwitchKeyboard: userSwitchKeyboard,
                userSwitchAccessible: userSwitchAccessible,
                userSwitchDisabled: userSwitchDisabled,
                userSwitchCleared: switchProbe.clearedBeforeSwitch,
                unexpectedLogins: root.unexpectedLogins,
                passwordSubmitted: passwordSubmitted,
                inputVisible: field ? field.visible : false,
                width: root.width, height: root.height
            }));
            })
        }
    }
""".replace("WIDTH", str(width)).replace("HEIGHT", str(height)).replace(
        "SCREENSHOT", json.dumps(str(directory / f"{name}.png")))
    wrapper.write_text(source[:source.rfind("}")] + probe + "}\n")
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               QT_FORCE_STDERR_LOGGING="1", XDG_CONFIG_HOME=str(directory / "test-config"),
               XDG_CACHE_HOME=str(directory / "test-cache"))
    if renderer == "opengl":
        env.update(QT_QUICK_BACKEND="rhi", QSG_RHI_BACKEND="opengl")
    log = directory / f"{name}.log"
    with log.open("w") as output:
        process = subprocess.Popen([manage.greeter(), "--testing", "--shell", str(package)],
                                   env=env, stdout=output, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline and process.poll() is None:
                if "QYLOCK_CHECK " in log.read_text():
                    break
                time.sleep(0.1)
        finally:
            process.terminate()
            process.wait(timeout=5)
    text = log.read_text()
    records = [line.split("QYLOCK_CHECK ", 1)[1] for line in text.splitlines() if "QYLOCK_CHECK " in line]
    if not records:
        raise AssertionError(f"No native render result; see {log}\n{text}")
    result = json.loads(records[-1])
    assert result["fallback"] == fallback, result
    assert (result["width"], result["height"]) == (width, height), result
    if not fallback:
        assert result["loaderStatus"] == 1, result  # Loader.Ready
        assert result["viewVisible"] and result["prompt"] and result["canSubmit"], result
        assert result["inputEnabled"] and result["inputCleared"], result
        assert result["inlineFeedback"], result
        assert result["themeWidth"] == width and result["themeHeight"] == height, result
        assert result["optionsInitiallyHidden"] and result["optionsOpened"] and not result["optionsVisible"], result
        assert all(result[key] for key in ("userSwitchClicked", "userSwitchTab", "userSwitchKeyboard", "userSwitchAccessible",
                                           "userSwitchDisabled", "userSwitchCleared")), result
        assert result["passwordSubmitted"] and result["unexpectedLogins"] == 1 and result["inputVisible"], result
        assert "TypeError" not in text and "ReferenceError" not in text, text
        assert "no signal of the target matches" not in text, text
    else:
        assert result["fallbackStatus"] == 1, result
    print(f"PASS {name}", flush=True)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="retain screenshots and logs here")
    parser.add_argument("--renderer", choices=["software", "opengl"], default="software")
    parser.add_argument("--all-resolutions", action="store_true", help="check all themes at three resolutions")
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--theme", choices=sorted(manage.THEMES), default="nier-automata")
    selection.add_argument("--all-themes", action="store_true", help="check every registered KDE port at 1366×768")
    selection.add_argument("--themes", nargs="+", choices=sorted(manage.THEMES), help="check a subset of ports")
    args = parser.parse_args()
    if args.output:
        directory = args.output.resolve()
        directory.mkdir(parents=True, exist_ok=True)
        if args.all_themes or args.themes:
            failures = []
            for theme in args.themes or sorted(manage.THEMES):
                for width, height in ([(1366, 768), (1920, 1080), (800, 600)] if args.all_resolutions else [(1366, 768)]):
                    try:
                        check(directory, manage.system_shell(), width, height, theme=theme, renderer=args.renderer)
                    except (AssertionError, ValueError) as error:
                        failures.append(f"{theme} {width}x{height}: {error}")
                        print(f"FAIL {failures[-1][:1000]}", flush=True)
            if failures:
                raise SystemExit(f"{len(failures)} native checks failed; see logs in {directory}")
        else:
            for width, height, fallback in [(1366, 768, False), (1920, 1080, False), (800, 600, False), (1366, 768, True)]:
                check(directory, manage.system_shell(), width, height, fallback, args.theme, args.renderer)
    else:
        with tempfile.TemporaryDirectory(prefix="qylock-native-check-") as temporary:
            for theme in args.themes or (sorted(manage.THEMES) if args.all_themes else [args.theme]):
                for width, height in ([(1366, 768), (1920, 1080), (800, 600)] if args.all_resolutions else [(1366, 768)]):
                    check(Path(temporary), manage.system_shell(), width, height, theme=theme, renderer=args.renderer)
