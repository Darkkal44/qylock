import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    id: root

    // App Settings
    QtObject {
        id: settings
        property int key1: Qt.Key_Z
        property int key2: Qt.Key_X
        property bool use12HourTime: false
        property int requiredHits: 20
        property real osuSpeed:   0.7
        property real osuDensity: 0.8
        property real sliderChance: 0.3
    }

    readonly property real s: Screen.height / 768
    width: Screen.width
    color: "#0a0a0c"

    // Rhythm Gate Mode
    readonly property bool gameMode: config.gameMode !== "menu"

    // Menu Item
    component OsuMenuItem: Item {
        id: menuItem
        property string label: ""
        property color iconColor: "#662D91"
        property real s: root.s
        signal activated()

        width: 460*s; height: 75*s
        
        property real xOffset: menuMa.containsMouse ? 35*s : 0
        x: xOffset
        Behavior on xOffset { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        // Button Content
        Item {
            id: buttonContent
            anchors.fill: parent
            
            // Trapezoid Transform
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(1, -0.32, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
            }

            // Backdrop Shadow
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 20*s; anchors.topMargin: 4*s
                radius: 35*s
                color: "#22000000"
            }

            // Pill Shape
            Rectangle {
                id: mainRect
                anchors.fill: parent
                radius: 35*s
                gradient: Gradient { 
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: menuMa.containsMouse ? "#ffffff" : "#4A247A" }
                    GradientStop { position: 1.0; color: menuMa.containsMouse ? "#e8e8e8" : "#8E44AD" }
                }
                border.color: menuMa.containsMouse ? "white" : "#33ffffff"
                border.width: 2*s
                layer.enabled: true
                layer.effect: DropShadow { color: "#88000000"; radius: 10; samples: 21; spread: 0.1 }
            }

            // Click Flash
            Rectangle {
                id: clickFlash
                anchors.fill: parent; radius: 35*s
                color: "white"; opacity: 0
            }
        }

        // Label Text
        Text {
            anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -2*s
            anchors.left: parent.left; anchors.leftMargin: 140*s
            text: menuItem.label
            color: menuMa.containsMouse ? menuItem.iconColor : "white"
            font.family: mainFont.name; font.pixelSize: 42*s; font.weight: Font.Black; font.italic: true
            layer.enabled: true; layer.effect: DropShadow { color: "#44000000"; radius: 4 }
        }

        // Input Handling
        MouseArea {
            id: menuMa
            anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onPressed: clickAnim.restart()
            onClicked: menuItem.activated()
        }

        // Feedback Animation
        SequentialAnimation {
            id: clickAnim
            ParallelAnimation {
                NumberAnimation { target: menuItem; property: "scale"; to: 0.94; duration: 60; easing.type: Easing.OutQuad }
                NumberAnimation { target: clickFlash; property: "opacity"; to: 0.4; duration: 60 }
            }
            ParallelAnimation {
                NumberAnimation { target: menuItem; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                NumberAnimation { target: clickFlash; property: "opacity"; to: 0; duration: 200 }
            }
        }
    }

    // App State
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex:    (userModel    && userModel.lastIndex    >= 0) ? userModel.lastIndex    : 0
    property bool gameActive:    false
    property bool loginPending:  false
    property bool loginSuccess:  false

    // Game State
    property int  osuScore:    0
    property int  osuCombo:    0
    property int  osuMaxCombo: 0
    property int  osuHits:     0
    property int  osuMisses:   0
    property int  osu300s:     0
    property int  osu100s:     0
    property int  osu50s:      0
    property real osuAccuracy: 100.0
    property real osuHealth:   1.0
    property bool osuFailed:   false
    property int  osuCircleCount: 0
    property var  activeCircles: []

    // Hit Windows
    readonly property real hitWindow300: 80
    readonly property real hitWindow100: 140
    readonly property real hitWindow50:  200

    // Theme Backgrounds
    property int bgIndex: Math.floor(Math.random() * 7)

    readonly property var bgFiles: [
        "background/A Glow.jpg",
        "background/B Glow.jpg",
        "background/C Glow.jpg",
        "background/D Glow.jpg",
        "background/E Glow.jpg",
        "background/F Glow.jpg",
        "background/G Glow.jpg"
    ]

    // Color Schemes
    readonly property var bgSchemes: [
        { accent: "#ff4499", secondary: "#cc0066", glow: "#ff66bb", dark: "#1a0011", text: "#ffe0ef" },
        { accent: "#00ccff", secondary: "#0088cc", glow: "#44eeff", dark: "#001122", text: "#ddf6ff" },
        { accent: "#ff8800", secondary: "#cc5500", glow: "#ffbb44", dark: "#1a0e00", text: "#fff0dd" },
        { accent: "#88ff00", secondary: "#55bb00", glow: "#bbff55", dark: "#0a1400", text: "#f0ffe0" },
        { accent: "#aa44ff", secondary: "#7700cc", glow: "#cc88ff", dark: "#110022", text: "#f0e8ff" },
        { accent: "#00ffbb", secondary: "#00aa80", glow: "#55ffdd", dark: "#001a14", text: "#dffff7" },
        { accent: "#ff3355", secondary: "#cc1133", glow: "#ff7788", dark: "#1a0008", text: "#ffe8ec" }
    ]

    readonly property var scheme: bgSchemes[bgIndex]
    readonly property color accentColor:    scheme.accent
    readonly property color secondaryColor: scheme.secondary
    readonly property color glowColor:      scheme.glow
    readonly property color darkColor:      scheme.dark
    readonly property color textColor:      scheme.text

    // Assets
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader {
        id: mainFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }
    TextConstants { id: textConstants }

    // SDDM Bridges
    ListView {
        id: userHelper; model: userModel; currentIndex: root.userIndex
        width: 1; height: 1; opacity: 0
        delegate: Item {
            property string uName:  model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }
    ListView {
        id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex
        width: 1; height: 1; opacity: 0
        delegate: Item { property string sName: model.name || "" }
    }

    // Autofocus
    Timer { interval: 300; running: true; onTriggered: passField.forceActiveFocus() }

    // Fade In
    property real uiOpacity: 0
    Component.onCompleted: {
        fadeIn.start()
    }
    NumberAnimation {
        id: fadeIn; target: root; property: "uiOpacity"
        from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic
    }

    // Background Image
    Image {
        id: bgImage
        anchors.fill: parent
        source: root.bgFiles[root.bgIndex]
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.loginSuccess ? 0.15 : (root.gameActive ? 0.3 : 0.65)
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
    }

    // Dark Tint
    Rectangle {
        anchors.fill: parent
        color: root.darkColor
        opacity: root.gameActive ? 0.85 : 0.45
        Behavior on opacity { NumberAnimation { duration: 800 } }
    }

    // Vignette
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#aa000000" }
        }
    }

    // Login Screen
    Item {
        id: loginScreen
        anchors.fill: parent
        opacity: root.gameActive ? 0 : root.uiOpacity
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        // Top HUD
        Item {
            anchors.left: parent.left; anchors.top: parent.top; anchors.right: parent.right; height: 120*s
            z: 50

            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.right: parent.right; height: 80*s
                color: "#aa000000"
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1*s; color: "#22ffffff" }
            }

            // User Profile
            Item {
                id: userProfileWidget
                anchors.left: parent.left; anchors.top: parent.top
                anchors.leftMargin: 20 * s; anchors.topMargin: 2 * s
                width: 450 * s; height: 100 * s

                // Animation Wrapper
                Item {
                    id: userCardContent
                    anchors.fill: parent

                    Text {
                        id: rankWatermark
                        anchors.left: userAvatar.right; anchors.leftMargin: 15*s
                        anchors.top: parent.top; anchors.topMargin: -8*s
                        text: (root.userIndex + 1) + "71"
                        color: "#1affffff"
                        font.family: mainFont.name; font.pixelSize: 84*s; font.weight: Font.Black
                    }

                    Image {
                        id: userAvatar
                        anchors.left: parent.left; anchors.top: parent.top
                        width: 76*s; height: 76*s
                        source: (userHelper.currentItem && userHelper.currentItem.uLogin) 
                                ? Qt.resolvedUrl("avatars/" + userHelper.currentItem.uLogin + ".png") 
                                : Qt.resolvedUrl("pfp.png")
                        fillMode: Image.PreserveAspectCrop
                        onStatusChanged: {
                            if (status === Image.Error && source != Qt.resolvedUrl("pfp.png")) {
                                source = Qt.resolvedUrl("pfp.png")
                            }
                        }
                    }

                    Column {
                        anchors.left: userAvatar.right; anchors.leftMargin: 12*s
                        anchors.top: parent.top; anchors.topMargin: 4*s
                        spacing: -2*s

                        Text {
                            text: (userHelper.currentItem ? userHelper.currentItem.uName : "Player").toUpperCase()
                            color: "white"
                            font.family: mainFont.name; font.pixelSize: 20*s; font.weight: Font.Normal
                            layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 4 }
                        }
                        Text { text: "Performance: 6," + (userHelper.currentIndex + 0.48).toFixed(2).replace(".","") + "pp"; color: "#bbbbbb"; font.family: mainFont.name; font.pixelSize: 11*s }
                        Text { text: "Accuracy: 98.48%"; color: "#bbbbbb"; font.family: mainFont.name; font.pixelSize: 11*s }

                        Row {
                            spacing: 8*s; anchors.topMargin: 4*s
                            Text { text: "Lv100"; color: "white"; font.family: mainFont.name; font.pixelSize: 11*s; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: 140*s; height: 6*s; radius: 3*s; color: "#44ffffff"
                                Rectangle { width: parent.width * 0.85; height: parent.height; radius: 3*s; color: root.accentColor }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                SequentialAnimation {
                    id: userSwitchAnim
                    ParallelAnimation {
                        NumberAnimation { target: userCardContent; property: "opacity"; to: 0; duration: 70; easing.type: Easing.InQuad }
                        NumberAnimation { target: userCardContent; property: "scale"; to: 0.75; duration: 70; easing.type: Easing.InQuad }
                        NumberAnimation { target: userCardContent; property: "x"; to: -50 * s; duration: 70; easing.type: Easing.InQuad }
                    }
                    PropertyAction { target: userCardContent; property: "x"; value: 80 * s }
                    ParallelAnimation {
                        NumberAnimation { target: userCardContent; property: "opacity"; to: 1.0; duration: 550; easing.type: Easing.OutElastic; easing.period: 0.6; easing.amplitude: 1.0 }
                        NumberAnimation { target: userCardContent; property: "scale"; to: 1.0; duration: 550; easing.type: Easing.OutElastic; easing.period: 0.6; easing.amplitude: 1.0 }
                        NumberAnimation { target: userCardContent; property: "x"; to: 0; duration: 550; easing.type: Easing.OutElastic; easing.period: 0.6; easing.amplitude: 1.0 }
                    }
                }

                Connections {
                    target: root
                    function onUserIndexChanged() { userSwitchAnim.restart() }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % Math.max(1, userModel.count)
                }
            }

            // Session Widget
            Item {
                id: sessionWidget
                anchors.left: userProfileWidget.right; anchors.leftMargin: 40*s; anchors.top: parent.top; anchors.topMargin: 15*s
                width: 200*s; height: 100*s

                Column {
                    spacing: 2*s
                    Text {
                        text: "ENVIRONMENT"; color: "#99bbbbbb"; font.family: mainFont.name; font.pixelSize: 9*s; font.weight: Font.Black; font.letterSpacing: 2*s
                    }
                    Text {
                        text: sessionHelper.currentItem ? sessionHelper.currentItem.sName : "Default"
                        color: "white"
                        font.family: mainFont.name; font.pixelSize: 22*s; font.weight: Font.DemiBold
                        layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 4; samples: 9 }
                    }
                }
            }

            // Clock
            Item {
                anchors.top: parent.top; anchors.topMargin: 12*s
                anchors.right: parent.right; anchors.rightMargin: 25*s
                width: 250*s; height: 60*s

                Column {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    spacing: 4*s

                    Row {
                        anchors.right: parent.right; spacing: 14*s
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "CURRENT"; color: "#99bbbbbb"; font.family: mainFont.name; font.pixelSize: 9*s; anchors.right: parent.right; font.weight: Font.Black; font.letterSpacing: 1.5*s }
                            Text { text: "TIME"; color: "#99bbbbbb"; font.family: mainFont.name; font.pixelSize: 9*s; anchors.right: parent.right; font.weight: Font.Black; font.letterSpacing: 1.5*s }
                        }
                        Text {
                            property string timeStr: Qt.formatTime(new Date(), "HH:mm")
                            Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.timeStr = Qt.formatTime(new Date(), "HH:mm") }
                            text: timeStr
                            color: "white"; font.family: mainFont.name; font.pixelSize: 32*s; font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true; layer.effect: DropShadow { color: "#88000000"; radius: 4 }
                        }
                    }
                }
            }
        }

        // Main Menu
        Item {
            id: mainMenuWrapper
            anchors.fill: parent
            property bool menuExpanded: false

            MouseArea {
                anchors.fill: parent
                enabled: mainMenuWrapper.menuExpanded
                onClicked: mainMenuWrapper.menuExpanded = false
            }

        // Main Cookie
        Item {
            id: osuBtnArea
            z: 10
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: mainMenuWrapper.menuExpanded ? -220*s : 0
            Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 500; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.9 } }
            width:  340 * s
            height: 340 * s

            // Pink Round Button
            Rectangle {
                id: mainRoundButton
                anchors.centerIn: parent
                width: parent.width; height: parent.height; radius: width/2
                color: "#ff66aa"
                clip: true
                
                // Triangle Pattern
                Item {
                    id: triangleContainer
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: mainRoundButton.width - 25*s
                            height: width; radius: width/2
                            anchors.centerIn: parent
                        }
                    }

                    Repeater {
                        model: 18
                        Text {
                            x: Math.random() * (300 * s) + 20 * s
                            y: Math.random() * (300 * s) + 20 * s
                            text: "▲"
                            color: "white"
                            opacity: Math.random() * 0.12 + 0.04
                            font.pixelSize: (Math.random() * 90 + 30) * s
                            rotation: Math.random() * 360
                            
                            NumberAnimation on y {
                                from: y; to: y - (50 * s); duration: 8000 + Math.random() * 4000
                                loops: Animation.Infinite; running: true
                            }
                        }
                    }
                }

                    // Inner border glow
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4*s; radius: width/2
                        color: "transparent"; border.color: Qt.rgba(1,1,1,0.1); border.width: 10*s
                    }

                    // White Border
                    border.color: "white"; border.width: 12.5*s

                    layer.enabled: true
                    layer.effect: DropShadow { color: "#88000000"; radius: 18; samples: 25; spread: 0.1 }

                    property real hoverScale: menuMa_global.containsMouse ? 1.08 : 1.0
                    scale: hoverScale * innerPulse.scaleVal
                    Behavior on hoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    
                    QtObject { id: innerPulse; property real scaleVal: 1.0 }
                    SequentialAnimation {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { target: innerPulse; property: "scaleVal"; from: 1.0; to: 1.03; duration: 450; easing.type: Easing.OutQuad }
                        NumberAnimation { target: innerPulse; property: "scaleVal"; from: 1.03; to: 1.0; duration: 450; easing.type: Easing.InQuad }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -7 * s
                        text: "osu!"
                        color: "white"
                        font.family: mainFont.name
                        font.pixelSize: 140 * s
                        font.weight: Font.Black
                    }
                }

                // Ripple Rings
                Repeater {
                    model: 2
                    Rectangle {
                        anchors.centerIn: parent; width: parent.width; height: parent.height; radius: width/2
                        color: "transparent"; border.color: "white"; border.width: 4*s
                        SequentialAnimation on scale { loops: Animation.Infinite
                            PauseAnimation { duration: index * 600 }
                            NumberAnimation { from: 0.95; to: 1.5; duration: 1200; easing.type: Easing.OutQuad } }
                        SequentialAnimation on opacity { loops: Animation.Infinite
                            PauseAnimation { duration: index * 600 }
                            NumberAnimation { from: 0.6; to: 0.0; duration: 1200; easing.type: Easing.OutQuad } }
                    }
                }

                MouseArea {
                    id: menuMa_global
                    anchors.centerIn: parent
                    width: parent.width; height: parent.height
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!mainMenuWrapper.menuExpanded) {
                            mainMenuWrapper.menuExpanded = true
                        } else {
                            if (passField.text.length > 0) doAction(); else passField.forceActiveFocus()
                        }
                    }
                }
            }

            // Sliding Menu
            Column {
                anchors.left: osuBtnArea.horizontalCenter
                anchors.leftMargin: mainMenuWrapper.menuExpanded ? 80*s : 0*s
                anchors.verticalCenter: osuBtnArea.verticalCenter
                spacing: 6*s
                z: 5
                opacity: mainMenuWrapper.menuExpanded ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on anchors.leftMargin { NumberAnimation { duration: 450; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.8 } }

                OsuMenuItem { s: root.s; label: "Play"; iconColor: "#662D91"; onActivated: { if (passField.text.length > 0) doAction(); else passField.forceActiveFocus() } }
                OsuMenuItem { s: root.s; label: "Session"; iconColor: "#4B247A"; onActivated: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionModel.count) }
                OsuMenuItem { s: root.s; label: "Reboot"; iconColor: "#34495E"; onActivated: sddm.reboot() }
                OsuMenuItem { s: root.s; label: "Poweroff"; iconColor: "#C0392B"; onActivated: sddm.powerOff() }
            }
        }        // Password Ribbon
        Item {
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.margins: 35 * s
            width: 400 * s; height: 55 * s

            // Slanted Ribbon Background
            Rectangle {
                anchors.fill: parent
                radius: 25 * s
                color: "#dd111111"
                border.color: passField.activeFocus ? "#FF73B3" : "#22ffffff"
                border.width: passField.activeFocus ? 2.5 * s : 1.5 * s
                
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.28, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                layer.enabled: true
                layer.effect: DropShadow { color: "#aa000000"; radius: 10; samples: 17; spread: 0.1 }
                
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            Row {
                anchors.fill: parent; anchors.leftMargin: 45 * s; anchors.rightMargin: 25 * s
                spacing: 15 * s

                Text {
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    text: "PASSWORD"
                    color: passField.activeFocus ? "#FF73B3" : "white"
                    font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.Black; font.italic: true
                    opacity: passField.activeFocus ? 1.0 : 0.6
                }

                Rectangle { width: 1 * s; height: 20 * s; color: "#22ffffff"; anchors.verticalCenter: parent.verticalCenter }

                TextInput {
                    id: passField
                    width: parent.width - 150 * s
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    color: "transparent"
                    cursorVisible: false
                    cursorDelegate: Item {}
                    font.family: mainFont.name; font.pixelSize: 18 * s; font.weight: Font.Bold
                    echoMode: TextInput.Password
                    focus: true; Keys.onReturnPressed: if (text.length > 0) doAction()

                    // Placeholder
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "Enter password..."
                        color: "#33ffffff"; font.family: mainFont.name; font.pixelSize: 14 * s
                        visible: passField.text.length === 0
                    }

                    // Custom dots
                    Row {
                        id: dotsRow
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * s
                        Repeater {
                            model: passField.text.length
                            Rectangle {
                                width: 8 * s; height: 8 * s; radius: 4 * s; color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                NumberAnimation on scale { from: 0.5; to: 1.0; duration: 150; easing.type: Easing.OutBack }
                                layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 3 }
                            }
                        }
                    }

                    // Custom Animated Cursor
                    Rectangle {
                        width: 3 * s; height: 24 * s; radius: 1.5 * s
                        color: "#FF73B3"
                        visible: passField.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                        x: dotsRow.x + dotsRow.width + (dotsRow.width > 0 ? 8*s : 0)
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.2; duration: 500; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.2; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }

        Text {
            id: errorMsg
            anchors.bottom: parent.top; anchors.bottomMargin: 40*s
            anchors.right: parent.right; anchors.rightMargin: 10*s
            text: ""
            color: "#ff4455"
            font.family: mainFont.name; font.pixelSize: 14*s; font.weight: Font.Black; font.italic: true
            layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 4; samples: 9 }
        }
    }

    // Game Screen
    FocusScope {
        id: gameScreen
        anchors.fill: parent
        visible: root.gameActive
        focus: root.gameActive
        opacity: root.gameActive ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        // Progress Bar
        Item {
            id: progressBarArea
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 6 * s

            Rectangle {
                anchors.fill: parent; color: "#22ffffff"
            }
            Rectangle {
                width: parent.width * Math.min(1.0, root.osuHits / settings.requiredHits)
                height: parent.height; color: root.accentColor
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                layer.enabled: true
                layer.effect: DropShadow {
                    color: root.glowColor; radius: 8; samples: 13; spread: 0.3
                    horizontalOffset: 0; verticalOffset: 0
                }
            }
        }

        // HP Bar
        Item {
            id: hpBarArea
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 8 * s

            Rectangle {
                anchors.fill: parent; color: "#44000000"
            }
            Rectangle {
                width: parent.width * root.osuHealth
                height: parent.height; color: root.osuHealth > 0.3 ? "#fff" : "#ff4444"
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                layer.enabled: true
                layer.effect: DropShadow { color: color; radius: 12; samples: 17; opacity: 0.8 }
            }
        }

        // Score HUD
        Column {
            anchors.top: progressBarArea.bottom; anchors.topMargin: 16*s
            anchors.right: parent.right; anchors.rightMargin: 40*s
            spacing: 2*s

            Text {
                anchors.right: parent.right
                text: String(root.osuScore).padStart(8, "0")
                color: "white"; font.family: mainFont.name
                font.pixelSize: 32*s; font.weight: Font.Black; font.letterSpacing: -1*s
                layer.enabled: true
                layer.effect: DropShadow { color: "#88000000"; radius: 4; samples: 9; horizontalOffset: 1*s; verticalOffset: 1*s }
            }
            Text {
                anchors.right: parent.right
                text: root.osuAccuracy.toFixed(2) + "%"
                color: "#ccffffff"; font.family: mainFont.name; font.pixelSize: 14*s
            }
        }

        // Combo
        Column {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 50*s
            anchors.left: parent.left; anchors.leftMargin: 40*s
            spacing: 0

            Text {
                id: comboText
                text: root.osuCombo + "x"
                color: comboBreakAnim.running ? "#ff4444" : "white"; font.family: mainFont.name
                font.pixelSize: 52*s + Math.min(20*s, root.osuCombo * 0.5); font.weight: Font.Black

                NumberAnimation on scale { id: comboPopAnim; from: 1.35; to: 1.0; duration: 150; easing.type: Easing.OutBack }

                SequentialAnimation {
                    id: comboBreakAnim
                    NumberAnimation { target: comboText; property: "anchors.horizontalCenterOffset"; from: -10*s; to: 10*s; duration: 50 }
                    NumberAnimation { target: comboText; property: "anchors.horizontalCenterOffset"; from: 10*s; to: -8*s; duration: 50 }
                    NumberAnimation { target: comboText; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
                }

                layer.enabled: true
                layer.effect: DropShadow {
                    color: root.osuCombo > 10 ? root.accentColor : root.glowColor
                    radius: Math.min(20, 8 + root.osuCombo * 0.2); samples: 17; horizontalOffset: 0; verticalOffset: 0
                }
            }
        }

        // Judgment Counters
        Column {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 50*s
            anchors.right: parent.right; anchors.rightMargin: 40*s
            spacing: 2*s

            Text { text: root.osuHits + " / " + settings.requiredHits + " HITS"; color: "#aaffffff"; font.family: mainFont.name; font.pixelSize: 13*s; font.letterSpacing: 2*s; anchors.right: parent.right }
            Row {
                anchors.right: parent.right; spacing: 8*s
                Text { text: root.osu300s + "×"; color: root.accentColor;  font.family: mainFont.name; font.pixelSize: 11*s; font.weight: Font.Bold }
                Text { text: root.osu100s + "×"; color: root.glowColor;    font.family: mainFont.name; font.pixelSize: 11*s; font.weight: Font.Bold }
                Text { text: root.osu50s  + "×"; color: "#aaaaaa";          font.family: mainFont.name; font.pixelSize: 11*s; font.weight: Font.Bold }
                Text { text: root.osuMisses + "×"; color: "#ff4455";        font.family: mainFont.name; font.pixelSize: 11*s; font.weight: Font.Bold }
            }
        }

        // Game Area
        Item {
            id: gameArea
            anchors.fill: parent

            property int actionCount: 0
            property bool isActionHeld: actionCount > 0
            property real mouseXPos: 0
            property real mouseYPos: 0

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.BlankCursor
                onPositionChanged: {
                    gameArea.mouseXPos = mouseX;
                    gameArea.mouseYPos = mouseY;
                    if (root.gameActive) {
                        trailContainer.spawnTrail(mouseX, mouseY);
                    }
                }
                onPressed: (mouse) => {
                    gameArea.actionCount++;
                    root.tryHitAt(mouseX, mouseY);
                    mouse.accepted = true;
                }
                onReleased: {
                    gameArea.actionCount = Math.max(0, gameArea.actionCount - 1);
                }
            }
            // Ghost Trail Pool
            Item {
                id: trailContainer
                z: 8900
                property int maxTrail: 80
                property int currentIdx: 0
                property real lastX: -1000
                property real lastY: -1000

                function spawnTrail(px, py) {
                    var dx = px - lastX
                    var dy = py - lastY
                    // Density check
                    if (dx*dx + dy*dy > 6 * s * s) { 
                        lastX = px
                        lastY = py
                        var curr = rep.itemAt(currentIdx)
                        if (curr && curr.spawn) curr.spawn(px, py)
                        currentIdx = (currentIdx + 1) % maxTrail
                    }
                }

                Repeater {
                    id: rep
                    model: trailContainer.maxTrail
                    delegate: Item {
                        id: particle
                        width: 36 * s; height: 36 * s
                        opacity: 0; scale: 1.0
                        z: 8900
                        
                        // Pointer Ghosting
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4)
                            border.color: "white"; border.width: 1.5 * s
                            opacity: 0.8
                        }

                        ParallelAnimation { 
                            id: trailAnim
                            NumberAnimation { target: particle; property: "opacity"; to: 0; duration: 350; easing.type: Easing.OutSine }
                            NumberAnimation { target: particle; property: "scale";   to: 0.2; duration: 400; easing.type: Easing.InQuad }
                        }

                        function spawn(px, py) {
                            particle.x = px - width / 2
                            particle.y = py - height / 2
                            particle.opacity = 0.6
                            particle.scale = 0.85
                            trailAnim.restart()
                        }
                    }
                }
            }

            // ── osu! cursor ─────────────────────────────────────────
            Item {
                id: customCursor
                x: gameArea.mouseXPos - width  / 2
                y: gameArea.mouseYPos - height / 2
                width:  36*s; height: 36*s
                z: 9000
                visible: root.gameActive

                // Press Scale
                scale: gameArea.isActionHeld ? 0.85 : 1.0
                Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                // Main ring
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width; height: parent.height; radius: width / 2
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                    border.color: "white"; border.width: 2.5*s
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: root.glowColor; radius: 10; samples: 15; spread: 0.15
                        horizontalOffset: 0; verticalOffset: 0
                    }
                }

                // Accent Ring
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 6*s; height: width; radius: width / 2
                    color: "transparent"
                    border.color: root.accentColor; border.width: 1.5*s
                    opacity: 0.8
                }

                // Center dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 6*s; height: 6*s; radius: width / 2
                    color: "white"
                    layer.enabled: true
                    layer.effect: DropShadow { color: root.glowColor; radius: 5; samples: 9; spread: 0.2 }
                }
            }
        }

        // Ready Text
        Text {
            id: readyText
            anchors.centerIn: parent
            text: "CLICK THE CIRCLES!"
            color: "white"; font.family: mainFont.name
            font.pixelSize: 28*s; font.weight: Font.Black; font.letterSpacing: 6*s
            opacity: root.osuCircleCount === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            layer.enabled: true
            layer.effect: DropShadow { color: root.glowColor; radius: 16; samples: 21; spread: 0.2 }
        }

        // Key Controls
        Keys.onPressed: function(event) {
            if (event.isAutoRepeat) return;
            if (event.key === settings.key1 || event.key === settings.key2) {
                event.accepted = true;
                gameArea.actionCount++;
                root.tryHitAt(gameArea.mouseXPos, gameArea.mouseYPos);
            }
        }
        Keys.onReleased: function(event) {
            if (event.isAutoRepeat) return;
            if (event.key === settings.key1 || event.key === settings.key2) {
                event.accepted = true;
                gameArea.actionCount = Math.max(0, gameArea.actionCount - 1);
            }
        }
    }

    // Hit Circle
    Component {
        id: hitCircleComp

        Item {
            id: hc
            property int  circleNum: 1
            property bool hit: false
            property bool missed: false
            property real lifetime: 1000
            property real approachDuration: lifetime
            property real spawnTime: 0

            // Hit Time Calc
            readonly property real perfectTime: spawnTime + approachDuration

            width: 80*s; height: 80*s

            signal hitSignal(int judgment)
            signal missSignal()

            // Approach Ring
            Rectangle {
                id: approachRing
                anchors.centerIn: parent
                width: parent.width * 3.0; height: parent.width * 3.0; radius: width / 2
                color: "transparent"
                border.color: root.accentColor; border.width: 3 * s
                opacity: hc.hit || hc.missed ? 0 : 1

                NumberAnimation on width  { from: hc.width * 3.0; to: hc.width * 1.05; duration: hc.approachDuration; easing.type: Easing.Linear; running: true }
                NumberAnimation on height { from: hc.width * 3.0; to: hc.width * 1.05; duration: hc.approachDuration; easing.type: Easing.Linear; running: true }
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }

            // Circle Body
            Item {
                id: circleBody
                anchors.fill: parent

                // Circle Fill
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.9)
                    
                    // Inner shading gradient
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1, 0.4) }
                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.2) }
                    }
                }

                // Circle Overlay
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: "transparent"
                    border.color: "white"; border.width: 3.5 * s
                    
                    layer.enabled: true
                    layer.effect: DropShadow { color: "#aa000000"; radius: 6; samples: 9; spread: 0.1 }
                }

                // Tiny Outline
                Rectangle {
                    anchors.centerIn: parent; width: parent.width - 7*s; height: width; radius: width / 2
                    color: "transparent"
                    border.color: Qt.rgba(0,0,0,0.3); border.width: 1*s
                }

                // Number
                Text {
                    anchors.centerIn: parent; text: hc.circleNum; color: "white"
                    font.family: mainFont.name; font.pixelSize: 34*s; font.weight: Font.Black
                    layer.enabled: true; layer.effect: DropShadow { color: "#66000000"; radius: 5; samples: 9; verticalOffset: 1.5*s }
                }
            }

            Rectangle { anchors.centerIn: parent; width: parent.width+20*s; height: parent.width+20*s; radius: width/2; color: root.glowColor; opacity: 0.12 }

            // Hit Burst
            Rectangle {
                id: hitBurst
                anchors.centerIn: parent; width: parent.width; height: parent.width; radius: width/2
                color: "transparent"; border.color: root.glowColor; border.width: 5*s; opacity: 0
                NumberAnimation on scale   { id: burstScale;   from: 1.0; to: 2.2; duration: 350; easing.type: Easing.OutQuad; running: false }
                NumberAnimation on opacity { id: burstOpacity; from: 1.0; to: 0.0; duration: 350; easing.type: Easing.OutQuad; running: false; onStopped: { hc.destroy() } }
            }

            NumberAnimation on opacity { id: missAnim; to: 0.0; duration: 300; running: false }

            Timer {
                id: lifeTimer; interval: hc.lifetime + root.hitWindow50; running: true
                onTriggered: {
                    if (!hc.hit) { hc.missed = true; hc.missSignal(); missAnim.start(); Qt.callLater(function() { hc.destroy() }) }
                }
            }

            function tryHit() {
                if (hc.hit || hc.missed) return false
                var delta = Math.abs(Date.now() - hc.perfectTime)
                var j = 0
                if      (delta <= root.hitWindow300) j = 300
                else if (delta <= root.hitWindow100) j = 100
                else if (delta <= root.hitWindow50)  j = 50
                else return false   // too early — ignore click

                hc.hit = true
                lifeTimer.stop()
                hc.hitSignal(j)

                circleBody.opacity = 0; approachRing.opacity = 0
                hitBurst.opacity = 1; hitBurst.scale = 1.0
                burstScale.restart(); burstOpacity.restart()
                
                return true
            }
        }
    }

    // Slider Component
    Component {
        id: sliderComp
        Item {
            id: sliderRoot
            property int  circleNum: 1
            property real lifetime: 2000
            property real approachDuration: lifetime
            property real sx: 0; property real sy: 0
            property real ex: 0; property real ey: 0
            property real slideDuration: 800
            property real spawnTime: 0

            property bool hit: false
            property bool missed: false
            property bool sliding: false
            property bool completed: false

            signal hitSignal(int judgment)
            signal missSignal()
            signal sliderCompleted()

            width: 80 * s; height: 80 * s
            x: sx - 40*s; y: sy - 40*s

            property real destX: ex - sx
            property real destY: ey - sy
            property real ballProgress: 0

            // Track
            Rectangle {
                id: track
                x: 40*s; y: 40*s - height/2
                height: 72*s; width: Math.sqrt(destX*destX + destY*destY)
                radius: height/2
                color: Qt.rgba(0.1, 0.1, 0.1, 0.85) // Slider Track
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.7)
                border.width: 4*s
                transformOrigin: Item.Left; rotation: Math.atan2(destY, destX) * 180 / Math.PI
                opacity: (!completed && !missed) ? 0.75 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                
                // Track highlight/shading
                Rectangle { 
                    anchors.centerIn: parent; width: parent.width - 8*s; height: parent.height - 8*s; radius: height/2
                    color: "transparent"; border.color: Qt.rgba(1,1,1,0.2); border.width: 1.5*s 
                }
            }

            // Approach Ring
            Rectangle {
                id: sliderApproach
                anchors.centerIn: sBody
                width: 240*s; height: 240*s; radius: 120*s; color: "transparent"
                border.color: root.accentColor; border.width: 3.5*s
                opacity: (hit || missed) ? 0 : 1
                NumberAnimation on width  { from: 240*s; to: 82*s; duration: approachDuration; easing.type: Easing.Linear; running: true }
                NumberAnimation on height { from: 240*s; to: 82*s; duration: approachDuration; easing.type: Easing.Linear; running: true }
            }

            // Head Circle
            Item {
                id: sBody
                anchors.fill: parent; opacity: hit ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 100 } }
                
                // Inner volume
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.9)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1, 0.4) }
                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.2) }
                    }
                }
                // Hitcircle Overlay
                Rectangle {
                    anchors.fill: parent; radius: width / 2; color: "transparent"
                    border.color: "white"; border.width: 3.5*s
                    layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 6; samples: 9; spread: 0.1 }
                }
                // Inner tiny outline
                Rectangle { anchors.centerIn: parent; width: parent.width - 7*s; height: width; radius: width / 2; color: "transparent"; border.color: Qt.rgba(0,0,0,0.3); border.width: 1*s }
                
                Text { anchors.centerIn: parent; text: circleNum; color: "white"; font.family: mainFont.name; font.pixelSize: 34*s; font.weight: Font.Black; layer.enabled: true; layer.effect: DropShadow { color: "#66000000"; radius: 5; samples: 9; verticalOffset: 1.5*s } }
            }



            // Slider ball — sleek modern design
            Item {
                id: sBall
                width: 76*s; height: 76*s
                opacity: sliding ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 80 } }

                x: ballProgress * destX + 2*s
                y: ballProgress * destY + 2*s

                // Ball Body
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: Qt.rgba(0.05, 0.05, 0.05, 0.9)
                    border.color: "white"
                    border.width: 3.5*s

                    layer.enabled: true
                    layer.effect: DropShadow { color: root.accentColor; radius: 14; samples: 21; spread: 0.4 }
                }

                // Inner pulsing core
                Rectangle {
                    anchors.centerIn: parent
                    width: 24*s; height: 24*s; radius: width / 2
                    color: root.accentColor
                    
                    SequentialAnimation on scale {
                        loops: Animation.Infinite; running: sliding
                        NumberAnimation { from: 1.0; to: 1.4; duration: 300; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.4; to: 1.0; duration: 300; easing.type: Easing.InOutQuad }
                    }

                    layer.enabled: true
                    layer.effect: DropShadow { color: root.glowColor; radius: 10; samples: 15; spread: 0.5 }
                }
                
                // Follow Visual
                Rectangle {
                    anchors.centerIn: parent
                    width: 400*s; height: 400*s; radius: 200*s // Follow Bound
                    color: "transparent"; border.color: "white"; border.width: 2.5*s
                    opacity: 0.12
                }
            }

            // Travel Animation
            SequentialAnimation {
                id: ballTravelAnim
                running: true
                PauseAnimation { duration: approachDuration }
                ScriptAction { script: { sliding = true } }
                NumberAnimation {
                    target: sliderRoot; property: "ballProgress"
                    from: 0; to: 1; duration: slideDuration; easing.type: Easing.Linear
                }
                ScriptAction { script: { if (sliderRoot.ballProgress >= 0.99 && !sliderRoot.missed) sliderRoot.finish() } }
            }

            // Head Miss
            Timer {
                id: headMissTimer
                interval: approachDuration + root.hitWindow50
                running: true
                onTriggered: {
                    if (!hit && !missed) fail() 
                }
            }

            // Follow Check
            Timer {
                id: holdCheck
                interval: 16; repeat: true; running: sliding
                onTriggered: {
                    if (!hit) return
                    if (!gameArea.isActionHeld) { fail(); return }
                    
                    var bx = sliderRoot.x + sBall.x + 40*s
                    var by = sliderRoot.y + sBall.y + 40*s
                    var mx = gameArea.mouseXPos - bx
                    var my = gameArea.mouseYPos - by
                    var followRadius = 200 * s // Leniency Radius
                    if (mx*mx + my*my > followRadius * followRadius) fail()
                }
            }

            function tryHit() {
                if (hit || missed) return false
                var perfectTime = spawnTime + approachDuration
                var delta = Math.abs(Date.now() - perfectTime)
                if (delta > root.hitWindow50) return false // too early/late

                hit = true
                headMissTimer.stop()
                
                var j = 0
                if      (delta <= root.hitWindow300) j = 300
                else if (delta <= root.hitWindow100) j = 100
                else                                 j = 50
                
                hitSignal(j) // Head Judgment
                return true
            }

            function fail()   { ballTravelAnim.stop(); sliding = false; missed = true; missSignal(); Qt.callLater(destroy) }
            function finish() { if (!missed && sliding) { ballTravelAnim.stop(); sliding = false; completed = true; sliderCompleted(); Qt.callLater(destroy) } }
        }
    }

    // Feedback Text
    Component {
        id: feedbackComp
        Text {
            id: fbText
            property string msg: "300"
            property color col: "white"
            text: msg; color: col
            font.family: mainFont.name; font.pixelSize: 36*s; font.weight: Font.Black
            layer.enabled: true
            layer.effect: DropShadow { color: Qt.rgba(col.r, col.g, col.b, 0.6); radius: 10; samples: 15 }

            NumberAnimation on y   { from: y;       to: y - 60*s; duration: 700; easing.type: Easing.OutCubic }
            NumberAnimation on opacity { from: 1.0; to: 0.0;      duration: 700; easing.type: Easing.InCubic }
            onOpacityChanged: if (opacity <= 0.01) fbText.destroy()
        }
    }

    // Ripple Effect
    Component {
        id: rippleComp
        Rectangle {
            id: rip
            width: 80*s; height: 80*s; radius: 40*s
            color: "transparent"; border.color: root.glowColor; border.width: 5*s
            NumberAnimation on scale   { from: 1.0; to: 2.5; duration: 400; easing.type: Easing.OutQuad }
            NumberAnimation on opacity { from: 0.9; to: 0.0; duration: 400; easing.type: Easing.OutQuad }
            onOpacityChanged: if (opacity <= 0.01) rip.destroy()
        }
    }

    // Game Logic
    readonly property real margin: 100 * s

    property int patternStep: 0
    readonly property var spawnPattern: [450, 350, 600, 250, 450, 800, 300, 500, 200, 400, 350, 700, 400, 300, 500, 750]

    // Screen Shake
    SequentialAnimation {
        id: gameShake
        property real intensity: 5*s
        NumberAnimation { target: gameArea; property: "anchors.horizontalCenterOffset"; from: -intensity; to: intensity; duration: 30 }
        NumberAnimation { target: gameArea; property: "anchors.horizontalCenterOffset"; from: intensity; to: -intensity; duration: 30 }
        NumberAnimation { target: gameArea; property: "anchors.horizontalCenterOffset"; to: 0; duration: 30 }
    }

    // Passive Drain
    Timer {
        id: hpDrainTimer
        interval: 100; repeat: true; running: root.gameActive && !root.osuFailed
        onTriggered: {
            root.osuHealth = Math.max(0, root.osuHealth - 0.0008)
            if (root.osuHealth <= 0.001) failSequence.start()
        }
    }

    Timer {
        id: circleSpawnTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (!root.gameActive) { stop(); return }
            if (root.osuHits >= settings.requiredHits) { stop(); return }
            
            var sliderHoldDelay = spawnCircle()

            var comboDensityBonus = 1.0 + Math.min(0.4, root.osuCombo * 0.015)
            var baseInterval = root.spawnPattern[root.patternStep % root.spawnPattern.length]
            var nextInterval = baseInterval / (settings.osuDensity * comboDensityBonus)

            root.patternStep++
            // Sequence Interval
            interval = Math.max(150, nextInterval) + sliderHoldDelay
            restart()
        }
    }

    Timer {
        id: gameStartDelay
        interval: 600
        onTriggered: {
            patternStep = 0
            circleSpawnTimer.interval = 1000
            circleSpawnTimer.start()
            spawnCircle()
        }
    }

    // Win Check
    Timer {
        id: winCheckTimer
        interval: 200; repeat: true; running: false
        onTriggered: {
            if (root.osuHits >= settings.requiredHits) {
                stop()
                circleSpawnTimer.stop()
                winSequence.start()
            }
        }
    }

    SequentialAnimation {
        id: winSequence
        PauseAnimation { duration: 500 }
        ScriptAction {
            script: {
                root.loginSuccess = true
                loginTransition.start()
            }
        }
        PauseAnimation { duration: 600 }
        ScriptAction {
            script: {
                var uname = (userHelper.currentItem && userHelper.currentItem.uLogin)
                            ? userHelper.currentItem.uLogin : userModel.lastUser
                sddm.login(uname, passField.text, root.sessionIndex)
            }
        }
    }

    // Win Flash
    Rectangle {
        id: winFlash
        anchors.fill: parent; color: root.accentColor; z: 9999
        opacity: 0
        NumberAnimation { id: loginTransition; target: winFlash; property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.OutQuad }
    }

    function spawnCircle() {
        if (!root.gameActive) return 0
        root.osuCircleCount++
        if (root.osuCircleCount > 12) root.osuCircleCount = 1

        var margin = 120 * s
        var cx = 0, cy = 0
        var foundPos = false
        var attempts = 0

        while (!foundPos && attempts < 15) {
            cx = margin + Math.random() * (root.width - margin * 2)
            cy = margin + Math.random() * (root.height - margin * 2)
            cy = Math.max(120*s, Math.min(root.height - 150*s, cy))

            var collision = false
            for (var i = 0; i < root.activeCircles.length; i++) {
                var other = root.activeCircles[i]
                var ox = other.x + 40*s
                var oy = other.y + 40*s
                var distSq = (cx - ox)*(cx - ox) + (cy - oy)*(cy - oy)
                if (distSq < (150*s * 150*s)) {
                    collision = true
                    break
                }
            }
            if (!collision) foundPos = true
            attempts++
        }

        // Approach Scaling
        var baseApproach = 750 / settings.osuSpeed
        var lifetime     = baseApproach + Math.random() * (100 / settings.osuSpeed)

        var isSlider = Math.random() < settings.sliderChance
        var circle
        var now = Date.now()

        if (isSlider) {
            var dist     = 80*s + Math.random() * 260*s
            var ang      = Math.random() * Math.PI * 2
            var sdx      = Math.cos(ang) * dist
            var sdy      = Math.sin(ang) * dist
            var ex       = Math.max(margin, Math.min(root.width  - margin, cx + sdx))
            var ey       = Math.max(80*s,  Math.min(root.height - 100*s,  cy + sdy))
            var slideDur = Math.max(250, Math.min(800, dist / s / settings.osuSpeed * 2.2))

            circle = sliderComp.createObject(gameArea, {
                sx: cx, sy: cy, ex: ex, ey: ey,
                circleNum: root.osuCircleCount,
                lifetime: lifetime + slideDur,
                approachDuration: lifetime,
                slideDuration: slideDur,
                spawnTime: now
            })
        } else {
            circle = hitCircleComp.createObject(gameArea, {
                x: cx - 40*s, y: cy - 40*s,
                circleNum: root.osuCircleCount,
                lifetime: lifetime, approachDuration: lifetime,
                spawnTime: now
            })
        }

        if (circle) {
            root.activeCircles.push(circle)

            circle.hitSignal.connect(function(judgment) {
                onCircleHit(judgment, circle.x + 40*s, circle.y + 40*s)
                var idx = root.activeCircles.indexOf(circle)
                if (idx >= 0) root.activeCircles.splice(idx, 1)
            })

            circle.missSignal.connect(function() {
                onCircleMiss(circle.x + 40*s, circle.y + 40*s)
                var idx = root.activeCircles.indexOf(circle)
                if (idx >= 0) root.activeCircles.splice(idx, 1)
            })

            if (isSlider) {
                circle.sliderCompleted.connect(function() {
                    // Slider Judgment
                    onCircleHit(300, circle.sx + circle.destX, circle.sy + circle.destY)
                })
            }
        }
        
        return isSlider ? slideDur : 0
    }

    // judgment: 300 / 100 / 50
    function onCircleHit(judgment, cx, cy) {
        root.osuHits++
        root.osuCombo++
        if (root.osuCombo > root.osuMaxCombo) root.osuMaxCombo = root.osuCombo

        // HP Recovery
        var hpGain = judgment === 300 ? 0.10 : judgment === 100 ? 0.05 : 0.01
        root.osuHealth = Math.min(1.0, root.osuHealth + hpGain)

        // Track judgment counts
        if      (judgment === 300) root.osu300s++
        else if (judgment === 100) root.osu100s++
        else                       root.osu50s++

        // Points Formula
        var comboMult = 1.0 + (root.osuCombo / 25.0)
        root.osuScore += Math.round(judgment * comboMult)

        updateAccuracy()
        comboPopAnim.restart()

        rippleComp.createObject(gameArea, { x: cx - 40*s, y: cy - 40*s })

        var col = judgment === 300 ? root.accentColor : (judgment === 100 ? root.glowColor : "#aaaaaa")
        feedbackComp.createObject(gameArea, {
            x: cx - 30*s, y: cy - 55*s,
            msg: String(judgment), col: col
        })
    }

    function onCircleMiss(cx, cy) {
        root.osuCombo = 0
        root.osuMisses++
        root.osuHealth = Math.max(0, root.osuHealth - 0.18)
        updateAccuracy()
        comboBreakAnim.restart()

        gameShake.intensity = 15*s
        gameShake.restart()

        if (root.osuHealth <= 0.01 && !root.osuFailed) {
            failSequence.start()
        }

        feedbackComp.createObject(gameArea, {
            x: cx - 30*s,
            y: cy - 40*s,
            msg: "✕",
            col: "#ff4455"
        })
    }

    SequentialAnimation {
        id: failSequence
        ScriptAction { script: { root.osuFailed = true; circleSpawnTimer.stop() } }
        ParallelAnimation {
            NumberAnimation { target: gameScreen; property: "opacity"; to: 0; duration: 500 }
            NumberAnimation { target: failOverlay; property: "opacity"; to: 1; duration: 200 }
        }
        PauseAnimation { duration: 1000 }
        ScriptAction { script: { resetGame() } }
        NumberAnimation { target: failOverlay; property: "opacity"; to: 0; duration: 300 }
    }

    Rectangle {
        id: failOverlay
        anchors.fill: parent; color: "#aa000000"; opacity: 0; z: 10000
        Text {
            anchors.centerIn: parent; text: "FAILED"; color: "#ff4444"
            font.family: mainFont.name; font.pixelSize: 80*s; font.weight: Font.Black; font.italic: true
        }
    }

    function resetGame() {
        root.gameActive = false
        root.osuFailed = false
        root.osuHealth = 1.0
        root.osuHits = 0
        root.osuMisses = 0
        root.osu300s = 0
        root.osu100s = 0
        root.osu50s  = 0
        root.osuCombo = 0
        root.osuMaxCombo = 0
        root.osuScore = 0
        root.osuAccuracy = 100.0
        root.osuCircleCount = 0
        root.activeCircles = []
        passField.text = ""
        passField.forceActiveFocus()
    }

    // Accuracy Check
    function updateAccuracy() {
        var totalNotes = root.osu300s + root.osu100s + root.osu50s + root.osuMisses
        if (totalNotes === 0) { root.osuAccuracy = 100.0; return }
        root.osuAccuracy = (300.0 * root.osu300s + 100.0 * root.osu100s + 50.0 * root.osu50s)
                         / (300.0 * totalNotes) * 100.0
    }

    function tryHitAt(hx, hy) {
        var hitTolerance = 52 * s;
        for (var i = 0; i < root.activeCircles.length; i++) {
            var c = root.activeCircles[i];
            if (!c.hit && !c.missed) {
                var dx = (c.x + 40*s) - hx;
                var dy = (c.y + 40*s) - hy;
                if (dx*dx + dy*dy < hitTolerance * hitTolerance) {
                    var clickAccepted = true;
                    if (typeof c.tryHit === "function") {
                        clickAccepted = c.tryHit();
                    } else {
                        c.hit = true;
                        onCircleHit(300, c.x + 40*s, c.y + 40*s);
                        c.opacity = 0;
                        Qt.callLater(function() { c.destroy(); });
                    }
                    
                    if (clickAccepted) {
                        var idx = root.activeCircles.indexOf(c);
                        if (idx >= 0) root.activeCircles.splice(idx, 1);
                        return;
                    }
                }
            }
        }
    }

    function doAction() {
        if (root.gameMode) {
            startGame()
        } else {
            doLogin()
        }
    }

    function doLogin() {
        errorMsg.text = ""
        root.loginPending = true
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin)
                    ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(uname, passField.text, root.sessionIndex)
    }

    function startGame() {
        errorMsg.text = ""
        root.osuScore = 0
        root.osuCombo = 0
        root.osuMaxCombo = 0
        root.osuHits = 0
        root.osuMisses = 0
        root.osu300s = 0
        root.osu100s = 0
        root.osu50s  = 0
        root.osuAccuracy = 100.0
        root.osuHealth = 1.0
        root.osuCircleCount = 0
        root.activeCircles = []
        root.patternStep = 0
        root.gameActive = true
        gameStartDelay.start()
        winCheckTimer.start()
    }

    // Login Failed
    Connections {
        target: sddm
        function onLoginFailed() {
            root.gameActive = false
            root.loginSuccess = false
            circleSpawnTimer.stop()
            gameStartDelay.stop()
            winCheckTimer.stop()
            winSequence.stop()

            winFlash.opacity = 0
            root.activeCircles = []

            errorMsg.text = "✖  WRONG PASSWORD — TRY AGAIN"
            passField.text = ""
            passField.forceActiveFocus()

            errorShake.restart()
        }
    }

    SequentialAnimation {
        id: errorShake
        NumberAnimation { target: errorMsg; property: "anchors.rightMargin"; from: -8*s; to: 8*s; duration: 60 }
        NumberAnimation { target: errorMsg; property: "anchors.rightMargin"; from: 8*s; to: -6*s; duration: 60 }
        NumberAnimation { target: errorMsg; property: "anchors.rightMargin"; from: -6*s; to: 4*s; duration: 60 }
        NumberAnimation { target: errorMsg; property: "anchors.rightMargin"; to: 0;          duration: 60 }
    }

}