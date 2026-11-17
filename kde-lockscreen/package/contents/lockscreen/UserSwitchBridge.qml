import QtQml

QtObject {
    required property var backend
    required property var authentication
    property bool active: false
    readonly property bool canSwitchUser: active && backend.canSwitchUser && backend.canLock
    signal switchingUser()

    function switchUser() {
        if (!canSwitchUser) return false;
        authentication.reset();
        switchingUser();
        // KDE locks the current session before handing off to the display manager.
        backend.switchUser();
        return true;
    }
}
