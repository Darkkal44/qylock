import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel

Item {
    id: root
    width: 1920; height: 1080
    readonly property real s: width / 1920
    
    // AMBIENT ACCENT
    readonly property color fgColor: "#ffffff"
    readonly property color accentColor: "#d3eaad" 
    
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property real uiOpacity: 0
    property bool sessionPopupOpen: false
    property bool userPopupOpen: false
    property bool loginError: false
    onUserPopupOpenChanged: if (userPopupOpen) sessionPopupOpen = false
    onSessionPopupOpenChanged: if (sessionPopupOpen) userPopupOpen = false

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    function capitalize(str) { if (!str) return ""; return str.charAt(0).toUpperCase() + str.slice(1); }
    function login() { 
        var lName = (userHelper.currentItem && userHelper.currentItem.uLogin !== "") ? userHelper.currentItem.uLogin : (userModel.lastUser || "")
        sddm.login(lName, passInput.text, root.sessionIndex) 
    }
    
    Connections { target: sddm; function onLoginFailed() { root.loginError = true; passInput.text = ""; passInput.forceActiveFocus() } }

    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    // BACKGROUND
    Rectangle { anchors.fill: parent; color: "#010801"; z: -1000 }
    
    MediaPlayer {
        id: player; source: "bg.mp4"
        videoOutput: bgVideo; loops: MediaPlayer.Infinite
        Component.onCompleted: player.play()
    }
    VideoOutput { id: bgVideo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop; z: -500 }


    // GLASS ENGINE
    ShaderEffectSource { id: baseVideoSource; sourceItem: bgVideo; visible: false; live: true }
    FastBlur { id: globalGlassBlur; anchors.fill: parent; source: baseVideoSource; radius: 85; z: -1000; visible: true }

    component LiquidGlass: Item {
        id: lg
        property real glassRadius: 35 * s
        property color glassTint: "#95081508" 
        property real borderWidth: 1.0 * s
        property real blurBrightness: -0.20 
        property color topRimColor: "#ffffff" 
        property color bottomRimColor: "#55ffffff" 
        
        Behavior on blurBrightness { NumberAnimation { duration: 400 } }
        anchors.fill: parent
        
        Rectangle { id: maskRect; anchors.fill: parent; radius: lg.glassRadius; visible: false }
        ShaderEffectSource {
            id: localBlur; sourceItem: globalGlassBlur; visible: false
            sourceRect: {
                var pos = lg.mapToItem(root, 0, 0);
                return Qt.rect(pos.x, pos.y, lg.width, lg.height);
            }
        }

        BrightnessContrast {
            id: brightnessEffect; anchors.fill: parent; source: localBlur; visible: false
            brightness: lg.blurBrightness
        }

        OpacityMask { anchors.fill: parent; source: brightnessEffect; maskSource: maskRect }
        
        Rectangle {
            anchors.fill: parent; opacity: 1.0; visible: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#45ffffff" } 
                GradientStop { position: 0.25; color: "#00000000" } 
                GradientStop { position: 0.7; color: "#00000000" } 
                GradientStop { position: 1.0; color: "#15000000" } 
            }
            layer.enabled: true; layer.effect: OpacityMask { maskSource: maskRect }
        }
        
        Rectangle { anchors.fill: parent; radius: lg.glassRadius; color: lg.glassTint }

        Rectangle { id: topRim; anchors.fill: parent; radius: lg.glassRadius; color: "transparent"; border.color: lg.topRimColor; border.width: lg.borderWidth; visible: false }
        Rectangle {
            id: topFade; anchors.fill: parent; visible: false
            gradient: Gradient { 
                GradientStop { position: 0.0; color: "white" }
                GradientStop { position: 1.0; color: "transparent" } 
            }
        }
        OpacityMask { anchors.fill: parent; source: topRim; maskSource: topFade }

        Rectangle { id: bottomRim; anchors.fill: parent; radius: lg.glassRadius; color: "transparent"; border.color: lg.bottomRimColor; border.width: lg.borderWidth; visible: false }
        Rectangle {
            id: bottomFade; anchors.fill: parent; visible: false
            gradient: Gradient { 
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "white" } 
            }
        }
        OpacityMask { anchors.fill: parent; source: bottomRim; maskSource: bottomFade }
    }

    // 1. TOP-LEFT CLOCK
    Item {
        id: clockPebble
        x: 100 * s; y: 100 * s
        width: 360 * s; height: 180 * s
        opacity: root.uiOpacity
        scale: 1.0
        
        layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#2a000000"; radius: 60*s; samples: 81; verticalOffset: 12 * s }
        
        LiquidGlass { glassRadius: 30 * s; blurBrightness: -0.25 } 
    
        Column {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -8 * s; spacing: 5 * s
            Text {
                id: clockText; text: Qt.formatTime(new Date(), "HH:mm")
                font.family: mainFont.name; font.pixelSize: 90 * s; font.weight: Font.Medium; color: "white"; font.letterSpacing: -2 * s; opacity: 0.95; anchors.horizontalCenter: parent.horizontalCenter
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") }
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase(); font.family: mainFont.name; font.pixelSize: 15 * s; color: root.accentColor
                font.letterSpacing: 4 * s; horizontalAlignment: Text.AlignHCenter; opacity: 0.7; anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // 2. BOTTOM-RIGHT PANEL
    Item {
        id: mainPanelStack
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 100 * s
        width: 440 * s; height: 335 * s
        opacity: root.uiOpacity

        // PEBBLE 1: USER 
        Item {
            id: userMorpher; width: parent.width; height: root.userPopupOpen ? 325 * s : 75 * s; y: 0
            opacity: root.sessionPopupOpen ? 0.0 : 1.0; z: root.userPopupOpen ? 100 : 1
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#2a000000"; radius: root.userPopupOpen ? 45*s : 30*s; verticalOffset: 10 * s }
            
            LiquidGlass { 
                glassRadius: 20 * s 
                blurBrightness: root.userPopupOpen ? -0.45 : (userMouse.containsMouse ? -0.25 : -0.35)
                topRimColor: (userMouse.containsMouse || root.userPopupOpen) ? "#ffffff" : "#ccffffff"
            }

            property real morphRatio: root.userPopupOpen ? 1.0 : 0.0; Behavior on morphRatio { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

            Row {
                anchors.fill: parent; anchors.leftMargin: 20 * s; spacing: 15 * s; visible: userMorpher.morphRatio < 0.99; opacity: 1.0 - userMorpher.morphRatio; scale: 1.0 - (userMorpher.morphRatio * 0.2)
                Rectangle {
                    width: 45 * s; height: 45 * s; radius: 22.5 * s; color: root.accentColor; anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName[0] : "A").toUpperCase(); font.pixelSize: 18 * s; font.weight: Font.Black; color: "#0d1b0d" }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "WELCOME BACK"; font.family: mainFont.name; font.pixelSize: 12 * s; color: "white"; opacity: 0.5; font.letterSpacing: 2 * s }
                    Text { text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "USER").toUpperCase(); font.family: mainFont.name; font.pixelSize: 22 * s; font.weight: Font.Bold; color: "white"; font.letterSpacing: 1 * s }
                }
            }
            Column {
                anchors.fill: parent; anchors.margins: 20 * s; visible: opacity > 0.01; opacity: userMorpher.morphRatio; scale: 0.9 + (userMorpher.morphRatio * 0.1); spacing: 15 * s
                Text { text: "ACCOUNT"; font.family: mainFont.name; font.pixelSize: 13 * s; color: root.accentColor; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 3 * s; opacity: 0.8 }
                ListView {
                    width: parent.width; height: 120 * s; model: userModel; clip: true; spacing: 5 * s
                    delegate: Item {
                        width: parent.width; height: 35 * s
                        Rectangle { anchors.fill: parent; radius: 10 * s; color: "#1affffff"; visible: innerUserMouse.containsMouse || index === root.userIndex; opacity: (innerUserMouse.containsMouse || index === root.userIndex) ? 1.0 : 0.0 }
                        Row { anchors.centerIn: parent; spacing: 10 * s
                            Rectangle { width: 4 * s; height: 4 * s; radius: 2 * s; color: root.accentColor; anchors.verticalCenter: parent.verticalCenter; visible: index === root.userIndex }
                            Text { text: (model.realName || model.name || "USER").toUpperCase(); font.family: mainFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s; color: index === root.userIndex ? root.accentColor : "white" }
                        }
                        MouseArea { id: innerUserMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.userIndex = index; root.userPopupOpen = false } }
                    }
                }
                Text { text: "ESCAPE"; font.family: mainFont.name; font.pixelSize: 9 * s; color: "white"; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 3 * s; opacity: 0.4; MouseArea { anchors.fill: parent; onClicked: root.userPopupOpen = false; cursorShape: Qt.PointingHandCursor } }
            }
            MouseArea { id: userMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; visible: !root.userPopupOpen; onClicked: root.userPopupOpen = true; onPressed: userMorpher.scale = 0.98; onReleased: userMorpher.scale = 1.0 }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }

        // PEBBLE 2: PASSWORD
        Item {
            id: passwordCard; width: parent.width; height: 75 * s; y: 95 * s
            opacity: (root.sessionPopupOpen || root.userPopupOpen) ? 0.0 : 1.0
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: passInput.activeFocus ? "#33d3eaad" : "#2a000000"; radius: 30*s; verticalOffset: 8 * s }
            Behavior on opacity { NumberAnimation { duration: 400 } }
            LiquidGlass {
                glassRadius: 20 * s; blurBrightness: passInput.activeFocus ? -0.15 : -0.35 
                topRimColor: passInput.activeFocus ? root.accentColor : "#ffffff"; borderWidth: passInput.activeFocus ? 2.5 * s : 1.0 * s
            }
            TextInput {
                id: passInput; anchors.fill: parent; anchors.leftMargin: 25 * s; anchors.rightMargin: 25 * s
                verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password; passwordCharacter: "●"
                font.family: mainFont.name; font.pixelSize: 22 * s; color: root.accentColor; clip: true; focus: true; selectionColor: "white"
                font.letterSpacing: 2 * s; onAccepted: root.login()
                Text { text: "Enter Passcode"; anchors.fill: parent; verticalAlignment: Text.AlignVCenter; color: "white"; font.italic: true; opacity: 0.3; visible: !parent.text && !parent.activeFocus; font.pixelSize: 18 * s }
            }
        }

        // LOGIN ARROW PEBBLE (UNCONSTRAINED)
        Item {
            anchors.right: parent.right; anchors.rightMargin: 15 * s; y: 95 * s + 15 * s // Centered in the 75px row
            width: 44 * s; height: 1.0 * width; z: 50
            opacity: (root.sessionPopupOpen || root.userPopupOpen) ? 0.0 : (passInput.text.length > 0 ? 1.0 : 0.0)
            scale: innerLoginMouse.containsMouse ? 1.15 : 1.0; Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            LiquidGlass { glassRadius: width/2; blurBrightness: innerLoginMouse.containsMouse ? -0.15 : -0.25; topRimColor: innerLoginMouse.containsMouse ? root.accentColor : "#ffffff" }
            Text { anchors.centerIn: parent; text: "→"; font.pixelSize: 22 * s; color: "white"; opacity: innerLoginMouse.containsMouse ? 1.0 : 0.7 }
            MouseArea { id: innerLoginMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.login(); cursorShape: Qt.PointingHandCursor }
        }

        // PEBBLE 3: SESSION 
        Item {
            id: sessionMorpher; width: parent.width; height: root.sessionPopupOpen ? 335 * s : 75 * s; y: root.sessionPopupOpen ? 0 : 190 * s
            opacity: root.userPopupOpen ? 0.0 : 1.0; z: root.sessionPopupOpen ? 100 : 1
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#2a000000"; radius: root.sessionPopupOpen ? 45*s : 30*s; verticalOffset: 10 * s }
            
            LiquidGlass { glassRadius: 20 * s; blurBrightness: root.sessionPopupOpen ? -0.45 : (sessMouse.containsMouse ? -0.25 : -0.35); topRimColor: (sessMouse.containsMouse || root.sessionPopupOpen) ? "#ffffff" : "#ccffffff" }

            property real morphRatio: root.sessionPopupOpen ? 1.0 : 0.0; Behavior on morphRatio { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

            Text { 
                anchors.centerIn: parent; visible: sessionMorpher.morphRatio < 0.99; opacity: (1.0 - sessionMorpher.morphRatio)
                scale: 1.0 - (sessionMorpher.morphRatio * 0.2); text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()
                font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.DemiBold; color: root.accentColor; font.letterSpacing: 2 * s
            }
            Column {
                anchors.fill: parent; anchors.margins: 20 * s; visible: opacity > 0.01; opacity: sessionMorpher.morphRatio; scale: 0.9 + (sessionMorpher.morphRatio * 0.1); spacing: 15 * s
                Text { text: "SESSION"; font.family: mainFont.name; font.pixelSize: 13 * s; color: root.accentColor; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 3 * s; opacity: 0.8 }
                ListView {
                    width: parent.width; height: 120 * s; model: sessionModel; clip: true; spacing: 5 * s
                    delegate: Item {
                        width: parent.width; height: 35 * s
                        Rectangle { anchors.fill: parent; radius: 10 * s; color: "#1affffff"; visible: innerSessMouse.containsMouse || index === root.sessionIndex; opacity: (innerSessMouse.containsMouse || index === root.sessionIndex) ? 1.0 : 0.0 }
                        Text { anchors.centerIn: parent; text: (model.name || "UNNAMED").toUpperCase(); font.family: mainFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s; color: index === root.sessionIndex ? root.accentColor : "white" }
                        MouseArea { id: innerSessMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.sessionIndex = index; root.sessionPopupOpen = false } }
                    }
                }
                Text { text: "ESCAPE"; font.family: mainFont.name; font.pixelSize: 9 * s; color: "white"; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 4 * s; opacity: 0.4; MouseArea { anchors.fill: parent; onClicked: root.sessionPopupOpen = false; cursorShape: Qt.PointingHandCursor } }
            }
            MouseArea { id: sessMouse; anchors.fill: parent; hoverEnabled: true; visible: !root.sessionPopupOpen; onClicked: root.sessionPopupOpen = true; cursorShape: Qt.PointingHandCursor; onPressed: sessionMorpher.scale = 0.98; onReleased: sessionMorpher.scale = 1.0 }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }

        // PEBBLE 4: ACTIONS
        Row {
            width: parent.width; height: 50 * s; y: 285 * s; spacing: 20 * s
            opacity: (root.sessionPopupOpen || root.userPopupOpen) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Item { id: rebootBtn; x:0; y:0; width: (parent.width / 2) - 10 * s; height: 50 * s; layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#2a000000"; radius: 25*s; verticalOffset: 8 * s }
                LiquidGlass { glassRadius: 15 * s; blurBrightness: -0.35; topRimColor: "#ccffffff" }
                Text { anchors.centerIn: parent; text: "REBOOT"; font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.DemiBold; color: "white"; opacity: restMouse.containsMouse ? 1.0 : 0.8 }
                MouseArea { id: restMouse; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot(); cursorShape: Qt.PointingHandCursor; onPressed: rebootBtn.scale = 0.98; onReleased: rebootBtn.scale = 1.0 }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
            Item { id: powerBtn; x:0; y:0; width: (parent.width / 2) - 10 * s; height: 50 * s; layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#2a000000"; radius: 25*s; verticalOffset: 8 * s }
                LiquidGlass { glassRadius: 15 * s; blurBrightness: -0.35; topRimColor: "#ccffffff" }
                Text { anchors.centerIn: parent; text: "POWER"; font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.DemiBold; color: "white"; opacity: shutMouse.containsMouse ? 1.0 : 0.8 }
                MouseArea { id: shutMouse; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff(); cursorShape: Qt.PointingHandCursor; onPressed: powerBtn.scale = 0.98; onReleased: powerBtn.scale = 1.0 }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
        }
    }

    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: userModel; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }
    NumberAnimation { id: fadeIn; target: root; property: "uiOpacity"; to: 1; duration: 2500; easing.type: Easing.OutCubic }
    Component.onCompleted: fadeIn.start()
}
