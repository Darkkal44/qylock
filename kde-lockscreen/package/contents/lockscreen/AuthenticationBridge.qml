import QtQuick
import "." as Shared

// No PAM implementation or password cache: KDE owns the whole conversation.
Item {
    id: bridge
    required property var backend
    property bool active: false
    property bool awaitingPrompt: false
    property string message: ""
    property string promptLabel: qsTr("Password")
    property bool capsLockOn: false
    readonly property string statusText: {
        const parts = [];
        if (capsLockOn) parts.push(qsTr("Caps Lock is on"));
        if (backend.inPasswordDelay) {
            parts.push(qsTr("Please wait before trying again."));
        } else if (message && !/^password\s*:?\s*$/i.test(message)) {
            parts.push(message);
        }
        return parts.join(" • ");
    }
    readonly property bool canSubmit: active && awaitingPrompt && !Shared.AuthenticationState.responsePending && !backend.unlocked
                                      && !backend.inPasswordDelay
    signal loginFailed()
    signal clearRequested()
    signal authenticated()

    function login(user, password, sessionIndex) {
        if (!canSubmit) return;
        Shared.AuthenticationState.responsePending = true;
        awaitingPrompt = false;
        message = qsTr("Checking credentials…");
        clearRequested();
        backend.respond(password);
    }

    function reset() {
        clearRequested();
    }

    Connections {
        target: Shared.AuthenticationState
        function onResponsePendingChanged() {
            if (Shared.AuthenticationState.responsePending) bridge.clearRequested();
        }
    }

    onActiveChanged: {
        reset();
        if (active && !backend.unlocked) backend.startAuthenticating();
    }

    // KDE may start its worker asynchronously or restart it after suspend.
    Timer {
        interval: 1000
        running: bridge.active && !bridge.backend.unlocked
        repeat: true
        onTriggered: bridge.backend.startAuthenticating()
    }

    Connections {
        target: bridge.backend
        function onPromptForSecretChanged() {
            Shared.AuthenticationState.responsePending = false;
            bridge.promptLabel = bridge.backend.promptForSecret || qsTr("Password");
            bridge.message = bridge.promptLabel;
            bridge.clearRequested();
            bridge.awaitingPrompt = true;
        }
        function onPromptChanged() {
            Shared.AuthenticationState.responsePending = false;
            bridge.promptLabel = bridge.backend.prompt || qsTr("Response");
            bridge.message = bridge.promptLabel;
            bridge.clearRequested();
            bridge.awaitingPrompt = true;
        }
        function onInfoMessageChanged() { bridge.message = bridge.backend.infoMessage; }
        function onErrorMessageChanged() { bridge.message = bridge.backend.errorMessage; }
        function onFailed(kind) {
            // Background fingerprint failures must not reset a password attempt.
            if (kind !== 0) return;
            bridge.awaitingPrompt = false;
            bridge.reset();
            bridge.message = qsTr("Unlocking failed. Please try again.");
            bridge.loginFailed();
            if (bridge.active) bridge.backend.startAuthenticating();
        }
        function onAuthenticatorChanged() {
            bridge.awaitingPrompt = false;
            bridge.reset();
            bridge.message = "";
            if (bridge.active) bridge.backend.startAuthenticating();
        }
        function onSucceeded() {
            // An event alone is insufficient: KDE must report an unlocked state.
            if (!bridge.backend.unlocked) return;
            bridge.awaitingPrompt = false;
            bridge.reset();
            if (Shared.AuthenticationState.successHandled) return;
            Shared.AuthenticationState.successHandled = true;
            bridge.backend.stopAuthenticating();
            bridge.authenticated();
        }
    }
}
