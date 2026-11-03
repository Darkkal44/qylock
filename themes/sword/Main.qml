import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    id: root
    width: Screen.width; height: Screen.height
    color: "#050810"
    readonly property real s: height / 768

    // Quickshell
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined

    // State
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0
    property int focusedElement: 0 // 0: Password, 1: Session, 2: Restart, 3: Shutdown, 4: User

    function activateFocused() {
        if (root.focusedElement === 0) {
            doLogin()
        } else if (root.focusedElement === 1) {
            if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                sToggleAnim.start()
        } else if (root.focusedElement === 2) {
            if (typeof sddm !== "undefined") sddm.reboot()
        } else if (root.focusedElement === 3) {
            if (typeof sddm !== "undefined") sddm.powerOff()
        } else if (root.focusedElement === 4) {
            if (typeof userModel !== "undefined" && userModel.rowCount() > 0)
                uToggleAnim.start()
        }
    }
    TextConstants { id: textConstants }

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: shurikenFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Helpers
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sName: model.name || "" }
    }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex
        opacity: 0; width: 100 * s; height: 100 * s; z: -100
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }

    // Animation
    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }

    Timer { interval: 300; running: true; onTriggered: passwordField.forceActiveFocus() }

    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic }

    // Visuals
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#080c14" }
            GradientStop { position: 0.5; color: "#0e1420" }
            GradientStop { position: 1.0; color: "#050810" }
        }
    }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    RadialGradient {
        anchors.fill: parent; opacity: 0.75
        gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#bb000000" } }
    }

    Rectangle {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 200 * s; opacity: 0.65
        gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#dd000000" } }
    }

    // Clock
    Column {
        anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 70 * s; anchors.topMargin: 60 * s; spacing: 8 * s; opacity: root.ui
        Text {
            id: clockText; text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.family: shurikenFont.name; font.pixelSize: 88 * s; font.weight: Font.Thin
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") }
        }
        Row {
            spacing: 10 * s
            Rectangle { width: 22 * s; height: 1 * s; color: "#6090b8"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Qt.formatDate(new Date(), "dddd · MMMM d").toUpperCase(); color: "#6090b8"; font.family: shurikenFont.name; font.pixelSize: 13 * s; font.letterSpacing: 3 * s }
        }
    }

    // Interface
    Column {
        id: loginPanel
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: 40 * s; anchors.bottomMargin: 110 * s; width: 280 * s; spacing: 0 * s; opacity: root.ui

        Text {
            id: userDisplay; anchors.right: parent.right
            property bool isFocused: root.focusedElement === 4
            text: (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? (userModel.lastUser || "User") : "User")
            color: (isFocused || uMa.containsMouse) ? "#80b0d8" : "white"
            font.family: shurikenFont.name; font.pixelSize: 22 * s; font.letterSpacing: 2 * s
            scale: (isFocused || uMa.containsMouse) ? 1.05 : 1.0
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            transform: Translate { id: uTrans; x: 0 }
            MouseArea {
                id: uMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (typeof userModel !== "undefined" && userModel.rowCount() > 0) uToggleAnim.start() }
            }
            SequentialAnimation {
                id: uToggleAnim; ParallelAnimation { NumberAnimation { target: userDisplay; property: "opacity"; to: 0; duration: 120 } NumberAnimation { target: uTrans; property: "x"; to: 15 * s; duration: 120 } }
                ScriptAction { script: root.userIndex = (root.userIndex + 1) % userModel.rowCount() }
                ParallelAnimation { NumberAnimation { target: userDisplay; property: "opacity"; to: 1; duration: 180 } NumberAnimation { target: uTrans; property: "x"; to: 0; duration: 180 } }
            }
        }

        Item { width: 1 * s; height: 22 * s }

        Item {
            width: parent.width; height: 36 * s
            TextInput {
                id: passwordField; anchors.left: parent.left; anchors.right: arrowHint.left; anchors.rightMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter
                color: "transparent"; font.family: shurikenFont.name; font.pixelSize: 14 * s; echoMode: TextInput.NoEcho; focus: true; clip: true; cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                selectionColor: "#6090b8"; property bool wasClicked: false; onTextEdited: errorMessage.text = ""
                Keys.onTabPressed: (event) => {
                    root.focusedElement = (root.focusedElement + 1) % 5
                    event.accepted = true
                }
                Keys.onBacktabPressed: (event) => {
                    root.focusedElement = (root.focusedElement - 1 + 5) % 5
                    event.accepted = true
                }
                Keys.onEscapePressed: (event) => {
                    root.focusedElement = 0
                    passwordField.text = ""
                    errorMessage.text = ""
                    event.accepted = true
                }
                Keys.onReturnPressed: (event) => {
                    root.activateFocused()
                    event.accepted = true
                }
                Keys.onEnterPressed: (event) => {
                    root.activateFocused()
                    event.accepted = true
                }
                Keys.onSpacePressed: (event) => {
                    if (root.focusedElement !== 0) {
                        root.activateFocused()
                        event.accepted = true
                    }
                }
                Keys.onUpPressed: (event) => {
                    if (root.focusedElement === 1) {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                            sToggleAnim.start()
                        event.accepted = true
                    } else if (root.focusedElement === 4) {
                        if (typeof userModel !== "undefined" && userModel.rowCount() > 0)
                            uToggleAnim.start()
                        event.accepted = true
                    }
                }
                Keys.onDownPressed: (event) => {
                    if (root.focusedElement === 1) {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                            sToggleAnim.start()
                        event.accepted = true
                    } else if (root.focusedElement === 4) {
                        if (typeof userModel !== "undefined" && userModel.rowCount() > 0)
                            uToggleAnim.start()
                        event.accepted = true
                    }
                }
                Keys.onPressed: (event) => {
                    if (root.focusedElement !== 0 && event.text && event.text.length > 0 &&
                        event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab &&
                        event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter &&
                        event.key !== Qt.Key_Space && event.key !== Qt.Key_Escape) {
                        root.focusedElement = 0
                    }
                }
                Row {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 8 * s
                    Repeater { model: passwordField.text.length; delegate: Text { text: "✦"; color: "white"; font: passwordField.font; verticalAlignment: Text.AlignVCenter } }
                    Text {
                        id: customCursor; text: "✦"; color: "white"; font: passwordField.font; verticalAlignment: Text.AlignVCenter; visible: root.focusedElement === 0 && passwordField.focus && (passwordField.text.length > 0 || passwordField.wasClicked)
                        layer.enabled: true; layer.effect: DropShadow { color: "white"; radius: 8; samples: 16 }
                        SequentialAnimation { loops: Animation.Infinite; running: customCursor.visible; NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.2; duration: 600; easing.type: Easing.InOutSine } NumberAnimation { target: customCursor; property: "opacity"; from: 0.2; to: 1; duration: 600; easing.type: Easing.InOutSine } }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter; text: "Enter password"; color: "white"
                    opacity: (passwordField.text.length === 0 && !passwordField.wasClicked) ? 0.25 : 0
                    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutSine } }
                    font.family: shurikenFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: { passwordField.forceActiveFocus(); passwordField.wasClicked = true } }
            }
            Text {
                id: arrowHint; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "→"; color: "#6090b8"; font.pixelSize: 16 * s; opacity: passwordField.text.length > 0 ? 1.0 : 0.3
                Behavior on opacity { NumberAnimation { duration: 200 } }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
            }
        }

        Rectangle { width: parent.width; height: 1 * s; color: (root.focusedElement === 0 && passwordField.activeFocus) ? "#80b0d8" : "#28607888"; Behavior on color { ColorAnimation { duration: 300 } } }

        Item { width: 1 * s; height: 10 * s }

        Text { id: errorMessage; anchors.right: parent.right; height: 15 * s; verticalAlignment: Text.AlignTop; font.family: shurikenFont.name; font.pixelSize: 11 * s; font.letterSpacing: 1 * s; color: "#d06060"; text: "" }
    }

    Rectangle {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 40 * s; anchors.rightMargin: 40 * s; anchors.bottomMargin: 30 * s; height: 1 * s; color: "#15a0c8e0"; opacity: root.ui
    }

    Item {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 40 * s; height: 40 * s; opacity: root.ui * 0.8

        Item {
            width: sessionSwitchRow.implicitWidth; height: sessionSwitchRow.implicitHeight; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; visible: !root.isQuickshell
            property bool isFocused: root.focusedElement === 1
            Row {
                id: sessionSwitchRow; spacing: 10 * s
                opacity: (parent.isFocused || sMa.containsMouse) ? 1.0 : 0.85
                scale: (parent.isFocused || sMa.containsMouse) ? 1.08 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                transform: Translate { id: sTrans; x: 0 }
                Text {
                    text: "◈"
                    color: (parent.parent.isFocused || sMa.containsMouse) ? "#80b0d8" : "#405070"
                    font.pixelSize: 10 * s
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    id: sessionLabel; text: (typeof sessionModel !== "undefined" && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0) ? sessionHelper.currentItem.sName : "Session"
                    color: (parent.parent.isFocused || sMa.containsMouse) ? "#80b0d8" : "white"
                    opacity: (parent.parent.isFocused || sMa.containsMouse) ? 1.0 : 0.6
                    font.family: shurikenFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1 * s; anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
            MouseArea { id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) sToggleAnim.start() } }
            SequentialAnimation {
                id: sToggleAnim; ParallelAnimation { NumberAnimation { target: sessionLabel; property: "opacity"; to: 0; duration: 120 } NumberAnimation { target: sTrans; property: "x"; to: 10 * s; duration: 120 } }
                ScriptAction { script: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                ParallelAnimation { NumberAnimation { target: sessionLabel; property: "opacity"; to: (root.focusedElement === 1 || sMa.containsMouse) ? 1.0 : 0.6; duration: 180 } NumberAnimation { target: sTrans; property: "x"; to: 0; duration: 180 } }
            }
        }

        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 28 * s
            Text {
                id: restartBtn
                property bool isFocused: root.focusedElement === 2
                text: "Restart"
                color: (isFocused || rMa.containsMouse) ? "#80b0d8" : "white"
                opacity: (isFocused || rMa.containsMouse) ? 1.0 : 0.4
                font.family: shurikenFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1 * s
                scale: (isFocused || rMa.containsMouse) ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                MouseArea { id: rMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (typeof sddm !== "undefined") sddm.reboot() } }
            }
            Text {
                id: shutdownBtn
                property bool isFocused: root.focusedElement === 3
                text: "Shut Down"
                color: (isFocused || pMa.containsMouse) ? "#80b0d8" : "white"
                opacity: (isFocused || pMa.containsMouse) ? 1.0 : 0.4
                font.family: shurikenFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1 * s
                scale: (isFocused || pMa.containsMouse) ? 1.15 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (typeof sddm !== "undefined") sddm.powerOff() } }
            }
        }
    }

    // Action
    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        if (typeof sddm !== "undefined") sddm.login(uname, passwordField.text, root.sessionIndex)
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { errorMessage.text = "ACCESS DENIED"; passwordField.text = ""; passwordField.focus = true; shakeAnim.start() }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: 50 * s; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: 30 * s; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: 45 * s; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: 35 * s; duration: 50 }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: 40 * s; duration: 50 }
    }
}
