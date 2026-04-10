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
    color: "#0a0a0a"

    // ── Properties ───────────────────────────────────────────────────
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property real ui: 0

    // Colors - Carbon Theme (Standardized Tech/Mono)
    readonly property color accent:     "#ffffff" // Pure White for high tech feel
    readonly property color light:      "#f8f8f2"
    readonly property color panelBg:    "#dd0a0a0a"

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: orbitron; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // ── Helpers ──────────────────────────────────────────────────────
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: userModel; currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || "" } }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordField.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1800; easing.type: Easing.OutCubic }

    // ── Background ────────────────────────────────────────────────────
    Image {
        id: bg
        anchors.fill: parent
        source: "Background.jpeg"
        fillMode: Image.PreserveAspectCrop
        
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.75
        }
    }

    // ── Data Fragments Animation (Carbon Tech) ────────────────────────
    Repeater {
        model: 15
        delegate: Item {
            id: frag
            property real startX: Math.random() * root.width
            property real dur:    6000 + Math.random() * 4000
            property real sz:     2 + Math.random() * 3
            property real delay:  Math.random() * 5000
            x: startX; y: root.height + 20; width: sz; height: sz; opacity: 0
            
            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: 0.3
            }

            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: frag.delay }
                ParallelAnimation {
                    NumberAnimation { target: frag; property: "y"; from: root.height + 20; to: -100; duration: frag.dur; easing.type: Easing.Linear }
                    NumberAnimation { target: frag; property: "x"; to: frag.startX + (Math.random()-0.5)*100; duration: frag.dur }
                    SequentialAnimation {
                        NumberAnimation { target: frag; property: "opacity"; to: 0.6; duration: 1000 }
                        PauseAnimation { duration: frag.dur - 2000 }
                        NumberAnimation { target: frag; property: "opacity"; to: 0; duration: 1000 }
                    }
                }
            }
        }
    }

    // Centered Content
    Column {
        id: mainPanel
        anchors.left: parent.left
        anchors.leftMargin: 120 * s
        anchors.verticalCenter: parent.verticalCenter
        width: 360 * s
        spacing: 40 * s
        opacity: root.ui

        // Clock
        Column {
            spacing: 5 * s
            Text {
                id: clockLabel
                text: Qt.formatTime(new Date(), "HH:mm")
                font.family: orbitron.name; font.pixelSize: 84 * s; font.weight: Font.DemiBold; color: "white"
                style: Text.Outline; styleColor: "#40000000"
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockLabel.text = Qt.formatTime(new Date(), "HH:mm") }
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
                font.family: orbitron.name; font.pixelSize: 13 * s; font.letterSpacing: 4 * s; color: "white"; opacity: 0.6
                font.weight: Font.Bold
            }
        }

        // Login Card
        Column {
            width: parent.width
            spacing: 25 * s

            Text {
                text: (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName.toUpperCase() : "CARBON USER"
                font.family: orbitron.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s; color: "white"; opacity: 1.0; font.weight: Font.DemiBold
            }

            Item {
                width: parent.width; height: 50 * s
                Rectangle { 
                    anchors.fill: parent; radius: 4 * s; color: "#44000000"
                    border.color: passwordField.activeFocus ? "white" : "#44ffffff"; border.width: 1 * s
                }
                
                TextInput {
                    id: passwordField; anchors.fill: parent; anchors.leftMargin: 20 * s; anchors.rightMargin: 20 * s
                    color: "white"; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14 * s; font.letterSpacing: 12 * s
                    echoMode: TextInput.Password; passwordCharacter: "■"; focus: true
                    font.weight: Font.Bold
                    cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    selectionColor: root.accent
                    property bool wasClicked: false
                    Keys.onReturnPressed: doLogin()

                    Rectangle {
                        id: customCursor
                        width: 2 * s; height: 20 * s
                        color: root.accent
                        anchors.verticalCenter: parent.verticalCenter
                        x: passwordField.cursorRectangle.x
                        visible: passwordField.focus && (passwordField.text.length > 0 || passwordField.wasClicked)
                        SequentialAnimation {
                            loops: Animation.Infinite; running: customCursor.visible
                            NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                            NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordField.forceActiveFocus()
                            passwordField.wasClicked = true
                        }
                    }
                }
                
                Text {
                    anchors.left: passwordField.left; anchors.right: passwordField.right; anchors.top: passwordField.top; anchors.bottom: passwordField.bottom
                    verticalAlignment: Text.AlignVCenter
                    text: "Access Key..."; color: "white"; font.pixelSize: 13 * s
                    opacity: passwordField.text.length === 0 ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }
            }

            MouseArea {
                id: loginBtn
                width: parent.width; height: 50 * s; hoverEnabled: true; onClicked: doLogin()
                Rectangle {
                    anchors.fill: parent; radius: 4 * s; color: parent.containsMouse ? "white" : "transparent"
                    border.color: "white"; border.width: 1 * s
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    anchors.centerIn: parent; text: "CONFIRM"; color: loginBtn.containsMouse ? "black" : "white"
                    font.family: orbitron.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; font.weight: Font.Bold
                }
            }
        }

        Text { id: errorMessage; text: ""; color: "#ff5555"; font.family: orbitron.name; font.pixelSize: 11 * s; font.weight: Font.Bold }
    }

    // Power
    Row {
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 60 * s; spacing: 40 * s; opacity: root.ui * 0.8
        Repeater {
            model: [{l: "Shutdown", f: sddm.powerOff}, {l: "Restart", f: sddm.reboot}]
            delegate: Text {
                text: modelData.l.toUpperCase(); font.family: orbitron.name; font.pixelSize: 11 * s; font.letterSpacing: 2 * s; color: "white"; opacity: 0.6; font.weight: Font.Bold
                MouseArea { anchors.fill: parent; onEntered: parent.opacity = 1; onExited: parent.opacity = 0.6; onClicked: modelData.f() }
            }
        }
    }

    // Session Manager
    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 60 * s
        anchors.leftMargin: 120 * s
        spacing: 12 * s
        opacity: root.ui * 0.8

        Text {
            text: "ENVIRONMENT"
            font.family: orbitron.name; font.pixelSize: 10 * s; font.letterSpacing: 2 * s; color: "white"; opacity: 0.5; font.weight: Font.Bold
        }

        MouseArea {
            id: sessionBtn
            width: 180 * s; height: 36 * s; hoverEnabled: true
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()

            Rectangle {
                anchors.fill: parent; radius: 4 * s; color: sessionBtn.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                border.color: sessionBtn.containsMouse ? root.accent : Qt.rgba(1,1,1,0.2); border.width: 1 * s
                Behavior on border.color { ColorAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Row {
                anchors.centerIn: parent; spacing: 10 * s
                Rectangle { width: 4 * s; height: 4 * s; color: root.accent; radius: 2 * s; anchors.verticalCenter: parent.verticalCenter; opacity: sessionBtn.containsMouse ? 1 : 0.5 }
                Text {
                    text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "Session").toUpperCase()
                    font.family: orbitron.name; font.pixelSize: 11 * s; font.letterSpacing: 1 * s; color: "white"; font.weight: Font.Bold
                }
            }
        }
    }

    Connections { target: sddm; function onLoginFailed() { errorMessage.text = "DATA_CORRUPT"; passwordField.text = ""; shakeAnim.start() } }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: mainPanel; property: "anchors.leftMargin"; to: 130 * s; duration: 50 }
        NumberAnimation { target: mainPanel; property: "anchors.leftMargin"; to: 110 * s; duration: 50 }
        NumberAnimation { target: mainPanel; property: "anchors.leftMargin"; to: 120 * s; duration: 50 }
    }
    function doLogin() { sddm.login(userModel.lastUser, passwordField.text, root.sessionIndex) }
}
