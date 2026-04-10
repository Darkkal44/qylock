import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel

Item {
    id: root
    width: 1920
    height: 1080
    readonly property real s: width / 1920

    // Theme Palette
    readonly property color fg:         "#fdfaf2" 
    readonly property color gold:       "#c9a063" 
    readonly property color orbitClr:    "#ffffff" 
    
    // Core State
    property int  userIndex:    userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int  sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool sessionMenuOpen: false
    property bool interactionMode: false 

    FontLoader {
        id: titleFont
        source: "font/Cinzel-Bold.ttf"
    }

    ListView { 
        id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; z: -100
        delegate: Item { property string sName: (model && model.name) ? model.name : "" }
    }
    
    ListView { 
        id: userHelper; model: userModel; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; z: -100
        delegate: Item { 
            property string uName: (model && (model.realName || model.name)) ? (model.realName || model.name) : ""
            property string uLogin: (model && model.name) ? model.name : "" 
        } 
    }

    function login() {
        var n = (userHelper.currentItem && userHelper.currentItem.uName !== "") ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(n, passInput.text, root.sessionIndex)
    }

    function startInteraction() {
        root.interactionMode = true
        passInput.focus = true
    }

    function toggleUser() {
        root.userIndex = (root.userIndex + 1) % userModel.count
    }

    // Video Background
    Rectangle { anchors.fill: parent; color: "#000000"; z: -1000 }
    
    MediaPlayer { 
        id: player; source: "bg.mp4"; videoOutput: bgVideo; loops: MediaPlayer.Infinite
        Component.onCompleted: player.play()
    }
    
    VideoOutput { id: bgVideo; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop; z: -500 }
    
    Rectangle { 
        id: dimOverlay
        anchors.fill: parent; z: -300
        color: "#000000"
        opacity: root.interactionMode ? 0.75 : 0.4
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    }

    // Top Clock
    Item {
        id: cornerClock
        anchors.left: parent.left; anchors.leftMargin: 80 * s
        anchors.top: parent.top; anchors.topMargin: 60 * s
        width: 300 * s; height: 80 * s; z: 1000
        opacity: root.interactionMode ? 0.3 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600 } }
        
        Row {
            spacing: 12 * s
            Text {
                id: hhLab
                text: Qt.formatTime(new Date(), "HH:mm")
                font.family: titleFont.name; font.pixelSize: 64 * s; font.letterSpacing: 4 * s; color: root.fg
                layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 10 }
            }
            Rectangle { width: 1.2 * s; height: 40 * s; color: root.gold; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 1 * s
                Text { text: Qt.formatDate(new Date(), "dddd").toUpperCase(); font.family: titleFont.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s; color: root.gold }
                Text { text: Qt.formatDate(new Date(), "MMM dd").toUpperCase(); font.family: titleFont.name; font.pixelSize: 10 * s; font.letterSpacing: 3 * s; color: root.fg; opacity: 0.6 }
            }
        }
        Timer { 
            interval: 1000; running: true; repeat: true
            onTriggered: { hhLab.text = Qt.formatTime(new Date(), "HH:mm") }
        }
    }

    // Logo Center
    Image {
        id: mainLogo
        source: "logo.png"
        width: 650 * s; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
        opacity: (root.interactionMode) ? 0.15 : 1.0; z: 100
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
    }

    // Console Cluster
    Item {
        id: promptZone
        anchors.bottom: parent.bottom; anchors.bottomMargin: 150 * s
        anchors.horizontalCenter: parent.horizontalCenter
        width: 800 * s; height: 260 * s; z: 200

        Item {
            id: startPrompt
            anchors.fill: parent; opacity: root.interactionMode ? 0 : 1.0; visible: opacity > 0
            scale: startMa.containsMouse ? 1.05 : 1.0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Item {
                id: startOrbit
                anchors.centerIn: parent; width: 320 * s; height: 90 * s; rotation: -10
                Shape {
                    anchors.fill: parent; opacity: 0.15
                    ShapePath {
                        strokeWidth: 1.2; strokeColor: root.orbitClr; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 160 * s; centerY: 45 * s; radiusX: 160 * s; radiusY: 45 * s; startAngle: 0; sweepAngle: 360 }
                    }
                }
                Rectangle {
                    width: 6 * s; height: 6 * s; radius: 3 * s; color: root.orbitClr; opacity: 0.6
                    property real t: 0
                    NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 9000; loops: Animation.Infinite; running: !root.interactionMode }
                    x: (160 * s) + (160 * s * Math.cos(t)) - (width / 2); y: (45 * s) + (45 * s * Math.sin(t)) - (height / 2)
                }
            }
            Text {
                text: "START"; font.family: titleFont.name; font.pixelSize: 28 * s; font.letterSpacing: 14 * s; color: root.fg
                anchors.centerIn: parent; layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 12 }
            }
            MouseArea { id: startMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.startInteraction() }
        }

        Item {
            id: inputZone
            anchors.fill: parent; opacity: root.interactionMode ? 1.0 : 0; visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 400 } }

            // User Toggle
            Item {
                id: userSwitcher
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                width: 500 * s; height: 60 * s
                
                Text {
                    id: userLabel
                    text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "USER").toUpperCase()
                    font.family: titleFont.name; font.pixelSize: 32 * s; font.letterSpacing: 10 * s; color: root.fg
                    anchors.centerIn: parent; layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 15 } 
                    MouseArea { id: userToggleMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleUser() }
                }
            }

            Column {
                anchors.top: userSwitcher.bottom; anchors.topMargin: 20 * s
                anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; spacing: 10 * s
                
                Item {
                    width: 600 * s; height: 60 * s; anchors.horizontalCenter: parent.horizontalCenter
                    TextInput {
                        id: passInput; width: contentWidth + 10; height: parent.height; anchors.centerIn: parent
                        verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignLeft
                        echoMode: TextInput.Password; passwordCharacter: "✦"; font.family: titleFont.name; font.pixelSize: 32 * s; font.letterSpacing: 15 * s; color: root.fg
                        selectionColor: root.gold
                        cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                        onAccepted: root.login()
                        onActiveFocusChanged: { if (!activeFocus && text.length === 0) root.interactionMode = false }
                        
                        Rectangle {
                            id: cursorRect; width: 2.2 * s; height: 32 * s; color: root.gold; anchors.verticalCenter: parent.verticalCenter
                            x: passInput.cursorRectangle.x - (width / 2)
                            opacity: (passInput.focus && root.interactionMode) ? 1.0 : 0
                            SequentialAnimation {
                                loops: Animation.Infinite; running: cursorRect.opacity > 0
                                NumberAnimation { target: cursorRect; property: "opacity"; from: 1; to: 0.1; duration: 450 }
                                NumberAnimation { target: cursorRect; property: "opacity"; from: 0.1; to: 1; duration: 450 }
                            }
                        }
                    }
                }
                Rectangle { width: 350 * s; height: 1.2 * s; color: root.gold; opacity: 0.5; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }

    // Left Session
    Item {
        id: sessionGroup
        anchors.left: parent.left; anchors.leftMargin: 100 * s
        anchors.bottom: parent.bottom; anchors.bottomMargin: 80 * s
        width: 350 * s; height: 50 * s; z: 2000
        opacity: root.interactionMode ? 0.3 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600 } }

        Item {
            anchors.fill: parent
            Text {
                id: sessionLabel
                text: (sessionHelper.currentItem ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()
                font.family: titleFont.name; font.pixelSize: 15 * s
                font.letterSpacing: (sMa.containsMouse || root.sessionMenuOpen) ? 8 * s : 6 * s
                color: (sMa.containsMouse || root.sessionMenuOpen) ? root.gold : root.fg
                anchors.left: parent.left; anchors.leftMargin: 25 * s; opacity: 0.9
                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on font.letterSpacing { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
                layer.enabled: true; layer.effect: DropShadow { color: "#cc000000"; radius: 10 }
            }
            Text {
                text: "✦"; font.pixelSize: 12 * s; color: root.gold; anchors.verticalCenter: sessionLabel.verticalCenter
                anchors.left: parent.left; opacity: (sMa.containsMouse || root.sessionMenuOpen) ? 1.0 : 0
                x: (sMa.containsMouse || root.sessionMenuOpen) ? 0 : -5 * s
                Behavior on opacity { NumberAnimation { duration: 350 } }
                Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea { id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.sessionMenuOpen = !root.sessionMenuOpen }

        Item {
            id: sMenu
            anchors.bottom: parent.top; anchors.bottomMargin: 20 * s
            anchors.left: parent.left; width: 320 * s
            height: root.sessionMenuOpen ? (40 * s * sessionModel.count) + 20 : 0; clip: true
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            
            Rectangle { 
                anchors.fill: parent
                color: "#111111"
                opacity: 0.6
                radius: 4 * s
                layer.enabled: true
                layer.effect: DropShadow { color: "#aa000000"; radius: 15 }
            }
            
            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1.2 * s; color: root.gold; opacity: 0.4 }
            
            Column {
                anchors.fill: parent; anchors.leftMargin: 15 * s; anchors.topMargin: 10 * s; spacing: 8 * s
                Repeater {
                    model: sessionModel
                    delegate: Item {
                        width: 280 * s; height: 32 * s; property bool itemHover: mMa.containsMouse
                        Text {
                            text: "✦"; font.pixelSize: 12 * s; color: root.gold; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            opacity: (root.sessionIndex === index || itemHover) ? 1.0 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        Text {
                            text: model.name.toUpperCase(); font.family: titleFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s
                            color: root.fg; opacity: (root.sessionIndex === index || itemHover) ? 1.0 : 0.4
                            anchors.left: parent.left; anchors.leftMargin: 25 * s; anchors.verticalCenter: parent.verticalCenter
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        MouseArea { id: mMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.sessionIndex = index; root.sessionMenuOpen = false } }
                    }
                }
            }
        }
    }

    // Right System
    Row {
        id: sysCommands
        anchors.right: parent.right; anchors.rightMargin: 100 * s
        anchors.bottom: parent.bottom; anchors.bottomMargin: 80 * s
        spacing: 60 * s; z: 1000
        opacity: root.interactionMode ? 0.3 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600 } }

        Repeater {
            model: [
                { id: "restart", text: "REBOOT",  action: function() { sddm.reboot() } },
                { id: "power",   text: "SHUTDOWN", action: function() { sddm.powerOff() } }
            ]
            delegate: Item {
                width: 200 * s; height: 40 * s
                Text {
                    id: cmdText
                    text: modelData.text; font.family: titleFont.name; font.pixelSize: 15 * s; font.letterSpacing: bMa.containsMouse ? 8 * s : 6 * s; color: bMa.containsMouse ? root.gold : root.fg
                    anchors.right: parent.right; anchors.rightMargin: 25 * s; transformOrigin: Item.Right
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on font.letterSpacing { NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
                    layer.enabled: true; layer.effect: DropShadow { color: "#cc000000"; radius: 10 }
                }
                Text {
                    text: "✦"; font.pixelSize: 12 * s; color: root.gold; anchors.verticalCenter: cmdText.verticalCenter
                    anchors.right: parent.right; opacity: bMa.containsMouse ? 1.0 : 0; anchors.rightMargin: bMa.containsMouse ? 0 : -5 * s
                    Behavior on opacity { NumberAnimation { duration: 350 } }
                    Behavior on anchors.rightMargin { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                }
                MouseArea { id: bMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.action() }
            }
        }
    }

    focus: true
    Keys.onPressed: (event) => { if (!root.interactionMode) { if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || (event.text.length > 0 && event.text[0].match(/[a-z0-9]/i))) { root.startInteraction() } } }
}
