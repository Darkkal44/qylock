import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Rainy Room
Rectangle {
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#01060c"
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color lamp: "#e6bb5c"
    readonly property color rainBlue: "#2f9eff"

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: pf; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 2000; easing.type: Easing.OutSine }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // Rain FX
    Repeater {
        model: 80
        delegate: Item {
            id: drop
            property real sx:  Math.random() * root.width
            property real dur: 600 + Math.random() * 800
            property real dl:  Math.random() * 4000
            property real len: (15 + Math.random() * 30) * s
            x: sx; y: -drop.len; width: 1 * s; height: drop.len; opacity: 0

            Rectangle {
                anchors.fill: parent
                gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#a0ffffff" } }
            }
            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: drop.dl }
                ParallelAnimation {
                    NumberAnimation { target: drop; property: "y"; from: -drop.len; to: root.height + drop.len; duration: drop.dur; easing.type: Easing.Linear }
                    SequentialAnimation {
                        NumberAnimation { target: drop; property: "opacity"; to: 0.8; duration: drop.dur * 0.1 }
                        PauseAnimation  { duration: drop.dur * 0.8 }
                        NumberAnimation { target: drop; property: "opacity"; to: 0; duration: drop.dur * 0.1 }
                    }
                }
            }
        }
    }

    // Sidebar Backdrop
    Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 440 * s; opacity: root.ui
        gradient: Gradient { 
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#d0000000" } 
            GradientStop { position: 1.0; color: "transparent" } 
        }
    }

    // Sidebar UI
    Column {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.leftMargin: 60 * s; width: 340 * s; spacing: 0; opacity: root.ui

        // Top spacer
        Item { width: 1; height: 100 * s }

        // Clock Unit
        Column {
            spacing: 4 * s
            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "HH:mm")
                color: "white"; font.family: pf.name; font.pixelSize: 84 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") }
            }
            Row {
                spacing: 8 * s
                Rectangle { width: 12 * s; height: 1 * s; color: root.rainBlue; anchors.verticalCenter: parent.verticalCenter }
                Text { text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase(); color: root.lamp; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 3 * s; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // Mid spacer
        Item { width: 1; height: 100 * s }

        // Login Unit
        Column {
            width: parent.width; spacing: 24 * s

            // Username with arrows
            Text { text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase(); color: "white"; font.family: pf.name; font.pixelSize: 24 * s; font.letterSpacing: 4 * s
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (userModel && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } } }

            // Password Field
            Item {
                width: parent.width; height: 40 * s
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1 * s; color: root.rainBlue; opacity: pwd.activeFocus ? 1.0 : 0.3; Behavior on opacity { NumberAnimation {duration: 300} } }
                Rectangle { anchors.bottom: parent.bottom; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.lamp; Behavior on width { NumberAnimation {duration: 300; easing.type: Easing.OutExpo} } }
                TextInput {
                    id: pwd; anchors.fill: parent; color: root.lamp; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                    echoMode: TextInput.Password; passwordCharacter: "─"; focus: true; clip: true; verticalAlignment: TextInput.AlignVCenter
                    Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "password..."; color: root.rainBlue; opacity: 0.4; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s; visible: !pwd.text && !pwd.activeFocus }
            }

            // Buttons
            Row {
                spacing: 12 * s
                // Login Button
                Item {
                    width: 140 * s; height: 36 * s
                    Rectangle { anchors.fill: parent; color: sbm.containsMouse ? root.rainBlue : "transparent"; border.color: root.rainBlue; border.width: 1; radius: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                    Text { anchors.centerIn: parent; text: "LOG IN"; color: sbm.containsMouse ? "#000" : root.lamp; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                    MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
                }
            }
            Text { id: err; text: ""; color: "#ff4444"; font.family: pf.name; font.pixelSize: 12 * s }
        }
    }

    // Power Section
    Row {
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 40 * s; spacing: 20 * s; opacity: root.ui
        Repeater {
            model: [{l: (sessionHelper.currentItem ? sessionHelper.currentItem.sName : "SESSION").toUpperCase(), a: 2}, {l: "RESTART", a: 0}, {l: "OFF", a: 1}]
            delegate: Item {
                width: pmt.implicitWidth + 24 * s; height: 28 * s
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.rainBlue; border.width: 1 * s; opacity: pm.containsMouse ? 1.0 : 0.4; radius: 4 * s; Behavior on opacity { NumberAnimation { duration: 150 } } Rectangle { anchors.fill: parent; anchors.margins: 1 * s; color: modelData.a === 2 ? root.lamp : root.rainBlue; radius: 3 * s; opacity: pm.containsMouse ? 0.3 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } } }
                Text { id: pmt; anchors.centerIn: parent; text: modelData.l; color: "white"; font.family: pf.name; font.pixelSize: 10 * s; font.letterSpacing: 2 * s }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.a === 0) sddm.reboot(); else if (modelData.a === 1) sddm.powerOff(); else if (sessionModel && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() } }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() { err.text = "DECLINED"; pwd.text = ""; pwd.focus = true }
    }
    function doLogin() { var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : userModel.lastUser; sddm.login(u, pwd.text, root.sessionIndex) }
}
