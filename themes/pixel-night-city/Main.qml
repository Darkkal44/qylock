import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

// Night City
Rectangle {
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#060810"
    
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color signTeal: "#50c8d8"
    readonly property color signPink: "#d06880"
    readonly property color winAmber: "#c8804a"
    readonly property color textWhite: "#e8e4f0"

    FontLoader { id: pf; source: "font/PixelifySans-Bold.ttf" }
    
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutSine }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // Dark Overlay
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.3 }

    // Rain FX
    Repeater {
        model: 40
        delegate: Item {
            id: drop
            property real sx:  Math.random() * root.width
            property real dur: 800 + Math.random() * 1200
            property real dl:  Math.random() * 3000
            property real len: (20 + Math.random() * 30) * s
            x: sx; y: -drop.len; width: 1 * s; height: drop.len; opacity: 0
            Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#8050c8d8" } } }
            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: drop.dl }
                ParallelAnimation {
                    NumberAnimation { target: drop; property: "y"; from: -drop.len; to: root.height + drop.len; duration: drop.dur; easing.type: Easing.Linear }
                    SequentialAnimation {
                        NumberAnimation { target: drop; property: "opacity"; to: 0.6; duration: drop.dur * 0.1 }
                        PauseAnimation  { duration: drop.dur * 0.8 }
                        NumberAnimation { target: drop; property: "opacity"; to: 0; duration: drop.dur * 0.1 }
                    }
                }
            }
        }
    }

    // HUD Units

    // Power Section
    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 40 * s; spacing: 30 * s; opacity: root.ui
        Repeater {
            model: [{l: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0 ? sessionModel.get(root.sessionIndex).name : "SESSION").toUpperCase(), a: 2}, {l: "REBOOT", a: 0}, {l: "OFF", a: 1}]
            delegate: Item {
                width: pmt.implicitWidth; height: 30 * s
                Text {
                    id: pmt; anchors.centerIn: parent; text: modelData.l
                    color: pm.containsMouse ? "white" : (modelData.a === 2 ? root.signPink : root.signTeal)
                    font.family: pf.name; font.pixelSize: 10 * s; font.letterSpacing: 2 * s
                    layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Rectangle {
                    anchors.bottom: pmt.bottom; anchors.bottomMargin: -4 * s; anchors.horizontalCenter: parent.horizontalCenter
                    width: pm.containsMouse ? parent.width : 0; height: 1 * s; color: modelData.a === 2 ? root.signPink : root.signTeal; opacity: 0.8
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.a === 0) sddm.reboot(); else if (modelData.a === 1) sddm.powerOff(); else if (sessionModel && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() } }
            }
        }
    }

    // Clock Section
    Column {
        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 60 * s
        spacing: 10 * s; opacity: root.ui
        
        Row {
            spacing: 20 * s
            Text {
                id: hT; text: Qt.formatTime(new Date(), "HH")
                color: "white"; font.family: pf.name; font.pixelSize: 100 * s; font.letterSpacing: -5 * s
                Timer { interval: 60000; running: true; repeat: true; onTriggered: hT.text = Qt.formatTime(new Date(), "HH") }
                layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 6; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
            }
            
            // Neon Needle
            Rectangle { width: 4 * s; height: 80 * s; color: root.signPink; anchors.verticalCenter: parent.verticalCenter; radius: 2 * s }
            
            Text {
                id: mT; text: Qt.formatTime(new Date(), "mm")
                color: root.signTeal; font.family: pf.name; font.pixelSize: 100 * s; font.letterSpacing: -5 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: mT.text = Qt.formatTime(new Date(), "mm") }
                layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 6; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
            }
        }
        
        Text {
            text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
            color: "white"; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 8 * s
            opacity: 0.8
            layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
        }
    }

    // Login Area
    Column {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 80 * s
        width: 360 * s; spacing: 30 * s; opacity: root.ui

        // User Field
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: unt.implicitWidth; height: unt.implicitHeight
            Text {
                id: unt
                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
                color: unm.containsMouse ? "white" : root.textWhite; font.family: pf.name; font.pixelSize: 22 * s; font.letterSpacing: 6 * s
                layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Rectangle {
                anchors.bottom: unt.bottom; anchors.bottomMargin: -6 * s; anchors.horizontalCenter: parent.horizontalCenter
                width: unm.containsMouse ? parent.width : 0; height: 1 * s; color: root.signPink; opacity: 0.8
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            MouseArea { id: unm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (userModel && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
        }

        // Pass Field
        Item {
            width: parent.width; height: 40 * s
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1 * s; color: root.signPink; opacity: pwd.activeFocus ? 1.0 : 0.3 }
            Rectangle { id: activeBar; anchors.bottom: parent.bottom; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.signPink; Behavior on width { NumberAnimation {duration: 400; easing.type: Easing.OutExpo} } }
            TextInput {
                id: pwd; anchors.fill: parent; color: root.signPink; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 6 * s
                echoMode: TextInput.Password; passwordCharacter: "─"; focus: true; clip: true; horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
            }
            Text { anchors.centerIn: parent; text: "CONNECTING..."; color: root.signTeal; opacity: 0.3; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; visible: !pwd.text && !pwd.activeFocus }
        }

        Text { id: err; text: ""; color: "#ff4444"; anchors.horizontalCenter: parent.horizontalCenter; font.family: pf.name; font.pixelSize: 12 * s }
    }

    Connections {
        target: sddm
        function onLoginFailed() { err.text = "PERMISSION DENIED"; pwd.text = ""; pwd.focus = true }
    }
    function doLogin() { var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : userModel.lastUser; sddm.login(u, pwd.text, root.sessionIndex) }
}
