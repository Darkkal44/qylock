import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    readonly property real s: (Screen.height / 768) * 0.75
    id: root
    width: Screen.width
    height: Screen.height
    color: "#050a15"
    focus: true
    Keys.onPressed: {
        if (!loginFormVisible && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            loginFormVisible = true
        }
    }

    property real uiOpacity: 0
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string activeUser: (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : userModel.lastUser
    property bool sessionPopupOpen: false
    property bool loginFormVisible: false

    readonly property string bgMode: config.background_mode || "time"
    readonly property string bgVideo: {
        if (bgMode === "static") {
            var idx = parseInt(config.background_index) || 1
            return ["day.mp4","night.mp4","dawn.mp4","dusk.mp4"][idx - 1] || "day.mp4"
        } else if (bgMode === "time") {
            var h = new Date().getHours()
            if (h >= 5  && h < 9)  return "dawn.mp4"
            if (h >= 9  && h < 17) return "day.mp4"
            if (h >= 17 && h < 20) return "dusk.mp4"
            return "night.mp4"
        } else {
            var imgs = ["day.mp4","night.mp4","dawn.mp4","dusk.mp4"]
            return imgs[Math.floor(Math.random() * imgs.length)]
        }
    }

    readonly property bool isDarkTheme: bgVideo === "night.mp4" || bgVideo === "dusk.mp4" || bgVideo === "dawn.mp4"
    readonly property color gTextMain: isDarkTheme ? "#ece5d8" : "#1a243d"
    readonly property color gTextDim: isDarkTheme ? "#88ffffff" : "#aa1a243d"
    readonly property color gGold: "#d3bc8e"

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: passIn.forceActiveFocus() }

    ListView {
        id: sessionHelper
        model: sessionModel; currentIndex: root.sessionIndex
        opacity: 0; width: 100; height: 100; z: -100
        delegate: Item { property string sName: model.name || "" }
    }

    ListView {
        id: userHelper
        model: userModel; currentIndex: root.userIndex
        opacity: 0; width: 100; height: 100; z: -100
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }

    Item {
        id: bgContainer
        anchors.fill: parent
        clip: true

        MediaPlayer {
            id: bgVideoPlayer
            source: root.bgVideo
            loops: MediaPlayer.Infinite
            autoPlay: true
            videoOutput: bgVideoOutput
        }
        VideoOutput {
            id: bgVideoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#44000000" }
            }
        }

        Repeater {
            model: 24
            Item {
                property real px: Math.random() * root.width
                property real py: Math.random() * root.height
                property int  dur: 12000 + Math.random() * 8000
                x: px; y: py
                Rectangle {
                    width: 2 * s; height: width; radius: width/2
                    color: root.isDarkTheme ? "#d3bc8e" : "#1a243d"
                    opacity: 0
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: root.isDarkTheme ? 0.5 : 0.3; duration: 3000 }
                        NumberAnimation { from: root.isDarkTheme ? 0.5 : 0.3; to: 0; duration: 3000 }
                        PauseAnimation { duration: Math.random() * 4000 }
                    }
                    NumberAnimation on y { from: 0; to: -100 * s; duration: 15000; loops: Animation.Infinite }
                }
            }
        }
    }

    Item {
        id: mainUI
        anchors.fill: parent
        opacity: root.uiOpacity
        Component.onCompleted: NumberAnimation { target: root; property: "uiOpacity"; from: 0; to: 1; duration: 1200; easing.type: Easing.OutCubic }

        // Top Left: Username
        Row {
            anchors.left: parent.left; anchors.leftMargin: 40 * s
            anchors.top: parent.top; anchors.topMargin: 40 * s
            spacing: 12 * s
            
            Rectangle {
                width: 14 * s; height: 14 * s; rotation: 45
                color: root.gGold; anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: 6 * s; height: 6 * s; color: root.isDarkTheme ? "#1a243d" : "white"; anchors.centerIn: parent }
            }
            Text {
                text: (activeUser || "USER").toUpperCase()
                font.family: mainFont.name; font.pixelSize: 17 * s; font.letterSpacing: 1.5 * s
                color: root.gTextMain
                anchors.verticalCenter: parent.verticalCenter
                layer.enabled: true
                layer.effect: DropShadow { radius: 4; color: "#99000000"; samples: 10; x: 1; y: 2 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (userModel && userModel.rowCount() > 0)
                            root.userIndex = (root.userIndex + 1) % userModel.rowCount()
                    }
                }
            }
        }

        // Logo at the center
        Image {
            id: centerLogo
            source: "logo.png"
            width: 380 * s; fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -100 * s // Slightly higher than dead center
            opacity: root.loginFormVisible ? 0 : 0.95
            layer.enabled: true
            layer.effect: DropShadow { radius: 15; color: "#aa000000"; samples: 24 }
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
            visible: opacity > 0
        }

        // Center-Bottom UI Area (Login)
        Item {
            id: bottomUiContainer
            width: 600 * s; height: 350 * s
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80 * s

            // Divider / Ornament (Stays at bottom center)
            Item {
                width: 480 * s; height: 10 * s
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10 * s
                opacity: root.loginFormVisible ? 0.3 : 0.8
                Behavior on opacity { NumberAnimation { duration: 500 } }
                
                Rectangle {
                    width: parent.width; height: 1 * s
                    anchors.centerIn: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: "#66d3bc8e" }
                        GradientStop { position: 0.5; color: "#d3bc8e" }
                        GradientStop { position: 0.8; color: "#66d3bc8e" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                
                // Central Ornate Diamond
                Rectangle {
                    width: 8 * s; height: 8 * s; rotation: 45
                    color: "#050a15"; border.color: "#d3bc8e"; border.width: 1 * s
                    anchors.centerIn: parent
                    
                    Rectangle {
                        width: 3 * s; height: 3 * s
                        color: "#d3bc8e"; anchors.centerIn: parent; rotation: 45
                    }
                }

                // Side dots
                Rectangle { width: 2 * s; height: 2 * s; radius: 1; color: "#d3bc8e"; anchors.verticalCenter: parent.verticalCenter; anchors.horizontalCenterOffset: -40 * s; anchors.horizontalCenter: parent.horizontalCenter }
                Rectangle { width: 2 * s; height: 2 * s; radius: 1; color: "#d3bc8e"; anchors.verticalCenter: parent.verticalCenter; anchors.horizontalCenterOffset: 40 * s; anchors.horizontalCenter: parent.horizontalCenter }
            }

            // LOGIN SECTION
            Item {
                width: 600 * s; height: 200 * s
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30 * s
                visible: root.loginFormVisible
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                
                Column {
                    id: loginFields
                    anchors.fill: parent
                    spacing: 20 * s

                    Item {
                        width: 460 * s; height: 56 * s; anchors.horizontalCenter: parent.horizontalCenter
                        
                        Rectangle {
                            anchors.fill: parent; color: "#aa1a243d"; radius: 6 * s
                            border.color: passIn.activeFocus ? root.gGold : "#55ffffff"
                            border.width: 1.5 * s
                            Behavior on border.color { ColorAnimation { duration: 250 } }
                        }
                        
                        TextInput {
                            id: passIn
                            anchors.fill: parent; anchors.leftMargin: 20 * s; anchors.rightMargin: 20 * s
                            font.family: mainFont.name; font.pixelSize: 20 * s; color: root.gTextMain
                            echoMode: TextInput.Password; passwordCharacter: "✦"
                            horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                            cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                            selectionColor: root.gGold
                            property bool wasClicked: false
                            
                            Text {
                                text: "ENTER PASSWORD"
                                opacity: passIn.text.length === 0 ? 0.6 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                                font: parent.font; color: root.gTextDim; anchors.centerIn: parent
                            }
                            
                            Rectangle {
                                id: customCursor
                                width: 3 * s; height: 24 * s; radius: 1; color: root.gGold
                                anchors.verticalCenter: parent.verticalCenter
                                x: passIn.cursorRectangle.x
                                visible: passIn.focus && (passIn.text.length > 0 || passIn.wasClicked)
                                SequentialAnimation {
                                    loops: Animation.Infinite; running: customCursor.visible
                                    NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.1; duration: 400 }
                                    NumberAnimation { target: customCursor; property: "opacity"; from: 0.1; to: 1; duration: 400 }
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { passIn.forceActiveFocus(); passIn.wasClicked = true } }
                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    var uname = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : userModel.lastUser
                                    sddm.login(uname, passIn.text, root.sessionIndex)
                                }
                            }
                        }
                    }

                    // Session Switcher
                    Item {
                        id: sessionBox
                        width: 460 * s; height: 44 * s
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            anchors.fill: parent
                            color: "#cc26303e"
                            radius: 2 * s
                        }

                        // Filled cream diamond with dark tick — left side
                        Item {
                            width: 28 * s; height: 28 * s
                            anchors.left: parent.left
                            anchors.leftMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 18 * s; height: 18 * s
                                rotation: 45
                                color: "#d4c9a8"
                                anchors.centerIn: parent
                            }
                            Text {
                                text: "✓"
                                anchors.centerIn: parent
                                color: "#26303e"
                                font.pixelSize: 14 * s
                                font.bold: true
                            }
                        }

                        // Session name — centered
                        Text {
                            text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0)
                                  ? sessionHelper.currentItem.sName : "Select Realm"
                            anchors.centerIn: parent
                            font.family: mainFont.name
                            font.pixelSize: 18 * s
                            color: "white"
                        }

                        MouseArea {
                            id: sesM; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sessionPopupOpen = true
                        }
                    }
                }
            }
        }

        
        // Version Info
        Text {
            text: "OSRELWin3.2.0_R11611027_S11212885_D11643430"
            anchors.left: parent.left; anchors.leftMargin: 40 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 15 * s
            font.family: mainFont.name; font.pixelSize: 11 * s; color: "white"; opacity: 0.8
        }

        // CLICK TO BEGIN bar (Fading edges gradient)
        Rectangle {
            id: clickToBeginBar
            width: parent.width; height: 34 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 42 * s
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: "#77000000" }
                GradientStop { position: 0.8; color: "#77000000" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            visible: !root.loginFormVisible
            
            Text {
                text: "CLICK TO BEGIN"
                font.family: mainFont.name; font.pixelSize: 16 * s; font.letterSpacing: 4 * s
                color: "white"; anchors.centerIn: parent
                opacity: 0.9
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.4; to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.4; duration: 1800; easing.type: Easing.InOutSine }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.loginFormVisible = true
            }
        }

        // Power & System controls
        Item {
            anchors.fill: parent
            
            // Bottom Left: Power
            Rectangle {
                width: 44 * s; height: 44 * s; radius: width/2; color: "white"
                anchors.left: parent.left; anchors.leftMargin: 35 * s
                anchors.bottom: parent.bottom; anchors.bottomMargin: 80 * s
                
                
                Canvas {
                    anchors.fill: parent; anchors.margins: 10 * s
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                        ctx.strokeStyle = "#1a243d"; ctx.lineWidth = 2 * s; ctx.lineCap = "round";
                        ctx.beginPath(); ctx.arc(width/2, height/2, width*0.35, -Math.PI*0.25, -Math.PI*0.75, false); ctx.stroke();
                        ctx.beginPath(); ctx.moveTo(width/2, height*0.15); ctx.lineTo(width/2, height*0.5); ctx.stroke();
                    }
                }
                MouseArea { 
                    id: pM; anchors.fill: parent; hoverEnabled: true
                    onClicked: sddm.powerOff()
                    cursorShape: Qt.PointingHandCursor 
                }
                layer.enabled: true; layer.effect: DropShadow { radius: 6; color: "#aa000000" }
            }

            // Bottom Right: Reboot only
            Rectangle {
                width: 44 * s; height: 44 * s; radius: width/2; color: "white"
                anchors.right: parent.right; anchors.rightMargin: 35 * s
                anchors.bottom: parent.bottom; anchors.bottomMargin: 80 * s

                Canvas {
                    anchors.fill: parent; anchors.margins: 12 * s
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = "#1a243d";
                        ctx.lineWidth = 2.5 * s;
                        ctx.lineCap = "round";
                        
                        var r = width * 0.4;
                        var cx = width / 2;
                        var cy = height / 2;
                        
                        // Circular Arrow
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI * 0.1, Math.PI * 1.6);
                        ctx.stroke();
                        
                        // Arrow Head
                        ctx.beginPath();
                        ctx.moveTo(cx + r - 4 * s, cy - 2 * s);
                        ctx.lineTo(cx + r, cy + 2 * s);
                        ctx.lineTo(cx + r + 4 * s, cy - 2 * s);
                        ctx.stroke();
                    }
                }

                MouseArea { 
                    id: rM; anchors.fill: parent; hoverEnabled: true
                    onClicked: sddm.reboot()
                    cursorShape: Qt.PointingHandCursor 
                }
                layer.enabled: true; layer.effect: DropShadow { radius: 6; color: "#aa000000" }
            }
        }
    }

    Item {
        id: popupOverlay
        anchors.fill: parent
        visible: root.sessionPopupOpen || popupContent.opacity > 0
        
        Rectangle { 
            anchors.fill: parent; color: "#cc000000"
            opacity: root.sessionPopupOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        MouseArea { anchors.fill: parent; onClicked: root.sessionPopupOpen = false }

        Rectangle {
            id: popupContent
            width: 440 * s; height: 400 * s; anchors.centerIn: parent
            color: "#f01a243d"; radius: 12 * s; border.color: "#d3bc8e"; border.width: 2 * s
            
            opacity: root.sessionPopupOpen ? 1 : 0
            scale: root.sessionPopupOpen ? 1 : 0.8
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

            Column {
                anchors.fill: parent; anchors.margins: 25 * s; spacing: 20 * s
                Text {
                    text: "SELECT REALM"; anchors.horizontalCenter: parent.horizontalCenter
                    font.family: mainFont.name; font.pixelSize: 22 * s; color: "#d3bc8e"; font.bold: true
                    font.letterSpacing: 2 * s
                }
                ListView {
                    width: parent.width; height: 300 * s; model: sessionModel; clip: true; spacing: 10 * s
                    delegate: Item {
                        width: parent.width; height: 54 * s
                        Rectangle {
                            anchors.fill: parent; radius: 6 * s
                            color: (index === root.sessionIndex) ? "#3b4a6b" : (sM.containsMouse ? "#2a3554" : "transparent")
                            border.color: (index === root.sessionIndex) ? "#d3bc8e" : "transparent"
                            border.width: 1.5 * s
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                text: model.name.toUpperCase(); anchors.centerIn: parent
                                font.family: mainFont.name; font.pixelSize: 18 * s; color: "#ece5d8"
                                font.letterSpacing: 1 * s
                            }
                            MouseArea { 
                                id: sM; anchors.fill: parent; hoverEnabled: true
                                onClicked: { root.sessionIndex = index; root.sessionPopupOpen = false } 
                            }
                        }
                    }
                }
            }
        }
    }

    Connections { target: sddm; function onLoginFailed() { passIn.text = ""; passIn.forceActiveFocus() } }
}
