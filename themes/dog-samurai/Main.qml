import QtQuick
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
    width: 1920
    height: 1080
    readonly property real s: Screen.height / 1080

    // Quickshell
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined

    // Colors
    readonly property color textPrimary:   "#f8f1e5"
    readonly property color textSecondary: "#8b949e"
    readonly property color accent:        "#ffb7c5"
    readonly property color accentGlow:    Qt.rgba(1, 0.72, 0.77, 0.4)
    readonly property color glassBg:       Qt.rgba(0.04, 0.05, 0.06, 0.8)

    // State
    property int  userIndex:    (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property int  sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool loginError:   false
    property bool userMenuOpen: false
    property bool isLoaded:     false
    property string displayUserName: ""

    // Fonts
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"] 
    }
    FontLoader {
        id: mainFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" 
    }

    // Models
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string sName: model.name || ""
        } 
    }
    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        } 
    }

    // Login
    function login() {
        var n = (userHelper.currentItem && userHelper.currentItem.uName !== "") ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "")
        if (typeof sddm !== "undefined") sddm.login(n, passInput.text, root.sessionIndex)
    }

    Component.onCompleted: {
        keyboard.numLock = true
        if (userHelper.currentItem && userHelper.currentItem.uName) {
            root.displayUserName = userHelper.currentItem.uName.toUpperCase()
        } else if (typeof userModel !== "undefined" && userModel.lastUser) {
            root.displayUserName = userModel.lastUser.toUpperCase()
        } else {
            root.displayUserName = "USER"
        }
    }

    onUserIndexChanged: userTransition.start()

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.loginError = true
            passInput.text = ""
            errorShake.start()
            passInput.forceActiveFocus()
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            passInput.forceActiveFocus()
            root.isLoaded = true
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#0d1117"
        z: -2000
    }
    MediaPlayer {
        id: player
        source: "bg.mp4"
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        Component.onCompleted: player.play() 
    }
    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        z: -1000
    }

    // Overlay
    Rectangle {
        anchors.fill: parent
        z: -800
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#cc0a0a09" }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1; color: "#550a0a09" }
        }
    }

    // UI
    Item {
        id: uiContainer
        anchors.fill: parent
        z: 10
        readonly property real sideMargin: 100 * s

        // Clock
        Item {
            anchors.left: parent.left
            anchors.leftMargin: uiContainer.sideMargin
            anchors.top: parent.top
            anchors.topMargin: 110 * s
            width: 400 * s
            height: 150 * s
            opacity: root.isLoaded ? 1 : 0
            transform: Translate { y: root.isLoaded ? 0 : -30 * s }
            Behavior on opacity {
                NumberAnimation { duration: 1000; easing.type: Easing.OutQuart }
            }
            Behavior on y {
                NumberAnimation { duration: 1000; easing.type: Easing.OutQuart }
            }
            
            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "HH:mm")
                font {
                    family: mainFont.name
                    pixelSize: 102 * s
                    weight: Font.ExtraLight
                    letterSpacing: 6 * s
                }
                color: root.textPrimary
                layer.enabled: true
                layer.effect: DropShadow {
                    color: root.accent
                    radius: 12
                    samples: 24
                }
                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
                }
            }
            Text {
                anchors.top: clockText.bottom
                anchors.topMargin: -5 * s
                text: Qt.formatDate(new Date(), "dddd // MMMM d").toUpperCase()
                font {
                    family: mainFont.name
                    pixelSize: 15 * s
                    letterSpacing: 10 * s
                    weight: Font.Light
                }
                color: root.accent
                opacity: 0.8
            }
        }

        // Panel
        Item {
            id: loginWrapper
            anchors.left: parent.left
            anchors.leftMargin: uiContainer.sideMargin
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 100 * s
            width: 420 * s
            height: 240 * s

            opacity: root.isLoaded ? 1 : 0
            transform: Translate { x: root.isLoaded ? 0 : -40 * s }
            Behavior on opacity {
                NumberAnimation { duration: 800; easing.type: Easing.OutQuart }
            }
            Behavior on x {
                NumberAnimation { duration: 800; easing.type: Easing.OutQuart }
            }

            SequentialAnimation {
                id: errorShake
                NumberAnimation { target: loginWrapper; property: "anchors.leftMargin"; to: uiContainer.sideMargin - 15 * s; duration: 50; easing.type: Easing.InOutSine }
                NumberAnimation { target: loginWrapper; property: "anchors.leftMargin"; to: uiContainer.sideMargin + 15 * s; duration: 50; easing.type: Easing.InOutSine }
                NumberAnimation { target: loginWrapper; property: "anchors.leftMargin"; to: uiContainer.sideMargin; duration: 50; easing.type: Easing.InOutSine }
                onStopped: root.loginError = false
            }

            // Outline
            Item {
                anchors.fill: parent
                Rectangle {
                    anchors.fill: parent
                    color: root.glassBg
                    radius: 2 * s
                    border.color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1 
                }
                Rectangle {
                    width: 4 * s
                    height: parent.height
                    color: root.accent
                    anchors.left: parent.left
                    anchors.leftMargin: -2 * s
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: root.accent
                        radius: 15
                        samples: 24
                    }
                }
            }

            // Elements
            Column {
                anchors.fill: parent
                anchors.margins: 40 * s
                spacing: 35 * s
                
                // Switcher
                Column {
                    width: parent.width
                    spacing: 10 * s
                    Text {
                        text: "USER"
                        font {
                            family: mainFont.name
                            pixelSize: 11 * s
                            letterSpacing: 6 * s
                            weight: Font.DemiBold
                        }
                        color: root.accent
                        opacity: 0.8
                    }
                    Row {
                        spacing: 20 * s
                        width: parent.width
                        Text {
                            id: userNameDisplay
                            text: root.displayUserName
                            font {
                                family: mainFont.name
                                pixelSize: 34 * s
                                letterSpacing: 2 * s
                                weight: Font.ExtraLight
                            }
                            color: root.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                            transform: Translate { id: userTrans; x: 0 }
                            SequentialAnimation {
                                id: userTransition
                                ParallelAnimation {
                                    NumberAnimation { target: userNameDisplay; property: "opacity"; to: 0; duration: 200 }
                                    NumberAnimation { target: userTrans; property: "x"; to: -15 * s; duration: 200 }
                                }
                                ScriptAction {
                                    script: {
                                        if (userHelper.currentItem && userHelper.currentItem.uName) {
                                            root.displayUserName = userHelper.currentItem.uName.toUpperCase()
                                        } else if (typeof userModel !== "undefined" && userModel.get(root.userIndex)) {
                                            var u = userModel.get(root.userIndex)
                                            root.displayUserName = (u.realName || u.name || "USER").toUpperCase()
                                        }
                                    }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: userNameDisplay; property: "opacity"; to: 1; duration: 300 }
                                    NumberAnimation { target: userTrans; property: "x"; from: 15 * s; to: 0; duration: 300 }
                                }
                            }
                        }
                        Item { 
                            width: 32 * s
                            height: 32 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent
                                color: root.accent
                                radius: 2 * s
                                opacity: uMa.containsMouse ? 0.2 : 0.06
                                border.color: root.accent; border.width: 1 
                                Behavior on opacity {
                                    NumberAnimation { duration: 250 }
                                }
                            }
                            Text {
                                text: "↕"
                                color: root.accent
                                anchors.centerIn: parent
                                font {
                                    family: mainFont.name
                                    pixelSize: 14 * s
                                }
                            }
                            MouseArea {
                                id: uMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.userMenuOpen = !root.userMenuOpen
                            }
                        }
                    }
                }

                // Input
                Column {
                    width: parent.width
                    spacing: 12 * s
                    Item {
                        width: parent.width
                        height: 54 * s
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(1, 1, 1, 0.04)
                            radius: 2 * s
                        }
                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.leftMargin: 22 * s
                            anchors.rightMargin: 100 * s
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "✦"
                            font {
                                family: mainFont.name
                                pixelSize: 22 * s
                                letterSpacing: 12 * s
                            }
                            color: root.textPrimary
                            focus: true
                            cursorVisible: false
                            onAccepted: root.login()
                            property bool wasClicked: false
                            Text { 
                                anchors.verticalCenter: parent.verticalCenter
                                text: "PASSCODE"
                                font {
                                    family: mainFont.name
                                    pixelSize: 13 * s
                                    letterSpacing: 6 * s
                                }
                                color: root.loginError ? "#ff4444" : root.textSecondary
                                opacity: (passInput.text.length === 0 && !passInput.wasClicked) ? 0.8 : 0.0
                                Behavior on opacity {
                                    NumberAnimation { duration: 300 }
                                } 
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                            Rectangle {
                                id: cur
                                width: 2 * s
                                height: 20 * s
                                color: root.loginError ? "#ff4444" : root.accent
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, passInput.cursorRectangle.x)
                                visible: passInput.focus && passInput.wasClicked
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1; to: 0; duration: 600 }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                        Text {
                            id: enterBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 20 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: "GO"
                            font {
                                family: mainFont.name
                                pixelSize: 16 * s
                                weight: Font.Medium
                                letterSpacing: 3 * s
                            }
                            color: root.accent
                            opacity: passInput.text.length > 0 ? 1 : 0
                            scale: passInput.text.length > 0 ? 1 : 0.85
                            Behavior on opacity {
                                NumberAnimation { duration: 300 }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: 450; easing.type: Easing.OutBack }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.login()
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: passInput.text.length === 0
                            onClicked: {
                                passInput.forceActiveFocus()
                                passInput.wasClicked = true
                            }
                        }
                    }
                }
            }

            // Users
            Item {
                id: dossierMenu
                anchors.left: parent.right
                anchors.leftMargin: 30 * s
                anchors.top: parent.top
                width: 340 * s
                height: menuLayout.implicitHeight
                
                z: -1
                opacity: root.userMenuOpen ? 1 : 0
                visible: opacity > 0
                
                transform: Translate { x: 0 }

                Behavior on opacity {
                    NumberAnimation { 
                        duration: root.userMenuOpen ? 300 : 250
                        easing.type: Easing.OutCubic 
                    }
                }

                Item {
                    anchors.fill: parent
                    Rectangle {
                        anchors.fill: parent
                        color: root.glassBg
                        radius: 2 * s
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1 
                        layer.enabled: true
                        layer.effect: DropShadow {
                            color: "#cc000000"
                            radius: 35
                            samples: 32
                            verticalOffset: 15
                        }
                    }
                    Rectangle {
                        width: 2 * s
                        height: parent.height
                        color: root.accent
                        anchors.right: parent.right
                        opacity: 0.5
                    }
                }

                Column {
                    id: menuLayout
                    width: parent.width
                    topPadding: 30 * s
                    bottomPadding: 25 * s
                    spacing: 0
                    Text { 
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "SWITCH USER"
                        font {
                            family: mainFont.name
                            pixelSize: 10 * s
                            letterSpacing: 6 * s
                            weight: Font.Bold
                        }
                        color: root.accent
                        opacity: 0.6 
                    }
                    Item {
                        width: parent.width
                        height: 20 * s
                    }
                    Column {
                        width: parent.width - 60 * s
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8 * s
                        Repeater {
                            model: typeof userModel !== "undefined" ? userModel : null
                            delegate: Item {
                                width: parent.width
                                height: 46 * s
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 1 * s
                                    color: root.accent
                                    opacity: (itemMa.containsMouse || index === root.userIndex) ? 0.1 : 0.02
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                }
                                Text {
                                    text: (model.realName || model.name).toUpperCase()
                                    font {
                                        family: mainFont.name
                                        pixelSize: 14 * s
                                        letterSpacing: 2 * s
                                        weight: Font.Light
                                    }
                                    color: index === root.userIndex ? root.accent : (itemMa.containsMouse ? root.textPrimary : root.textSecondary)
                                    anchors.centerIn: parent
                                    Behavior on color {
                                        ColorAnimation { duration: 250 }
                                    }
                                }
                                MouseArea {
                                    id: itemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.userIndex = index
                                        root.userMenuOpen = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Actions
        Item {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80 * s
            anchors.left: parent.left
            anchors.leftMargin: uiContainer.sideMargin
            width: sessContainer.width + powerActions.width + 100 * s
            height: 40 * s
            
            opacity: root.isLoaded ? 1 : 0
            transform: Translate { y: root.isLoaded ? 0 : 30 * s }
            Behavior on opacity {
                NumberAnimation { duration: 1000; easing.type: Easing.OutQuart }
            }
            Behavior on y {
                NumberAnimation { duration: 1000; easing.type: Easing.OutQuart }
            }

            Row {
                id: powerActions
                spacing: 50 * s
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [ { label: "SHUTDOWN", act: 1 }, { label: "REBOOT", act: 0 } ]
                    delegate: Text {
                        text: modelData.label
                        font {
                            family: mainFont.name
                            pixelSize: 13 * s
                            letterSpacing: 3 * s
                            weight: Font.Bold
                        }
                        color: pMa.containsMouse ? root.accent : root.textSecondary
                        Behavior on color {
                            ColorAnimation { duration: 250 }
                        }
                        MouseArea {
                            id: pMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof sddm !== "undefined") {
                                    if (modelData.act === 0) sddm.reboot()
                                    else sddm.powerOff()
                                }
                            }
                        }
                    }
                }
            }
            
            // Session
            Item {
                id: sessContainer
                visible: !root.isQuickshell
                width: sessLayout.implicitWidth
                height: 40 * s
                anchors.left: powerActions.right
                anchors.leftMargin: 60 * s
                anchors.verticalCenter: parent.verticalCenter
                Row {
                    id: sessLayout
                    spacing: 12 * s
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle { 
                        width: 5 * s
                        height: 5 * s
                        radius: 2.5 * s
                        color: sMa.containsMouse ? root.accent : root.textSecondary
                        opacity: 0.8
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 1 * s
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 1500 }
                            NumberAnimation { to: 0.8; duration: 1500 } 
                        }
                    }
                    Text {
                        id: sessText
                        text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "SYSTEM").toUpperCase()
                        font {
                            family: mainFont.name
                            pixelSize: 13 * s
                            letterSpacing: 2 * s
                            weight: Font.Bold
                        }
                        color: sMa.containsMouse ? root.textPrimary : root.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        transform: Translate { id: sessTrans; x: 0 }
                    }
                }
                MouseArea {
                    id: sMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleAnim.start()
                }
                SequentialAnimation {
                    id: toggleAnim
                    ParallelAnimation {
                        NumberAnimation { target: sessText; property: "opacity"; to: 0; duration: 150 }
                        NumberAnimation { target: sessTrans; property: "x"; to: 12 * s; duration: 150 }
                    }
                    ScriptAction {
                        script: { if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: sessText; property: "opacity"; to: 1; duration: 200 }
                        NumberAnimation { target: sessTrans; property: "x"; to: 0; duration: 200 }
                    }
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        z: -10
        visible: root.userMenuOpen
        onClicked: root.userMenuOpen = false
    }
}
