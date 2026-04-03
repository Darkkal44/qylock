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
    color: "#050203"

    // ── Properties ────────────────────────────────────────────────────
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    ListView { id: sessionHelper; model: sessionModel; currentIndex: root.sessionIndex
        opacity: 0; width: 100; height: 100; z: -100; visible: true
        delegate: Item { property string sName: model.name || "" }
    }
    property real ui: 0

    // Palette
    readonly property color red1:  "#e8251a"
    readonly property color red2:  "#ff4433"
    readonly property color red3:  "#7a100a"
    readonly property color chalk: "#f2ede8"
    readonly property color smoke: "#7a7068"

    TextConstants { id: textConstants }

    // ── Font ─────────────────────────────────────────────────────────
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: tektur; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // ── Helpers ───────────────────────────────────────────────────────
    ListView { id: userHelper; model: userModel
        currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
        visible: false; width: 100; height: 100
        delegate: Item { property string uName: model.realName || model.name || "" }
    }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordField.forceActiveFocus() }

    // ── Boot Fade-in ──────────────────────────────────────────────────
    Component.onCompleted: fadeAnim.start()
    NumberAnimation {
        id: fadeAnim; target: root; property: "ui"
        from: 0; to: 1; duration: 2000; easing.type: Easing.OutCubic
    }

    // ══════════════════════════════════════════════════════════════════
    //  BACKGROUND
    // ══════════════════════════════════════════════════════════════════
    Rectangle { anchors.fill: parent; color: "#050203" }
    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // Vignette
    RadialGradient {
        anchors.fill: parent
        horizontalRadius: root.width * 0.42
        verticalRadius: root.height * 0.48
        opacity: 0.92
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.55; color: "#88000000" }
            GradientStop { position: 1.0;  color: "#f8000000" }
        }
    }

    // Bottom blackout
    Rectangle {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: 120 * s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#f8050203" }
        }
    }

    // Top blackout
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 140 * s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#e8050203" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    //  ANIMATION 1: AMBIENT FLOOR BREATHE
    //  Pulses the red floor glow like the taillight is alive
    // ══════════════════════════════════════════════════════════════════
    Rectangle {
        id: floorGlow
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80 * s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#40e8251a" }
        }
        opacity: root.ui
        SequentialAnimation on opacity {
            running: root.ui > 0
            loops: Animation.Infinite
            NumberAnimation { to: root.ui * 0.4; duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.ui * 1.0; duration: 2200; easing.type: Easing.InOutSine }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    //  VERTICAL STRIPES — livery accents
    // ══════════════════════════════════════════════════════════════════
    Item {
        id: leftStripe
        x: 0; y: 0
        width: 3 * s; height: root.height
        opacity: root.ui * 0.7

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: root.red1 }
                GradientStop { position: 0.7; color: root.red1 }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    Item {
        id: rightStripe
        x: root.width - 3 * s; y: 0
        width: 3 * s; height: root.height
        opacity: root.ui * 0.7

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: root.red1 }
                GradientStop { position: 0.7; color: root.red1 }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    //  TOP — Driver ID (top-left) & Clock (top-right)
    // ══════════════════════════════════════════════════════════════════

    // ANIMATION 3: Driver display slides UP from below on boot
    Item {
        id: driverDisplay
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 38 * s
        anchors.leftMargin: 28 * s
        width: root.width * 0.5
        opacity: root.ui

        // Slide-up entrance tied to the ui fade
        transform: Translate {
            y: (1.0 - root.ui) * 22 * s
        }

        // Tiny status row
        Row {
            id: statusRow
            spacing: 7 * s

            Rectangle {
                width: 5 * s; height: 5 * s; radius: 2.5 * s
                color: root.red1
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: "DRIVER ID"
                color: root.red1; font.family: tektur.name
                font.pixelSize: 9 * s; font.letterSpacing: 4 * s; font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            id: userText
            anchors.top: statusRow.bottom
            anchors.topMargin: 6 * s
            text: (userHelper.currentItem && userHelper.currentItem.uName)
                  ? userHelper.currentItem.uName.toUpperCase()
                  : (userModel.lastUser || "DRIVER").toUpperCase()
            color: root.chalk
            font.family: tektur.name
            font.pixelSize: 52 * s
            font.weight: Font.Black
            font.letterSpacing: -0.5 * s
            clip: true
            width: root.width * 0.55
        }
    }

    // Clock — top right
    Item {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 38 * s
        anchors.rightMargin: 36 * s
        opacity: root.ui

        transform: Translate {
            y: (1.0 - root.ui) * -18 * s
            x: (1.0 - root.ui) * 8 * s
        }

        Column {
            anchors.right: parent.right
            spacing: 0

            Text {
                id: clockText
                anchors.right: parent.right
                text: Qt.formatTime(new Date(), "HH:mm")
                color: root.chalk
                font.family: tektur.name
                font.pixelSize: 44 * s
                font.weight: Font.Thin
                font.letterSpacing: 2 * s
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
                }
            }

            Text {
                id: dateText
                anchors.right: parent.right
                text: Qt.formatDate(new Date(), "ddd  d MMM").toUpperCase()
                color: root.smoke
                font.family: tektur.name
                font.pixelSize: 9 * s
                font.letterSpacing: 3.5 * s
                font.weight: Font.Light
                Timer {
                    interval: 60000; running: true; repeat: true
                    onTriggered: dateText.text = Qt.formatDate(new Date(), "ddd  d MMM").toUpperCase()
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    //  TAILLIGHT BAR
    // ══════════════════════════════════════════════════════════════════
    Item {
        id: taillightBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 68 * s
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width * 0.62
        height: 56 * s
        opacity: root.ui

        // ANIMATION 5: boot slide-up for the bar itself
        transform: Translate {
            y: (1.0 - root.ui) * 16 * s
        }

        // ── Top hairline — LED strip ──────────────────────────────────
        Item {
            id: topLineArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2 * s
            clip: true

            // Static gradient base
            Rectangle {
                id: topLine
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.08; color: root.red1 }
                    GradientStop { position: 0.5;  color: root.red2 }
                    GradientStop { position: 0.92; color: root.red1 }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
                layer.enabled: passwordField.activeFocus
                layer.effect: DropShadow {
                    color: root.red1
                    radius: 14; spread: 0.1; samples: 20
                    verticalOffset: 0
                }
            }
        }

        // ANIMATION 7: TYPING FLASH — topLine flares bright white on each character typed
        Rectangle {
            id: typeFlash
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2 * s
            color: "white"
            opacity: 0
            // Triggered by keystroke via onTextChanged
        }

        // Dark translucent backing
        Rectangle {
            anchors.top: topLineArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: Qt.rgba(0.02, 0.01, 0.01, 0.78)
        }

        // ── Content zone ──────────────────────────────────────────────
        Item {
            id: contentZone
            anchors.top: topLineArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            // TextInput
            TextInput {
                id: passwordField
                anchors.left: parent.left
                anchors.leftMargin: 48 * s
                anchors.right: engageArea.left
                anchors.rightMargin: 10 * s
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                verticalAlignment: TextInput.AlignVCenter
                leftPadding: 6 * s
                color: root.chalk
                font.family: tektur.name
                font.pixelSize: 15 * s
                font.letterSpacing: 5 * s
                font.weight: Font.Medium
                echoMode: TextInput.Password
                passwordCharacter: "●"
                focus: true; clip: true
                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed:  doLogin()

                // ANIMATION 7 trigger: flash topLine on every keystroke
                onTextChanged: {
                    typeFlash.opacity = 0.55
                    typeFlashAnim.restart()
                }
            }

            // Lock indicator circle
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 22 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 8 * s; height: 8 * s; radius: 4 * s
                color: "transparent"
                border.color: passwordField.activeFocus ? root.red2 : root.red3
                border.width: 1.5 * s
                Behavior on border.color { ColorAnimation { duration: 300 } }
            }

            // Placeholder
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 54 * s
                anchors.verticalCenter: parent.verticalCenter
                text: "ENTER ACCESS CODE"
                color: root.smoke
                font.family: tektur.name
                font.pixelSize: 12 * s
                font.letterSpacing: 3.5 * s
                font.weight: Font.Light
                opacity: 0.4
                visible: !passwordField.text && !passwordField.activeFocus
            }

            // ANIMATION 8: GO button that PULSES (scale beat) when text is entered
            Item {
                id: engageArea
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 80 * s

                // Track whether we just went from empty to having text
                property bool hasText: passwordField.text.length > 0
                onHasTextChanged: {
                    if (hasText) goScaleAnim.start()
                }

                // Divider border
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1 * s
                    color: Qt.rgba(0.91, 0.15, 0.10, engageArea.hasText ? 0.55 : 0.15)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // Hover fill
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.91, 0.15, 0.10, engageMouse.containsMouse ? 0.20 : 0.0)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "GO"
                    color: engageArea.hasText
                           ? (engageMouse.containsMouse ? root.red2 : root.red1)
                           : Qt.rgba(0.91, 0.15, 0.10, 0.25)
                    font.family: tektur.name
                    font.pixelSize: 11 * s
                    font.letterSpacing: 4 * s
                    font.weight: Font.Bold
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Scale beat animation
                SequentialAnimation {
                    id: goScaleAnim
                    NumberAnimation { target: engageArea; property: "scale"; to: 1.12; duration: 120; easing.type: Easing.OutQuad }
                    NumberAnimation { target: engageArea; property: "scale"; to: 0.96; duration: 100; easing.type: Easing.InOutSine }
                    NumberAnimation { target: engageArea; property: "scale"; to: 1.0;  duration: 140; easing.type: Easing.OutBounce }
                }

                MouseArea {
                    id: engageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }
    }

    // ── Typing flash fade-out animation ───────────────────────────────
    NumberAnimation {
        id: typeFlashAnim
        target: typeFlash; property: "opacity"
        to: 0; duration: 350; easing.type: Easing.OutCubic
    }

    // ── Error Message ─────────────────────────────────────────────────
    Text {
        id: errorMessage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: taillightBar.top
        anchors.bottomMargin: 10 * s
        text: ""
        color: root.red2
        font.family: tektur.name
        font.pixelSize: 9 * s
        font.letterSpacing: 4 * s
        opacity: root.ui
        // ANIMATION: error fades in from below
        transform: Translate { y: errorMessage.text !== "" ? 0 : 6 * s }
        Behavior on transform { }
    }

    // Shake animation
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: taillightBar; property: "x"; to: taillightBar.x + 12; duration: 40 }
        NumberAnimation { target: taillightBar; property: "x"; to: taillightBar.x - 10; duration: 40 }
        NumberAnimation { target: taillightBar; property: "x"; to: taillightBar.x + 7;  duration: 40 }
        NumberAnimation { target: taillightBar; property: "x"; to: taillightBar.x - 4;  duration: 40 }
        NumberAnimation { target: taillightBar; property: "x"; to: taillightBar.x;      duration: 40 }
    }

    // ══════════════════════════════════════════════════════════════════
    //  VERY BOTTOM — Session & Power
    // ══════════════════════════════════════════════════════════════════
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 * s
        anchors.left: parent.left
        anchors.leftMargin: 28 * s
        spacing: 6 * s
        opacity: root.ui * 0.5

        Text {
            text: "◂"
            color: root.smoke; font.pixelSize: 8 * s
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0)
                  ? sessionHelper.currentItem.sName.toUpperCase() : "SESSION"
            color: root.smoke
            font.family: tektur.name; font.pixelSize: 9 * s; font.letterSpacing: 2 * s
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sessionModel && sessionModel.rowCount() > 0)
                        root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                }
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 * s
        anchors.right: parent.right
        anchors.rightMargin: 36 * s
        spacing: 24 * s
        opacity: root.ui * 0.5

        Repeater {
            model: [ { t: "RESTART", a: 0 }, { t: "SHUTDOWN", a: 1 } ]
            delegate: Text {
                property var d: modelData
                text: d.t
                color: root.smoke
                font.family: tektur.name; font.pixelSize: 9 * s; font.letterSpacing: 2 * s
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: parent.color = root.red1
                    onExited:  parent.color = root.smoke
                    onClicked: { if (d.a === 0) sddm.reboot(); else sddm.powerOff() }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    //  LOGIC
    // ══════════════════════════════════════════════════════════════════
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "// ACCESS DENIED"
            passwordField.text = ""
            passwordField.focus = true
            shakeAnim.start()
        }
    }

    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uName)
                    ? userHelper.currentItem.uName : userModel.lastUser
        sddm.login(uname, passwordField.text, root.sessionIndex)
    }
}
