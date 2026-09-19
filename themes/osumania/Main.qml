import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0
import Qt.labs.settings 1.0

Rectangle {
    id: root

    // Wayland Fix
    MouseArea { anchors.fill: parent; cursorShape: Qt.ArrowCursor; z: -1 }

    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined

    // Settings
    Settings {
        id: settings
        category: "osumania"
        property int   laneCount:    4
        property real  noteSpeed:    1.0
        property real  noteDensity:  1.0
        property int   key0: Qt.Key_S
        property int   key1: Qt.Key_D
        property int   key2: Qt.Key_K
        property int   key3: Qt.Key_L
        property int   preset: 1
    }

    readonly property real s: Screen.height / 768
    width: Screen.width
    color: "#0a0009"

    readonly property bool gameMode: config.gameMode !== "menu"

    // UI State
    property int  sessionIndex:    (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int  userIndex:       (userModel    && userModel.lastIndex    >= 0) ? userModel.lastIndex    : 0
    property bool gameActive:      false
    property bool loginPending:    false
    property bool loginSuccess:    false
    property bool showingSettings: false

    // Game State
    property int  maniaScore:    0
    property int  maniaCombo:    0
    property int  maniaMaxCombo: 0
    property int  maniaHits:     0
    property int  maniaMisses:   0
    property int  mania300s:     0
    property int  mania100s:     0
    property int  mania50s:      0
    property real maniaAccuracy: 100.0
    property real maniaHealth:   1.0
    property bool maniaFailed:   false
    property bool showingDiff:   false
    property real missPenalty:   0.25

    // Hit Windows (ms)
    readonly property real hitWindow300: 45
    readonly property real hitWindow100: 100
    readonly property real hitWindow50:  180

    // Background Art
    property int bgIndex: Math.floor(Math.random() * 7)
    readonly property var bgFiles: [
        "background/A Glow.jpg","background/B Glow.jpg","background/C Glow.jpg",
        "background/D Glow.jpg","background/E Glow.jpg","background/F Glow.jpg",
        "background/G Glow.jpg"
    ]
    readonly property var bgSchemes: [
        { accent:"#ff44bb", secondary:"#cc0088", glow:"#ff88cc", dark:"#1a0015", text:"#ffe0ef", lane:"#cc0077" },
        { accent:"#44ddff", secondary:"#0099cc", glow:"#88eeff", dark:"#001222", text:"#ddf6ff", lane:"#0077bb" },
        { accent:"#ffaa00", secondary:"#cc6600", glow:"#ffcc55", dark:"#1a0e00", text:"#fff0dd", lane:"#cc8800" },
        { accent:"#aaff22", secondary:"#66cc00", glow:"#ccff66", dark:"#0c1400", text:"#f0ffe0", lane:"#88cc00" },
        { accent:"#bb55ff", secondary:"#8800cc", glow:"#dd99ff", dark:"#110022", text:"#f0e8ff", lane:"#9900dd" },
        { accent:"#00ffcc", secondary:"#00aa88", glow:"#66ffee", dark:"#001a14", text:"#dffff7", lane:"#00bbaa" },
        { accent:"#ff4466", secondary:"#cc1133", glow:"#ff8899", dark:"#1a0008", text:"#ffe8ec", lane:"#dd2255" }
    ]
    readonly property var scheme:         bgSchemes[bgIndex]
    readonly property color accentColor:  scheme.accent
    readonly property color glowColor:    scheme.glow
    readonly property color darkColor:    scheme.dark
    readonly property color laneColor:    scheme.lane

    // Lane Keys
    property int bindingIdx: -1
    readonly property var laneKeys: [settings.key0, settings.key1, settings.key2, settings.key3]
    readonly property var keyNames: {
        var out = []; var keys = [settings.key0,settings.key1,settings.key2,settings.key3]
        for (var i=0;i<keys.length;i++) {
            var k=keys[i]
            if      (k===Qt.Key_Left)  out.push("←")
            else if (k===Qt.Key_Right) out.push("→")
            else if (k===Qt.Key_Up)    out.push("↑")
            else if (k===Qt.Key_Down)  out.push("↓")
            else if (k===Qt.Key_Space) out.push("SP")
            else if (k>=48 && k<=57)   out.push(String.fromCharCode(k)) // Numbers
            else if (k>=65 && k<=90)   out.push(String.fromCharCode(k)) // Letters
            else if (k>=0x01000030 && k<=0x01000039) out.push("N" + (k-0x01000030)) // Numpad
            else out.push(k > 0 ? "..." : "?")
        }
        return out
    }

    // Active Notes
    property var laneNotes: [[], [], [], []]

    // Assets
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf","*.otf"] }
    FontLoader   { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0,"fileName") : "" }
    TextConstants { id: textConstants }

    // SDDM Bridges
    ListView {
        id: userHelper; model: userModel; currentIndex: root.userIndex
        width:1; height:1; opacity:0
        delegate: Item { 
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
            property string uSystemIcon: model.icon || ""
        }
    }
    ListView {
        id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex
        width:1; height:1; opacity:0
        delegate: Item { property string sName: model.name || "" }
    }

    // Focus
    Timer { interval:300; running:true; onTriggered: passField.forceActiveFocus() }

    // Fade in
    property real uiOpacity: 0
    Component.onCompleted: { fadeIn.start(); keyboard.numLock = true }
    NumberAnimation { id:fadeIn; target:root; property:"uiOpacity"; from:0; to:1; duration:400; easing.type:Easing.OutCubic }

    // Background
    Image {
        id: bgImage; anchors.fill:parent
        source: root.bgFiles[root.bgIndex]
        fillMode: Image.PreserveAspectCrop; asynchronous: true
        opacity: root.loginSuccess ? 0.1 : (root.gameActive ? 0.18 : 0.55)
        Behavior on opacity { NumberAnimation { duration:800 } }
    }
    Rectangle {
        anchors.fill:parent; color: root.darkColor
        opacity: root.gameActive ? 0.92 : 0.5
        Behavior on opacity { NumberAnimation { duration:800 } }
    }
    Rectangle {
        anchors.fill:parent
        gradient: Gradient {
            GradientStop { position:0.0; color:"transparent" }
            GradientStop { position:1.0; color:"#cc000000" }
        }
    }



    // Key Button
    component ManiaCard: Item {
        id: mc
        property string label:  ""
        property color  ccolor: root.accentColor
        signal activated()
        width: 150*s; height: 44*s

        // Hover scale effect
        scale: mcMa.containsMouse ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        Item {
            anchors.fill: parent
            
            // Base Pill
            Rectangle {
                anchors.fill: parent; radius: height/2
                color: mcMa.containsMouse ? Qt.rgba(mc.ccolor.r, mc.ccolor.g, mc.ccolor.b, 0.25) : Qt.rgba(0,0,0,0.75)
                border.color: mcMa.containsMouse ? mc.ccolor : Qt.rgba(1,1,1,0.2)
                border.width: 1.5*s
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                // Interior glow on hover
                Rectangle {
                    anchors.fill: parent; radius: parent.radius; opacity: mcMa.containsMouse ? 0.3 : 0
                    color: "transparent"; border.color: mc.ccolor; border.width: 1*s
                    layer.enabled: true; layer.effect: DropShadow { color: mc.ccolor; radius: 10; samples: 16 }
                }
            }

            Text {
                anchors.centerIn: parent
                text: mc.label; color: mcMa.containsMouse ? "white" : Qt.rgba(1,1,1,0.6)
                font.family: mainFont.name; font.pixelSize: 13*s; font.weight: Font.Black
                font.italic: true; font.letterSpacing: 1.5*s
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            id: mcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: mc.activated()
        }
    }

    // Heading Component
    component ManiaHeading: Item {
        id: mh
        property string title: ""
        property color  accent: root.accentColor
        property real   s: root.s

        width: 850*s; height: 60*s
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            anchors.centerIn: parent; spacing: 20*s
            Rectangle { width: 40*s; height: 1.5*s; color: mh.accent; anchors.verticalCenter: parent.verticalCenter; opacity: 0.6 }
            Text {
                text: mh.title.toUpperCase(); color: "white"
                font.family: mainFont.name; font.pixelSize: 22*s; font.weight: Font.Black; font.letterSpacing: 10*s
            }
            Rectangle { width: 40*s; height: 1.5*s; color: mh.accent; anchors.verticalCenter: parent.verticalCenter; opacity: 0.6 }
        }
    }

    // Login Screen
    Item {
        id: loginScreen; anchors.fill:parent
        opacity: (root.gameActive || root.loginSuccess) ? 0 : root.uiOpacity
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration:600; easing.type:Easing.OutQuint } }


        // Top HUD
        Item {
            id: topHudBar; anchors.left:parent.left; anchors.top:parent.top; anchors.right:parent.right; height:65*s; z:100
            
            // Glass Bar
            Rectangle {
                anchors.fill:parent; color:Qt.rgba(0,0,0,0.4)
                // Bottom Shadow
                layer.enabled: true
                layer.effect: DropShadow { color: "black"; radius: 10; samples: 16; verticalOffset: 2 }
            }

            // User Profile
            Item {
                id: hudUserSegment; anchors.left:parent.left; anchors.top:parent.top; anchors.leftMargin:30*s
                width:450*s; height:70*s
                
                Row {
                    anchors.verticalCenter:parent.verticalCenter; spacing:20*s
                    
                    // Avatar Ring
                    Item {
                        width:54*s; height:54*s; anchors.verticalCenter:parent.verticalCenter
                        Rectangle {
                            anchors.fill:parent; radius:width/2; color:"#111"
                            border.color:root.accentColor; border.width:2*s
                        }
                        Item {
                            anchors.fill:parent; anchors.margins:4*s
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle { width: 46*s; height: 46*s; radius: 23*s }
                            }
                            Image {
                                id: hudAvatar; anchors.fill:parent
                                // Custom Avatar
                                source: (userHelper.currentItem && userHelper.currentItem.uLogin) ? "avatars/" + userHelper.currentItem.uLogin + ".png" : "avatars/pfp.png"
                                fillMode: Image.PreserveAspectCrop
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        // System Icon
                                        if (source.toString().indexOf("avatars/pfp.png") === -1 && userHelper.currentItem.uSystemIcon) {
                                            source = userHelper.currentItem.uSystemIcon
                                        } else {
                                            // Fallback PFP
                                            source = "avatars/pfp.png"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Info Column
                    Column {
                        anchors.verticalCenter:parent.verticalCenter; spacing:4*s
                        Text {
                            text:(userHelper.currentItem?userHelper.currentItem.uName:"PLAYER").toUpperCase()
                            color:"white"; font.family:mainFont.name; font.pixelSize:19*s; font.weight:Font.Black; font.italic:false; font.letterSpacing:1*s
                        }
                        Row {
                            spacing:12*s
                            Text { text:"#721"; color:root.accentColor; font.family:mainFont.name; font.pixelSize:10*s; font.weight:Font.Black }
                            Text { text:"6,512 PP"; color:"#888"; font.family:mainFont.name; font.pixelSize:10*s; font.weight:Font.Bold }
                            Rectangle { width:1.5*s; height:8*s; color:"#33ffffff"; anchors.verticalCenter:parent.verticalCenter }
                            
                            // XP Display
                            Item {
                                width:120*s; height:12*s; anchors.verticalCenter:parent.verticalCenter
                                Row {
                                    anchors.fill:parent; spacing:8*s
                                    Text { text:"LV100"; color:"#66ffffff"; font.family:mainFont.name; font.pixelSize:9*s; font.weight:Font.Black; anchors.verticalCenter:parent.verticalCenter }
                                    Rectangle {
                                        width:85*s; height:3*s; radius:1.5*s; color:"#22ffffff"; anchors.verticalCenter:parent.verticalCenter
                                        Rectangle { width:parent.width*0.88; height:parent.height; radius:1.5*s; color:root.accentColor }
                                    }
                                }
                            }
                        }
                    }
                }
                
                MouseArea {
                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex+1) % Math.max(1, userModel.count)
                }
            }

            // Environment Segment
            Item {
                anchors.horizontalCenter:parent.horizontalCenter; anchors.verticalCenter:parent.verticalCenter
                width:300*s; height:70*s
                Column {
                    anchors.centerIn:parent; spacing:0
                    Text { 
                        anchors.horizontalCenter:parent.horizontalCenter
                        text:"ENVIRONMENT STATUS"; color:root.accentColor; font.family:mainFont.name; font.pixelSize:8*s; font.weight:Font.Black; font.letterSpacing:3*s; opacity:0.8
                    }
                    Text {
                        anchors.horizontalCenter:parent.horizontalCenter
                        text:sessionHelper.currentItem ? sessionHelper.currentItem.sName.toUpperCase() : "DEFAULT"
                        color:"white"; font.family:mainFont.name; font.pixelSize:14*s; font.weight:Font.Black; font.letterSpacing:1.5*s
                    }
                }
                MouseArea {
                    anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                    onClicked: root.sessionIndex = (root.sessionIndex+1) % Math.max(1, sessionModel.count)
                }
            }

            // Clock Segment
            Item {
                anchors.right:parent.right; anchors.rightMargin:30*s; anchors.verticalCenter:hudUserSegment.verticalCenter
                width:180*s; height:60*s
                Row {
                    anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; spacing:14*s
                    Rectangle { width:1.5*s; height:32*s; color:root.accentColor; opacity:0.4 }
                    Column {
                        anchors.verticalCenter:parent.verticalCenter; spacing:-2*s
                        Text {
                            property string timeStr: Qt.formatTime(new Date(),"HH:mm")
                            Timer { interval:1000; running:true; repeat:true; onTriggered: parent.timeStr=Qt.formatTime(new Date(),"HH:mm") }
                            text:timeStr; color:"white"; font.family:mainFont.name; font.pixelSize:28*s; font.weight:Font.Black
                        }
                        Text {
                            text:Qt.formatDate(new Date(), "ddd, MMM d").toUpperCase()
                            color:root.accentColor; font.family:mainFont.name; font.pixelSize:10*s; font.weight:Font.Black; font.letterSpacing:1.5*s
                        }
                    }
                }
            }
        }

        // Main Menu
        Item {
            id: mainMenuWrapper; anchors.fill:parent

            // ── Ambient Art ────────────────────────────────
            Item {
                anchors.fill: parent
                clip: true
                opacity: 1.0
                // Falling Notes
                Repeater {
                    model: 16
                    Item {
                        property int   col:   index % 4
                    }
                }

            // ── Centre Block ───────────────────────────────────────────
            Item {
                anchors.centerIn: parent
                width: 720*s; height: 600*s

                // Background Glow
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 1.5; height: parent.height * 1.2
                    radius: width / 2; opacity: 0.15
                    gradient: Gradient {
                        GradientStop { position: 0; color: "black" }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }

                Column {
                    anchors.fill: parent; spacing: 0

                    // ── Logo ──────────────────────────────────────────────────────
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width; height: 180*s

                        // Logo Shadow
                        Text {
                            anchors.centerIn: parent; anchors.verticalCenterOffset: 6*s; anchors.horizontalCenterOffset: 4*s
                            text: "osu!"; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4)
                            font.family: mainFont.name; font.pixelSize: 140*s; font.weight: Font.Black; font.italic: true
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "osu!"; color: "white"
                            font.family: mainFont.name; font.pixelSize: 140*s; font.weight: Font.Black; font.italic: true
                        }
                    }

                    // ── Subtitle Area ─────────────────────────────────────────────
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 480*s; height: 40*s
                        Rectangle {
                            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width; height: 2*s
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 0.5; color: root.accentColor }
                                GradientStop { position: 1; color: "transparent" }
                            }
                        }
                        Text {
                            anchors.centerIn: parent; anchors.verticalCenterOffset: 4*s
                            text: "M A N I A   E D I T I O N"
                            color: "white"; font.family: mainFont.name; font.pixelSize: 14*s; font.weight: Font.Black; opacity: 0.6
                        }
                    }

                    Item { width: 1; height: 60*s }

                    // Password Box
                    Item {
                        id: passwordWrapper
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 500*s; height: 50*s

                        // Glassy background
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0,0,0,0.85)
                            radius: 2*s
                        }

                        // Framing Lines
                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            height: 1*s; color: passField.activeFocus ? root.accentColor : Qt.rgba(1,1,1,0.3)
                            opacity: passField.activeFocus ? 1.0 : 0.6
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: 1*s; color: passField.activeFocus ? root.accentColor : Qt.rgba(1,1,1,0.3)
                            opacity: passField.activeFocus ? 1.0 : 0.6
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Focus Glow
                        Rectangle {
                            anchors.fill: parent; anchors.margins: -4*s
                            color: "transparent"; border.color: root.accentColor; border.width: 1*s
                            opacity: passField.activeFocus ? 0.15 : 0; radius: 4*s
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        TextInput {
                            id: passField
                            anchors.fill: parent; anchors.leftMargin: 20*s; anchors.rightMargin: 20*s
                            verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
                            clip: true; color: "transparent"; cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                            font.family: mainFont.name; font.pixelSize: 18*s; font.weight: Font.DemiBold
                            font.letterSpacing: 4*s; echoMode: TextInput.Password; focus: true
                            property bool wasClicked: false
                            selectByMouse: false
                            Keys.onReturnPressed: if(text.length > 0) root.doAction()
                            MouseArea { anchors.fill: parent; onClicked: { passField.forceActiveFocus(); passField.wasClicked = true } }

                            Text {
                                anchors.centerIn: parent
                                text: "ACCESS REQUIRED"; color: Qt.rgba(1,1,1,0.6)
                                font.family: mainFont.name; font.pixelSize: 12*s; font.weight: Font.Black
                                font.letterSpacing: 4*s; visible: passField.text.length === 0
                            }
                        }

                        // Password Dots
                        Row {
                            anchors.centerIn: parent; spacing: 14*s
                            Repeater {
                                model: passField.text.length
                                Rectangle {
                                    width: 8*s; height: 8*s; radius: 4*s; color: root.accentColor
                                    opacity: 0.8
                                }
                            }
                        }

                        // Caret
                        Rectangle {
                            id: bladeCaret
                            anchors.centerIn: parent
                            // Caret Placement
                            property real dotsW: Math.max(0, passField.text.length * 22*s - 14*s)
                            anchors.horizontalCenterOffset: passField.text.length > 0 ? (dotsW/2 + 12*s) : 0
                            width: 2*s; height: 18*s; color: root.accentColor
                            visible: passField.activeFocus && (passField.text.length > 0 || passField.wasClicked)
                            SequentialAnimation {
                                running: bladeCaret.visible; loops: Animation.Infinite
                                NumberAnimation { target: bladeCaret; property: "opacity"; from: 1; to: 0.1; duration: 500 }
                                NumberAnimation { target: bladeCaret; property: "opacity"; from: 0.1; to: 1; duration: 500 }
                                onFinished: if (root.isQuickshell) console.log("Caret Breathing...")
                            }
                        }
                    }

                    Item { width: 1; height: 50*s }

                    // Action Buttons
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16*s
                        ManiaCard { label: "PLAY"; onActivated: { if(root.gameMode) root.showingDiff = true; else root.doAction() } }
                        ManiaCard { label: "ENV"; ccolor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.7); onActivated: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionModel.count) }
                        ManiaCard { label: "REBOOT"; ccolor: "#3498DB"; onActivated: sddm.reboot() }
                        ManiaCard { label: "SHUTDOWN"; ccolor: "#E74C3C"; onActivated: sddm.powerOff() }
                    }

                    Item { width: 1; height: 40*s }

                    // ── Config Button ─────────────────────────────────────────────
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter; width: 140*s; height: 32*s
                        Rectangle {
                            anchors.fill: parent; color: configMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            border.color: configMa.containsMouse ? "white" : "#33ffffff"; border.width: 1*s; radius: 16*s
                        }
                        Text {
                            anchors.centerIn: parent; text: "CONFIG"; color: "white"
                            font.family: mainFont.name; font.pixelSize: 10*s; font.weight: Font.Black; font.letterSpacing: 1*s; opacity: 0.5
                        }
                        MouseArea { id: configMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.showingSettings = true }
                    }
                }
            }
        }
    }

        // Difficulty Selector 
        Rectangle {
            id: diffOverlay
            anchors.fill:parent; z:5000; color:Qt.rgba(0,0,0,0.95)
            visible:opacity>0.01; opacity:root.showingDiff?1:0
            Behavior on opacity { NumberAnimation { duration:300 } }
            MouseArea { anchors.fill:parent; hoverEnabled:true; onClicked:root.showingDiff=false }

            Column {
                anchors.centerIn:parent; spacing:40*s
                
                // Heading Style
                ManiaHeading {
                    title: "SELECT CHALLENGE LEVEL"
                }

                Row {
                    anchors.horizontalCenter:parent.horizontalCenter; spacing:20*s
                    property var diffs: [
                        { name:"EASY",       stars:1, col:"#2ECC71", desc:"Beginner friendly" },
                        { name:"NORMAL",     stars:2, col:"#F1C40F", desc:"The standard play" },
                        { name:"HARD",       stars:4, col:"#E67E22", desc:"Test your reflexes" },
                        { name:"PRO",        stars:6, col:"#E74C3C", desc:"Absolute chaos" }
                    ]
                    Repeater {
                        model: 4
                        Item {
                            width:180*s; height:240*s
                            Rectangle {
                                anchors.fill:parent; radius:15*s
                                color: Qt.rgba(parent.parent.diffs[index].col.r, parent.parent.diffs[index].col.g, parent.parent.diffs[index].col.b, diffMa.containsMouse?0.15:0.05)
                                border.color: diffMa.containsMouse ? parent.parent.diffs[index].col : "#33ffffff"; border.width:2*s
                                Behavior on color { ColorAnimation { duration:200 } }
                                Column {
                                    anchors.centerIn:parent; spacing:12*s; width:parent.width-20*s
                                    Text {
                                        anchors.horizontalCenter:parent.horizontalCenter
                                        text:parent.parent.parent.parent.diffs[index].name
                                        color:parent.parent.parent.parent.diffs[index].col
                                        font.family:mainFont.name; font.pixelSize:22*s; font.weight:Font.Black
                                    }
                                    Row {
                                        anchors.horizontalCenter:parent.horizontalCenter; spacing:4*s
                                        Repeater {
                                            model: parent.parent.parent.parent.parent.diffs[index].stars
                                            Text { text:"★"; color:parent.parent.parent.parent.parent.parent.diffs[index].col; font.pixelSize:14*s }
                                        }
                                    }
                                    Text {
                                        width:parent.width; horizontalAlignment:Text.AlignHCenter; wrapMode:Text.Wrap
                                        text:parent.parent.parent.parent.diffs[index].desc
                                        color:"#88ffffff"; font.family:mainFont.name; font.pixelSize:12*s
                                    }
                                }
                            }
                            MouseArea {
                                id: diffMa; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                                onClicked: root.launchGame(index)
                            }
                            scale: diffMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration:150; easing.type:Easing.OutQuad } }
                        }
                    }
                }
            }
        }


        Text {
            id: errorMsg
            anchors.bottom:parent.bottom; anchors.bottomMargin:40*s
            anchors.right:parent.right; anchors.rightMargin:10*s
            text:""; color:"#ff4455"
            font.family:mainFont.name; font.pixelSize:14*s; font.weight:Font.Black; font.italic:true
        }
    }

    // Game Mode
    FocusScope {
        id: gameScreen; anchors.fill:parent; z:10000
        visible:root.gameActive; focus:root.gameActive
        onVisibleChanged: if (visible) gameScreen.forceActiveFocus()
        opacity:root.gameActive?1:0
        
        Behavior on opacity { NumberAnimation { duration:500 } }

        // Progress bar
        Rectangle {
            id: progressBg
            anchors.top:parent.top; anchors.left:parent.left; anchors.right:parent.right
            height:6*s; color:"#22ffffff"
            Rectangle {
                width:parent.width * Math.min(1.0, root.maniaHits/20.0)
                height:parent.height; color:root.accentColor
                Behavior on width { NumberAnimation { duration:300; easing.type:Easing.OutCubic } }
            }
        }

        // HP bar
        Rectangle {
            anchors.bottom:parent.bottom; anchors.left:parent.left; anchors.right:parent.right; height:8*s
            color:"#44000000"
            Rectangle {
                width:parent.width * root.maniaHealth; height:parent.height
                color: root.maniaHealth>0.3?"#ffffff":"#ff4444"
                Behavior on width { NumberAnimation { duration:200; easing.type:Easing.OutCubic } }
                layer.enabled:true; layer.effect:DropShadow { color:color; radius:12; samples:17; opacity:0.8 }
            }
        }

        // Score HUD
        Column {
            anchors.top:progressBg.bottom; anchors.topMargin:16*s
            anchors.right:parent.right; anchors.rightMargin:40*s; spacing:2*s
            Text {
                anchors.right:parent.right
                text:String(root.maniaScore).padStart(8,"0")
                color:"white"; font.family:mainFont.name; font.pixelSize:32*s; font.weight:Font.Black
                layer.enabled:true; layer.effect:DropShadow { color:"#88000000"; radius:4; samples:9; horizontalOffset:1*s; verticalOffset:1*s }
            }
            Text { anchors.right:parent.right; text:root.maniaAccuracy.toFixed(2)+"%"; color:"#ccffffff"; font.family:mainFont.name; font.pixelSize:14*s }
        }

        // Combo
        Column {
            anchors.bottom:parent.bottom; anchors.bottomMargin:90*s
            anchors.left:maniaField.left; anchors.leftMargin:-80*s
            spacing:0
            Text {
                id: comboText
                text:root.maniaCombo+"x"; color:"white"
                font.family:mainFont.name; font.pixelSize:44*s; font.weight:Font.Black
                NumberAnimation on scale { id:comboPopAnim; from:1.3; to:1.0; duration:150; easing.type:Easing.OutBack }
                layer.enabled:true; layer.effect:DropShadow { color:root.glowColor; radius:14; samples:17 }
            }
        }

        // Judgment counters
        Column {
            anchors.bottom:parent.bottom; anchors.bottomMargin:90*s
            anchors.right:maniaField.right; anchors.rightMargin:-80*s; spacing:2*s
            Text { text:root.maniaHits+" / 20 HITS"; color:"#aaffffff"; font.family:mainFont.name; font.pixelSize:12*s; anchors.right:parent.right }
            Row {
                anchors.right:parent.right; spacing:6*s
                Text { text:root.mania300s+"×"; color:root.accentColor; font.family:mainFont.name; font.pixelSize:11*s; font.weight:Font.Bold }
                Text { text:root.mania100s+"×"; color:root.glowColor;   font.family:mainFont.name; font.pixelSize:11*s; font.weight:Font.Bold }
                Text { text:root.mania50s+"×";  color:"#aaaaaa";         font.family:mainFont.name; font.pixelSize:11*s; font.weight:Font.Bold }
                Text { text:root.maniaMisses+"×"; color:"#ff4455";       font.family:mainFont.name; font.pixelSize:11*s; font.weight:Font.Bold }
            }
        }

        // Key hint label
        Text {
            anchors.top:progressBg.bottom; anchors.topMargin:16*s
            anchors.horizontalCenter:maniaField.horizontalCenter
            text:root.keyNames.join("   "); color:"#44ffffff"
            font.family:mainFont.name; font.pixelSize:14*s; font.letterSpacing:8*s; font.weight:Font.Black
        }

        // Playfield
        Item {
            id: maniaField
            anchors.horizontalCenter:parent.horizontalCenter
            anchors.top:progressBg.bottom
            anchors.bottom:parent.bottom; anchors.bottomMargin:8*s

            property real laneW: 72*s
            property real fieldW: settings.laneCount * laneW + (settings.laneCount-1)*2*s
            width: fieldW

            // Lane backgrounds
            Row {
                anchors.fill:parent; spacing:2*s
                Repeater {
                    model:settings.laneCount
                    Rectangle {
                        width:maniaField.laneW; height:parent.height
                        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.05)
                        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
                        border.width:1*s
                    }
                }
            }

            // Scan Lines
            Repeater {
                model:12
                Rectangle {
                    anchors.left:parent.left; anchors.right:parent.right
                    y: index * (maniaField.height/12)
                    height:1; color:"#08ffffff"
                }
            }

            // Judgment line
            Rectangle {
                id: judgmentLine
                anchors.left:parent.left; anchors.right:parent.right
                anchors.bottom:parent.bottom; anchors.bottomMargin:70*s
                height:5*s; radius:2.5*s; color:root.accentColor; opacity:0.9
                layer.enabled:true; layer.effect:DropShadow { color:root.glowColor; radius:12; samples:17; spread:0.3; horizontalOffset:0; verticalOffset:0 }
            }

            // Hit Feedback

            // Notes container
            Item {
                id: notesContainer; anchors.fill:parent
            }

            // Feedback Container
            Item { id: feedbackContainer; anchors.fill:parent; z:100 }
        }

        // Pressed State
        property var lanePressed: [false, false, false, false]

        // Ready Text
        Text {
            id: readyText
            anchors.centerIn:parent; anchors.verticalCenterOffset:-80*s
            text:"PRESS  " + root.keyNames.join("  ") + "  TO PLAY!"
            color:"white"; font.family:mainFont.name; font.pixelSize:18*s; font.weight:Font.Black; font.letterSpacing:4*s
            property bool autoHidden: false
            opacity: (root.maniaHits===0 && root.gameActive && !autoHidden) ? 0.8 : 0
            Behavior on opacity { NumberAnimation { duration:400 } }
            layer.enabled:true; layer.effect:DropShadow { color:"black"; radius:8 }
            Timer {
                interval:1200; running:root.maniaHits===0 && root.gameActive; repeat:false
                onTriggered: readyText.autoHidden=true
            }
            Connections {
                target:root
                function onGameActiveChanged() { if(root.gameActive) readyText.autoHidden=false }
            }
        }

        // Keyboard Handling
        Keys.onPressed: function(event) {
            if (event.isAutoRepeat) return
            var keys = [settings.key0, settings.key1, settings.key2, settings.key3]
            for (var i=0; i<keys.length; i++) {
                if (event.key===keys[i]) {
                    event.accepted=true
                    var newArr = gameScreen.lanePressed.slice()
                    newArr[i]=true
                    gameScreen.lanePressed=newArr
                    root.tryHitLane(i)
                    return
                }
            }
        }
        Keys.onReleased: function(event) {
            if (event.isAutoRepeat) return
            var keys = [settings.key0, settings.key1, settings.key2, settings.key3]
            for (var i=0; i<keys.length; i++) {
                if (event.key===keys[i]) {
                    event.accepted=true
                    var newArr = gameScreen.lanePressed.slice()
                    newArr[i]=false
                    gameScreen.lanePressed=newArr
                    return
                }
            }
        }
    }

    // ── Win Flash ────────────────────────────────────────────────────────────
    Rectangle {
        id: winFlash; anchors.fill:parent; color:root.accentColor; z:9999; opacity:0
        NumberAnimation { id:loginTransition; target:winFlash; property:"opacity"; from:0; to:1; duration:600; easing.type:Easing.OutQuad }
    }

    // ── Win Sequence ─────────────────────────────────────────────────────────
    Timer {
        id: winCheckTimer; interval:200; repeat:true; running:false
        onTriggered: {
            if (root.gameActive && root.maniaHits>=20) {
                stop(); noteSpawnTimer.stop(); root.clearAllNotes(); winSequence.start()
            }
        }
    }

    SequentialAnimation {
        id: winSequence
        PauseAnimation { duration:400 }
        ScriptAction {
            script: {
                root.gameActive=false; root.loginSuccess=true; loginTransition.start()
            }
        }
        PauseAnimation { duration:800 }
        ScriptAction {
            script: {
                var uname=(userHelper.currentItem&&userHelper.currentItem.uLogin)?userHelper.currentItem.uLogin:userModel.lastUser
                sddm.login(uname, passField.text, root.sessionIndex)
            }
        }
    }

    // ── Fail Overlay ─────────────────────────────────────────────────────────
    SequentialAnimation {
        id: failSequence
        ScriptAction { script: { root.maniaFailed=true; noteSpawnTimer.stop() } }
        ParallelAnimation {
            NumberAnimation { target:gameScreen;  property:"opacity"; to:0.08; duration:500 }
            NumberAnimation { target:failOverlay; property:"opacity"; to:1;    duration:250 }
        }
    }

    // ── Fail Overlay ────────────────────────────────────────────────
    Rectangle {
        id: failOverlay
        anchors.fill:parent; color:Qt.rgba(0,0,0,0.95); opacity:0; z:10001; visible:opacity>0.01
        
        // Glitch Background
        Rectangle {
            anchors.fill:parent; color:"transparent"
            Rectangle { anchors.top:parent.top; width:parent.width; height:2*s; color:"#ff4444"; opacity:0.2 }
            Rectangle { anchors.bottom:parent.bottom; width:parent.width; height:2*s; color:"#ff4444"; opacity:0.2 }
        }

        Column {
            anchors.centerIn:parent; spacing:60*s; width:parent.width*0.9

            ManiaHeading {
                title: root.maniaFailed ? "FAILURE DETECTED" : "ACCESS DENIED"
                accent: "#ff4444"
            }

            Row {
                anchors.horizontalCenter:parent.horizontalCenter; spacing:20*s
                Repeater {
                    model: [
                        { label:"TRY AGAIN",    col:"#ff4444", act: function(){ root.randomizeTheme(); failOverlay.opacity=0; resetGame(); root.startGame() } },
                        { label:"LOWER DIFF",   col:"#F1C40F", act: function(){ root.randomizeTheme(); failOverlay.opacity=0; resetGame(); root.showingDiff=true } },
                        { label:"SETTINGS",     col:"#3498DB", act: function(){ failOverlay.opacity=0; root.showingSettings=true } },
                        { label:"ABORT",        col:"#ffffff", act: function(){ root.randomizeTheme(); failOverlay.opacity=0; resetGame(); root.gameActive=false; passField.text=""; passField.forceActiveFocus() } }
                    ]
                    Rectangle {
                        width:180*s; height:90*s; radius:10*s
                        color: fMa.containsMouse ? Qt.rgba(modelData.col.r, modelData.col.g, modelData.col.b, 0.2) : "#0a0a0a"
                        border.color: fMa.containsMouse ? modelData.col : "#22ffffff"
                        border.width:2*s
                        Text {
                            anchors.centerIn:parent; text:modelData.label
                            color:fMa.containsMouse?modelData.col:"white"
                            font.family:mainFont.name; font.pixelSize:16*s; font.weight:Font.Black; font.letterSpacing:2*s
                        }
                        MouseArea {
                            id: fMa; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                            onClicked: modelData.act()
                        }
                        scale: fMa.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration:150 } }
                    }
                }
            }
        }
    }

    // ── HP Drain ─────────────────────────────────────────────────────────────
    Timer {
        id: hpDrainTimer; interval:100; repeat:true; running:root.gameActive && !root.maniaFailed
        onTriggered: {
            root.maniaHealth=Math.max(0, root.maniaHealth-0.0006)
            if (root.maniaHealth<=0.001) failSequence.start()
        }
    }

    // ── Note Spawner ─────────────────────────────────────────────────────────
    Timer {
        id: noteSpawnTimer; interval:500; repeat:true; running:false
        property int patternIdx: 0
        property var pattern: []
        onTriggered: {
            if (!root.gameActive || root.maniaHits>=20) { stop(); return }
            spawnNote()
            var baseInterval = 200 + Math.random()*300
            interval = Math.max(120, baseInterval / settings.noteDensity)
            restart()
        }
    }

    // ── Note Component ────────────────────────────────────────────────────────
    Component {
        id: noteComp
        Item {
            id: note
            property int  lane:       0
            property real fallDuration: 1200
            property real spawnTime:  0
            property bool hit:        false
            property bool missed:     false
            property real laneX:      0
            property real laneW:      72*s
            property real judgY:      0   // Hit line

            width: laneW - 4*s
            height: 28*s
            x: laneX + 2*s
            y: -height

            // Note body
            Rectangle {
                anchors.fill:parent; radius:6*s
                color:root.accentColor; opacity:0.92
                gradient: Gradient {
                    GradientStop { position:0.0; color:Qt.rgba(1,1,1,0.3) }
                    GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.1) }
                }
                border.color:"white"; border.width:1.5*s
                layer.enabled:true; layer.effect:DropShadow { color:root.glowColor; radius:8; samples:13; spread:0.2 }
            }

            // Hit burst
            Rectangle {
                id: noteBurst; anchors.centerIn:parent
                width:note.laneW; height:note.laneW; radius:note.laneW/2
                color:root.accentColor; opacity:0
                NumberAnimation on scale   { id:burstScaleAnim;   from:0.5; to:2.0; duration:300; easing.type:Easing.OutQuad }
                NumberAnimation on opacity { id:burstOpacityAnim; from:0.8; to:0.0; duration:300; easing.type:Easing.OutQuad }
            }

            // Fall Animation
            NumberAnimation on y {
                id: fallAnim
                from: -note.height; to: root.height + 100*s
                duration: note.fallDuration * ((root.height + 100*s + note.height) / (note.judgY + note.height))
                easing.type:Easing.Linear; running:true
            }

            // Fade Effect
            Behavior on opacity { NumberAnimation { duration: 250 } }

            // Miss check timer
            Timer {
                id: missCheckTimer
                // Trigger Miss
                interval: note.fallDuration + 150; running:true
                onTriggered: {
                    if (!note.hit && !note.missed) {
                        note.missed=true
                        onNoteMiss(note.lane)
                        note.opacity = 0
                        // Destroy after fade
                        destroyTimer.start()
                    }
                }
            }
            Timer { id: destroyTimer; interval: 250; onTriggered: note.destroy() }

            function tryHit() {
                if (hit || missed) return false
                
                // Entry Position
                var lineY = judgY
                var noteCenter = note.y + note.height / 2
                var dist = Math.abs(noteCenter - lineY)

                // Distance Check
                // Casual Tolerance
                if (dist > note.height * 2.0) return false

                // Multi Judgment
                var j = 0
                if      (dist < note.height * 0.5) j=300
                else if (dist < note.height * 1.2) j=100
                else                               j=50

                hit=true; missed=false
                missCheckTimer.stop(); fallAnim.stop()
                onNoteHit(lane, j, note.x+note.width/2, judgY)
                burstScaleAnim.restart(); burstOpacityAnim.restart()
                Qt.callLater(function(){ note.destroy() })
                return true
            }
        }
    }

    // ── Feedback Component ───────────────────────────────────────────────
    Component {
        id: feedbackComp
        Text {
            id: fbTxt
            property color col: "white"
            color:col; font.family:mainFont.name; font.pixelSize:24*s; font.weight:Font.Black
            layer.enabled:true; layer.effect:DropShadow { color:Qt.rgba(col.r,col.g,col.b,0.7); radius:8; samples:13 }
            NumberAnimation on y   { from:y;   to:y-50*s; duration:600; easing.type:Easing.OutCubic }
            NumberAnimation on opacity { from:1; to:0;     duration:600; easing.type:Easing.InCubic }
            onOpacityChanged: if(opacity<=0.01) fbTxt.destroy()
        }
    }

    // ── Game Logic ────────────────────────────────────────────────────────────
    function spawnNote() {
        if (!root.gameActive) return
        var lCount = (settings && settings.laneCount > 0) ? settings.laneCount : 4
        var lane = Math.floor(Math.random() * lCount)
        var laneW = maniaField.laneW
        var laneSpacing = 2*s
        var laneX = lane*(laneW+laneSpacing)
        var nSpeed = (settings && settings.noteSpeed > 0.1) ? settings.noteSpeed : 1.0
        var judgY = maniaField.height - 70*s
        var duration = Math.max(500, 1100/nSpeed)

        var n = noteComp.createObject(notesContainer, {
            lane:     lane,
            laneX:    laneX,
            laneW:    laneW,
            judgY:    judgY,
            fallDuration: duration,
            spawnTime: Date.now()
        })

        if (n) {
            // Track notes
            var arr = root.laneNotes[lane].slice()
            arr.push(n)
            root.laneNotes[lane] = arr

            n.Component.destruction.connect(function() {
                var a = root.laneNotes[lane].slice()
                var idx = a.indexOf(n)
                if (idx>=0) a.splice(idx,1)
                root.laneNotes[lane]=a
            })
        }
    }

    function tryHitLane(lane) {
        var notes = root.laneNotes[lane]
        for (var i=0; i<notes.length; i++) {
            var n = notes[i]
            if (n && !n.hit && !n.missed) {
                if (n.tryHit()) return
            }
        }
    }

    function onNoteHit(lane, judgment, fx, fy) {
        root.maniaHits++
        root.maniaCombo++
        if (root.maniaCombo>root.maniaMaxCombo) root.maniaMaxCombo=root.maniaCombo

        var hpGain = judgment===300?0.08:judgment===100?0.04:0.01
        root.maniaHealth=Math.min(1.0, root.maniaHealth+hpGain)

        if      (judgment===300) root.mania300s++
        else if (judgment===100) root.mania100s++
        else                     root.mania50s++

        var mult = 1.0 + root.maniaCombo/30.0
        root.maniaScore += Math.round(judgment * mult)
        updateAccuracy(); comboPopAnim.restart()

        var col = judgment===300?root.accentColor:(judgment===100?root.glowColor:"#999999")
        var lbl = judgment===300?"PERFECT":judgment===100?"GOOD":"MEH"
        feedbackComp.createObject(feedbackContainer, {
            text:lbl, col:col,
            x:fx-30*s, y:maniaField.y + fy - 60*s
        })
    }

    function onNoteMiss(lane) {
        root.maniaCombo=0; root.maniaMisses++
        root.maniaHealth=Math.max(0, root.maniaHealth-root.missPenalty)
        updateAccuracy()
        if (root.maniaHealth<=0.01 && !root.maniaFailed) failSequence.start()
    }

    function updateAccuracy() {
        var total=root.mania300s+root.mania100s+root.mania50s+root.maniaMisses
        if (total===0) { root.maniaAccuracy=100.0; return }
        root.maniaAccuracy=(300.0*root.mania300s+100.0*root.mania100s+50.0*root.mania50s)/(300.0*total)*100.0
    }

    function resetGame() {
        // Stop all game timers immediately
        noteSpawnTimer.stop()
        gameStartDelay.stop()
        winCheckTimer.stop()

        root.gameActive=false; root.maniaFailed=false
        root.maniaHealth=1.0; root.maniaHits=0; root.maniaMisses=0
        root.mania300s=0; root.mania100s=0; root.mania50s=0
        root.maniaCombo=0; root.maniaMaxCombo=0; root.maniaScore=0
        root.maniaAccuracy=100.0;
        root.clearAllNotes()
    }

    function clearAllNotes() {
        for (var i=0; i<notesContainer.children.length; i++) {
            notesContainer.children[i].destroy()
        }
        root.laneNotes=[[], [], [], []]
    }

    function startGame() {
        errorMsg.text=""
        root.maniaScore=0; root.maniaCombo=0; root.maniaMaxCombo=0
        root.maniaHits=0; root.maniaMisses=0; root.mania300s=0; root.mania100s=0; root.mania50s=0
        root.maniaAccuracy=100.0; root.maniaHealth=1.0; root.laneNotes=[[], [], [], []]
        root.gameActive=true
        gameScreen.forceActiveFocus()
        if (!settings.noteSpeed || settings.noteSpeed < 0.1) settings.noteSpeed = 1.0
        if (!settings.noteDensity || settings.noteDensity < 0.1) settings.noteDensity = 1.0
        gameStartDelay.start(); winCheckTimer.start()
    }

    Timer {
        id: gameStartDelay; interval:700
        onTriggered: { noteSpawnTimer.interval=500; noteSpawnTimer.start(); spawnNote() }
    }

    function doAction() {
        if (root.gameMode) root.showingDiff=true; else doLogin()
    }

    function randomizeTheme() {
        var old=root.bgIndex
        while (root.bgIndex===old && root.bgFiles.length>1)
            root.bgIndex=Math.floor(Math.random()*root.bgFiles.length)
    }

    function launchGame(level) {
        root.showingDiff=false
        if (level===0) { settings.noteSpeed=0.6;  settings.noteDensity=0.7;  root.missPenalty=0.15 }
        if (level===1) { settings.noteSpeed=0.9;  settings.noteDensity=0.9;  root.missPenalty=0.22 }
        if (level===2) { settings.noteSpeed=1.2;  settings.noteDensity=1.2;  root.missPenalty=0.35 }
        if (level===3) { settings.noteSpeed=1.5;  settings.noteDensity=1.4;  root.missPenalty=0.50 }
        root.startGame()
    }

    function doLogin() {
        errorMsg.text=""; root.loginPending=true
        var uname=(userHelper.currentItem&&userHelper.currentItem.uLogin)?userHelper.currentItem.uLogin:userModel.lastUser
        sddm.login(uname, passField.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.gameActive=false; root.loginSuccess=false
            noteSpawnTimer.stop(); gameStartDelay.stop(); winCheckTimer.stop(); winSequence.stop()
            winFlash.opacity=0; root.laneNotes=[[], [], [], []]
            errorMsg.text="✖  WRONG PASSWORD — TRY AGAIN"
            passField.text=""; passField.forceActiveFocus()
            errorShake.restart()
        }
    }

    SequentialAnimation {
        id: errorShake
        NumberAnimation { target:errorMsg; property:"anchors.rightMargin"; from:-8*s; to:8*s;  duration:60 }
        NumberAnimation { target:errorMsg; property:"anchors.rightMargin"; from:8*s;  to:-6*s; duration:60 }
        NumberAnimation { target:errorMsg; property:"anchors.rightMargin"; from:-6*s; to:4*s;  duration:60 }
        NumberAnimation { target:errorMsg; property:"anchors.rightMargin"; to:0;                duration:60 }
    }

    // Settings Overlay
    Rectangle {
        id: settingsOverlay
        anchors.fill:parent; color:Qt.rgba(0,0,0,0.98); z:20000
        visible:opacity>0.01; opacity:root.showingSettings?1:0
        focus: root.showingSettings
        
        Keys.onPressed: function(event) {
            if (root.bindingIdx !== -1) {
                var k = event.key
                if      (root.bindingIdx === 0) settings.key0 = k
                else if (root.bindingIdx === 1) settings.key1 = k
                else if (root.bindingIdx === 2) settings.key2 = k
                else if (root.bindingIdx === 3) settings.key3 = k
                root.bindingIdx = -1
                event.accepted = true
            }
        }

        Behavior on opacity { NumberAnimation { duration:300 } }
        MouseArea { anchors.fill:parent; hoverEnabled:true; onClicked: { root.showingSettings=false; root.bindingIdx=-1 } }

        Column {
            anchors.centerIn:parent; spacing:30*s; width:parent.width*0.9

            // Settings Heading
                ManiaHeading {
                    title: "MODIFIERS & BINDINGS"
                }

            // Keyboard Preview
            Item {
                anchors.horizontalCenter:parent.horizontalCenter
                width:450*s; height:120*s
                Row {
                    anchors.centerIn:parent; spacing:12*s
                    Repeater {
                        model: 4
                        Rectangle {
                            width:85*s; height:85*s; radius:10*s
                            color: root.bindingIdx === index ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3) : "#111111"
                            border.color: root.bindingIdx === index ? "white" : root.accentColor; border.width:3*s
                            layer.enabled:true; layer.effect:DropShadow { color:root.glowColor; radius:10; samples:13; opacity:0.5 }
                            Text {
                                anchors.centerIn:parent; text: root.bindingIdx === index ? "?" : root.keyNames[index]
                                color:"white"; font.family:mainFont.name; font.pixelSize:36*s; font.weight:Font.Black
                            }
                            // Key Decoration
                            Rectangle {
                                anchors.bottom:parent.bottom; anchors.horizontalCenter:parent.horizontalCenter
                                width:parent.width-20*s; height:6*s; radius:3*s; color:root.accentColor; anchors.bottomMargin:8*s
                            }
                            MouseArea {
                                anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                                onClicked: { root.bindingIdx = index; settings.preset = -1 }
                            }
                        }
                    }
                }
                Text {
                    anchors.top:parent.bottom; anchors.topMargin:10*s; anchors.horizontalCenter:parent.horizontalCenter
                    text: root.bindingIdx !== -1 ? "PRESS ANY KEY TO BIND..." : "CLICK A BOX TO CUSTOMIZE BINDINGS"
                    color: root.bindingIdx !== -1 ? root.accentColor : "#888"
                    font.family:mainFont.name; font.pixelSize:11*s; font.weight:Font.Black; font.letterSpacing:2*s
                }
            }

            Item { width:1; height:15*s }

            // Presets Selection
            Row {
                anchors.horizontalCenter:parent.horizontalCenter; spacing:15*s
                Repeater {
                    model: [
                        { name:"DF JK (Modern)", keys:[Qt.Key_D, Qt.Key_F, Qt.Key_J, Qt.Key_K], label:"D F J K" },
                        { name:"SD KL (Standard)", keys:[Qt.Key_S, Qt.Key_D, Qt.Key_K, Qt.Key_L], label:"S D K L" },
                        { name:"AS KL (Classic)", keys:[Qt.Key_A, Qt.Key_S, Qt.Key_K, Qt.Key_L], label:"A S K L" },
                        { name:"Arrow Keys", keys:[Qt.Key_Left, Qt.Key_Down, Qt.Key_Up, Qt.Key_Right], label:"← ↓ ↑ →" }
                    ]
                    Rectangle {
                        width:180*s; height:100*s; radius:12*s
                        color: settings.preset === index ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2) : "#0a0a0a"
                        border.color: settings.preset === index ? root.accentColor : "#222"
                        border.width:2*s
                        Column {
                            anchors.centerIn:parent; spacing:6*s
                            Text { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.name; color:"white"; font.family:mainFont.name; font.pixelSize:13*s; font.weight:Font.Bold }
                            Text { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.label; color:root.accentColor; font.family:mainFont.name; font.pixelSize:18*s; font.weight:Font.Black }
                        }
                        MouseArea {
                            anchors.fill:parent; cursorShape:Qt.PointingHandCursor
                            onClicked: {
                                settings.preset = index
                                settings.key0 = modelData.keys[0]; settings.key1 = modelData.keys[1]
                                settings.key2 = modelData.keys[2]; settings.key3 = modelData.keys[3]
                                root.bindingIdx = -1
                            }
                        }
                    }
                }
            }

            // Confirm Button
            Item {
                anchors.horizontalCenter:parent.horizontalCenter
                width:300*s; height:70*s
                Rectangle {
                    anchors.fill:parent; radius:35*s
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position:0.0; color:exitMa.containsMouse?root.accentColor:Qt.rgba(1,1,1,0.06) }
                        GradientStop { position:1.0; color:exitMa.containsMouse?Qt.lighter(root.accentColor,1.2):Qt.rgba(1,1,1,0.12) }
                    }
                    border.color: exitMa.containsMouse ? "white" : Qt.rgba(1,1,1,0.2); border.width: 1.5*s
                    Behavior on radius { NumberAnimation { duration:200 } }
                }
                Text {
                    anchors.centerIn:parent; text:"CONFIRM CHANGES"
                    color:"white"; font.family:mainFont.name; font.pixelSize:18*s; font.weight:Font.Black; font.letterSpacing:4*s
                }
                MouseArea {
                    id: exitMa; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                    onClicked: {
                        var wasFailing = root.maniaFailed
                        root.showingSettings=false
                        if (wasFailing) {
                            resetGame()
                            root.showingDiff = true
                        }
                    }
                }
                scale: exitMa.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration:200; easing.type:Easing.OutBack } }
            }
        }
    }
}