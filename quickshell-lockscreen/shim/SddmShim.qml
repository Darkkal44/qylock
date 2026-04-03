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
                // Fallback: garantir que sempre exista um background padrão
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
            console.warn("SddmShim: falha ao carregar theme.conf:", e);
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
    }

    // Processo para enumerar sessões desktop do sistema
    Process {
        id: sessionEnumerator
        command: [
            "bash", "-c",
            "for f in /usr/share/wayland-sessions/*.desktop /usr/share/xsessions/*.desktop; do " +
            "[ -f \"$f\" ] && echo \"$(grep -m1 '^Name=' \"$f\" | sed 's/^Name=//')|||$(basename \"$f\")\"; " +
            "done 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                shim.parseSessions(this.text);
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Se o processo falhou sem produzir saída, garantir fallback
            if (internalSessionModel.count === 0) {
                internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
            }
        }
    }

    function parseSessions(output) {
        internalSessionModel.clear();

        if (!output || output.trim() === "") {
            internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
            return;
        }

        var lines = output.trim().split("\n");
        var added = 0;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;

            var parts = line.split("|||");
            if (parts.length === 2 && parts[0] !== "" && parts[1] !== "") {
                internalSessionModel.append({ name: parts[0], file: parts[1] });
                added++;
            }
        }

        // Fallback se nenhuma sessão válida foi encontrada
        if (added === 0) {
            internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
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
    Component.onCompleted: sessionEnumerator.exec()
}
