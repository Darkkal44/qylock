import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Item {
    id: root

    property string user: Quickshell.env("USER") || ""
    readonly property bool enabled: (Quickshell.env("QS_FINGERPRINT") || "auto").toLowerCase() !== "off"
    readonly property int maxTries: Math.max(1, parseInt(Quickshell.env("QS_FINGERPRINT_TRIES")) || 3)

    property bool available: false
    property int tries: 0
    property int errors: 0
    property string status: "idle"
    property string message: ""

    readonly property bool active: pam.active
    readonly property bool canAttempt: enabled && available && tries < maxTries

    signal succeeded()
    signal failed(int tries, int maxTries)

    function check() {
        if (enabled) availProc.running = true;
    }

    function start() {
        if (!canAttempt || pam.active) return;
        status = "waiting";
        pam.start();
    }

    function abort() {
        retryTimer.stop();
        if (pam.active) pam.abort();
        if (status === "waiting") status = "idle";
    }

    Process {
        id: availProc
        command: [
            "sh", "-c",
            "command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$1\" 2>/dev/null | grep -q '#[0-9]*:'",
            "fprintd-avail", root.user
        ]

        onExited: (exitCode, exitStatus) => {
            root.available = exitCode === 0;
            if (root.available) {
                root.start();
            } else {
                console.log("Fingerprint: no reader or no enrolled fingerprints, using password only");
            }
        }
    }

    PamContext {
        id: pam
        config: "fprint"
        configDirectory: Quickshell.shellDir + "/pam.d"
        user: root.user

        onMessageChanged: root.message = message

        onResponseRequiredChanged: {
            if (responseRequired) respond("");
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.status = "success";
                root.succeeded();
                return;
            }

            if (result === PamResult.Error) {
                // A timeout just means nobody touched the sensor, listen again
                if (root.message.toLowerCase().indexOf("timed out") !== -1) {
                    retryTimer.restart();
                    return;
                }
                root.errors++;
                root.status = "error";
                console.warn("Fingerprint PAM error:", root.message);
                if (root.errors < 5) retryTimer.restart();
                return;
            }

            root.tries++;
            root.failed(root.tries, root.maxTries);
            if (root.tries < root.maxTries) {
                root.status = "failed";
                retryTimer.restart();
            } else {
                root.status = "exhausted";
            }
        }

        onError: (error) => {
            root.status = "error";
            root.message = PamError.toString(error);
            console.warn("Fingerprint PAM failed to start:", root.message);
        }
    }

    Timer {
        id: retryTimer
        interval: 800
        onTriggered: root.start()
    }
}
