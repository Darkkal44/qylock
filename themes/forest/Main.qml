import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Item {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    id: root
    width: 1920; height: 1080
    readonly property real s: width / 1920
    
    // Quickshell
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined

    // Colors
    readonly property color fgColor: "#ffffff"
    readonly property color accentColor: "#d3eaad" 
    
    // State
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property real uiOpacity: 0
    property bool sessionPopupOpen: false
    property bool userPopupOpen: false
    property bool loginError: false
    property int focusedElement: 0 // 0: Password, 1: Session, 2: Reboot, 3: Power, 4: User
    onUserPopupOpenChanged: if (userPopupOpen) sessionPopupOpen = false
    onSessionPopupOpenChanged: if (sessionPopupOpen) userPopupOpen = false

    function activateFocused() {
        if (root.focusedElement === 0) {
            root.login()
        } else if (root.focusedElement === 1) {
            root.sessionPopupOpen = !root.sessionPopupOpen
        } else if (root.focusedElement === 2) {
            if (typeof sddm !== "undefined") sddm.reboot()
        } else if (root.focusedElement === 3) {
            if (typeof sddm !== "undefined") sddm.powerOff()
        } else if (root.focusedElement === 4) {
            root.userPopupOpen = !root.userPopupOpen
        }
    }
    // Fonts
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    function capitalize(str) { if (!str) return ""; return str.charAt(0).toUpperCase() + str.slice(1); }
    
    // Login
    function login() { 
        var lName = (userHelper.currentItem && userHelper.currentItem.uLogin !== "") ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        if (typeof sddm !== "undefined") sddm.login(lName, passInput.text, root.sessionIndex) 
    }
    
    Connections { 
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { 
            errText.text = "ACCESS DENIED"
            passInput.text = ""
            passInput.forceActiveFocus() 
        } 
    }

    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    // Background
    Rectangle { anchors.fill: parent; color: "#010801"; z: -1000 }
    
    MediaPlayer {
        id: player; source: "bg.mp4"
        videoOutput: bgVideo; loops: MediaPlayer.Infinite
        Component.onCompleted: player.play()
    }
    VideoOutput { id: bgVideo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop; z: -500 }


    // Glass
    ShaderEffectSource { id: baseVideoSource; sourceItem: bgVideo; visible: false; live: true; recursive: false }
    FastBlur { id: globalGlassBlur; anchors.fill: parent; source: baseVideoSource; radius: 96; z: -1000; visible: true }

    component LiquidGlass: Item {
        id: lg
        property real glassRadius: 22 * s
        property color glassTint: "#55101a10"
        property real borderWidth: 1.0 * s
        property real blurBrightness: -0.10
        property color topRimColor: "#ccffffff"
        
        Behavior on blurBrightness { NumberAnimation { duration: 300 } }
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
            id: darkenEffect; anchors.fill: parent; source: localBlur; visible: false
            brightness: lg.blurBrightness
            contrast: 0.10
        }

        OpacityMask { anchors.fill: parent; source: darkenEffect; maskSource: maskRect }

        Rectangle { anchors.fill: parent; radius: lg.glassRadius; color: lg.glassTint }

        Rectangle {
            id: topRimSrc
            anchors.fill: parent
            radius: lg.glassRadius
            color: "transparent"
            border.color: lg.topRimColor
            border.width: lg.borderWidth
            visible: false
        }
        Rectangle {
            id: topRimMask
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "white" }
                GradientStop { position: 0.08; color: "transparent" }
            }
        }
        OpacityMask { anchors.fill: parent; source: topRimSrc; maskSource: topRimMask }

        Rectangle {
            id: bottomRimSrc
            anchors.fill: parent
            radius: lg.glassRadius
            color: "transparent"
            border.color: "#40ffffff"
            border.width: lg.borderWidth
            visible: false
        }
        Rectangle {
            id: bottomRimMask
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                GradientStop { position: 0.92; color: "transparent" }
                GradientStop { position: 1.0;  color: "white" }
            }
        }
        OpacityMask { anchors.fill: parent; source: bottomRimSrc; maskSource: bottomRimMask }
    }

    // Clock
    Item {
        id: clockPebble
        x: 100 * s; y: 100 * s
        width: 360 * s; height: 180 * s
        opacity: root.uiOpacity
        scale: 1.0
        
        layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#35000000"; radius: 30*s; samples: 81; verticalOffset: 10 * s }
        
        LiquidGlass { glassRadius: 25 * s }
    
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

    // Widget
    Item {
        id: mainPanelStack
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 100 * s
        width: 440 * s; height: 335 * s
        opacity: root.uiOpacity

        // Users
        Item {
            id: userMorpher; width: parent.width; height: root.userPopupOpen ? 325 * s : 75 * s; y: 0
            opacity: root.sessionPopupOpen ? 0.0 : 1.0; z: root.userPopupOpen ? 100 : 1
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#35000000"; radius: root.userPopupOpen ? 45*s : 30*s; verticalOffset: 10 * s }
            
            LiquidGlass { 
                glassRadius: 22 * s 
                blurBrightness: root.userPopupOpen ? -0.25 : ((userMouse.containsMouse || root.focusedElement === 4) ? -0.05 : -0.10)
                topRimColor: (userMouse.containsMouse || root.focusedElement === 4 || root.userPopupOpen) ? root.accentColor : "#ccffffff"
            }

            property real morphRatio: root.userPopupOpen ? 1.0 : 0.0; Behavior on morphRatio { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

            Row {
                id: compactUserContent
                anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 20 * s; anchors.topMargin: 15 * s; height: 45 * s; spacing: 15 * s
                visible: userMorpher.morphRatio < 0.99; opacity: 1.0 - userMorpher.morphRatio
                Rectangle {
                    width: 45 * s; height: 45 * s; radius: 22.5 * s; color: root.accentColor; anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName[0] : (typeof userModel !== "undefined" && userModel.lastUser ? userModel.lastUser[0] : "A")).toUpperCase(); font.pixelSize: 18 * s; font.weight: Font.Black; color: "#0d1b0d" }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "WELCOME BACK"; font.family: mainFont.name; font.pixelSize: 12 * s; color: "white"; opacity: 0.5; font.letterSpacing: 2 * s }
                    Text { text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" && userModel.lastUser ? userModel.lastUser : "USER")).toUpperCase(); font.family: mainFont.name; font.pixelSize: 22 * s; font.weight: Font.Bold; color: "white"; font.letterSpacing: 1 * s }
                }
            }
            Column {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20 * s; visible: opacity > 0.01; opacity: userMorpher.morphRatio; spacing: 15 * s
                Text { text: "ACCOUNT"; font.family: mainFont.name; font.pixelSize: 13 * s; color: root.accentColor; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 3 * s; opacity: 0.8 }
                ListView {
                    width: parent.width; height: 120 * s; model: typeof userModel !== "undefined" ? userModel : null; clip: true; spacing: 5 * s
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
            scale: (root.focusedElement === 4 || userMouse.containsMouse) ? 1.02 : 1.0
            MouseArea { id: userMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; visible: !root.userPopupOpen; onClicked: root.userPopupOpen = true; onPressed: userMorpher.scale = 0.98; onReleased: userMorpher.scale = 1.0 }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }

        // Target
        Item {
            id: passwordCard; width: parent.width; height: 75 * s; y: 95 * s
            opacity: (root.sessionPopupOpen || root.userPopupOpen) ? 0.0 : 1.0
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: (root.focusedElement === 0 && passInput.activeFocus) ? "#33d3eaad" : "#35000000"; radius: 30*s; verticalOffset: 8 * s }
            Behavior on opacity { NumberAnimation { duration: 400 } }
            LiquidGlass {
                glassRadius: 22 * s
                blurBrightness: (root.focusedElement === 0 && passInput.activeFocus) ? -0.05 : -0.10
                topRimColor: (root.focusedElement === 0 && passInput.activeFocus) ? root.accentColor : "#ccffffff"
                borderWidth: (root.focusedElement === 0 && passInput.activeFocus) ? 1.5 * s : 1.0 * s
            }
            TextInput {
                id: passInput; anchors.fill: parent; anchors.leftMargin: 25 * s; anchors.rightMargin: 25 * s
                anchors.verticalCenterOffset: 2 * s
                verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password; passwordCharacter: "●"
                font.family: mainFont.name; font.pixelSize: 22 * s; color: root.accentColor; clip: true; focus: true; selectionColor: "white"
                font.letterSpacing: 4 * s
                onAccepted: root.login()
                onTextEdited: errText.text = ""
                Keys.onTabPressed: (event) => {
                    if (root.sessionPopupOpen) {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                    } else if (root.userPopupOpen) {
                        if (typeof userModel !== "undefined" && userModel.count > 0)
                            root.userIndex = (root.userIndex + 1) % userModel.count
                    } else {
                        root.focusedElement = (root.focusedElement + 1) % 5
                    }
                    event.accepted = true
                }
                Keys.onBacktabPressed: (event) => {
                    if (root.sessionPopupOpen) {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex - 1 + sessionModel.rowCount()) % sessionModel.rowCount()
                    } else if (root.userPopupOpen) {
                        if (typeof userModel !== "undefined" && userModel.count > 0)
                            root.userIndex = (root.userIndex - 1 + userModel.count) % userModel.count
                    } else {
                        root.focusedElement = (root.focusedElement - 1 + 5) % 5
                    }
                    event.accepted = true
                }
                Keys.onEscapePressed: (event) => {
                    if (root.sessionPopupOpen) {
                        root.sessionPopupOpen = false
                    } else if (root.userPopupOpen) {
                        root.userPopupOpen = false
                    } else {
                        root.focusedElement = 0
                        passInput.text = ""
                        errText.text = ""
                    }
                    event.accepted = true
                }
                Keys.onReturnPressed: (event) => {
                    if (root.sessionPopupOpen) {
                        root.sessionPopupOpen = false
                    } else if (root.userPopupOpen) {
                        root.userPopupOpen = false
                    } else {
                        root.activateFocused()
                    }
                    event.accepted = true
                }
                Keys.onEnterPressed: (event) => {
                    if (root.sessionPopupOpen) {
                        root.sessionPopupOpen = false
                    } else if (root.userPopupOpen) {
                        root.userPopupOpen = false
                    } else {
                        root.activateFocused()
                    }
                    event.accepted = true
                }
                Keys.onSpacePressed: (event) => {
                    if (root.sessionPopupOpen) {
                        root.sessionPopupOpen = false
                        event.accepted = true
                    } else if (root.userPopupOpen) {
                        root.userPopupOpen = false
                        event.accepted = true
                    } else if (root.focusedElement !== 0) {
                        root.activateFocused()
                        event.accepted = true
                    }
                }
                Keys.onDownPressed: (event) => {
                    if (root.sessionPopupOpen) {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                        event.accepted = true
                    } else if (root.userPopupOpen) {
                        if (typeof userModel !== "undefined" && userModel.count > 0)
                            root.userIndex = (root.userIndex + 1) % userModel.count
                        event.accepted = true
                    } else if (root.focusedElement === 1) {
                        root.sessionPopupOpen = true
                        event.accepted = true
                    } else if (root.focusedElement === 4) {
                        root.userPopupOpen = true
                        event.accepted = true
                    }
                }
                Keys.onUpPressed: (event) => {
                    if (root.sessionPopupOpen) {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex - 1 + sessionModel.rowCount()) % sessionModel.rowCount()
                        event.accepted = true
                    } else if (root.userPopupOpen) {
                        if (typeof userModel !== "undefined" && userModel.count > 0)
                            root.userIndex = (root.userIndex - 1 + userModel.count) % userModel.count
                        event.accepted = true
                    } else if (root.focusedElement === 1) {
                        root.sessionPopupOpen = true
                        event.accepted = true
                    } else if (root.focusedElement === 4) {
                        root.userPopupOpen = true
                        event.accepted = true
                    }
                }
                Keys.onPressed: (event) => {
                    if (root.focusedElement !== 0 && !root.sessionPopupOpen && !root.userPopupOpen &&
                        event.text && event.text.length > 0 &&
                        event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab &&
                        event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter &&
                        event.key !== Qt.Key_Space && event.key !== Qt.Key_Escape) {
                        root.focusedElement = 0
                    }
                }
                property bool wasClicked: false
                onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                Text { 
                    text: "Enter Passcode"; anchors.fill: parent; verticalAlignment: Text.AlignVCenter; color: "white"; font.italic: true; font.pixelSize: 18 * s
                    opacity: (passInput.text.length === 0 && errText.text === "") ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }
                Text {
                    id: errText
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 25 * s
                    text: ""
                    color: "#ff6666"
                    font.family: mainFont.name
                    font.pixelSize: 9 * s
                    font.letterSpacing: 2 * s
                }
                Rectangle {
                    id: customCursor
                    width: 2.2 * s; height: 26 * s
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    x: passInput.cursorRectangle.x - width/2 + 2 * s
                    visible: root.focusedElement === 0 && passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite; running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passInput.forceActiveFocus()
                        passInput.wasClicked = true
                    }
                }
            }
        }

        // Enter
        Item {
            anchors.right: parent.right; anchors.rightMargin: 15 * s; y: 95 * s + 15 * s
            width: 44 * s; height: 1.0 * width; z: 50
            opacity: (root.sessionPopupOpen || root.userPopupOpen) ? 0.0 : (passInput.text.length > 0 ? 1.0 : 0.0)
            scale: innerLoginMouse.containsMouse ? 1.15 : 1.0; Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#45000000"; radius: 20*s; verticalOffset: 5 * s }

            LiquidGlass { glassRadius: width/2; blurBrightness: innerLoginMouse.containsMouse ? -0.05 : -0.10; topRimColor: innerLoginMouse.containsMouse ? root.accentColor : "#ccffffff" }
            Text { anchors.centerIn: parent; text: "→"; font.pixelSize: 22 * s; color: "white"; opacity: innerLoginMouse.containsMouse ? 1.0 : 0.7 }
            MouseArea { id: innerLoginMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.login(); cursorShape: Qt.PointingHandCursor }
        }

        // Sessions
        Item {
            id: sessionMorpher
            visible: !root.isQuickshell
            width: parent.width; height: root.sessionPopupOpen ? 335 * s : 75 * s; y: root.sessionPopupOpen ? 0 : 190 * s
            opacity: root.userPopupOpen ? 0.0 : 1.0; z: root.sessionPopupOpen ? 100 : 1
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
            layer.enabled: true; layer.effect: DropShadow { transparentBorder: true; color: "#35000000"; radius: root.sessionPopupOpen ? 45*s : 30*s; verticalOffset: 10 * s }
            
            LiquidGlass {
                glassRadius: 22 * s
                blurBrightness: root.sessionPopupOpen ? -0.25 : ((sessMouse.containsMouse || root.focusedElement === 1) ? -0.05 : -0.10)
                topRimColor: (sessMouse.containsMouse || root.focusedElement === 1 || root.sessionPopupOpen) ? root.accentColor : "#ccffffff"
            }

            property real morphRatio: root.sessionPopupOpen ? 1.0 : 0.0; Behavior on morphRatio { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }

            Text { 
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 27 * s
                visible: sessionMorpher.morphRatio < 0.99; opacity: (1.0 - sessionMorpher.morphRatio)
                text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()
                font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.DemiBold; color: root.accentColor; font.letterSpacing: 2 * s
            }
            Column {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20 * s; visible: opacity > 0.01; opacity: sessionMorpher.morphRatio; spacing: 15 * s
                Text { text: "SESSION"; font.family: mainFont.name; font.pixelSize: 13 * s; color: root.accentColor; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 3 * s; opacity: 0.8 }
                ListView {
                    width: parent.width; height: 120 * s; model: typeof sessionModel !== "undefined" ? sessionModel : null; clip: true; spacing: 5 * s
                    delegate: Item {
                        width: parent.width; height: 35 * s
                        Rectangle { anchors.fill: parent; radius: 10 * s; color: "#1affffff"; visible: innerSessMouse.containsMouse || index === root.sessionIndex; opacity: (innerSessMouse.containsMouse || index === root.sessionIndex) ? 1.0 : 0.0 }
                        Text { anchors.centerIn: parent; text: (model.name || "UNNAMED").toUpperCase(); font.family: mainFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s; color: index === root.sessionIndex ? root.accentColor : "white" }
                        MouseArea { id: innerSessMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.sessionIndex = index; root.sessionPopupOpen = false } }
                    }
                }
                Text { text: "ESCAPE"; font.family: mainFont.name; font.pixelSize: 9 * s; color: "white"; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 4 * s; opacity: 0.4; MouseArea { anchors.fill: parent; onClicked: root.sessionPopupOpen = false; cursorShape: Qt.PointingHandCursor } }
            }
            scale: (root.focusedElement === 1 || sessMouse.containsMouse) ? 1.02 : 1.0
            MouseArea { id: sessMouse; anchors.fill: parent; hoverEnabled: true; visible: !root.sessionPopupOpen; onClicked: root.sessionPopupOpen = true; cursorShape: Qt.PointingHandCursor; onPressed: sessionMorpher.scale = 0.98; onReleased: sessionMorpher.scale = 1.0 }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }

        // Actions
        Row {
            width: parent.width; height: 50 * s; y: 285 * s; spacing: 20 * s
            opacity: (root.sessionPopupOpen || root.userPopupOpen) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Item { id: rebootBtn; x:0; y:0; width: (parent.width / 2) - 10 * s; height: 50 * s; layer.enabled: true
                property bool isFocused: root.focusedElement === 2
                layer.effect: DropShadow { transparentBorder: true; color: rebootBtn.isFocused ? "#40d3eaad" : "#35000000"; radius: rebootBtn.isFocused ? 30*s : 25*s; verticalOffset: 8 * s }
                scale: restMouse.pressed ? 0.98 : ((isFocused || restMouse.containsMouse) ? 1.04 : 1.0)
                LiquidGlass { glassRadius: 18 * s; blurBrightness: (restMouse.containsMouse || rebootBtn.isFocused) ? 0.20 : 0.10; glassTint: "#30101a10"; topRimColor: rebootBtn.isFocused ? root.accentColor : "#ccffffff" }
                Text { anchors.centerIn: parent; text: "REBOOT"; font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.DemiBold; color: "white"; opacity: (restMouse.containsMouse || rebootBtn.isFocused) ? 1.0 : 0.75 }
                MouseArea { id: restMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (typeof sddm !== "undefined") sddm.reboot() } cursorShape: Qt.PointingHandCursor }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
            Item { id: powerBtn; x:0; y:0; width: (parent.width / 2) - 10 * s; height: 50 * s; layer.enabled: true
                property bool isFocused: root.focusedElement === 3
                layer.effect: DropShadow { transparentBorder: true; color: powerBtn.isFocused ? "#40d3eaad" : "#35000000"; radius: powerBtn.isFocused ? 30*s : 25*s; verticalOffset: 8 * s }
                scale: shutMouse.pressed ? 0.98 : ((isFocused || shutMouse.containsMouse) ? 1.04 : 1.0)
                LiquidGlass { glassRadius: 18 * s; blurBrightness: (shutMouse.containsMouse || powerBtn.isFocused) ? 0.20 : 0.10; glassTint: "#30101a10"; topRimColor: powerBtn.isFocused ? root.accentColor : "#ccffffff" }
                Text { anchors.centerIn: parent; text: "POWER"; font.family: mainFont.name; font.pixelSize: 15 * s; font.weight: Font.DemiBold; color: "white"; opacity: (shutMouse.containsMouse || powerBtn.isFocused) ? 1.0 : 0.75 }
                MouseArea { id: shutMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (typeof sddm !== "undefined") sddm.powerOff() } cursorShape: Qt.PointingHandCursor }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
        }
    }

    // Helpers
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }
    
    // Boot
    NumberAnimation { id: fadeIn; target: root; property: "uiOpacity"; to: 1; duration: 2500; easing.type: Easing.OutCubic }
    Component.onCompleted: { fadeIn.start(); keyboard.numLock = true }
}
