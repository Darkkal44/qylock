import QtQuick
import QtQuick.Effects
import QtMultimedia
import Qt.labs.folderlistmodel
import SddmComponents 2.0
import "ClockMath.js" as ClockMath
import "Config.js" as PluginConfig

// ---------------------------------------------------------------------------
// omarchy-orbital — SDDM greeter port of Omarchy's Orbital Lock screen
// (https://github.com/dumidulkdev/omarchy-orbital-lock, MIT).
// Same presentation as the lock: rotating minute/second rings, hour readout,
// date panel, password pill, two-click power actions. SDDM's injected
// `sddm` / `userModel` / `sessionModel` replace the Quickshell PAM lock core.
// Theme.conf keys beyond qylock's type/background/color:
//   dimOpacity, hourFormat, showSecondsRing, showPowerActions, identityLabel
// ---------------------------------------------------------------------------

Item {
    id: root
    width: 1920
    height: 1080

    readonly property real s: width / 1920
    readonly property real uiScale: Math.max(0.62, Math.min(1.5, Math.min(width / 1920, height / 1080)))
    readonly property bool compact: width / Math.max(1, height) < 1.35

    // theme.conf values arrive as strings; Config.js clamps like the lock does
    property var viewSettings: PluginConfig.normalize({
        backgroundMode: config.type === "color" ? "solid" : "wallpaper",
        dimOpacity: config.dimOpacity,
        hourFormat: config.hourFormat,
        showSecondsRing: config.showSecondsRing,
        showPowerActions: config.showPowerActions,
        identityLabel: config.identityLabel
    })

    readonly property bool videoBg: config.type === "video"
    readonly property bool colorBg: config.type === "color"
    readonly property bool wallpaperEnabled: viewSettings.backgroundMode !== "solid"
    readonly property bool showPasswordCursor: !authenticatingPassword && failureMessage.length === 0
    readonly property color foreground: "#f2f4f8"
    readonly property color muted: alphaColor(foreground, 0.66)
    readonly property color surface: "#0d1017"
    readonly property color errorColor: "#ff7a7a"
    readonly property string identityText: viewSettings.identityLabel && viewSettings.identityLabel.length > 0
        ? viewSettings.identityLabel.toUpperCase()
        : String((typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : "USER").toUpperCase()

    property bool authenticatingPassword: false
    property string failureMessage: ""
    property int failedAttempts: 0
    property string pendingPowerAction: ""
    property var currentTime: new Date()

    function alphaColor(colorValue, opacity) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function forcePasswordFocus() {
        passInput.forceActiveFocus()
    }

    function submitPassword() {
        if (root.authenticatingPassword) return
        var password = passInput.text
        if (password.length === 0) return

        passInput.text = ""
        root.failureMessage = ""
        root.authenticatingPassword = true

        var userName = (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : ""
        var sessionIndex = (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
        if (typeof sddm !== "undefined") sddm.login(userName, password, sessionIndex)
    }

    function requestPower(action) {
        if (action !== "reboot" && action !== "shutdown") return
        if (root.pendingPowerAction === action) {
            root.pendingPowerAction = ""
            powerConfirmationTimer.stop()
            if (typeof sddm !== "undefined") {
                if (action === "reboot") sddm.reboot()
                else sddm.powerOff()
            }
            return
        }
        root.pendingPowerAction = action
        powerConfirmationTimer.restart()
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            if (!root.authenticatingPassword) return
            root.authenticatingPassword = false
            root.failedAttempts += 1
            root.failureMessage = "AUTHENTICATION FAILED (" + root.failedAttempts + ")"
            Qt.callLater(root.forcePasswordFocus)
        }
    }

    // Fonts (drop a .ttf/.otf into font/ to match the lock screen's typeface)
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Clock ticker (33ms, like the lock screen)
    Timer { interval: 33; repeat: true; running: true; onTriggered: root.currentTime = new Date() }

    Timer {
        id: powerConfirmationTimer
        interval: 5000
        repeat: false
        onTriggered: root.pendingPowerAction = ""
    }

    // --- Background: image or video, blurred/dimmed like the lock ---
    Rectangle { anchors.fill: parent; color: colorBg && config.color ? config.color : surface; z: -1000 }

    Image {
        id: bgImage
        anchors.fill: parent
        visible: !root.videoBg
        source: root.wallpaperEnabled && !root.colorBg ? (config.background || "bg.png") : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: width
        sourceSize.height: height
    }

    MediaPlayer {
        id: player
        source: root.videoBg ? (config.background || "bg.mp4") : ""
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        Component.onCompleted: player.play()
    }

    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        visible: root.videoBg
        fillMode: VideoOutput.PreserveAspectCrop
    }

    ShaderEffectSource {
        id: bgVideoSource
        sourceItem: root.videoBg ? bgVideo : null
        visible: false
        live: true
    }

    MultiEffect {
        id: bgFx
        anchors.fill: parent
        source: root.videoBg ? bgVideoSource : bgImage
        autoPaddingEnabled: false
        blurEnabled: root.wallpaperEnabled && (root.videoBg || bgImage.status === Image.Ready)
        blur: 1
        blurMax: 96
        blurMultiplier: 1.2
        saturation: -0.35
        contrast: -0.08
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.viewSettings.dimOpacity)
    }

    // Click anywhere: focus the password pill
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.forcePasswordFocus()
    }

    // --- Orbital clock (verbatim from the lock screen) ---
    OrbitalClock {
        id: orbitalClock
        z: 2
        width: root.compact ? Math.min(parent.width * 1.2, parent.height * 0.84) : Math.min(parent.width * 0.62, parent.height * 1.3)
        height: width
        x: root.compact ? (parent.width - width) / 2 : -width * 0.49
        y: root.compact ? -height * 0.2 : (parent.height - height) / 2
        currentTime: root.currentTime
        foreground: root.foreground
        muted: root.muted
        showSecondsRing: root.viewSettings.showSecondsRing
        authenticating: root.authenticatingPassword
        hourFormat: root.viewSettings.hourFormat
    }

    // --- Date panel ---
    Column {
        id: datePanel
        z: 3
        width: root.compact ? parent.width * 0.86 : Math.min(560 * root.uiScale, parent.width * 0.46)
        x: (parent.width - width) / 2
        y: root.compact ? parent.height * 0.43 : (parent.height - implicitHeight) / 2
        spacing: 8 * root.uiScale

        Text {
            width: parent.width
            text: Qt.formatDate(root.currentTime, "dd MMM yyyy").toUpperCase()
            color: root.muted
            font.family: mainFont.name
            font.pixelSize: 15 * root.uiScale
            font.letterSpacing: 4 * root.uiScale
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: Qt.formatDate(root.currentTime, "dddd").toUpperCase()
            color: root.foreground
            font.family: mainFont.name
            font.pixelSize: 22 * root.uiScale
            font.weight: Font.Bold
            font.letterSpacing: 8 * root.uiScale
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // --- Power actions (two clicks within five seconds) ---
    Row {
        id: powerRow
        z: 5
        visible: root.viewSettings.showPowerActions
        anchors.right: parent.right
        anchors.rightMargin: 64 * root.uiScale
        anchors.top: parent.top
        anchors.topMargin: 46 * root.uiScale
        spacing: 22 * root.uiScale

        Text {
            text: "OMARCHY"
            color: root.foreground
            font.family: mainFont.name
            font.pixelSize: 11 * root.uiScale
            font.weight: Font.Bold
            font.letterSpacing: 3 * root.uiScale
        }

        ActionLabel {
            label: root.pendingPowerAction === "reboot" ? "CONFIRM REBOOT" : "REBOOT"
            active: root.pendingPowerAction === "reboot"
            onTriggered: root.requestPower("reboot")
        }

        ActionLabel {
            label: root.pendingPowerAction === "shutdown" ? "CONFIRM SHUTDOWN" : "SHUTDOWN"
            active: root.pendingPowerAction === "shutdown"
            onTriggered: root.requestPower("shutdown")
        }
    }

    // --- Identity + password pill ---
    Column {
        id: identityPanel
        z: 4
        width: Math.min(430 * root.uiScale, parent.width * 0.86)
        x: root.compact ? (parent.width - width) / 2 : parent.width - width - 72 * root.uiScale
        y: parent.height - implicitHeight - 68 * root.uiScale
        spacing: 9 * root.uiScale
        transform: Translate { id: failureOffset }

        Text {
            width: parent.width
            text: root.identityText
            color: root.foreground
            font.family: mainFont.name
            font.pixelSize: 19 * root.uiScale
            font.weight: Font.Bold
            font.letterSpacing: 7 * root.uiScale
            horizontalAlignment: Text.AlignRight
        }

        Rectangle {
            id: passwordField
            width: parent.width
            height: 62 * root.uiScale
            radius: height / 2
            color: root.alphaColor(root.surface, 0.28)
            border.width: Math.max(1, 1.5 * root.uiScale)
            border.color: root.alphaColor(root.foreground, root.authenticatingPassword ? 0.55 : 0.2)
            Behavior on border.color { ColorAnimation { duration: 180 } }

            Rectangle {
                id: typingPulse
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: height / 2
                color: "transparent"
                border.width: Math.max(1, 1.5 * root.uiScale)
                border.color: root.alphaColor(root.foreground, 0.7)
                opacity: 0
                scale: 0.9
                transformOrigin: Item.Center

                ParallelAnimation {
                    id: typingPulseAnimation
                    NumberAnimation { target: typingPulse; property: "scale"; from: 0.9; to: 1.16; duration: 420; easing.type: Easing.OutCubic }
                    NumberAnimation { target: typingPulse; property: "opacity"; from: 0.72; to: 0; duration: 420; easing.type: Easing.OutCubic }
                }
            }

            TextInput {
                id: passInput
                property int lastTextLength: 0
                anchors.fill: parent
                anchors.leftMargin: 28 * root.uiScale
                anchors.rightMargin: 28 * root.uiScale
                horizontalAlignment: TextInput.AlignRight
                verticalAlignment: TextInput.AlignVCenter
                activeFocusOnPress: true
                enabled: !root.authenticatingPassword
                readOnly: root.authenticatingPassword
                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                color: root.foreground
                selectionColor: root.alphaColor(root.foreground, 0.35)
                selectedTextColor: root.foreground
                font.family: mainFont.name
                font.pixelSize: 16 * root.uiScale
                font.letterSpacing: 8 * root.uiScale
                cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
                cursorDelegate: Rectangle {
                    width: 2 * root.uiScale
                    color: root.foreground
                    visible: passInput.cursorVisible
                }

                onTextChanged: {
                    if (text.length > lastTextLength && !root.authenticatingPassword) {
                        typingPulseAnimation.restart()
                    }
                    lastTextLength = text.length
                    if (text.length > 0 && root.failureMessage.length > 0) root.failureMessage = ""
                }

                onAccepted: root.submitPassword()

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                        passInput.text = ""
                        event.accepted = true
                    }
                }
            }

            Text {
                anchors.fill: passInput
                text: root.authenticatingPassword ? "CHECKING KEY" : (root.failureMessage.length > 0 ? root.failureMessage.toUpperCase() : "WAITING FOR KEY")
                visible: passInput.text.length === 0
                color: root.failureMessage.length > 0 ? root.errorColor : root.muted
                font.family: mainFont.name
                font.pixelSize: 11 * root.uiScale
                font.letterSpacing: 3 * root.uiScale
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    Item { id: authPulse; property real value: 1 }

    SequentialAnimation {
        loops: Animation.Infinite
        running: root.authenticatingPassword
        NumberAnimation { target: authPulse; property: "value"; from: 1; to: 0.42; duration: 450; easing.type: Easing.InOutSine }
        NumberAnimation { target: authPulse; property: "value"; from: 0.42; to: 1; duration: 450; easing.type: Easing.InOutSine }
    }

    SequentialAnimation {
        id: failureShake
        NumberAnimation { target: failureOffset; property: "x"; from: 0; to: -10 * root.uiScale; duration: 45 }
        NumberAnimation { target: failureOffset; property: "x"; to: 10 * root.uiScale; duration: 70 }
        NumberAnimation { target: failureOffset; property: "x"; to: -6 * root.uiScale; duration: 60 }
        NumberAnimation { target: failureOffset; property: "x"; to: 0; duration: 45 }
    }

    onFailureMessageChanged: if (failureMessage.length > 0) failureShake.restart()

    // Initial focus (qylock pattern)
    Timer { interval: 300; running: true; onTriggered: root.forcePasswordFocus() }
    Component.onCompleted: Qt.callLater(root.forcePasswordFocus)

    component ActionLabel: Item {
        id: actionRoot
        property string label: ""
        property bool active: false
        signal triggered()
        width: actionText.implicitWidth
        height: actionText.implicitHeight

        Text {
            id: actionText
            text: actionRoot.label
            color: actionRoot.active || actionMouse.containsMouse ? root.foreground : root.muted
            font.family: mainFont.name
            font.pixelSize: 11 * root.uiScale
            font.weight: actionRoot.active ? Font.Bold : Font.Normal
            font.letterSpacing: 3 * root.uiScale
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionRoot.triggered()
        }
    }
}