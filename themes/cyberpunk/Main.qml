import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Qt.labs.folderlistmodel 2.15
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#030405" // Deep dark background

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string activeUser: userModel.lastUser
    
    // Theme Colors
    readonly property color textColor: "#fcee09" // Cyberpunk Yellow
    readonly property color accentColor: "#00f0ff" // Cyan
    readonly property color errorColor: "#f83641" // Dark Red
    readonly property color highlightColor: Qt.rgba(0, 0.94, 1.0, 0.2)
    
    readonly property string fontName: mainFont.name

    // States
    property real glitchX: 0
    property real glitchY: 0
    property bool glitchActive: false
    property real glitchOpacity: 0
    property real bootOpacity: 1.0
    property real scanLineY: 0

    TextConstants { id: textConstants }

    // Font Loader
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Session Helper
    ListView {
        id: sessionNameHelper
        model: sessionModel; currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sessionName: model.name || "" }
    }

    // Timer
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            var r = Math.random();
            root.glitchActive = (r > 0.94); // Slightly rarer but more intense
            if (root.glitchActive) {
                root.glitchX = (Math.random() - 0.5) * 20;
                root.glitchY = (Math.random() - 0.5) * 8;
                root.glitchOpacity = Math.random() * 0.5;
            } else {
                root.glitchX = 0;
                root.glitchY = 0;
                root.glitchOpacity = 0;
            }
        }
    }

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordInput.forceActiveFocus() }

    // Boot Sequence
    Component.onCompleted: bootSequence.start()
    SequentialAnimation {
        id: bootSequence
        PropertyAction { target: root; property: "bootOpacity"; value: 1.0 }
    }

    // Scan Line
    NumberAnimation {
        target: root; property: "scanLineY"
        from: 0; to: root.height; duration: 4000
        loops: Animation.Infinite
        running: true
    }

    // Background
    Image {
        id: bgImage
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        
        // Signal jitter on glitch
        x: root.glitchActive ? root.glitchX * 0.1 : 0
        opacity: 0.9 + (root.glitchOpacity * 0.1)
    }

    // Overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1.0, 0, 0.23, 0.05) // Reddish tint
    }

    // Scan Line
    Rectangle {
        id: scanningHUD
        width: parent.width; height: 2 * s
        y: root.scanLineY
        color: "#00f0ff"
        opacity: 0.05
        z: 100
        layer.enabled: true
        layer.effect: Glow {
            color: "#00f0ff"
            radius: 8 * s; samples: 16; spread: 0.5
        }
    }

    // Noise Layer
    Canvas {
        anchors.fill: parent; opacity: 0.03; z: 101
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "white"
            for (var i = 0; i < 1000; i++) {
                ctx.fillRect(Math.random() * width, Math.random() * height, 1, 1)
            }
        }
        Timer {
            interval: 50; running: true; repeat: true
            onTriggered: parent.requestPaint()
        }
    }

    // --- LEFT PANEL ---
    Item {
        id: leftPanelContainer
        width: 420 * s; height: parent.height

        // Ghost Layer
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 0, 0.23, 0.4)
            visible: root.glitchActive
            x: root.glitchX * 0.5
            z: 1
        }

        Rectangle {
            id: leftPanel
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.85)
            clip: true
            z: 2
            
            // Apply slight jitter to the actual panel during glitches
            x: root.glitchActive ? root.glitchX * 0.2 : 0
        
        // Decoration
        Rectangle {
            id: panelBorder
            width: 2 * s; height: parent.height
            anchors.right: parent.right
            color: "#00f0ff"
            opacity: 0.4
            
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.2; to: 0.8; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.8; to: 0.2; duration: 1500; easing.type: Easing.InOutSine }
            }
        }

        // Texture
        Rectangle {
            anchors.fill: parent
            z: 10
            color: "transparent"
            Image {
                anchors.fill: parent
                source: "background.png"
                opacity: 0.1
                fillMode: Image.Tile
            }
        }



        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 120 * s
            anchors.leftMargin: 60 * s
            spacing: 12 * s
            width: parent.width - 20

            // Logo
            Item {
                width: 260 * s; height: 100 * s
                anchors.left: parent.left

                // Ghost 1 (Red)
                Image {
                    source: "logo.png"; width: 260 * s; fillMode: Image.PreserveAspectFit
                    opacity: root.glitchActive ? 0.6 : 0
                    x: root.glitchX; y: root.glitchY
                    visible: root.glitchActive
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: "#ff003c" }
                }

                // Ghost 2 (Cyan)
                Image {
                    source: "logo.png"; width: 260 * s; fillMode: Image.PreserveAspectFit
                    opacity: root.glitchActive ? 0.6 : 0
                    x: -root.glitchX; y: -root.glitchY
                    visible: root.glitchActive
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: "#00f0ff" }
                }

                Image {
                    id: mainLogo
                    source: "logo.png"
                    width: 260 * s
                    fillMode: Image.PreserveAspectFit
                    anchors.centerIn: parent

                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0; verticalOffset: 0
                        radius: 12 * s; samples: 16; color: "#00f0ff"
                    }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.7; duration: 2500; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.7; to: 1; duration: 2500; easing.type: Easing.InOutQuad }
                    }
                }
            }

            Rectangle { width: 1 * s; height: 15 * s; color: "transparent" } // Spacer

            // User Selection
            // Moved above password box
            ListView {
                id: userList
                width: 340 * s
                height: Math.min(count * 48, 150)
                model: userModel
                currentIndex: userModel.lastIndex
                clip: true
                spacing: 4 * s
                delegate: CyberButton {
                    text: model.realName || model.name
                    selected: userList.currentIndex === index
                    fontName: mainFont.name
                    onClicked: {
                        userList.currentIndex = index;
                        passwordInput.focus = true;
                    }
                }
            }

            Rectangle { width: 1 * s; height: 10 * s; color: "transparent" } // Spacer

            // Password Field
            Rectangle {
                id: passwordContainer
                width: 340 * s; height: 48 * s
                color: passwordInput.activeFocus ? Qt.rgba(0, 0.94, 1.0, 0.15) : "transparent"
                
                // Focus Indicator
                Rectangle {
                    width: 4 * s; height: parent.height
                    anchors.left: parent.left
                    color: passwordInput.activeFocus ? "#ff003c" : "transparent"
                }

                // Bottom Border
                Rectangle {
                    width: parent.width; height: 2 * s
                    anchors.bottom: parent.bottom
                    color: passwordInput.activeFocus ? "#00f0ff" : Qt.rgba(1, 1, 1, 0.1)
                }
                
                TextInput {
                    id: passwordInput
                    anchors.fill: parent; anchors.leftMargin: 20 * s; anchors.rightMargin: 10 * s
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: mainFont.name; font.pixelSize: 18 * s; color: "#00f0ff"
                    echoMode: TextInput.Password; focus: true; passwordCharacter: "*"
                    
                    Text {
                        text: "ACCESS CODES"
                        visible: !parent.text
                        color: "#ff003c"
                        font.family: parent.font.family
                        font.pixelSize: 14 * s
                        font.letterSpacing: 2 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: {
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        var username = userList.model.data(userList.model.index(userList.currentIndex, 0), Qt.UserRole + 1)
        sddm.login(username, passwordInput.text, root.sessionIndex)
    }
}
                }
            }

            Rectangle { width: 1 * s; height: 20 * s; color: "transparent" } // Spacer

            // Menu
            Column {
                spacing: 8 * s
                width: 340 * s

                CyberButton {
                    text: (sessionNameHelper.currentItem && sessionNameHelper.currentItem.sessionName) 
                          ? "FIRMWARE: " + sessionNameHelper.currentItem.sessionName 
                          : "CHANGE FIRMWARE"
                    fontName: mainFont.name
                    onClicked: {
                        if (sessionModel && sessionModel.rowCount() > 0) {
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                        }
                    }
                }

                CyberButton {
                    text: "SYSTEM LOGIN"
                    fontName: mainFont.name
                    onClicked: {
                        var username = userList.model.data(userList.model.index(userList.currentIndex, 0), Qt.UserRole + 1)
                        sddm.login(username, passwordInput.text, root.sessionIndex)
                    }
                }

                CyberButton {
                    text: "POWER DOWN"
                    fontName: mainFont.name
                    onClicked: sddm.powerOff()
                }

                CyberButton {
                    text: "REBOOT"
                    fontName: mainFont.name
                    onClicked: sddm.reboot()
                }
            }
        }
    }
}

    // --- BOTTOM INFO ---
    Column {
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 40 * s
        spacing: 4 * s
        CyberText {
            baseText: "ACCESS_CORE: L5 SECURED"
            color: "#ff003c"; font.pixelSize: 10 * s; font.letterSpacing: 2 * s; opacity: 0.5
            anchors.right: parent.right
        }
        CyberText {
            baseText: "Ver 1.2.0 | [NEURAL LINK: STABLE] | SDDM OS"
            color: "#ff003c"; font.pixelSize: 12 * s; font.letterSpacing: 1.5; opacity: 0.8
            anchors.right: parent.right
        }
    }

    // --- LEFT DECO ---
    Column {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 40 * s
        anchors.leftMargin: 60 * s
        spacing: 2 * s
        z: 30
        CyberText { baseText: "NET: 99.8% STABLE"; color: "#00f0ff"; font.pixelSize: 10 * s; opacity: 0.4 }
        Rectangle { width: 100 * s; height: 1 * s; color: "#00f0ff"; opacity: 0.2 }
        CyberText { baseText: "DECRYPTION: ACTIVE"; color: "#ff003c"; font.pixelSize: 10 * s; opacity: 0.4 }
    }

    // --- GLITCH OVERLAY ---
    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: root.glitchOpacity * 0.2
        visible: root.glitchActive
    }

    // --- DATA STREAM ---
    Column {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 60 * s
        spacing: 4 * s
        opacity: 0.4
        z: 5
        Repeater {
            model: 12
            CyberText {
                property string hex: "00 00 00 00"
                baseText: "NET_DATA >> " + hex
                color: "#00f0ff"; font.pixelSize: 9 * s
                Timer {
                    interval: 100 + Math.random() * 800; running: true; repeat: true
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

    // --- COMPONENTS ---
    component CyberText: Text {
        id: ctRoot
        property string baseText: ""
        property real reveal: root.bootOpacity
        property bool scramble: true
        
        text: scramble ? scrambleText(baseText, reveal) : baseText
        font.family: root.fontName
        
        function scrambleText(t, r) {
            if (r >= 1.0 && !root.glitchActive) return t;
            var out = "";
            var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+";
            for (var i = 0; i < t.length; i++) {
                if (Math.random() > r || root.glitchActive) {
                    out += chars.charAt(Math.floor(Math.random() * chars.length));
                } else {
                    out += t[i];
                }
            }
            return out;
        }
    }

    // Flickering tech lines
    Rectangle {
        width: 300 * s; height: 1 * s; color: "#00f0ff"; opacity: 0.1; x: 500 * s; y: 200 * s
        visible: root.glitchActive
    }
    Rectangle {
        width: 1 * s; height: 300 * s; color: "#ff003c"; opacity: 0.1; x: 800 * s; y: 100 * s
        visible: root.glitchActive
    }

    // Distorted Line Glitch
    Rectangle {
        width: parent.width; height: Math.random() * 20
        y: Math.random() * parent.height
        color: Math.random() > 0.5 ? "#ff003c" : "#00f0ff"
        opacity: root.glitchActive ? 0.3 : 0
        visible: root.glitchActive
    }
}
