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
    color: "#0d1018"

    // Theme Props
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0)
                               ? sessionModel.lastIndex : 0
    property real ui: 0

    // Colors
    readonly property color sakuraPink:    "#d4849e"
    readonly property color sakuraLight:   "#f0c4d4"
    readonly property color mistWhite:     "#e8eef2"
    readonly property color slateDeep:     "#1a1f2e"
    readonly property color accentGlow:    "#c8608080"

    TextConstants { id: textConstants }

    // Font Config
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: orbitron; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    // Session Helper
    ListView {
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sName: model.name || "" }
    }

    // User Helper
    ListView {
        id: userHelper
        model: userModel
        currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string uName: model.realName || model.name || "" }
    }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordField.forceActiveFocus() }

    // Boot Anim
    Component.onCompleted: fadeAnim.start()
    NumberAnimation {
        id: fadeAnim
        target: root; property: "ui"
        from: 0; to: 1; duration: 1600
        easing.type: Easing.OutCubic
    }

    // Theme Base

    // Gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#12151e" }
            GradientStop { position: 0.5; color: "#1a1f2a" }
            GradientStop { position: 1.0; color: "#0d1018" }
        }
    }

    // Video background
    Loader {
        anchors.fill: parent
        source: "BackgroundVideo.qml"
    }

    // View FX

    // Vignette
    RadialGradient {
        anchors.fill: parent
        opacity: 0.6
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#c0000000" }
        }
    }

    // Mist
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 260 * s
        opacity: 0.55
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#e8000000" }
        }
    }

    // Tint
    Rectangle {
        anchors.fill: parent
        color: "#08c86080"
        opacity: 0.5
    }

    // Petal FX
    Repeater {
        model: 18
        delegate: Item {
            id: petal
            property real startX: Math.random() * root.width
            property real drift:  (Math.random() - 0.5) * 120
            property real dur:    7000 + Math.random() * 8000
            property real sz:     4 + Math.random() * 6
            property real delayMs: Math.random() * 8000
            property real rot:    Math.random() * 360

            x: startX; y: -20 * s
            width: sz; height: sz * 0.6
            opacity: 0

            Rectangle {
                anchors.fill: parent
                radius: width * 0.5
                color: Qt.rgba(
                    0.85 + Math.random() * 0.15,
                    0.55 + Math.random() * 0.2,
                    0.65 + Math.random() * 0.2,
                    0.7
                )
                rotation: petal.rot
            }

            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: petal.delayMs }
                ParallelAnimation {
                    NumberAnimation {
                        target: petal; property: "y"
                        from: -20; to: root.height + 20
                        duration: petal.dur; easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: petal; property: "x"
                        from: petal.startX; to: petal.startX + petal.drift
                        duration: petal.dur; easing.type: Easing.InOutSine
                    }
                    SequentialAnimation {
                        NumberAnimation { target: petal; property: "opacity"; to: 0.75; duration: 800 }
                        PauseAnimation { duration: petal.dur - 1600 }
                        NumberAnimation { target: petal; property: "opacity"; to: 0; duration: 800 }
                    }
                    NumberAnimation {
                        target: petal; property: "rotation"
                        from: petal.rot; to: petal.rot + 540
                        duration: petal.dur
                    }
                }
            }
        }
    }

    // Clock Module
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 64 * s
        anchors.topMargin: 55 * s
        spacing: 6 * s
        opacity: root.ui

        // Large clock
        Text {
            id: clockText
            text: Qt.formatTime(new Date(), "HH:mm")
            color: root.mistWhite
            font.family: orbitron.name
            font.pixelSize: 80 * s
            font.weight: Font.Light
            style: Text.Normal
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        // Date row with a small decorative accent
        Row {
            spacing: 12 * s
            // Sakura accent dot
            Rectangle {
                width: 6 * s; height: 6 * s; radius: 3 * s
                color: root.sakuraPink
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
                color: root.sakuraPink
                font.family: orbitron.name
                font.pixelSize: 12 * s
                font.letterSpacing: 3 * s
                font.weight: Font.Light
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Login Module
    Column {
        id: loginPanel
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 110 * s
        anchors.horizontalCenter: parent.horizontalCenter
        width: 360 * s
        spacing: 0 * s
        opacity: root.ui

        // User Section
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (userHelper.currentItem && userHelper.currentItem.uName)
                  ? userHelper.currentItem.uName
                  : (userModel.lastUser || "User")
            color: root.mistWhite
            font.family: orbitron.name
            font.pixelSize: 18 * s
            font.weight: Font.Light
            font.letterSpacing: 4 * s
        }

        Item { width: 1 * s; height: 6 * s }

        // Thin centered divider
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8 * s
            Rectangle { width: 40 * s; height: 1 * s; color: root.sakuraPink; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 5 * s; height: 5 * s; radius: 2.5; color: root.sakuraPink; opacity: 0.8 }
            Rectangle { width: 40 * s; height: 1 * s; color: root.sakuraPink; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter }
        }

        Item { width: 1 * s; height: 22 * s }

        // Password Section
        Item {
            width: parent.width
            height: 48 * s
            anchors.horizontalCenter: parent.horizontalCenter

            // Backdrop
            Rectangle {
                anchors.fill: parent
                radius: 24 * s
                color: Qt.rgba(1, 1, 1, passwordField.activeFocus ? 0.10 : 0.06)
                border.color: passwordField.activeFocus
                              ? Qt.rgba(0.84, 0.52, 0.62, 0.6)
                              : Qt.rgba(1, 1, 1, 0.10)
                border.width: 1 * s

                Behavior on border.color { ColorAnimation { duration: 300 } }
                Behavior on color      { ColorAnimation { duration: 300 } }
            }

            // Focus Indicator
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 18 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 6 * s; height: 6 * s; radius: 3 * s
                color: root.sakuraPink
                opacity: passwordField.activeFocus ? 1.0 : 0.2
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            // Actual input
            TextInput {
                id: passwordField
                anchors.left: parent.left
                anchors.leftMargin: 36 * s
                anchors.right: submitBtn.left
                anchors.rightMargin: 10 * s
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                font.family: orbitron.name; font.pixelSize: 13 * s; font.letterSpacing: 2 * s
                echoMode: TextInput.Password
                passwordCharacter: "✦"
                focus: true; clip: true
                cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                selectionColor: root.sakuraPink
                property bool wasClicked: false
                Keys.onReturnPressed: doLogin()
                Keys.onEnterPressed:  doLogin()
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "password"
                    color: "white"
                    opacity: passwordField.text.length === 0 ? 0.2 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                    font.family: orbitron.name; font.pixelSize: 13 * s; font.letterSpacing: 2 * s
                }
                Rectangle {
                    id: customCursor
                    width: 2 * s; height: 18 * s
                    color: root.sakuraPink
                    anchors.verticalCenter: parent.verticalCenter
                    x: passwordField.cursorRectangle.x
                    visible: passwordField.focus && (passwordField.text.length > 0 || passwordField.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite; running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passwordField.forceActiveFocus()
                        passwordField.wasClicked = true
                    }
                }
            }

            // Submit Button
            Item {
                id: submitBtn
                anchors.right: parent.right
                anchors.rightMargin: 8 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 34 * s; height: 34 * s

                Rectangle {
                    anchors.fill: parent
                    radius: 17 * s
                    color: submitMouse.containsMouse
                           ? Qt.rgba(0.84, 0.52, 0.62, 0.35)
                           : Qt.rgba(0.84, 0.52, 0.62, 0.15)
                    border.color: Qt.rgba(0.84, 0.52, 0.62, 0.45)
                    border.width: 1 * s
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.sakuraLight
                    font.family: orbitron.name
                    font.pixelSize: 20 * s
                    opacity: passwordField.text.length > 0 ? 1.0 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    id: submitMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }

                scale: submitMouse.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }

        Item { width: 1 * s; height: 10 * s }

        // Error text
        Text {
            id: errorMessage
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: "#e08090"
            font.family: orbitron.name
            font.pixelSize: 11 * s
            font.letterSpacing: 2 * s
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Shake Animation
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 10; duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 9;  duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 7;  duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 5;  duration: 50 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x;      duration: 50 }
    }

    // Bottom Bar
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * s
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 80
        height: 1 * s
        color: "#18d4849e"
        opacity: root.ui
    }

    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 40 * s
        anchors.rightMargin: 40 * s
        height: 42 * s
        opacity: root.ui * 0.85

        // Left: Session
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * s
            Text {
                text: "✦"
                color: root.sakuraPink; font.pixelSize: 8 * s; opacity: 0.6
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0)
                      ? sessionHelper.currentItem.sName : "Session"
                color: "white"; opacity: 0.45
                font.family: orbitron.name; font.pixelSize: 11 * s; font.letterSpacing: 1 * s
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (sessionModel && sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                    }
                }
            }
        }

        // Right: Power
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 30 * s

            Repeater {
                model: [
                    { label: "Restart",   act: 0 },
                    { label: "Shut Down", act: 1 }
                ]
                delegate: Text {
                    property var d: modelData
                    text: d.label
                    color: "white"; opacity: 0.4
                    font.family: orbitron.name; font.pixelSize: 11 * s; font.letterSpacing: 1 * s

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.opacity = 0.9
                        onExited:  parent.opacity = 0.4
                        onClicked: {
                            if (d.act === 0) sddm.reboot()
                            else             sddm.powerOff()
                        }
                    }
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
            errorMessage.text = "incorrect password"
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
