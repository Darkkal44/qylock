import QtQuick
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel

Item {
    id: root
    width: 1920; height: 1080
    readonly property real s: width / 1920

    // ── PALETTE ──
    readonly property color textPrimary:   "#ffffff"
    readonly property color textSecondary: "#99aab5"
    readonly property color accent:        "#cde4ef"

    // ── STATE ──
    property int  userIndex:    userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int  sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool loginError:   false
    
    // UI state for menus
    property bool sessionMenuOpen: false


    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader      { id: mainFont;  source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper;    model: userModel;    currentIndex: root.userIndex;    opacity: 0; width: 1; height: 1; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    function login() {
        var n = (userHelper.currentItem && userHelper.currentItem.uLogin !== "") ? userHelper.currentItem.uLogin : (userModel.lastUser || "")
        sddm.login(n, passInput.text, root.sessionIndex)
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginError = true
            passInput.text = ""
            errorShake.start()
            passInput.forceActiveFocus()
        }
    }

    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    // ── BACKGROUND ──
    Rectangle { anchors.fill: parent; color: "#05080c"; z: -1000 }
    MediaPlayer {
        id: player; source: "bg.mp4"
        videoOutput: bgVideo; loops: MediaPlayer.Infinite
        Component.onCompleted: player.play()
    }
    VideoOutput { id: bgVideo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop; z: -500 }

    // Subtle dark gradient from bottom up to improve text legibility over the dark trees
    Rectangle {
        anchors.fill: parent; z: -300
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "#00000000" }
            GradientStop { position: 0.5;  color: "#00000000" }
            GradientStop { position: 1.0;  color: "#aa05080c" }
        }
    }

    Item {
        anchors.fill: parent

        // ── TOP CENTER: TIME & DATE ──
        Column {
            anchors.top: parent.top; anchors.topMargin: 120 * s
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 15 * s

            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "HH:mm")
                font.family: mainFont.name
                font.pixelSize: 180 * s
                font.weight: Font.Thin
                color: root.textPrimary
                style: Text.Normal
                layer.enabled: true
                layer.effect: DropShadow { color: "#50000000"; radius: 25 * s; samples: 31; verticalOffset: 6 * s; transparentBorder: true }
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
                font.family: mainFont.name; font.pixelSize: 18 * s
                font.letterSpacing: 12 * s
                font.weight: Font.DemiBold
                color: "#1a252c"
                opacity: 0.85
                layer.enabled: true
                layer.effect: DropShadow { color: "#55ffffff"; radius: 12 * s; samples: 25; verticalOffset: 0; transparentBorder: true }
            }
        }

        // ── CENTER: LOGIN AREA ──
        Item {
            id: loginArea
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 160 * s // Pushed down beautifully into the treeline
            width: 400 * s
            height: 120 * s

            Column {
                anchors.centerIn: parent
                spacing: 25 * s
                width: parent.width

                // User select
                Item {
                    width: parent.width; height: 30 * s
                    Item {
                        anchors.centerIn: parent; width: parent.width; height: parent.height
                        Column {
                            anchors.centerIn: parent; spacing: 2 * s
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "USER"; font.family: mainFont.name; font.pixelSize: 10 * s; font.letterSpacing: 4 * s; color: root.textSecondary; opacity: 0.8 }
                            Text {
                                text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "UNKNOWN").toUpperCase()
                                font.family: mainFont.name; font.pixelSize: 18 * s; font.letterSpacing: 3 * s; font.weight: Font.Bold; color: uClickMa.containsMouse ? root.accent : root.textPrimary; anchors.horizontalCenter: parent.horizontalCenter
                                scale: uClickMa.containsMouse ? 1.08 : 1.0
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                    MouseArea {
                        id: uClickMa
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: if (userModel.count > 1) root.userIndex = (root.userIndex + 1) % userModel.count
                    }
                }

                // Password
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320 * s; height: 50 * s

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password; passwordCharacter: "·"
                        font.family: mainFont.name; font.pixelSize: 32 * s; font.letterSpacing: 10 * s
                        color: root.textPrimary; clip: true; focus: true
                        onAccepted: root.login()

                        Text {
                            anchors.centerIn: parent
                            text: "PASSWORD"; font.family: mainFont.name
                            font.pixelSize: 14 * s; font.letterSpacing: 6 * s
                            color: root.textSecondary; opacity: (!passInput.text && !passInput.activeFocus) ? 0.6 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }

                        SequentialAnimation {
                            id: errorShake
                            NumberAnimation { target: passInput; property: "x"; to: -10 * s; duration: 50 }
                            NumberAnimation { target: passInput; property: "x"; to:  10 * s; duration: 50 }
                            NumberAnimation { target: passInput; property: "x"; to: -10 * s; duration: 50 }
                            NumberAnimation { target: passInput; property: "x"; to:  10 * s; duration: 50 }
                            NumberAnimation { target: passInput; property: "x"; to:  0;      duration: 50 }
                            onStopped: root.loginError = false
                        }
                    }

                    // Elegant expanding underline
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                        height: 1; width: passInput.activeFocus ? parent.width : parent.width * 0.3
                        color: root.loginError ? "#ff4444" : root.textPrimary
                        opacity: passInput.activeFocus ? 0.8 : 0.2
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                        Behavior on opacity { NumberAnimation { duration: 350 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }


                }
            }
        }

        // ── BOTTOM BAR: ACTIONS & SESSION ──
        Item {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 80 * s
            anchors.margins: 50 * s

            // Left: Session
            Row {
                id: sessionRow
                anchors.left: parent.left; anchors.bottom: parent.bottom; spacing: 12 * s
                Text { text: "SESSION"; font.family: mainFont.name; font.pixelSize: 12 * s; font.letterSpacing: 2 * s; color: root.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 1; height: 14 * s; color: root.textSecondary; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "DEFAULT").toUpperCase()
                    font.family: mainFont.name; font.pixelSize: 14 * s; font.weight: Font.Bold; font.letterSpacing: 1 * s; color: sessionMa.containsMouse ? root.textPrimary : root.accent
                    scale: sessionMa.containsMouse ? 1.08 : 1.0
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                }
            }
            MouseArea { id: sessionMa; anchors.fill: sessionRow; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.sessionMenuOpen = !root.sessionMenuOpen }

            // Right: Power
            Row {
                anchors.right: parent.right; anchors.bottom: parent.bottom; spacing: 25 * s

                Text {
                    text: "REBOOT"; font.family: mainFont.name; font.pixelSize: 12 * s; font.letterSpacing: 2 * s; color: reboot2Ma.containsMouse ? root.textPrimary : root.textSecondary
                    scale: reboot2Ma.containsMouse ? 1.12 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    MouseArea { id: reboot2Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sddm.reboot() }
                }
                Text {
                    text: "SHUTDOWN"; font.family: mainFont.name; font.pixelSize: 12 * s; font.letterSpacing: 2 * s; color: power2Ma.containsMouse ? "#ff6b6b" : root.textSecondary
                    scale: power2Ma.containsMouse ? 1.12 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    MouseArea { id: power2Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sddm.powerOff() }
                }
            }
        }

        // ── POPUP MENUS ──
        
        // Session Menu Menu
        Rectangle {
            anchors.left: parent.left; anchors.leftMargin: 50 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 100 * s
            width: 220 * s; height: sessionModel.count * 45 * s + 20 * s
            color: "#d005080c"; border.color: "#33cde4ef"; border.width: 1; radius: 4 * s
            opacity: root.sessionMenuOpen ? 1.0 : 0.0
            scale: root.sessionMenuOpen ? 1.0 : 0.96
            transformOrigin: Item.BottomLeft
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            ListView {
                anchors.fill: parent; anchors.margins: 10 * s
                model: sessionModel; clip: true
                delegate: Item {
                    width: parent.width; height: 45 * s
                    Text {
                        anchors.centerIn: parent
                        text: (model.name || "UNNAMED").toUpperCase()
                        font.family: mainFont.name; font.pixelSize: 13 * s; font.letterSpacing: 2 * s
                        color: index === root.sessionIndex ? root.accent : (sDelMa.containsMouse ? root.textPrimary : root.textSecondary)
                        font.weight: index === root.sessionIndex ? Font.Bold : Font.Normal
                    }
                    MouseArea { id: sDelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.sessionIndex = index; root.sessionMenuOpen = false } }
                }
            }
        }
    }

    // Gentle click-outside-to-close behavior for menus
    MouseArea {
        anchors.fill: parent; z: -10
        onClicked: { root.sessionMenuOpen = false }
        visible: root.sessionMenuOpen
    }
}
