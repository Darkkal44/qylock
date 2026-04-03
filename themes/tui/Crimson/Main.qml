import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Qt.labs.folderlistmodel 2.15
import SddmComponents 2.0

// TUI Theme
Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0)
                               ? sessionModel.lastIndex : 0

    // Colors
    readonly property color bg:          "#000000"
    readonly property color green:       "#ff4488"
    readonly property color greenDim:    "#aa2255"
    readonly property color greenDark:   "#1a0005"
    readonly property color greenBright: "#ff88aa"
    readonly property color amber:       "#8be9fd"
    readonly property color red:         "#ff4444"
    readonly property color gray:        "#442233"

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: inconsolata; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    readonly property string mono:       inconsolata.name
    readonly property color phosphor:   "#ff4488"

    // Animation States
    property real bootOpacity: 1.0
    property real uiOpacity: 0
    property int  bootLineCount: 0
    property real screenFlicker: 1.0
    property real typewriter: 0

    property bool globalBlink: true
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: globalBlink = !globalBlink
    }

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            // Subtle screen flicker
            if (Math.random() > 0.98) screenFlicker = 0.8 + Math.random() * 0.2
            else screenFlicker = 1.0
            
            // UI Jitter
            if (Math.random() > 0.99) {
                loginPanel.anchors.horizontalCenterOffset = (Math.random() - 0.5) * 4 * s
                loginPanel.anchors.verticalCenterOffset = -16 * s + (Math.random() - 0.5) * 4 * s
            } else {
                loginPanel.anchors.horizontalCenterOffset = 0
                loginPanel.anchors.verticalCenterOffset = -16 * s
            }
        }
    }

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            statusMsg.color = root.green
            statusMsg.text  = "  ✓  " + textConstants.loginSucceeded
        }
        function onLoginFailed() {
            passInput.text  = ""
            statusMsg.color = root.red
            statusMsg.text  = "  ✗  " + textConstants.loginFailed
        }
        function onInformationMessage(message) {
            statusMsg.color = root.red
            statusMsg.text  = "  ✗  " + message
        }
    }

    // Session Helper
    ListView {
        id: sessionNameHelper
        model: sessionModel; currentIndex: sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sessionName: model.name || "" }
    }

    // User Helper
    ListView {
        id: userHelper
        model: userModel
        currentIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string uName: model.name || "" }
    }

    // Background
    Rectangle { anchors.fill: parent; color: root.bg }

    // Screen Flicker Overlay
    Rectangle {
        anchors.fill: parent; color: root.green; opacity: (1.0 - root.screenFlicker) * 0.1; z: 500
    }

    Canvas {
        anchors.fill: parent; opacity: 0.08
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = root.green
            for (var y = 0; y < height; y += 3)
                ctx.fillRect(0, y, width, 1)
        }
    }

    // Binary Rain
    Item {
        anchors { fill: parent; margins: 12 * s }
        clip: true
        opacity: 0.12; z: 1
        visible: root.uiOpacity > 0
        Repeater {
            model: Math.floor(parent.width / (32 * s))
            Text {
                x: index * 32 * s; y: 0
                property string chars: "010110"
                text: {
                    var s = "";
                    for(var i=0; i<40; i++) s += chars.charAt(Math.floor(Math.random()*chars.length)) + "\n";
                    return s;
                }
                font.family: root.mono; font.pixelSize: 9 * s
                color: root.green
                
                NumberAnimation on y {
                    from: -500 * s; to: parent.height; duration: 4000 + Math.random() * 6000; loops: Animation.Infinite
                }
                
                Timer {
                    interval: 150 + Math.random() * 200; running: true; repeat: true
                    onTriggered: {
                        var ns = "";
                        for(var i=0; i<40; i++) ns += (Math.random() > 0.5 ? "1" : "0") + "\n";
                        parent.text = ns;
                    }
                }
            }
        }
    }

    // Border
    BorderBox {
        anchors { fill: parent; margins: 10 * s }
        lineColor: root.gray
    }

    // Login
    Item {
        id: loginPanel
        width:  500 * s
        height: mainCol.implicitHeight + 48
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -16 * s
        opacity: root.uiOpacity
        visible: opacity > 0
        
        // Appear logic
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

        BorderBox {
            anchors.fill: parent
            lineColor: root.green
            title: " SYSTEM LOGIN ".substring(0, Math.floor(root.typewriter))
            titleColor: root.amber
        }

        Column {
            id: mainCol
            anchors {
                top: parent.top; topMargin: 28 * s
                left: parent.left; leftMargin: 18 * s
                right: parent.right; rightMargin: 18 * s
            }
            spacing: 0 * s

            // Clock
            Row {
                width: parent.width
                spacing: 0 * s
                leftPadding: 2

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "TIME  "
                    font.family: root.mono; font.pixelSize: 13 * s
                    color: root.greenDim
                }
                Text {
                    id: tuiTime
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.mono; font.pixelSize: 13 * s; font.bold: true
                    color: root.amber
                    Timer {
                        interval: 1000; running: true; repeat: true
                        onTriggered: tuiTime.text = Qt.formatTime(new Date(), "hh:mm:ss")
                    }
                    Component.onCompleted: tuiTime.text = Qt.formatTime(new Date(), "hh:mm:ss")
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "   │   "
                    font.family: root.mono; font.pixelSize: 13 * s; color: root.gray
                }
                Text {
                    id: tuiDate
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.mono; font.pixelSize: 13 * s; color: root.greenDim
                    Timer {
                        interval: 60000; running: true; repeat: true
                        onTriggered: tuiDate.text = Qt.formatDate(new Date(), "ddd, MMM d yyyy")
                    }
                    Component.onCompleted: tuiDate.text = Qt.formatDate(new Date(), "ddd, MMM d yyyy")
                }
            }

            Item { width: 1 * s; height: 12 * s }

            // Divider ──────────────────────────────────────────────────────
            Rectangle { width: parent.width; height: 1 * s; color: root.gray }

            Item { width: 1 * s; height: 14 * s }

            // Username
            TuiField {
                id: tuiName
                width: parent.width
                label: "USER"
                isFocused: nameInput.activeFocus
                fieldInput: nameInput
            }
            TextInput {
                id: nameInput
                parent: tuiName.slot
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                text: (userHelper.currentItem && userHelper.currentItem.uName)
                      ? userHelper.currentItem.uName
                      : (userModel.lastUser || "")
                font.family: root.mono; font.pixelSize: 13 * s
                color: root.green
                cursorDelegate: TuiCursor {}
                clip: true
                KeyNavigation.backtab: rebootBtn
                KeyNavigation.tab:     passInput
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        passInput.forceActiveFocus(); event.accepted = true
                    }
                }
            }

            Item { width: 1 * s; height: 10 * s }

            // Password
            TuiField {
                id: tuiPass
                width: parent.width
                label: "PASS"
                isFocused: passInput.activeFocus
                fieldInput: passInput
            }
            TextInput {
                id: passInput
                parent: tuiPass.slot
                anchors.fill: parent
                anchors.topMargin: 1 * s
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "*"
                font.family: root.mono; font.pixelSize: 13 * s; font.letterSpacing: 2 * s
                color: root.green
                cursorDelegate: TuiCursor {}
                clip: true

                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "············"
                    color: root.gray; font.family: root.mono; font.pixelSize: 13 * s
                    visible: !passInput.text && !passInput.activeFocus
                }

                KeyNavigation.backtab: nameInput
                KeyNavigation.tab:     loginBtn
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(nameInput.text, passInput.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            Item { width: 1 * s; height: 10 * s }

            // Session
            Item {
                id: sessionSelector
                width: parent.width; height: 28 * s
                z: 10

                Row {
                    anchors.fill: parent; spacing: 0 * s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SESS  "
                        font.family: root.mono; font.pixelSize: 13 * s
                        color: root.greenDim
                    }
                    TuiBtn {
                        id: sessionBtn
                        anchors.verticalCenter: parent.verticalCenter
                        btnLabel: (sessionNameHelper.currentItem ? sessionNameHelper.currentItem.sessionName : "default") + " [ CYCLE ]"
                        KeyNavigation.backtab: loginBtn
                        KeyNavigation.tab:     shutdownBtn
                        onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                    }
                }
            }

            Item { width: 1 * s; height: 14 * s }

            // Divider ──────────────────────────────────────────────────────
            Rectangle { width: parent.width; height: 1 * s; color: root.gray }

            Item { width: 1 * s; height: 6 * s }

            // Status
            Text {
                id: statusMsg
                width: parent.width; text: ""
                color: root.red; font.family: root.mono; font.pixelSize: 13 * s
                height: text === "" ? 0 : implicitHeight + 4
                Behavior on height { NumberAnimation { duration: 120 } }
            }

            Item { width: 1 * s; height: 8 * s }

            // Buttons
            Row {
                width: parent.width; spacing: 12 * s; leftPadding: 0

                TuiBtn {
                    id: loginBtn
                    btnLabel: " LOGIN "
                    highlight: true
                    KeyNavigation.backtab: passInput
                    KeyNavigation.tab:     sessionBtn
                    onClicked: sddm.login(nameInput.text, passInput.text, sessionIndex)
                }
                TuiBtn {
                    id: shutdownBtn
                    btnLabel: " SHUTDOWN "
                    KeyNavigation.backtab: sessionBtn
                    KeyNavigation.tab:     rebootBtn
                    onClicked: sddm.powerOff()
                }
                TuiBtn {
                    id: rebootBtn
                    btnLabel: " REBOOT "
                    KeyNavigation.backtab: shutdownBtn
                    KeyNavigation.tab:     nameInput
                    onClicked: sddm.reboot()
                }
            }

            Item { width: 1 * s; height: 8 * s }
        }
    }

    // Bar
    Rectangle {
        height: 22 * s
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 10 * s }
        anchors.leftMargin: 10 * s; anchors.rightMargin: 10 * s
        color: root.green

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 10 * s }
            spacing: 0 * s
            Text { text: "[ "; font.family: root.mono; font.pixelSize: 12 * s; color: root.bg }
            Text {
                text: "KBD: "; font.family: root.mono; font.pixelSize: 12 * s; color: root.bg; opacity: 0.75
            }
            Text {
                font.family: root.mono; font.pixelSize: 12 * s; font.bold: true; color: root.bg
                // Safe check for keyboard object which is often missing in test mode
                text: (typeof keyboard !== 'undefined' && keyboard.currentLayoutName ? keyboard.currentLayoutName : "US").toUpperCase()
            }
            Text { text: "  |  HOST: "; font.family: root.mono; font.pixelSize: 12 * s; color: root.bg; opacity: 0.75 }
            Text {
                font.family: root.mono; font.pixelSize: 12 * s; font.bold: true; color: root.bg
                // Safe check for sddm.hostName
                text: (typeof sddm !== 'undefined' && sddm.hostName ? sddm.hostName : "LOCAL").toUpperCase()
            }
            Text { text: " ]"; font.family: root.mono; font.pixelSize: 12 * s; color: root.bg }
        }
        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 * s }
            text: "TAB: focus  │  ENTER: confirm"
            font.family: root.mono; font.pixelSize: 11 * s; color: root.bg; opacity: 0.65
        }
    }

    // Components

    // BorderBox
    component BorderBox: Item {
        property color  lineColor:  root.green
        property string title:      ""
        property color  titleColor: root.green

        // 4 border edges
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 1 * s; color: lineColor
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 1 * s; color: lineColor
        }
        Rectangle {
            anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
            width: 1 * s; color: lineColor
        }
        Rectangle {
            anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
            width: 1 * s; color: lineColor
        }

        // no corner characters — clean pixel borders only

        // title — covers the top border with bg rect + text
        Rectangle {
            visible: title !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0 * s; width: titleLabel.implicitWidth + 8; height: 1 * s
            color: root.bg
        }
        Text {
            id: titleLabel
            visible: title !== ""
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            anchors.topMargin: -7 * s
            text: title
            font.family: root.mono; font.pixelSize: 13 * s
            color: titleColor
        }
    }

    // TuiField
    component TuiField: Item {
        property string label:     "FIELD"
        property bool   isFocused: false
        property var    fieldInput
        property alias  slot: innerSlot
        height: 28 * s

        Row {
            anchors.fill: parent; spacing: 0 * s

            // label
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: label + "  "
                font.family: root.mono; font.pixelSize: 13 * s
                color: isFocused ? root.greenBright : root.greenDim
            }

            // input box
            Rectangle {
                width: parent.width - 60
                height: parent.height
                color: isFocused ? root.greenDark : "transparent"
                border.color: isFocused ? root.green : root.gray
                border.width: 1 * s

                // inner content area (TextInput is reparented here)
                Rectangle {
                    id: innerSlot
                    anchors { fill: parent; margins: 4 * s }
                    color: "transparent"
                }
            }
        }
    }

    // TuiBtn
    component TuiBtn: Item {
        property string btnLabel:  "BUTTON"
        property bool   highlight: false   // true = filled (primary action)
        signal clicked()

        implicitWidth:  lbl.implicitWidth + 8
        implicitHeight: 26

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
                clicked(); event.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: (btnMouse.containsMouse || highlight) ? root.greenDark : "transparent"
            border.color: btnMouse.containsMouse ? root.greenBright
                        : (highlight             ? root.green    : root.gray)
            border.width: 1 * s
        }
        Text {
            id: lbl
            anchors.centerIn: parent
            text: "[ " + btnLabel + " ]"
            font.family: root.mono; font.pixelSize: 13 * s
            color: btnMouse.containsMouse ? root.greenBright
                 : (highlight             ? root.green    : root.greenDim)
        }
        MouseArea {
            id: btnMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    // TuiCursor
    component TuiCursor: Rectangle {
        width: 2 * s
        height: 16 * s
        color: root.amber
        // Show only if field has focus AND the global blink cycle is 'on'
        visible: parent.activeFocus && root.globalBlink
    }

    // Boot
    Column {
        anchors { fill: parent; margins: 40 * s }
        spacing: 4 * s
        visible: root.bootOpacity > 0
        opacity: root.bootOpacity

        Repeater {
            model: [
                "[ OK ] Initializing SDDM_TUI Kernel...",
                "[ OK ] Mounting /dev/hda1 (VIRTUAL_DISK)",
                "[ OK ] Network: NeuralLink v4.2 Connected",
                "[ OK ] Decryption Engine: ACTIVE",
                "[ OK ] Secure Shell established...",
                "[ OK ] Loading User Profiles...",
                "[ !! ] System Ready. Initializing Login Interface."
            ]
            Text {
                text: modelData
                font.family: root.mono; font.pixelSize: 12 * s
                color: root.greenDim
                visible: index < root.bootLineCount
            }
        }

        SequentialAnimation {
            id: bootSequence
            running: true
            PauseAnimation  { duration: 400 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 1 }
            PauseAnimation  { duration: 200 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 2 }
            PauseAnimation  { duration: 150 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 3 }
            PauseAnimation  { duration: 250 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 4 }
            PauseAnimation  { duration: 300 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 5 }
            PauseAnimation  { duration: 200 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 6 }
            PauseAnimation  { duration: 400 }
            PropertyAction  { target: root; property: "bootLineCount"; value: 7 }
            PauseAnimation  { duration: 800 }
            
            // Switch to Login Panel
            NumberAnimation { target: root; property: "bootOpacity"; to: 0; duration: 400 }
            PropertyAction  { target: root; property: "uiOpacity"; value: 1.0 }
            NumberAnimation { target: root; property: "typewriter"; from: 0; to: 15; duration: 600 }
        }
    }

    // Decorations - Left Bottom (Hex Stream)
    Column {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 25 * s
        anchors.bottomMargin: 45 * s
        spacing: 2 * s
        opacity: root.uiOpacity * 0.4
        Repeater {
            model: 12
            Text {
                property string hex: "00 00 00 00"
                text: "DATA_STRM[" + (index < 10 ? "0"+index : index) + "]: " + hex
                font.family: root.mono; font.pixelSize: 9 * s
                color: root.greenDim
                Timer {
                    interval: 100 + Math.random() * 500; running: true; repeat: true
                    onTriggered: {
                        var chars = "0123456789ABCDEF";
                        var s = "";
                        for(var i=0; i<8; i++) {
                            s += chars.charAt(Math.floor(Math.random()*chars.length));
                            if(i%2==1) s += " ";
                        }
                        hex = s;
                    }
                }
            }
        }
    }

    // Decorations - Right Bottom (Resource Monitor)
    Column {
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 25 * s
        anchors.bottomMargin: 45 * s
        spacing: 2 * s
        opacity: root.uiOpacity * 0.4
        Repeater {
            model: [ "SYS_MEM", "CPU_LD", "NSA_TRC", "VOLT_PK" ]
            Text {
                property int val: 10 + Math.random() * 80
                width: 150 * s; horizontalAlignment: Text.AlignRight
                text: modelData + " ===> [ " + val + "% ]"
                font.family: root.mono; font.pixelSize: 9 * s
                color: root.greenDim
                Timer {
                    interval: 1000 + Math.random() * 2000; running: true; repeat: true
                    onTriggered: val = Math.max(0, Math.min(100, val + (Math.random() - 0.5) * 10))
                }
            }
        }
    }

    // Decorations - Top Right (Network Logs)
    Column {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 25 * s
        spacing: 2 * s
        opacity: root.uiOpacity * 0.3
        Repeater {
            model: 6
            Text {
                property string ip: "127.0.0.1"
                width: 250 * s; horizontalAlignment: Text.AlignRight
                text: "INBOUND_CONN [" + ip + "] ... OK"
                font.family: root.mono; font.pixelSize: 9 * s
                color: root.greenDim
                Timer {
                    interval: 2000 + Math.random() * 3000; running: true; repeat: true
                    onTriggered: {
                        ip = "192.168." + Math.floor(Math.random()*255) + "." + Math.floor(Math.random()*255)
                    }
                }
            }
        }
    }

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: { if (nameInput.text === "") nameInput.forceActiveFocus(); else passInput.forceActiveFocus() } }

    // Focus
    Component.onCompleted: {
        if (nameInput.text === "") nameInput.forceActiveFocus()
        else                       passInput.forceActiveFocus()
    }
}
