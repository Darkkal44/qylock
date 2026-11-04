import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

// Skyscrapers Layout
Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#14101a"
    
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color cmain: "#1793D1"
    readonly property color cdim: "#0a6593"
    readonly property color clight: "#90d7fa"
    readonly property color cdark: "#0d425d"

    FontLoader { id: pf; source: "font/WDXLLubrifontJPN-Regular.ttf" }
    
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 2000; easing.type: Easing.OutSine }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // View Overlays
    Rectangle { anchors.top: parent.top; width: parent.width; height: 160 * s; gradient: Gradient { GradientStop { position: 0.0; color: "#60000000" } GradientStop { position: 1.0; color: "transparent" } } }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 240 * s; gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#90000000" } } }

    // HUD Section
    // Main stacked column centered on vertical line at 25% from left
    Column {
        id: mainColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -parent.width * 0.25
        anchors.verticalCenter: parent.verticalCenter   // если нужна привязка к верху, замените на anchors.top: parent.top; anchors.topMargin: 60 * s
        spacing: 40 * s
        opacity: root.ui

        // Clock Unit
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4 * s

            Text {
                id: clk; text: Qt.formatTime(new Date(), "HH:mm")
                color: root.clight; font.family: pf.name; font.pixelSize: 84 * s; font.letterSpacing: -2 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.text = Qt.formatTime(new Date(), "HH:mm") }
                layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 6; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
                color: root.cmain; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s
            }
        }

        // Login Unit
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320 * s; spacing: 20 * s

            // User Select
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: unt.implicitWidth; height: unt.implicitHeight
                Text {
                    id: unt
                    text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
                    color: unm.containsMouse ? "white" : root.clight; font.family: pf.name; font.pixelSize: 22 * s; font.letterSpacing: 4 * s
                    layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Rectangle {
                    anchors.bottom: unt.bottom; anchors.bottomMargin: -6 * s; anchors.horizontalCenter: parent.horizontalCenter
                    width: unm.containsMouse ? parent.width : 0; height: 1 * s; color: root.cmain; opacity: 0.8
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
                MouseArea { id: unm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (typeof userModel !== "undefined" && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
            }

            // Pass Input
            Item {
                width: parent.width; height: 36 * s
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1 * s; color: root.cmain; opacity: pwd.activeFocus ? 1.0 : 0.4 }
                Rectangle { anchors.bottom: parent.bottom; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.cdim; anchors.horizontalCenter: parent.horizontalCenter; Behavior on width { NumberAnimation {duration: 300; easing.type: Easing.OutExpo} } }
                TextInput {
                    id: pwd; anchors.fill: parent; color: root.cdim; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                    echoMode: TextInput.Password; onTextEdited: err.text = ""; passwordCharacter: "─"; focus: true; clip: true; horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                    cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    selectionColor: root.cmain
                    property bool wasClicked: false
                    onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                    Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
                }
                Text { 
                    anchors.centerIn: parent; text: "password..."; color: root.cmain; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s
                    opacity: pwd.text.length === 0 ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }
                Rectangle {
                    id: customCursor
                    width: 2 * s; height: 20 * s
                    color: root.cmain
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

            // Login Button
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 140 * s; height: 36 * s
                Rectangle { anchors.fill: parent; color: sbm.containsMouse ? root.cmain : "transparent"; border.color: root.cmain; border.width: 1; radius: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                Text { anchors.centerIn: parent; text: "LOG IN"; color: sbm.containsMouse ? "#000" : root.clight; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
            }
            Text { id: err; text: ""; height: 12 * s; verticalAlignment: Text.AlignBottom; color: "#ff5555"; anchors.horizontalCenter: parent.horizontalCenter; font.family: pf.name; font.pixelSize: 12 * s }
        }

        // Power / Session Section
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 30 * s
            Repeater {
                model: [{l: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "Session").toUpperCase(), a: 2}, {l: "RESTART", a: 0}, {l: "POWER", a: 1}]
                delegate: Item {
                    visible: modelData.a === 2 ? !root.isQuickshell : true
                    width: pmt.implicitWidth; height: 30 * s
                    Text {
                        id: pmt; anchors.centerIn: parent; text: modelData.l
                        color: pm.containsMouse ? "white" : root.clight; font.family: pf.name; font.pixelSize: 11 * s; font.letterSpacing: 2 * s
                        layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Rectangle {
                        anchors.bottom: pmt.bottom; anchors.bottomMargin: -4 * s; anchors.horizontalCenter: parent.horizontalCenter
                        width: pm.containsMouse ? parent.width : 0; height: 1 * s; color: root.cmain; opacity: 0.8
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.a === 0) { if (typeof sddm !== "undefined") sddm.reboot() } else if (modelData.a === 1) { if (typeof sddm !== "undefined") sddm.powerOff() } else if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() } }
                }
            }
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { err.text = "ACCESS DENIED"; pwd.text = ""; pwd.focus = true }
    }
    function doLogin() { var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : ""); if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex) }
}
