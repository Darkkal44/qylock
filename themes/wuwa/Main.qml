import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import QtMultimedia 5.15
import Qt.labs.folderlistmodel 2.15
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0a0e18"

    property real uiOpacity: 0
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property bool sessionPopupOpen: false

     
    readonly property color wCyan:       "#9ecfdf"
    readonly property color wCyanDim:    "#6a9fb5"
    readonly property color wCyanGlow:   "#c8e8f0"
    readonly property color wSilver:     "#d4dae0"
    readonly property color wGhost:      "#8899aa"
    readonly property color wPanel:      "#1a2030"
    readonly property color wPanelLight: "#222e40"
    readonly property color wWhite:      "#eaf0f6"
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    ListView {
        id: sessionHelper
        model: sessionModel; currentIndex: root.sessionIndex
        visible: false
        delegate: Item { property string name: model.name || "" }
    }

        Item {
        id: bgContainer
        anchors.fill: parent
        clip: true

        Video {
            id: bgVideoPlayer
            anchors.fill: parent
            source: "bg.mp4"
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            autoPlay: true
            muted: false
            volume: 0.85
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "#cc060810" }
                GradientStop { position: 0.28; color: "#66060810" }
                GradientStop { position: 0.45; color: "transparent" }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.65; color: "transparent" }
                GradientStop { position: 0.82; color: "#55060810" }
                GradientStop { position: 1.0;  color: "#aa060810" }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.8; color: "transparent" }
                GradientStop { position: 1.0; color: "#88060810" }
            }
        }

        Repeater {
            model: 22
            Item {
                property real px: Math.random() * root.width * 0.35
                property real py: root.height * 0.4 + Math.random() * root.height * 0.6
                property real sz: (1 + Math.random() * 2) * s
                x: px; y: py

                Rectangle {
                    width: sz; height: width; radius: width / 2
                    color: Math.random() > 0.4 ? root.wCyan : root.wWhite
                    opacity: 0
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation { duration: Math.random() * 4000 }
                        NumberAnimation { from: 0; to: 0.5; duration: 2500; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 0.5; to: 0; duration: 3000; easing.type: Easing.InQuad }
                    }
                    NumberAnimation on y {
                        from: 0; to: -180 * s
                        duration: 9000 + Math.random() * 7000
                        loops: Animation.Infinite
                    }
                }
            }
        }
    }

        Item {
        id: mainUI
        anchors.fill: parent
        opacity: root.uiOpacity

        Component.onCompleted: NumberAnimation {
            target: root; property: "uiOpacity"
            from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic
        }
        Image {
            source: "logo.png"
            width: 200 * s
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left; anchors.leftMargin: 44 * s
            anchors.top: parent.top; anchors.topMargin: 32 * s
            opacity: 0.92

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.8; to: 0.96; duration: 4000; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.96; to: 0.8; duration: 4000; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.right: parent.right; anchors.rightMargin: 44 * s
            anchors.top: parent.top; anchors.topMargin: 36 * s
            text: "OS_" + Qt.platform.os.toUpperCase() + "_Product_0.9.0_" + Math.floor(1000000 + Math.random() * 9000000) + "_0.9.3_" + Math.floor(1000000 + Math.random() * 9000000)
            font.family: mainFont.name; font.pixelSize: 11 * s
            color: root.wGhost; opacity: 0.55
            font.letterSpacing: 0.5 * s
        }

        Column {
            id: loginPanel
            anchors.left: parent.left; anchors.leftMargin: 44 * s
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 80 * s
            spacing: 16 * s
            width: 300 * s

            Item {
                width: parent.width; height: 32 * s

                Rectangle {
                    width: userRow.width + 32 * s; height: parent.height
                    anchors.left: parent.left
                    color: uMouse.containsMouse ? "#88000000" : "#66000000"
                    radius: 16 * s
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Row {
                    id: userRow
                    anchors.left: parent.left; anchors.leftMargin: 16 * s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12 * s

                    Rectangle {
                        width: 8 * s; height: 8 * s; rotation: 45
                        color: root.wCyan
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on rotation {
                            loops: Animation.Infinite
                            NumberAnimation { from: 45; to: 90;  duration: 4000; easing.type: Easing.InOutCubic }
                            NumberAnimation { from: 90; to: 45;  duration: 4000; easing.type: Easing.InOutCubic }
                        }
                    }
                    Text {
                        id: userNameText
                        text: {
                            var _forceUpdate = userModel.count; // Force reactivity when model populates
                            var realName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1)
                            return (realName ? realName : "Rover").toUpperCase()
                        }
                        font.family: mainFont.name; font.pixelSize: 14 * s
                        font.letterSpacing: 2 * s; font.bold: true
                        color: root.wWhite
                    }
                }

                MouseArea {
                    id: uMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        root.userIndex = (root.userIndex + 1) % userModel.count
                        userModel.lastIndex = root.userIndex
                        sddm.userIndex = root.userIndex
                    }
                }
            }

            Rectangle {
                width: parent.width * 0.6; height: 1 * s
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.wCyanDim }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                opacity: 0.6
            }

            Item {
                id: passInContainer
                width: parent.width; height: 46 * s

                Rectangle {
                    anchors.fill: parent
                    color: "#88000000"
                    radius: 6 * s
                    border.color: passIn.activeFocus ? root.wCyan : "#44ffffff"
                    border.width: 1.5 * s
                    Behavior on border.color { ColorAnimation { duration: 250 } }
                }

                Rectangle {
                    id: passPulse
                    anchors.fill: parent; color: "transparent"; radius: 6 * s
                    border.color: root.wCyanGlow
                    border.width: 1.5 * s
                    opacity: passIn.activeFocus ? (jitterAnim.running ? 0.9 : 0.2) : 0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }

                    SequentialAnimation {
                        id: jitterAnim
                        NumberAnimation { target: passPulse; property: "opacity"; from: 0.2; to: 0.9; duration: 60; easing.type: Easing.OutCubic }
                        NumberAnimation { target: passPulse; property: "opacity"; from: 0.9; to: 0.2; duration: 400; easing.type: Easing.InCubic }
                    }
                }

                TextInput {
                    id: passIn
                    anchors.fill: parent
                    anchors.leftMargin: 16 * s; anchors.rightMargin: 16 * s
                    font.family: mainFont.name; font.pixelSize: 15 * s
                    font.letterSpacing: 5 * s
                    color: root.wWhite
                    echoMode: TextInput.Password; passwordCharacter: "*"
                    horizontalAlignment: TextInput.AlignLeft
                    verticalAlignment: TextInput.AlignVCenter
                    onTextEdited: jitterAnim.restart()

                    Text {
                        text: "Enter password..."
                        visible: !parent.text && !parent.activeFocus
                        font.family: mainFont.name; font.pixelSize: 13 * s
                        font.letterSpacing: 1 * s
                        color: "#77ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            var uname = userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 1)
                            sddm.login(uname, passIn.text, root.sessionIndex)
                        }
                    }
                }
            }

            Item {
                width: parent.width; height: 34 * s

                Rectangle {
                    anchors.fill: parent
                    color: "#55000000"; radius: 5 * s
                    border.color: sesMouse.containsMouse ? root.wCyanDim : "#33ffffff"
                    border.width: 1 * s
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                }

                Row {
                    anchors.left: parent.left; anchors.leftMargin: 12 * s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * s

                    Rectangle {
                        width: 6 * s; height: 6 * s; radius: 3 * s
                        color: root.wCyan
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: (sessionHelper.currentItem && sessionHelper.currentItem.name) ? sessionHelper.currentItem.name : "Select Session"
                        font.family: mainFont.name; font.pixelSize: 12 * s
                        font.letterSpacing: 0.5 * s
                        color: root.wSilver
                    }
                }

                MouseArea { id: sesMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.sessionPopupOpen = !root.sessionPopupOpen }
            }

        }
        Column {
            id: rightActionCol
            anchors.right: parent.right; anchors.rightMargin: 60 * s
            anchors.top: parent.top; anchors.topMargin: 120 * s
            spacing: 8 * s
            Item {
                width: 64 * s; height: 74 * s

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; width: 48 * s; height: 48 * s; radius: 24 * s
                    color: "#77000000"
                    opacity: restartMouse.containsMouse ? 1.0 : 0.5
                    scale: restartMouse.containsMouse ? 1.08 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
                    Behavior on scale  { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
                }
                Canvas {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: 8 * s
                    width: 32 * s; height: 32 * s
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                        ctx.strokeStyle = root.wWhite; ctx.lineWidth = 2 * s; ctx.lineCap = "round";
                        ctx.beginPath(); ctx.arc(width/2, height/2, width*0.33, -Math.PI*0.7, Math.PI*0.8); ctx.stroke();
                        ctx.fillStyle = root.wWhite;
                        ctx.beginPath();
                        ctx.moveTo(width*0.2, height*0.18);
                        ctx.lineTo(width*0.38, height*0.06);
                        ctx.lineTo(width*0.38, height*0.32);
                        ctx.closePath(); ctx.fill();
                    }
                }
                Text {
                    text: "Restart"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    font.family: mainFont.name; font.pixelSize: 12 * s
                    color: root.wWhite; opacity: 0.85
                }
                MouseArea { id: restartMouse; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot() }
            }
            Item {
                width: 64 * s; height: 74 * s

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; width: 48 * s; height: 48 * s; radius: 24 * s
                    color: "#77000000"
                    opacity: shutdownMouse.containsMouse ? 1.0 : 0.5
                    scale: shutdownMouse.containsMouse ? 1.08 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
                    Behavior on scale  { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
                }
                Canvas {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: 8 * s
                    width: 32 * s; height: 32 * s
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
                        ctx.strokeStyle = root.wWhite; ctx.lineWidth = 2 * s; ctx.lineCap = "round";
                        ctx.beginPath(); ctx.moveTo(width/2, height*0.1); ctx.lineTo(width/2, height*0.45); ctx.stroke();
                        ctx.beginPath(); ctx.arc(width/2, height/2, width*0.33, -Math.PI*0.65, -Math.PI*0.35, true); ctx.stroke();
                    }
                }
                Text {
                    text: "Shutdown"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    font.family: mainFont.name; font.pixelSize: 12 * s
                    color: root.wWhite; opacity: 0.85
                }
                MouseArea { id: shutdownMouse; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff() }
            }
        }

                Text {
            anchors.left: parent.left; anchors.leftMargin: 44 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 26 * s
            text: "Kuro Games  ·  Wuthering Waves"
            font.family: mainFont.name; font.pixelSize: 11 * s
            color: root.wGhost; opacity: 0.5
            font.letterSpacing: 0.5 * s
        }
        Item {
            id: centerCTA
            width: parent.width * 0.82
            height: 40 * s
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 68 * s

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.20; color: "#aa0a0e14" }
                    GradientStop { position: 0.80; color: "#aa0a0e14" }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
            }

            Rectangle {
                width: parent.width; height: 1 * s
                anchors.top: parent.top
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.20; color: "#40ffffff" }
                    GradientStop { position: 0.80; color: "#40ffffff" }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
            }

            Rectangle {
                width: parent.width; height: 1 * s
                anchors.bottom: parent.bottom
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.20; color: "#40ffffff" }
                    GradientStop { position: 0.80; color: "#40ffffff" }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 18 * s

                Canvas {
                    width: 14 * s; height: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2;
                        var outer = width * 0.48;
                        var inner = width * 0.12;
                        ctx.fillStyle = "#bbcccccc";
                        ctx.beginPath();
                        ctx.moveTo(cx, cy - outer);
                        ctx.lineTo(cx + inner, cy - inner);
                        ctx.lineTo(cx + outer, cy);
                        ctx.lineTo(cx + inner, cy + inner);
                        ctx.lineTo(cx, cy + outer);
                        ctx.lineTo(cx - inner, cy + inner);
                        ctx.lineTo(cx - outer, cy);
                        ctx.lineTo(cx - inner, cy - inner);
                        ctx.closePath();
                        ctx.fill();
                    }
                }

                Text {
                    text: "Tap to land in Solaris-3"
                    font.family: mainFont.name; font.pixelSize: 15 * s
                    font.letterSpacing: 1.2 * s
                    color: "#ccffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Canvas {
                    width: 14 * s; height: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2;
                        var outer = width * 0.48;
                        var inner = width * 0.12;
                        ctx.fillStyle = "#bbcccccc";
                        ctx.beginPath();
                        ctx.moveTo(cx, cy - outer);
                        ctx.lineTo(cx + inner, cy - inner);
                        ctx.lineTo(cx + outer, cy);
                        ctx.lineTo(cx + inner, cy + inner);
                        ctx.lineTo(cx, cy + outer);
                        ctx.lineTo(cx - inner, cy + inner);
                        ctx.lineTo(cx - outer, cy);
                        ctx.lineTo(cx - inner, cy - inner);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.6; to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.0; to: 0.6; duration: 2200; easing.type: Easing.InOutSine }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: passIn.forceActiveFocus()
            }
        }
    }
    Item {
        id: popupOverlay
        anchors.fill: parent
        visible: root.sessionPopupOpen

        Rectangle {
            anchors.fill: parent
            color: "#66000000"
            opacity: root.sessionPopupOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }
            MouseArea { anchors.fill: parent; onClicked: root.sessionPopupOpen = false }
        }

        Item {
            id: sessionBlade
            width: 300 * s
            anchors.left: parent.left; anchors.leftMargin: 44 * s
            anchors.bottom: parent.bottom; anchors.bottomMargin: 290 * s

            property real bladeH: Math.min(sessionModel.count, 5) * 52 * s + 56 * s

            Rectangle {
                width: parent.width
                height: sessionBlade.bladeH
                anchors.bottom: parent.bottom
                radius: 8 * s
                clip: true

                color: "#e6080c12"
                border.color: root.wCyanDim; border.width: 1 * s

                Rectangle {
                    width: parent.width * 0.7; height: 1 * s
                    anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: root.wCyan }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Column {
                    anchors.fill: parent; anchors.margins: 12 * s
                    spacing: 4 * s

                    Text {
                        text: "SESSION"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: mainFont.name; font.pixelSize: 10 * s
                        font.letterSpacing: 4 * s
                        color: root.wCyan; opacity: 0.7
                    }

                    Rectangle {
                        width: parent.width; height: 1 * s
                        color: "#22ffffff"
                    }

                    ListView {
                        width: parent.width
                        height: sessionBlade.bladeH - 44 * s
                        model: sessionModel; clip: true; spacing: 3 * s

                        delegate: Item {
                            width: ListView.view.width; height: 46 * s

                            Rectangle {
                                anchors.fill: parent; radius: 5 * s
                                color: (index === root.sessionIndex) ? "#22" + root.wCyan.toString().slice(1)
                                     : (dMouse.containsMouse ? "#15ffffff" : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    width: 2 * s; height: parent.height * 0.6
                                    anchors.left: parent.left; anchors.leftMargin: 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 1 * s
                                    color: root.wCyan
                                    opacity: (index === root.sessionIndex) ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 16 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10 * s

                                    Rectangle {
                                        width: 5 * s; height: 5 * s; rotation: 45
                                        color: (index === root.sessionIndex) ? root.wCyan : root.wGhost
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        text: model.name
                                        font.family: mainFont.name; font.pixelSize: 13 * s
                                        font.letterSpacing: 0.8 * s
                                        color: (index === root.sessionIndex) ? root.wWhite : root.wSilver
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: dMouse; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { root.sessionIndex = index; root.sessionPopupOpen = false }
                                }
                            }
                        }
                    }
                }
            }

            property real targetY: 0
            transform: Translate { y: root.sessionPopupOpen ? 0 : 30 * s }
            opacity: root.sessionPopupOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
        }
    }

    Rectangle {
        anchors.fill: parent; color: "transparent"
        Rectangle {
            width: parent.width; height: 1 * s
            color: root.wCyan; opacity: 0.03
            NumberAnimation on y { from: 0; to: root.height; duration: 9000; loops: Animation.Infinite }
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            passIn.text = ""
            passIn.forceActiveFocus()
            passFailAnim.start()
        }
    }

    SequentialAnimation {
        id: passFailAnim
        ColorAnimation { target: passIn.parent.children[0]; property: "border.color"; to: "#ff4466"; duration: 200 }
        PauseAnimation { duration: 800 }
        ColorAnimation { target: passIn.parent.children[0]; property: "border.color"; to: "#44ffffff"; duration: 400 }
    }
}
