import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#050810"

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0)
                               ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    TextConstants { id: textConstants }

    // Font
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: shurikenFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Session
    ListView {
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sName: model.name || "" }
    }

    // User
    ListView {
        id: userHelper
        model: userModel
        currentIndex: root.userIndex
        opacity: 0; width: 100 * s; height: 100 * s; z: -100
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }

    // Boot
    Component.onCompleted: fadeAnim.start()

    Timer {
        id: focusTimer
        interval: 300
        running: true
        onTriggered: passwordField.forceActiveFocus()
    }
    NumberAnimation {
        id: fadeAnim
        target: root; property: "ui"
        from: 0; to: 1; duration: 1400
        easing.type: Easing.OutCubic
    }

    // Background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#080c14" }
            GradientStop { position: 0.5; color: "#0e1420" }
            GradientStop { position: 1.0; color: "#050810" }
        }
    }

    // Video
    Loader {
        anchors.fill: parent
        source: "BackgroundVideo.qml"
    }

    // Vignette
    RadialGradient {
        anchors.fill: parent
        opacity: 0.75
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#bb000000" }
        }
    }

    // Overlay
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 200 * s
        opacity: 0.65
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#dd000000" }
        }
    }

    // Clock
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 70 * s
        anchors.topMargin: 60 * s
        spacing: 8 * s
        opacity: root.ui

        Text {
            id: clockText
            text: Qt.formatTime(new Date(), "HH:mm")
            color: "white"
            font.family: shurikenFont.name
            font.pixelSize: 88 * s
            font.weight: Font.Thin
            style: Text.Normal
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Row {
            spacing: 10 * s
            Rectangle {
                width: 22 * s; height: 1 * s
                color: "#6090b8"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd · MMMM d").toUpperCase()
                color: "#6090b8"
                font.family: shurikenFont.name
                font.pixelSize: 13 * s
                font.letterSpacing: 3 * s
            }
        }
    }

    // Login
    Column {
        id: loginPanel
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 40 * s
        anchors.bottomMargin: 110 * s
        width: 280 * s
        spacing: 0 * s
        opacity: root.ui

        // Username
        Text {
            id: userDisplay
            anchors.right: parent.right
            text: (userHelper.currentItem && userHelper.currentItem.uName)
                  ? userHelper.currentItem.uName
                  : (userModel.lastUser || "User")
            color: "white"
            font.family: shurikenFont.name
            font.pixelSize: 22 * s
            font.letterSpacing: 2 * s
            
            scale: uMa.containsMouse ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            transform: Translate { id: uTrans; x: 0 }

            MouseArea {
                id: uMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (userModel && userModel.rowCount() > 0)
                        uToggleAnim.start()
                }
            }

            SequentialAnimation {
                id: uToggleAnim
                ParallelAnimation {
                    NumberAnimation { target: userDisplay; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { target: uTrans; property: "x"; to: 15 * s; duration: 120; easing.type: Easing.InQuad }
                }
                ScriptAction { script: root.userIndex = (root.userIndex + 1) % userModel.rowCount() }
                ParallelAnimation {
                    NumberAnimation { target: userDisplay; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutQuad }
                    NumberAnimation { target: uTrans; property: "x"; to: 0; duration: 180; easing.type: Easing.OutQuad }
                }
            }
        }

        Item { width: 1 * s; height: 22 * s }

        // Password
        Item {
            width: parent.width
            height: 36 * s

            TextInput {
                id: passwordField
                anchors.left: parent.left
                anchors.right: arrowHint.left
                anchors.rightMargin: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                font.family: shurikenFont.name
                font.pixelSize: 14 * s
                echoMode: TextInput.NoEcho
                focus: true
                clip: true
                cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                selectionColor: "#6090b8"
                property bool wasClicked: false
                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed:  doLogin()
                
                // Visual representation row
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * s

                    Repeater {
                        model: passwordField.text.length
                        delegate: Text {
                            text: "✦"
                            color: "white"
                            font: passwordField.font
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        id: customCursor
                        text: "✦"
                        color: "white"
                        font: passwordField.font
                        verticalAlignment: Text.AlignVCenter
                        visible: passwordField.focus && (passwordField.text.length > 0 || passwordField.wasClicked)
                        
                        layer.enabled: true
                        layer.effect: DropShadow { color: "white"; radius: 8; samples: 16 }

                        SequentialAnimation {
                            loops: Animation.Infinite; running: customCursor.visible
                            NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { target: customCursor; property: "opacity"; from: 0.2; to: 1; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter password"
                    color: "white"
                    opacity: (passwordField.text.length === 0 && !passwordField.wasClicked) ? 0.25 : 0
                    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutSine } }
                    font.family: shurikenFont.name
                    font.pixelSize: 14 * s
                    font.letterSpacing: 2 * s
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        passwordField.forceActiveFocus()
                        passwordField.wasClicked = true
                    }
                }
            }

            Text {
                id: arrowHint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "→"
                color: "#6090b8"
                font.pixelSize: 16 * s
                opacity: passwordField.text.length > 0 ? 1.0 : 0.3
                Behavior on opacity { NumberAnimation { duration: 200 } }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }

        // Focus line
        Rectangle {
            width: parent.width
            height: 1 * s
            color: passwordField.activeFocus ? "#80b0d8" : "#28607888"
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Item { width: 1 * s; height: 10 * s }

        Text {
            id: errorMessage
            anchors.right: parent.right
            font.family: shurikenFont.name
            font.pixelSize: 11 * s
            font.letterSpacing: 1 * s
            color: "#d06060"
            text: ""
        }
    }

    // System
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 40 * s
        anchors.rightMargin: 40 * s
        anchors.bottomMargin: 30 * s
        height: 1 * s
        color: "#15a0c8e0"
        opacity: root.ui
    }

    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 40 * s
        height: 40 * s
        opacity: root.ui * 0.8

        // Left: Session cycler
        Item {
            width: sessionSwitchRow.implicitWidth; height: sessionSwitchRow.implicitHeight
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter

            Row {
                id: sessionSwitchRow
                spacing: 10 * s
                
                opacity: sMa.containsMouse ? 1.0 : 0.85
                scale: sMa.containsMouse ? 1.05 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                transform: Translate { id: sTrans; x: 0 }

                Text {
                    text: "◈"
                    color: "#405070"; font.pixelSize: 10 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: sessionLabel
                    text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0)
                          ? sessionHelper.currentItem.sName
                          : "Session"
                    color: "white"
                    opacity: 0.6
                    font.family: shurikenFont.name
                    font.pixelSize: 12 * s
                    font.letterSpacing: 1 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            MouseArea {
                id: sMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sessionModel && sessionModel.rowCount() > 0)
                        sToggleAnim.start()
                }
            }

            SequentialAnimation {
                id: sToggleAnim
                ParallelAnimation {
                    NumberAnimation { target: sessionLabel; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { target: sTrans; property: "x"; to: 10 * s; duration: 120; easing.type: Easing.InQuad }
                }
                ScriptAction { script: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                ParallelAnimation {
                    NumberAnimation { target: sessionLabel; property: "opacity"; to: 0.6; duration: 180; easing.type: Easing.OutQuad }
                    NumberAnimation { target: sTrans; property: "x"; to: 0; duration: 180; easing.type: Easing.OutQuad }
                }
            }
        }

        // Right: Power controls (no Sleep)
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 28 * s

            Text {
                text: "Restart"
                color: "white"; opacity: 0.4
                font.family: shurikenFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1 * s

                Behavior on opacity { NumberAnimation { duration: 150 } }
                scale: rMa.containsMouse ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                
                MouseArea {
                    id: rMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.opacity = 0.9
                    onExited:  parent.opacity = 0.4
                    onClicked: sddm.reboot()
                }
            }
            Text {
                text: "Shut Down"
                color: "white"; opacity: 0.4
                font.family: shurikenFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1 * s

                Behavior on opacity { NumberAnimation { duration: 150 } }
                scale: pMa.containsMouse ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                MouseArea {
                    id: pMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.opacity = 0.9
                    onExited:  parent.opacity = 0.4
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    // Logic
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "authentication failed"
            passwordField.text = ""
            passwordField.focus = true
            shakeAnim.start()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 10; duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 9;  duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 7;  duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 5;  duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x;      duration: 50 }
    }

    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin)
                    ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(uname, passwordField.text, root.sessionIndex)
    }
}
