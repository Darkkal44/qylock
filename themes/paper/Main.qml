import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#dad4bb"

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property var activeUser: userModel.lastUser
    
    // Safety check for session model range
    onSessionIndexChanged: {
        if (sessionModel && (sessionIndex < 0 || sessionIndex >= sessionModel.rowCount())) {
            sessionIndex = (sessionModel.rowCount() > 0) ? 0 : -1;
        }
    }
    readonly property color mainColor: "#4b4637"
    readonly property color accentColor: "#bab5a1"
    readonly property color bgLight: "#dad4bb"

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: customFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    readonly property string fontName: fontFolder.count > 0 ? customFont.name : "Advent Pro"
    readonly property string mono: fontFolder.count > 0 ? customFont.name : "JetBrains Mono"

    // States
    property real bootProgress: 0
    property real headerOpacity: 0
    property real contentOpacity: 0
    property real uiMaskW: 0
    property bool glitchActive: false
    property real glitchX: 0

    TextConstants { id: textConstants }

    // Session Helper
    ListView {
        id: sessionNameHelper
        model: sessionModel; currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sessionName: model.name || "" }
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            errorMessage.text = "ACCESS GRANTED"
            errorMessage.color = "#4b6b4b"
        }
        function onLoginFailed() {
            errorMessage.text = "ACCESS DENIED"
            errorMessage.color = "#7e3e3e"
            passwordInput.text = ""
        }
    }

    // Background
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.9
        
        // Slow breathing effect
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.02; duration: 25000; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1.02; to: 1.0; duration: 25000; easing.type: Easing.InOutQuad }
        }
    }

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordInput.forceActiveFocus() }

    // Glitch Timer
    Timer {
        id: glitchTimer
        interval: 3000 + Math.random() * 5000
        running: true; repeat: true
        onTriggered: {
            glitchActive = true
            glitchEffect.start()
            interval = 2000 + Math.random() * 6000
        }
    }

    SequentialAnimation {
        id: glitchEffect
        ParallelAnimation {
            NumberAnimation { target: root; property: "glitchX"; to: 15; duration: 40; easing.type: Easing.OutElastic }
            NumberAnimation { target: root; property: "headerOpacity"; to: 0.7; duration: 40 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "glitchX"; to: -10; duration: 40; easing.type: Easing.OutElastic }
            NumberAnimation { target: root; property: "headerOpacity"; to: 1.0; duration: 40 }
        }
        NumberAnimation { target: root; property: "glitchX"; to: 0; duration: 40 }
        PropertyAction { target: root; property: "glitchActive"; value: false }
    }

    // Content
    Item {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 40 * s
        
        // HUD Jitter
        x: root.glitchActive ? root.glitchX * 0.5 : 0
        y: root.glitchActive ? root.glitchX * 0.2 : 0

        // Boot Animation Sequence
        Component.onCompleted: bootSequence.start()
        
        SequentialAnimation {
            id: bootSequence
            PauseAnimation { duration: 400 }
            // 1. Header fades in with glitch
            ParallelAnimation {
                PropertyAnimation { target: root; property: "headerOpacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "uiMaskW"; from: 0; to: 1; duration: 600; easing.type: Easing.InOutExpo }
            }
            // 2. Rest of the UI loads
            PropertyAnimation { target: root; property: "contentOpacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutQuad }
            PropertyAnimation { target: root; property: "bootProgress"; from: 0; to: 1; duration: 850; easing.type: Easing.InOutCubic }
        }

        // Decorative Rings
        Item {
            anchors.centerIn: parent
            width: 800 * s; height: 800 * s
            opacity: 0.1
            z: -1
            
            Rectangle {
                anchors.centerIn: parent
                width: 700 * s; height: 700 * s; border.color: root.mainColor; border.width: 1 * s * s; radius: 350 * s; color: "transparent"
                RotationAnimation on rotation { from: 0; to: 360; duration: 60000; loops: Animation.Infinite }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 680 * s; height: 680 * s; border.color: root.mainColor; border.width: 1 * s * s; radius: 340 * s; color: "transparent"
                RotationAnimation on rotation { from: 360; to: 0; duration: 40000; loops: Animation.Infinite }
            }
        }

        Item {
            id: headerArea
            anchors.top: parent.top; anchors.left: parent.left
            width: headerText.implicitWidth + 40; height: 80 * s
            opacity: root.headerOpacity
            x: root.glitchActive ? root.glitchX : 0

            Text {
                id: headerText
                text: "SYSTEM ACCESS"
                font.family: root.fontName
                font.pixelSize: 42 * s
                font.letterSpacing: 4 * s
                color: root.mainColor
            }

            Rectangle {
                anchors.top: headerText.bottom
                anchors.left: parent.left
                width: (headerText.implicitWidth + 20) * root.uiMaskW
                height: 2 * s
                color: root.mainColor
                anchors.topMargin: 4 * s
            }
            
            Text {
                text: "POD_SIGNAL: STABLE // NODE_01"
                font.family: root.mono; font.pixelSize: 10 * s; color: root.mainColor; opacity: 0.5
                anchors.top: headerText.bottom; anchors.topMargin: 15 * s
            }
        }

        // Login Section
        Row {
            anchors.top: headerArea.bottom
            anchors.topMargin: 40 * s
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 80 * s
            width: parent.width
            opacity: root.contentOpacity

            // User Selection Column
            Column {
                spacing: 10 * s
                width: parent.width * 0.4

                Text {
                    text: "IDENTIFICATION"
                    font.family: root.fontName
                    font.pixelSize: 18 * s
                    color: root.mainColor
                    font.bold: true
                }

                ListView {
                    id: userList
                    width: parent.width
                    height: 180 * s
                    model: userModel
                    currentIndex: userModel.lastIndex
                    clip: true
                    
                    delegate: Item {
                        width: parent.width
                        height: 40 * s
                        property string userName: model.name
                        
                        Rectangle {
                            anchors.fill: parent
                            color: ListView.isCurrentItem ? root.mainColor : "transparent"
                            opacity: 0.8
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * s
                            spacing: 12 * s

                            Rectangle {
                                width: 12 * s
                                height: 12 * s
                                border.color: ListView.isCurrentItem ? root.bgLight : root.mainColor
                                border.width: 1 * s
                                color: "transparent"
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: "+"
                                    anchors.centerIn: parent
                                    font.pixelSize: 10 * s
                                    color: ListView.isCurrentItem ? root.bgLight : root.mainColor
                                }
                            }

                            Text {
                                text: model.name
                                color: ListView.isCurrentItem ? root.bgLight : root.mainColor
                                font.family: root.fontName
                                font.pixelSize: 16 * s
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: userList.currentIndex = index
                        }
                    }
                }
            }

            // Input Column
            Column {
                spacing: 20 * s
                width: parent.width * 0.5

                Text {
                    text: "AUTHENTICATION"
                    font.family: root.fontName
                    font.pixelSize: 18 * s
                    color: root.mainColor
                    font.bold: true
                }

                // Field with typical NieR box styling
                Rectangle {
                    id: authBox
                    width: parent.width
                    height: Math.max(1, 350 * root.bootProgress) // Top line visible first
                    color: "transparent"
                    border.color: root.mainColor
                    border.width: 1 * s
                    clip: true // Important for height reveal

                    // Corner decorations
                    Rectangle { width: 4 * s; height: 4 * s; color: root.mainColor; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 4 * s; height: 4 * s; color: root.mainColor; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 4 * s; height: 4 * s; color: root.mainColor; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 4 * s; height: 4 * s; color: root.mainColor; anchors.bottom: parent.bottom; anchors.right: parent.right }

                    Column {
                        id: authCol
                        anchors.fill: parent
                        anchors.margins: 15 * s
                        spacing: 12 * s

                        Text {
                            text: "SQUAD_STATUS: READY"
                            font.family: root.fontName
                            font.pixelSize: 14 * s
                            color: root.mainColor
                            font.bold: true
                        }

                        // Thumbnail area
                        Rectangle {
                            width: parent.width
                            height: 100 * s
                            color: Qt.rgba(root.mainColor.r, root.mainColor.g, root.mainColor.b, 0.05)
                            border.color: root.mainColor
                            border.width: 1 * s
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: "background.png"
                                fillMode: Image.PreserveAspectCrop
                                opacity: 0.4
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "USER: " + (userList.currentItem ? userList.currentItem.userName.toUpperCase() : "NONE")
                                color: root.mainColor
                                font.family: root.fontName
                                font.pixelSize: 16 * s
                                font.bold: true
                            }
                        }

                        Item { width: 1 * s; height: 2 * s }

                        Text {
                            text: "PASS_KEY_INPUT"
                            font.family: root.fontName
                            font.pixelSize: 14 * s
                            color: root.mainColor
                        }

                        Rectangle {
                            width: parent.width
                            height: 38 * s
                            color: Qt.rgba(root.mainColor.r, root.mainColor.g, root.mainColor.b, 0.1)
                            border.color: root.mainColor
                            border.width: 1 * s

                            TextInput {
                                id: passwordInput
                                anchors.fill: parent
                                anchors.leftMargin: 10 * s
                                anchors.rightMargin: 10 * s
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.mono
                                font.pixelSize: 18 * s
                                font.letterSpacing: 6 * s
                                color: root.mainColor
                                echoMode: TextInput.Password
                                focus: true
                                
                                onAccepted: sddm.login(userList.currentItem.userName, passwordInput.text, root.sessionIndex)
                                Keys.onPressed: {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        sddm.login(userList.currentItem.userName, passwordInput.text, root.sessionIndex)
                                    }
                                }
                            }
                        }

                        Item { width: 1 * s; height: 12 * s }

                        // Session Selection
                        Row {
                            width: parent.width
                            spacing: 12 * s
                            
                            Text {
                                text: "SESS:"
                                font.family: root.fontName
                                font.pixelSize: 13 * s
                                color: root.mainColor
                                anchors.top: sessionBoxContainer.top
                                anchors.topMargin: 6 * s // (26 height box / 2) - (text height / 2)
                            }
                            
                            Item {
                                id: sessionBoxContainer
                                width: parent.width - 60
                                height: 45 * s // Provides room for the CYCLE hint below

                                Rectangle {
                                    id: sessionBox
                                    width: parent.width
                                    height: 26 * s
                                    color: "transparent"
                                    border.color: root.mainColor
                                    border.width: 1 * s
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: (sessionNameHelper.currentItem && sessionNameHelper.currentItem.sessionName) 
                                              ? sessionNameHelper.currentItem.sessionName.toUpperCase() 
                                              : "SEARCHING..."
                                        font.family: root.fontName
                                        font.pixelSize: 12 * s
                                        font.bold: true
                                        color: root.mainColor
                                    }
                                    
                                    MouseArea {
                                        id: sessionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (sessionModel && sessionModel.rowCount() > 0) {
                                                sessionIndex = (sessionIndex + 1) % sessionModel.rowCount();
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: "[ CLICK TO CYCLE ]"
                                    font.family: root.fontName
                                    font.pixelSize: 10 * s
                                    color: root.mainColor
                                    opacity: 0.5
                                    anchors.top: sessionBox.bottom
                                    anchors.left: sessionBox.left
                                    anchors.topMargin: 4 * s
                                }
                            }
                        }

                        Text {
                            id: errorMessage
                            text: ""
                            font.family: root.fontName
                            font.pixelSize: 12 * s
                            color: "#7e3e3e"
                            visible: text !== ""
                        }
                    }
                } // End AUTH Rectangle

                // Lower spacing
                Item { width: 1 * s; height: 10 * s }

                // Power & Confirm Buttons Row
                Row {
                    spacing: 15 * s
                    anchors.right: parent.right

                    NierButton {
                        text: "POWER OFF"
                        onClicked: sddm.powerOff()
                    }
                    NierButton {
                        text: "REBOOT"
                        onClicked: sddm.reboot()
                    }
                    NierButton {
                        text: "CONFIRM"
                        primary: true
                        onClicked: sddm.login(userList.currentItem.userName, passwordInput.text, sessionIndex)
                    }
                }
            } // Input Column
        } // Login Row



        // Global Noise
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: 0.02
            z: 101
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.fillStyle = root.mainColor
                    for (var i = 0; i < 500; i++) {
                        ctx.fillRect(Math.random() * width, Math.random() * height, 1, 1)
                    }
                }
            }
        }

        // Pod Log
        Column {
            anchors.top: parent.top
            anchors.right: parent.right
            spacing: 5 * s
            opacity: root.contentOpacity
            width: 250 * s
            
            Text {
                text: "v1.2.0_SYSTEM_STABLE"
                font.family: root.fontName
                font.pixelSize: 10 * s
                color: root.mainColor
                opacity: 0.6
                anchors.right: parent.right
            }
            
            ListView {
                id: logList
                width: parent.width; height: 300 * s
                anchors.right: parent.right
                interactive: false
                model: 10
                delegate: Text {
                    property string logText: "INITIALIZING_HUD_MODULE... [OK]"
                    text: logText
                    font.family: root.mono; font.pixelSize: 9 * s; color: root.mainColor; opacity: (10 - index) / 15
                    anchors.right: parent.right
                    Component.onCompleted: {
                        var logs = [
                            "MEMORY_CHECK... COMPLETED",
                            "POD_LINK: ESTABLISHED",
                            "DATA_SYNC: ACTIVE",
                            "SQUAD_STATUS: READY",
                            "ENCRYPTION: L5_GRANTED",
                            "NEURAL_MAP: LOADED",
                            "SIGNAL_DETECTED... 0x4F2",
                            "ACCESSING_CORE_NODES...",
                            "ERROR: NONE",
                            "HUD_INIT: SUCCESS"
                        ];
                        logText = logs[index % logs.length];
                    }
                }
            }
        }

        // Hints
        Item {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 40 * s
            opacity: root.contentOpacity

            Row {
                anchors.right: parent.right
                spacing: 25 * s

                NierHint { key: "W S"; label: "SELECT" }
                NierHint { key: "ENTER"; label: "CONFIRM" }
                NierHint { key: "ESC"; label: "BACK" }
            }
        }
        // Scanline
        Rectangle {
            width: parent.width; height: 1 * s
            color: root.mainColor
            opacity: 0.3
            y: Math.random() * parent.height
            visible: root.glitchActive
            z: 200
        }
    } // mainContainer

    // Components

    component NierButton: Rectangle {
        property string text: ""
        property bool primary: false
        signal clicked()

        width: 120 * s
        height: 34 * s
        color: btnMouse.containsMouse ? root.mainColor : "transparent"
        border.color: root.mainColor
        border.width: 1 * s
        
        Behavior on color { ColorAnimation { duration: 150 } }

        // NieR Diamond indicator
        Rectangle {
            width: 6 * s; height: 6 * s
            color: root.mainColor
            rotation: 45
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: -12 * s
            visible: btnMouse.containsMouse
        }

        Text {
            text: parent.text
            anchors.centerIn: parent
            font.family: root.fontName
            font.pixelSize: 14 * s
            color: btnMouse.containsMouse ? root.bgLight : root.mainColor
            font.bold: parent.primary
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    component NierHint: Row {
        property string key: ""
        property string label: ""
        spacing: 8 * s

        Rectangle {
            width: keyText.implicitWidth + 12
            height: 20 * s
            color: root.mainColor
            Text {
                id: keyText
                text: parent.parent.key
                anchors.centerIn: parent
                font.family: root.fontName
                font.pixelSize: 12 * s
                font.bold: true
                color: root.bgLight
            }
        }
        Text {
            text: parent.label
            font.family: root.fontName
            font.pixelSize: 13 * s
            color: root.mainColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
