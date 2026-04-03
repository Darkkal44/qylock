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

    property real uiOpacity: 0
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string activeUser: userModel.lastUser
    property bool sessionPopupOpen: false

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
        delegate: Item { property string name: model.name || "" }
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
                text: (userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 1) || "Traveler").toUpperCase()
                font.family: mainFont.name; font.pixelSize: 16 * s; font.letterSpacing: 2 * s
                color: root.gTextMain; font.bold: true
                style: Text.Outline; styleColor: root.isDarkTheme ? "#aa000000" : "#44ffffff"
            }
        }

        Column {
            anchors.centerIn: parent
            width: 600 * s
            spacing: 20 * s

            Image {
                source: "logo.png"
                width: 380 * s; fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.95
                layer.enabled: true
                layer.effect: DropShadow { radius: 10; color: "#88000000"; samples: 16 }
            }

            Item {
                width: 320 * s; height: 20 * s
                anchors.horizontalCenter: parent.horizontalCenter
                
                Rectangle {
                    width: parent.width; height: 1.5 * s
                    anchors.centerIn: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#d3bc8e" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    width: 10 * s; height: 10 * s; rotation: 45
                    color: "#050a15"; border.color: "#d3bc8e"; border.width: 1.5 * s
                    anchors.centerIn: parent
                    Rectangle { 
                        width: 4 * s; height: 4 * s; color: "#d3bc8e"; anchors.centerIn: parent; rotation: 45 
                    }
                }
            }

            Text {
                text: "TAP TO BEGIN"
                font.family: mainFont.name; font.pixelSize: 20 * s; font.letterSpacing: 6 * s
                color: root.gTextMain; anchors.horizontalCenter: parent.horizontalCenter
                style: Text.Outline; styleColor: root.isDarkTheme ? "#88000000" : "#22ffffff"
                opacity: 0.8
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.3; to: 0.9; duration: 2500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.9; to: 0.3; duration: 2500; easing.type: Easing.InOutSine }
                }
            }

            Item {
                width: 300 * s; height: 40 * s
                anchors.horizontalCenter: parent.horizontalCenter
                
                Rectangle {
                    anchors.fill: parent; color: "#40ffffff"; radius: 4 * s
                    border.color: passIn.activeFocus ? "#d3bc8e" : "transparent"; border.width: 1 * s
                }
                
                TextInput {
                    id: passIn
                    anchors.fill: parent
                    font.family: mainFont.name; font.pixelSize: 18 * s; color: root.gTextMain
                    echoMode: TextInput.Password; passwordCharacter: "◆"
                    horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                    
                    Text {
                        text: "PASSWORD"
                        visible: !parent.text && !parent.activeFocus
                        font: parent.font; color: root.gTextDim; anchors.centerIn: parent
                    }
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            var uname = userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 1)
                            sddm.login(uname, passIn.text, root.sessionIndex)
                        }
                    }
                }
            }

            Item { width: 1; height: 20 * s }

            Item {
                id: sessionBox
                width: 420 * s; height: 58 * s
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    anchors.fill: parent; color: "#aa1a243d"; radius: 4 * s
                    border.color: sesM.containsMouse ? "#d3bc8e" : "#44ffffff"
                    border.width: 1 * s
                }

                Rectangle {
                    width: 28 * s; height: 28 * s; rotation: 45
                    anchors.left: parent.left; anchors.leftMargin: 15 * s; anchors.verticalCenter: parent.verticalCenter
                    color: "#ece5d8"; border.color: "#888"; border.width: 1 * s
                    
                    Text {
                        text: "✓"
                        rotation: -45; anchors.centerIn: parent; color: "#1a243d"
                        font.pixelSize: 18 * s; font.bold: true
                    }
                }

                Text {
                    text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0) ? sessionModel.get(root.sessionIndex).name : "Select Realm"
                    anchors.centerIn: parent
                    font.family: mainFont.name; font.pixelSize: 22 * s; color: "#ece5d8"
                    font.letterSpacing: 1.5 * s
                }

                MouseArea { id: sesM; anchors.fill: parent; hoverEnabled: true; onClicked: root.sessionPopupOpen = !root.sessionPopupOpen }
            }

            Item { width: 1; height: 10 * s }
        }

        
        Text {
            text: "OSREL" + config.version_string + "_UID" + (Math.floor(100000000 + Math.random() * 900000000))
            anchors.left: parent.left; anchors.leftMargin: 40 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 30 * s
            font.family: mainFont.name; font.pixelSize: 14 * s; color: root.gTextMain; opacity: 0.7
        }

        Column {
            anchors.right: parent.right; anchors.rightMargin: 40 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 40 * s
            spacing: 15 * s

            Rectangle {
                width: 54 * s; height: 54 * s; radius: 10 * s; color: "#ece5d8"
                opacity: rM.containsMouse ? 1.0 : 0.8
                border.color: rM.containsMouse ? root.gGold : "#888"; border.width: 1.5 * s
                
                Canvas {
                    anchors.fill: parent; anchors.margins: 12 * s
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                        ctx.strokeStyle = "#1a243d"; ctx.lineWidth = 2.5 * s; ctx.lineCap = "round";
                        ctx.beginPath(); ctx.arc(width/2, height/2, width*0.35, -0.2, Math.PI*1.5); ctx.stroke();
                        ctx.fillStyle = "#1a243d"; ctx.beginPath(); ctx.moveTo(width*0.85, height*0.1); ctx.lineTo(width*0.95, height*0.4); ctx.lineTo(width*0.65, height*0.4); ctx.closePath(); ctx.fill();
                    }
                }
                Text { 
                    text: "Reboot"
                    anchors.right: parent.left; anchors.rightMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter
                    font.family: mainFont.name; font.pixelSize: 14 * s; color: root.gTextMain
                    style: Text.Outline; styleColor: root.isDarkTheme ? "#aa000000" : "#44ffffff"
                    visible: rM.containsMouse
                }
                MouseArea { id: rM; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot() }
                layer.enabled: true; layer.effect: DropShadow { radius: 6; color: "#aa000000" }
            }

            Rectangle {
                width: 54 * s; height: 54 * s; radius: 10 * s; color: "#ece5d8"
                opacity: pM.containsMouse ? 1.0 : 0.8
                border.color: pM.containsMouse ? root.gGold : "#888"; border.width: 1.5 * s
                
                Canvas {
                    anchors.fill: parent; anchors.margins: 12 * s
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                        ctx.strokeStyle = "#1a243d"; ctx.lineWidth = 2.5 * s; ctx.lineCap = "round";
                        ctx.beginPath(); ctx.arc(width/2, height/2, width*0.35, -Math.PI*0.25, -Math.PI*0.75, false); ctx.stroke();
                        ctx.beginPath(); ctx.moveTo(width/2, height*0.1); ctx.lineTo(width/2, height*0.45); ctx.stroke();
                    }
                }
                Text { 
                    text: "Power Off"
                    anchors.right: parent.left; anchors.rightMargin: 12 * s; anchors.verticalCenter: parent.verticalCenter
                    font.family: mainFont.name; font.pixelSize: 14 * s; color: root.gTextMain
                    style: Text.Outline; styleColor: root.isDarkTheme ? "#aa000000" : "#44ffffff"
                    visible: pM.containsMouse
                }
                MouseArea { id: pM; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff() }
                layer.enabled: true; layer.effect: DropShadow { radius: 6; color: "#aa000000" }
            }
        }
    }

    Item {
        id: popupOverlay
        anchors.fill: parent
        visible: root.sessionPopupOpen
        
        Rectangle { anchors.fill: parent; color: "#aa000000" }
        MouseArea { anchors.fill: parent; onClicked: root.sessionPopupOpen = false }

        Rectangle {
            width: 440 * s; height: 400 * s; anchors.centerIn: parent
            color: "#f01a243d"; radius: 8 * s; border.color: "#d3bc8e"; border.width: 2 * s
            
            Column {
                anchors.fill: parent; anchors.margins: 20 * s; spacing: 15 * s
                Text {
                    text: "SELECT REALM"; anchors.horizontalCenter: parent.horizontalCenter
                    font.family: mainFont.name; font.pixelSize: 18 * s; color: "#d3bc8e"; font.bold: true
                }
                ListView {
                    width: parent.width; height: 320 * s; model: sessionModel; clip: true; spacing: 8 * s
                    delegate: Item {
                        width: parent.width; height: 50 * s
                        Rectangle {
                            anchors.fill: parent; radius: 4 * s
                            color: (index === root.sessionIndex) ? "#3b4a6b" : (sM.containsMouse ? "#2a3554" : "transparent")
                            border.color: (index === root.sessionIndex) ? "#d3bc8e" : "transparent"
                            Text {
                                text: model.name; anchors.centerIn: parent
                                font.family: mainFont.name; font.pixelSize: 18 * s; color: "#ece5d8"
                            }
                            MouseArea { id: sM; anchors.fill: parent; hoverEnabled: true; onClicked: { root.sessionIndex = index; root.sessionPopupOpen = false } }
                        }
                    }
                }
            }
        }
    }

    Connections { target: sddm; function onLoginFailed() { passIn.text = ""; passIn.forceActiveFocus() } }
}
