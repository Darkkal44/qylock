import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0c0a08"

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int  userIndex:   userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    // Theme colors
    readonly property color amberHot:   "#e8803c"
    readonly property color amberSoft:  "#c8a060"
    readonly property color tealSign:   "#4dd8c4"
    readonly property color textWhite:  "#f0ece4"
    readonly property color textDim:    "#907860"

    TextConstants { id: textConstants }
    FontLoader { id: pfReg; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: pfMed; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: pfSemi; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: pfBold; source: "font/PixelifySans-Bold.ttf" }

    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex
        visible: false; width: 100; height: 100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex
        visible: false; width: 100; height: 100
        delegate: Item {
            property string uName:  model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordField.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1800; easing.type: Easing.OutCubic }

    // Background
    Rectangle { anchors.fill: parent; color: "#0c0a08" }
    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // View Vignette
    RadialGradient {
        anchors.fill: parent; opacity: 0.88
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.6;  color: "#50000000" }
            GradientStop { position: 1.0;  color: "#f5000000" }
        }
    }
    // Bottom Shadow
    Rectangle {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: 300 * s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#f0000000" }
        }
    }

    // Particles
    Repeater {
        model: 18
        delegate: Item {
            id: em
            property real sx:  Math.random() * root.width * 0.6 + root.width * 0.2
            property real dr:  (Math.random() - 0.5) * 80
            property real dur: 5500 + Math.random() * 7000
            property real sz:  (1.5 + Math.random() * 2.5) * s
            property real dl:  Math.random() * 10000
            property int  ct:  Math.floor(Math.random() * 3)
            x: sx; y: root.height + 10; width: sz; height: sz; opacity: 0
            Rectangle {
                anchors.fill: parent; radius: width
                color: em.ct === 0 ? root.amberHot : em.ct === 1 ? root.amberSoft : root.tealSign
            }
            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: em.dl }
                ParallelAnimation {
                    NumberAnimation { target: em; property: "y"; from: root.height + 10; to: -20; duration: em.dur; easing.type: Easing.OutQuad }
                    NumberAnimation { target: em; property: "x"; from: em.sx; to: em.sx + em.dr; duration: em.dur; easing.type: Easing.InOutSine }
                    SequentialAnimation {
                        NumberAnimation { target: em; property: "opacity"; to: 0.85; duration: 700 }
                        PauseAnimation  { duration: em.dur - 1600 }
                        NumberAnimation { target: em; property: "opacity"; to: 0; duration: 900 }
                    }
                }
            }
        }
    }

    // Clock Unit
    Column {
        anchors.left: parent.left; anchors.top: parent.top
        anchors.leftMargin: 52 * s; anchors.topMargin: 48 * s
        spacing: 5 * s; opacity: root.ui

        Text {
            id: clockText
            text: Qt.formatTime(new Date(), "HH:mm")
            color: root.textWhite
            font.family: pfBold.name; font.pixelSize: 78 * s
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") }
        }
        Row {
            spacing: 8 * s
            Rectangle {
                width: 4 * s; height: 4 * s; color: root.amberHot
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: Qt.formatDate(new Date(), "ddd, MMM d").toUpperCase()
                color: root.amberSoft; font.family: pfMed.name
                font.pixelSize: 11 * s; font.letterSpacing: 3 * s
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Login Unit
    Item {
        id: loginPanel
        anchors.bottom: parent.bottom; anchors.bottomMargin: 90 * s
        anchors.horizontalCenter: parent.horizontalCenter
        width: 340 * s
        height: loginCol.implicitHeight
        opacity: root.ui

        Column {
            id: loginCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width; spacing: 0

            // Current User
                Text {
                    text: ((userHelper.currentItem && userHelper.currentItem.uName)
                          ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
                    color: root.textWhite; font.family: pfBold.name; font.pixelSize: 17 * s; font.letterSpacing: 4 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { var c = userModel.rowCount(); if (c > 1) root.userIndex = (root.userIndex + 1) % c } }
                }

            Item { width: 1; height: 8 * s }

            // Section Break
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 5 * s
                Rectangle { width: 44 * s; height: 1 * s; color: root.amberHot; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 5 * s; height: 5 * s; color: root.amberHot; opacity: 0.65; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 44 * s; height: 1 * s; color: root.amberHot; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
            }

            Item { width: 1; height: 20 * s }

            // Pass Input
            Item {
                width: parent.width; height: 52 * s
                anchors.horizontalCenter: parent.horizontalCenter

                // Base line
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: 1 * s
                    color: Qt.rgba(0.91, 0.50, 0.24, 0.25)
                }
                // Focus track
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2 * s
                    color: root.amberHot
                    width: passwordField.activeFocus ? parent.width : 0
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 2 * s
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    text: "password"
                    color: root.amberSoft
                    font.family: pfMed.name; font.pixelSize: 14 * s; font.letterSpacing: 3 * s
                    opacity: passwordField.text.length === 0 ? 0.38 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }

                TextInput {
                    id: passwordField
                    anchors.left: parent.left; anchors.leftMargin: 2 * s
                    anchors.right: submitBtn.left; anchors.rightMargin: 12 * s
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    color: root.textWhite
                    font.family: pfReg.name; font.pixelSize: 14 * s; font.letterSpacing: 3 * s
                    echoMode: TextInput.Password; passwordCharacter: "─"
                    focus: true; clip: true
                    cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    selectionColor: root.amberHot
                    property bool wasClicked: false
                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed:  doLogin()
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordField.forceActiveFocus()
                            passwordField.wasClicked = true
                        }
                    }
                }
                Rectangle {
                    id: customCursor
                    width: 2 * s; height: 16 * s
                    color: root.amberHot
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    x: passwordField.x + passwordField.cursorRectangle.x
                    visible: passwordField.focus && (passwordField.text.length > 0 || passwordField.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite; running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }

                // Submit Action
                Item {
                    id: submitBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    width: loginText.implicitWidth + 16 * s
                    height: 24 * s

                    Rectangle {
                        anchors.fill: parent
                        color: submitMouse.containsMouse
                               ? Qt.rgba(0.91, 0.50, 0.24, 0.18)
                               : "transparent"
                        border.color: Qt.rgba(0.91, 0.50, 0.24, passwordField.text.length > 0 ? 0.55 : 0.20)
                        border.width: 1 * s
                        Behavior on color        { ColorAnimation { duration: 160 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        id: loginText
                        anchors.centerIn: parent
                        text: "LOGIN"
                        color: root.amberHot
                        font.family: pfBold.name; font.pixelSize: 9 * s; font.letterSpacing: 2 * s
                        opacity: passwordField.text.length > 0 ? 1.0 : 0.30
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    MouseArea {
                        id: submitMouse; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: doLogin()
                    }
                }
            }

            Item { width: 1; height: 10 * s }

            Text {
                id: errorMessage; anchors.horizontalCenter: parent.horizontalCenter
                text: ""; color: "#f07050"
                font.family: pfSemi.name; font.pixelSize: 10 * s; font.letterSpacing: 2 * s
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Error Animation
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 10; duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 8;  duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 6;  duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 4;  duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x;      duration: 45 }
    }

    // Footer Area
    Rectangle {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 36 * s
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 44 * s; anchors.rightMargin: 44 * s
        height: 1 * s; color: Qt.rgba(0.91, 0.50, 0.24, 0.18); opacity: root.ui
    }
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 44 * s; anchors.rightMargin: 44 * s
        height: 36 * s; opacity: root.ui * 0.9

        Row {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            Item {
                width: sessionText.implicitWidth + 24 * s; height: 22 * s
                Rectangle {
                    anchors.fill: parent; radius: 2 * s
                    color: "transparent"; border.color: root.amberHot; border.width: 1 * s
                    opacity: sessionMouse.containsMouse ? 1.0 : 0.30
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 1 * s; color: root.amberHot; radius: 1 * s
                        opacity: sessionMouse.containsMouse ? 0.15 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
                Row {
                    anchors.centerIn: parent; spacing: 6 * s
                    Rectangle { width: 4 * s; height: 4 * s; color: root.amberHot; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        id: sessionText
                        text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "Session").toUpperCase()
                        color: root.textWhite; font.family: pfMed.name; font.pixelSize: 9 * s; font.letterSpacing: 1 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: sessionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (sessionModel && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                }
            }
        }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 14 * s
            Repeater {
                model: [{ label: "RESTART", act: 0 }, { label: "SHUT DOWN", act: 1 }]
                delegate: Item {
                    width: powerText.implicitWidth + 20 * s; height: 22 * s
                    Rectangle {
                        anchors.fill: parent; radius: 2 * s
                        color: "transparent"; border.color: root.amberHot; border.width: 1 * s
                        opacity: pm.containsMouse ? 1.0 : 0.30
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 1 * s; color: root.amberHot; radius: 1 * s
                            opacity: pm.containsMouse ? 0.15 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                    Text {
                        id: powerText; anchors.centerIn: parent
                        text: modelData.label; color: root.amberSoft
                        font.family: pfMed.name; font.pixelSize: 9 * s; font.letterSpacing: 1 * s
                    }
                    MouseArea {
                        id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData.act === 0) sddm.reboot(); else sddm.powerOff() }
                    }
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "incorrect password"
            passwordField.text = ""; passwordField.focus = true; shakeAnim.start()
        }
    }
    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin)
                    ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(uname, passwordField.text, root.sessionIndex)
    }
}
