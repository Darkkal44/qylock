import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Emerald Layout
Rectangle {
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#0b1d1c"
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color emerald: "#1fce8c"
    readonly property color mint: "#60e8b6"

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: pf; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: fadeAnim.start()
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutSine }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // Clock Area
    Column {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 60 * s
        spacing: 2 * s; opacity: root.ui
        
        Item {
            anchors.right: parent.right; width: ct.implicitWidth; height: ct.implicitHeight
            Text { text: ct.text; color: "#aa000000"; font: ct.font; x: 2*s; y: 2*s }
            Text { id: ct; text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.family: pf.name; font.pixelSize: 84 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: ct.text = Qt.formatTime(new Date(), "HH:mm") } }
        }
        Text {
            anchors.right: parent.right
            text: Qt.formatDate(new Date(), "dddd, MMM d").toUpperCase(); color: root.emerald; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s
            layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
        }
    }

    // Login Area
    Column {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 60 * s
        width: 320 * s; spacing: 20 * s; opacity: root.ui

        // User Select
        Text {
            text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
            color: "white"; font.family: pf.name; font.pixelSize: 22 * s; font.letterSpacing: 3 * s
            layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (userModel && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
        }

        // Pass Field
        Item {
            width: parent.width; height: 36 * s
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1 * s; color: root.emerald; opacity: pwd.activeFocus ? 1.0 : 0.4 }
            Rectangle { anchors.bottom: parent.bottom; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.mint; Behavior on width { NumberAnimation {duration: 300; easing.type: Easing.OutExpo} } }
            TextInput {
                id: pwd; anchors.fill: parent; color: root.mint; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                echoMode: TextInput.Password; passwordCharacter: "─"; focus: true; clip: true; verticalAlignment: TextInput.AlignVCenter
                cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                selectionColor: root.emerald
                property bool wasClicked: false
                onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
            }
            Text { 
                anchors.verticalCenter: parent.verticalCenter; text: "password..."; color: root.emerald; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s
                opacity: pwd.text.length === 0 ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
            }
            Rectangle {
                id: customCursor
                width: 2 * s; height: 20 * s
                color: root.mint
                anchors.verticalCenter: parent.verticalCenter
                x: pwd.cursorRectangle.x
                visible: pwd.focus && (pwd.text.length > 0 || pwd.wasClicked)
                SequentialAnimation {
                    loops: Animation.Infinite; running: customCursor.visible
                    NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                    NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pwd.forceActiveFocus()
                    pwd.wasClicked = true
                }
            }
        }

        // Login Action
        Item {
            width: 140 * s; height: 36 * s
            Rectangle { anchors.fill: parent; color: sbm.containsMouse ? root.emerald : "transparent"; border.color: root.emerald; border.width: 1; radius: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
            Text { anchors.centerIn: parent; text: "LOG IN"; color: sbm.containsMouse ? "#000" : root.mint; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
            MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
        }
        
        Text { id: err; text: ""; color: "#ff5555"; font.family: pf.name; font.pixelSize: 12 * s }
    }

    // Sessions Area
    Row {
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 40 * s; spacing: 20 * s; opacity: root.ui
        Repeater {
            model: [{l: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "Session").toUpperCase(), a: 2}, {l: "RESTART", a: 0}, {l: "POWER", a: 1}]
            delegate: Item {
                width: pmt.implicitWidth + 20 * s; height: 26 * s
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.emerald; border.width: 1 * s; opacity: pm.containsMouse ? 1.0 : 0.4; radius: 4 * s; Rectangle { anchors.fill: parent; anchors.margins: 1 * s; color: root.emerald; radius: 3 * s; opacity: pm.containsMouse ? 0.3 : 0 } }
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
