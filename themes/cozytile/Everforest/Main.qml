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
    color: "#232a2e"

    // ── Properties ───────────────────────────────────────────────────
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property real ui: 0

    // Colors - Everforest Theme
    readonly property color accent:     "#86918a"
    readonly property color light:      "#d3c6aa"
    readonly property color panelBg:    "#dd2e383c"

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
        source: "Background.png"
        fillMode: Image.PreserveAspectCrop
        
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.65
        }
    }

    // ── Forest Spores Animation (Everforest) ──────────────────────────
    Repeater {
        model: 25
        delegate: Item {
            id: spore
            property real startX: Math.random() * root.width
            property real startY: Math.random() * root.height
            property real dur:    15000 + Math.random() * 10000
            property real driftX: (Math.random() - 0.5) * 200
            property real driftY: (Math.random() - 0.5) * 200
            property real sz:     2 + Math.random() * 4
            property real delay:  Math.random() * 5000
            
            x: startX; y: startY; width: sz; height: sz; opacity: 0
            
            Rectangle {
                anchors.fill: parent
                radius: sz * 0.5
                color: "#a3be8c"
                opacity: 0.4
            }

            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: spore.delay }
                ParallelAnimation {
                    NumberAnimation { target: spore; property: "x"; to: spore.startX + spore.driftX; duration: spore.dur; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: spore; property: "y"; to: spore.startY + spore.driftY; duration: spore.dur; easing.type: Easing.InOutQuad }
                    SequentialAnimation {
                        NumberAnimation { target: spore; property: "opacity"; to: 0.5; duration: 4000 }
                        PauseAnimation { duration: spore.dur - 8000 }
                        NumberAnimation { target: spore; property: "opacity"; to: 0; duration: 4000 }
                    }
                }
                PropertyAction { target: spore; property: "x"; value: spore.startX }
                PropertyAction { target: spore; property: "y"; value: spore.startY }
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

        // Clock Column
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
                font.family: orbitron.name; font.pixelSize: 13 * s; font.letterSpacing: 4 * s; color: root.accent
                font.weight: Font.Bold
            }
        }

        // Login Card
        Column {
            width: parent.width
            spacing: 25 * s

            Text {
                text: (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName.toUpperCase() : "EVERFOREST"
                font.family: orbitron.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s; color: "white"; opacity: 1.0; font.weight: Font.DemiBold
            }

            // Simple Rounded Input
            Item {
                width: parent.width; height: 50 * s
                Rectangle { 
                    anchors.fill: parent; radius: 4 * s; color: "#44000000"
                    border.color: passwordField.activeFocus ? root.accent : "#44ffffff"; border.width: 1 * s
                }
                
                TextInput {
                    id: passwordField; anchors.fill: parent; anchors.leftMargin: 20 * s; anchors.rightMargin: 20 * s
                    color: "white"; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14 * s; font.letterSpacing: 12 * s
                    echoMode: TextInput.Password; passwordCharacter: "◈"; focus: true
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
                    text: "Password..."; color: "white"; font.pixelSize: 13 * s
                    opacity: passwordField.text.length === 0 ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }
            }

            // Action
            MouseArea {
                id: loginBtn
                width: parent.width; height: 50 * s; hoverEnabled: true; onClicked: doLogin()
                Rectangle {
                    anchors.fill: parent; radius: 4 * s; color: parent.containsMouse ? root.accent : "transparent"
                    border.color: root.accent; border.width: 1 * s
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    anchors.centerIn: parent; text: "CONFIRM"; color: loginBtn.containsMouse ? "#232a2e" : "white"
                    font.family: orbitron.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; font.weight: Font.Bold
                }
            }
        }

        Text { id: errorMessage; text: ""; color: "#ff8080"; font.family: orbitron.name; font.pixelSize: 11 * s; font.weight: Font.Bold }
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
                anchors.fill: parent; radius: 4 * s; color: sessionBtn.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
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

    Connections { target: sddm; function onLoginFailed() { errorMessage.text = "INVALID_KEY"; passwordField.text = ""; shakeAnim.start() } }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: mainPanel; property: "anchors.leftMargin"; to: 130 * s; duration: 50 }
        NumberAnimation { target: mainPanel; property: "anchors.leftMargin"; to: 110 * s; duration: 50 }
        NumberAnimation { target: mainPanel; property: "anchors.leftMargin"; to: 120 * s; duration: 50 }
    }
    function doLogin() { sddm.login(userModel.lastUser, passwordField.text, root.sessionIndex) }
}
