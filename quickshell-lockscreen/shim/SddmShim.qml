import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Item {
    id: shim

    property string themePath: ""
    property var config: ({})
    property bool configReady: false

    function loadConfig(path) {
        if (!path) {
            config = { background: "bg.png" };
            configReady = true;
            return;
        }
        var url = "file://" + path + "/theme.conf";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var newConfig = {};
                if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                    var lines = xhr.responseText.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.startsWith("[") || line === "" || line.startsWith("#")) continue;
                        var parts = line.split("=");
                        if (parts.length === 2) {
                            newConfig[parts[0].trim()] = parts[1].trim();
                        }
                    }
                }
                // Fallback: ensure a default background always exists
                if (!newConfig.background) {
                    newConfig.background = "bg.png";
                }
                config = newConfig;
                configReady = true;
            }
        };
        try {
            xhr.open("GET", url, true);
            xhr.send();
        } catch (e) {
            console.warn("SddmShim: failed to load theme.conf:", e);
            config = { background: "bg.png" };
            configReady = true;
        }
    }

    property var userModel: ListModel {
        id: internalUserModel
        property string lastUser: Quickshell.env("USER") || "traveler"
        property int lastIndex: 0

        function index(row, col) {
            return row;
        }

        function data(row, role) {
            var item = get(row);
            if (!item) return "";
            if (role === (Qt.UserRole + 1)) return item.name;
            if (role === (Qt.UserRole + 2)) return item.realName;
            return item.name;
        }

        Component.onCompleted: {
            append({
                name: Quickshell.env("USER") || "traveler",
                realName: Quickshell.env("USER") || "Traveler",
                icon: "",
                homeDir: "/home/" + (Quickshell.env("USER") || "traveler")
            })
        }
    }

    property var sessionModel: ListModel {
        id: internalSessionModel
        property int lastIndex: 0
        Component.onCompleted: {
            // Initial placeholder to ensure ListView.currentItem isn't null
            append({ name: "Session", file: "" });
        }
    }

    // Process to enumerate system desktop sessions
    Process {
        id: sessionEnumerator
        command: [
            "bash", "-c",
            "for f in /usr/share/wayland-sessions/*.desktop /usr/share/xsessions/*.desktop; do " +
            "if [ -f \"$f\" ]; then " +
            "NAME=$(grep -m1 '^Name=' \"$f\" | cut -d'=' -f2); " +
            "FILE=$(basename \"$f\"); " +
            "echo \"$NAME|||$FILE\"; " +
            "fi; done"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                shim.parseSessions(this.text);
            }
        }

        onExited: (exitCode, exitStatus) => {
            // If process failed without output, ensure fallback
            if (internalSessionModel.count === 0) {
                internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
            }
        }
    }

    function parseSessions(output) {
        if (!output || output.trim() === "") {
            internalSessionModel.clear();
            internalSessionModel.append({ name: "Session", file: "unknown.desktop" });
            return;
        }

        internalSessionModel.clear();
        var lines = output.trim().split("\n");
        var currentDesktop = (Quickshell.env("XDG_SESSION_DESKTOP") || Quickshell.env("DESKTOP_SESSION") || "").toLowerCase();
        var bestIndex = 0;
        var added = 0;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;

            var parts = line.split("|||");
            if (parts.length === 2 && parts[0] !== "" && parts[1] !== "") {
                internalSessionModel.append({ name: parts[0], file: parts[1] });
                
                // Try to match the current desktop session
                var fileName = parts[1].toLowerCase();
                if (currentDesktop !== "" && (fileName.indexOf(currentDesktop) !== -1 || currentDesktop.indexOf(fileName.replace(".desktop", "")) !== -1)) {
                    bestIndex = added;
                }
                added++;
            }
        }

        // Fallback if no valid sessions were found
        if (added === 0) {
            internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
        } else {
            internalSessionModel.lastIndex = bestIndex;
        }
    }

    property var sddm: QtObject {
        signal loginFailed()
        signal loginSucceeded()

        function login(user, password, sessionIndex) {
            pam.user = user;
            pam.pendingPassword = password;
            pam.start();
        }

        function reboot() { Quickshell.execDetached(["systemctl", "reboot"]); }
        function powerOff() { Quickshell.execDetached(["systemctl", "poweroff"]); }
    }

    PamContext {
        id: pam
        property string pendingPassword: ""

        onResponseRequiredChanged: {
            if (responseRequired && pendingPassword !== "") {
                respond(pendingPassword);
                pendingPassword = "";
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                shim.sddm.loginSucceeded();
                Quickshell.execDetached(["loginctl", "unlock-session"]);
                // Both emitting the signal for lock_shell.qml and calling
                // loginctl to satisfy any external session monitors.
            } else {
                shim.sddm.loginFailed();
            }
        }
    }

    onThemePathChanged: loadConfig(themePath)
    Component.onCompleted: sessionEnumerator.running = true
}
