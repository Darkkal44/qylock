import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0

// Skyscrapers Layout
Rectangle {
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#14101a"
    
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color roseUI: "#d05870"
    readonly property color peachSky: "#f0a060"
    readonly property color sunCream: "#fae8d0"
    readonly property color silhouettes: "#303c44"

    FontLoader { id: pf; source: "font/PixelifySans-Bold.ttf" }
    
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; visible: false; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex; visible: false; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 2000; easing.type: Easing.OutSine }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // View Overlays
    Rectangle { anchors.top: parent.top; width: parent.width; height: 160 * s; gradient: Gradient { GradientStop { position: 0.0; color: "#60000000" } GradientStop { position: 1.0; color: "transparent" } } }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 240 * s; gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#90000000" } } }

    // HUD Section

    // Clock Unit
    Column {
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 60 * s
        spacing: 4 * s; opacity: root.ui
        
        Text {
            id: clk; text: Qt.formatTime(new Date(), "HH:mm")
            color: root.sunCream; font.family: pf.name; font.pixelSize: 84 * s; font.letterSpacing: -2 * s
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.text = Qt.formatTime(new Date(), "HH:mm") }
            layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 6; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
        }
        Text {
            text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
            color: root.roseUI; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s
        }
    }

    // Login Unit
    Column {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.margins: 60 * s
        width: 320 * s; spacing: 20 * s; opacity: root.ui

        // User Select
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: unt.implicitWidth; height: unt.implicitHeight
            Text {
                id: unt
                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
                color: unm.containsMouse ? "white" : root.sunCream; font.family: pf.name; font.pixelSize: 22 * s; font.letterSpacing: 4 * s
                layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Rectangle {
                anchors.bottom: unt.bottom; anchors.bottomMargin: -6 * s; anchors.horizontalCenter: parent.horizontalCenter
                width: unm.containsMouse ? parent.width : 0; height: 1 * s; color: root.roseUI; opacity: 0.8
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            MouseArea { id: unm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (userModel && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
        }

        // Pass Input
        Item {
            width: parent.width; height: 36 * s
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1 * s; color: root.roseUI; opacity: pwd.activeFocus ? 1.0 : 0.4 }
            Rectangle { anchors.bottom: parent.bottom; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.peachSky; anchors.horizontalCenter: parent.horizontalCenter; Behavior on width { NumberAnimation {duration: 300; easing.type: Easing.OutExpo} } }
            TextInput {
                id: pwd; anchors.fill: parent; color: root.peachSky; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                echoMode: TextInput.Password; passwordCharacter: "─"; focus: true; clip: true; horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
            }
            Text { anchors.centerIn: parent; text: "password..."; color: root.roseUI; opacity: 0.5; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s; visible: !pwd.text && !pwd.activeFocus }
        }

        // Login Button
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 140 * s; height: 36 * s
            Rectangle { anchors.fill: parent; color: sbm.containsMouse ? root.roseUI : "transparent"; border.color: root.roseUI; border.width: 1; radius: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
            Text { anchors.centerIn: parent; text: "LOG IN"; color: sbm.containsMouse ? "#000" : root.sunCream; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
            MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
        }
        Text { id: err; text: ""; color: "#ff5555"; anchors.horizontalCenter: parent.horizontalCenter; font.family: pf.name; font.pixelSize: 12 * s }
    }

    // Power Section
    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 40 * s; spacing: 30 * s; opacity: root.ui
        Repeater {
            model: [{l: (sessionHelper.currentItem ? sessionHelper.currentItem.sName : "SESSION").toUpperCase(), a: 2}, {l: "RESTART", a: 0}, {l: "POWER", a: 1}]
            delegate: Item {
                width: pmt.implicitWidth; height: 30 * s
                Text {
                    id: pmt; anchors.centerIn: parent; text: modelData.l
                    color: pm.containsMouse ? "white" : root.sunCream; font.family: pf.name; font.pixelSize: 11 * s; font.letterSpacing: 2 * s
                    layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Rectangle {
                    anchors.bottom: pmt.bottom; anchors.bottomMargin: -4 * s; anchors.horizontalCenter: parent.horizontalCenter
                    width: pm.containsMouse ? parent.width : 0; height: 1 * s; color: root.roseUI; opacity: 0.8
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
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
