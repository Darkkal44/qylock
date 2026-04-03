import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#050505"
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color lantern: "#f5aa5b"
    readonly property color lore: "#8498ab"

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: pf; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }
    
    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 3000; easing.type: Easing.InOutQuad }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    Repeater {
        model: 60
        delegate: Rectangle {
            id: ash; width: (1 + Math.random() * 3) * s; height: width/2; color: root.lore; opacity: 0; rotation: Math.random() * 360
            x: Math.random() * root.width; y: -20 * s
            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: Math.random() * 8000 }
                ParallelAnimation {
                    NumberAnimation { target: ash; property: "opacity"; to: 0.8; duration: 2000 }
                    NumberAnimation { target: ash; property: "y"; to: root.height + 20 * s; duration: 8000 + Math.random() * 4000 }
                    NumberAnimation { target: ash; property: "x"; to: ash.x + (Math.random()-0.5)*200*s; duration: 8000 }
                    RotationAnimation { target: ash; to: ash.rotation + 360; duration: 8000 }
                }
            }
        }
    }

    Item {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 40 * s
        anchors.horizontalCenter: parent.horizontalCenter; opacity: root.ui * 0.9
        Row {
            anchors.centerIn: parent; spacing: 40 * s
            Text { text: Qt.formatDate(new Date(), "ddd, MMM d").toUpperCase(); color: root.lore; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 12 * s; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 1; height: 40 * s; color: root.lantern; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
            Text { id: ctxt; text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.family: pf.name; font.pixelSize: 48 * s; font.letterSpacing: 8 * s; anchors.verticalCenter: parent.verticalCenter
                Timer { interval: 1000; running: true; repeat: true; onTriggered: ctxt.text = Qt.formatTime(new Date(), "HH:mm") }
            }
        }
    }

    Item {
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        width: 320 * s; height: 180 * s; opacity: root.ui
        
        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; width: 2 * s; height: 40 * s; color: root.lantern; opacity: 0.4 }
        
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 40 * s; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width; height: 120 * s; color: "#d0050403"; border.color: root.lantern; border.width: 1 * s; radius: 4 * s
            
            Column {
                anchors.centerIn: parent; spacing: 16 * s; width: 260 * s
                Text { text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase(); color: "white"; font.family: pf.name; font.pixelSize: 16 * s; font.letterSpacing: 6 * s; anchors.horizontalCenter: parent.horizontalCenter
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (userModel && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } } }
                
                Item {
                    width: parent.width; height: 36 * s
                    Rectangle { anchors.fill: parent; color: "#20000000"; border.color: root.lore; border.width: 1 * s }
                    Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.lantern; border.width: 1 * s; opacity: pwd.activeFocus ? 1.0 : 0.0; Behavior on opacity { NumberAnimation { duration: 300 } } }
                    TextInput {
                        id: pwd; anchors.fill: parent; color: root.lantern; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s
                        echoMode: TextInput.Password; passwordCharacter: "x"; focus: true; clip: true; horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                        Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
                    }
                }
                Text { id: err; text: ""; color: "#cc2222"; anchors.horizontalCenter: parent.horizontalCenter; font.family: pf.name; font.pixelSize: 10 * s }
            }
        }
    }

    // Session Switcher
    Item {
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 40 * s; width: stm.implicitWidth + 24 * s; height: 28 * s; opacity: root.ui
        Text { id: stm; anchors.centerIn: parent; text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0 ? sessionModel.get(root.sessionIndex).name : "SESSION").toUpperCase(); color: sm.containsMouse ? root.lantern : root.lore; opacity: sm.containsMouse ? 1.0 : 0.5; font.family: pf.name; font.pixelSize: 10 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } Behavior on opacity { NumberAnimation { duration: 150 } } }
        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (sessionModel && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() } }
    }

    // Power Controls
    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 40 * s; spacing: 20 * s; opacity: root.ui
        Repeater {
            model: [{l: "RESTART", a: 0}, {l: "SHUT DOWN", a: 1}]
            delegate: Item {
                width: pmt.implicitWidth + 24 * s; height: 28 * s
                Text { id: pmt; anchors.centerIn: parent; text: modelData.l; color: pm.containsMouse ? root.lantern : root.lore; opacity: pm.containsMouse ? 1.0 : 0.5; font.family: pf.name; font.pixelSize: 10 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } Behavior on opacity { NumberAnimation { duration: 150 } } }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.a === 0) sddm.reboot(); else if (modelData.a === 1) sddm.powerOff() } }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() { err.text = "SHADE DENIED"; pwd.text = ""; pwd.focus = true }
    }
    function doLogin() { var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : userModel.lastUser; sddm.login(u, pwd.text, root.sessionIndex) }
}
