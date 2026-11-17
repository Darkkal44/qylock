import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kscreenlocker as ScreenLocker
import org.kde.plasma.private.sessions
import org.kde.plasma.workspace.components as Workspace
import org.kde.plasma.workspace.keyboardlayout as Keyboards
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

Item {
    id: root
    // KScreenLocker sets these properties on each output's root item.
    property bool viewVisible: false
    property bool debug: false
    property string notification: ""
    signal clearPassword()
    signal notificationRepeated()
    readonly property var nativeAuthenticator: authenticator
    readonly property var sddm: sddmCompat
    readonly property var qylockBackend: authBridge
    readonly property var userModel: users
    readonly property var sessionModel: sessions
    readonly property var keyboard: keyboardCompat
    property bool useFallback: false

    implicitWidth: 1366
    implicitHeight: 768
    onClearPassword: authBridge.reset()
    onViewVisibleChanged: {
        if (!viewVisible) { authBridge.reset(); optionsPopup.close(); }
    }

    function toggleOptions() {
        if (optionsPopup.opened) optionsPopup.close();
        else optionsPopup.open();
    }

    Shortcut {
        sequence: "F10"
        context: Qt.WindowShortcut
        enabled: root.viewVisible && !root.useFallback
        onActivated: root.toggleOptions()
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: !root.useFallback
        onTapped: root.toggleOptions()
    }

    ThemeConfig { id: themeConfig }
    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: capsLock; key: Qt.Key_CapsLock }

    // Existing themes use these SDDM names; KDE performs the actions.
    QtObject {
        id: sddmCompat
        readonly property bool canSwitchUser: userSwitch.canSwitchUser
        signal loginFailed()
        signal loginSucceeded()
        function login(user, password, sessionIndex) { authBridge.login(user, password, sessionIndex); }
        function switchUser() { return userSwitch.switchUser(); }
        function reboot() { if (sessionManagement.canReboot) sessionManagement.requestReboot(); }
        function powerOff() { if (sessionManagement.canShutdown) sessionManagement.requestShutdown(); }
        function suspend() {
            authBridge.reset();
            if (sessionManagement.canSuspend) sessionManagement.suspend();
        }
    }
    QtObject { id: keyboardCompat; property bool numLock: false }

    UserSwitchBridge {
        id: userSwitch
        backend: sessionManagement
        authentication: authBridge
        active: root.viewVisible && !root.useFallback
        onSwitchingUser: optionsPopup.close()
    }

    AuthenticationBridge {
        id: authBridge
        backend: root.nativeAuthenticator
        active: root.viewVisible && !root.useFallback
        capsLockOn: capsLock.locked
        onLoginFailed: sddmCompat.loginFailed()
        onAuthenticated: { sddmCompat.loginSucceeded(); Qt.quit(); }
    }

    ListModel {
        id: users
        property int lastIndex: 0
        readonly property string lastUser: kscreenlocker_userName
        function index(row, column) { return row; }
        function data(row, role) {
            if (row < 0 || row >= count) return "";
            return role === Qt.UserRole + 2 ? get(row).realName : get(row).name;
        }
        function rowCount() { return count; }
        Component.onCompleted: append({
            name: kscreenlocker_userName,
            realName: kscreenlocker_userName,
            icon: kscreenlocker_userImage ? "file://" + kscreenlocker_userImage.split("/").map(encodeURIComponent).join("/") : ""
        })
    }
    ListModel {
        id: sessions
        property int lastIndex: 0
        function rowCount() { return count; }
        ListElement { name: "Current session" }
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() { authBridge.reset(); }
    }

    Loader {
        id: themeLoader
        readonly property var config: themeConfig.values
        anchors.fill: parent
        focus: true
        source: "theme/Main.qml"
        active: !root.useFallback
        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("Qylock theme failed; loading the system lock screen");
                root.useFallback = true;
            }
        }
    }

    // A complete system locker is used if the theme cannot be loaded.
    Loader {
        id: fallbackLoader
        anchors.fill: parent
        active: root.useFallback
        source: active ? themeConfig.fallbackUrl : ""
        onLoaded: { item.viewVisible = Qt.binding(() => root.viewVisible); }
    }

    // Extra KDE controls are available on demand, without reserving theme space.
    Popup {
        id: optionsPopup
        objectName: "qylockOptions"
        x: root.width - width - 16
        y: 16
        width: Math.min(420, root.width - 32)
        height: Math.min(optionsColumn.implicitHeight + 32, root.height - 32)
        padding: 16
        focus: true
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: {
            if (themeLoader.item && authBridge.canSubmit) Qt.callLater(themeLoader.item.focusPassword);
        }
        background: Rectangle { color: "#1a1814"; radius: 8; border.color: "#706c58" }
        palette.windowText: "#d0cca8"
        palette.buttonText: "#d0cca8"
        palette.button: "#3e3c33"
        palette.highlight: "#706c58"
        palette.text: "#d0cca8"

        contentItem: Flickable {
            contentHeight: optionsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: optionsColumn
                width: parent.width
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Lock options"); color: "#d0cca8"; font.bold: true; Layout.fillWidth: true }
                    Button { text: qsTr("Close"); onClicked: optionsPopup.close() }
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: "#d0cca8"
                    text: authBridge.statusText
                    visible: text.length > 0
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: ScreenLocker.AuthenticatorModel
                        delegate: Button {
                            required property int type
                            required property string tooltip
                            required property bool functional
                            text: tooltip
                            checkable: true
                            checked: root.nativeAuthenticator.authenticator === type
                            enabled: functional
                            onClicked: {
                                root.nativeAuthenticator.authenticator = type;
                                optionsPopup.close();
                            }
                        }
                    }
                    Button {
                        text: qsTr("Keyboard")
                        visible: layoutSwitcher.hasMultipleKeyboardLayouts
                        onClicked: layoutSwitcher.keyboardLayout.switchToNextLayout()
                        Workspace.KeyboardLayoutSwitcher {
                            id: layoutSwitcher
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                        }
                        ToolTip.text: layoutSwitcher.layoutNames.longName
                        ToolTip.visible: hovered
                    }
                    Button {
                        text: qsTr("Virtual Keyboard")
                        onClicked: {
                            optionsPopup.close();
                            if (Keyboards.KWinVirtualKeyboard.visible) {
                                Keyboards.KWinVirtualKeyboard.active = false;
                            } else {
                                Qt.callLater(function() {
                                    if (themeLoader.item) themeLoader.item.focusPassword();
                                    Keyboards.KWinVirtualKeyboard.forceActivate();
                                });
                            }
                        }
                    }
                    Button {
                        text: qsTr("Sleep")
                        visible: sessionManagement.canSuspend
                        onClicked: { optionsPopup.close(); authBridge.reset(); sessionManagement.suspend(); }
                    }
                    Button {
                        text: qsTr("Switch User")
                        visible: sddmCompat.canSwitchUser
                        onClicked: sddmCompat.switchUser()
                    }
                }
            }
        }
    }
}
