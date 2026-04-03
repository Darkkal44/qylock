import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Qt.labs.folderlistmodel 2.15
import SddmComponents 2.0

// Minecraft theme
Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: sessionModel.lastIndex

    // Colors
    //  Button face colours (stone slab)
    readonly property color btnFace:      "#8B8B8B"
    readonly property color btnHighlight: "#BCBCBC"  // top-left bevel
    readonly property color btnShadow:    "#383838"  // bottom-right bevel
    readonly property color btnHoverFace: "#9090C0"  // classic blue-hover tint
    readonly property color btnHoverHL:   "#C0C0F0"
    readonly property color btnPressface: "#585868"

    //  Text
    readonly property color txtWhite:  "#FFFFFF"
    readonly property color txtShadow: "#3F3F3F"
    readonly property color txtYellow: "#FFFF55"
    readonly property color txtRed:    "#FF5555"
    readonly property color txtGreen:  "#55FF55"
    readonly property color txtGray:   "#AAAAAA"

    //  Input field
    readonly property color fldBg:        "#000000"
    readonly property color fldBorder:    "#A0A0A0"
    readonly property color fldBorderFoc: "#FFFFFF"

    // States
    property real uiOpacity: 0
    property real uiOffset: 40
    property real splashScale: 1.0
    property real bgScale: 1.1
    property real bgOffset: 0

    // Font
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: mcFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    TextConstants { id: textConstants }

    // Connections
    Connections {
        target: sddm

        function onLoginSucceeded() {
            errorMsg.color = root.txtGreen
            errorMsg.text  = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            passInput.text = ""
            errorMsg.color = root.txtRed
            errorMsg.text  = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            errorMsg.color = root.txtRed
            errorMsg.text  = message
        }
    }

    // Background (Animated)
    Item {
        anchors.fill: parent
        clip: true
        Image {
            id: bgImage
            width: parent.width * 1.2; height: parent.height * 1.2
            source: "background.png"
            fillMode: Image.PreserveAspectCrop
            anchors.centerIn: parent
            scale: root.bgScale
            x: - (root.bgOffset * 50)
            
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { from: -50; to: 50; duration: 30000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 50; to: -50; duration: 30000; easing.type: Easing.InOutSine }
            }
        }
    }

    // Session Helper
    ListView {
        id: sessionNameHelper
        model: sessionModel
        currentIndex: sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sessionName: model.name || "" }
    }

    // UI Stack
    Column {
        id: uiStack
        width: 360 * s
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.uiOffset
        spacing: 0 * s
        opacity: root.uiOpacity
        
        // --- Boot Animation ---
        Component.onCompleted: {
            bootAnim.start()
        }
        
        SequentialAnimation {
            id: bootAnim
            PauseAnimation { duration: 500 }
            ParallelAnimation {
                NumberAnimation { target: root; property: "uiOpacity"; to: 1.0; duration: 1000; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "uiOffset"; to: 0; duration: 1000; easing.type: Easing.OutBack }
            }
        }

            // Header Area

            Item {
                width: parent.width; height: 100 * s
                
                McText {
                    id: clockTime
                    anchors.centerIn: parent
                    label: "00:00"
                    pixelSize: 72 * s
                    textColor: root.txtYellow
                    Timer {
                        interval: 1000; running: true; repeat: true
                        onTriggered: clockTime.label = Qt.formatTime(new Date(), "hh:mm")
                    }
                    Component.onCompleted: clockTime.label = Qt.formatTime(new Date(), "hh:mm")
                }

                    // Splash Text
                    Text {
                        id: splashText
                        text: "Welcome back!"
                        font.family: mcFont.name
                        font.pixelSize: 16 * s
                        color: root.txtYellow
                        style: Text.Outline
                        styleColor: "black"
                        rotation: -20
                        anchors.left: clockTime.right
                        anchors.leftMargin: -20 * s
                        anchors.top: clockTime.top
                        anchors.topMargin: -10 * s
                        
                        scale: root.splashScale
                        
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.05; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.05; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                        }

                        Component.onCompleted: {
                            var splashMessages = [
                                "I use Arch btw",
                                "sudo rm -rf /",
                                "RTFM!",
                                "Distro hopping again?",
                                "Kernel Sanders",
                                "cron flakes",
                                "Where is the 'any' key?",
                                "Powered by TUX!",
                                "chmod 777 EVERYTHING",
                                "Segmentation fault",
                                "Wayland or X11?",
                                "Vim > Emacs",
                                "sudo get me a sandwich",
                                "NAT NAT NAT!",
                                "STILL COMPILING...",
                                "It's GNU/Linux!",
                                "Thou shalt not kill -9",
                                "Free as in speech!",
                                "Dependency hell!",
                                "Kernel Panic!",
                                "pacman -Syu",
                                "NixOS is the way!",
                                "Compile your own kernel",
                                "X11 is watching you",
                                "btw I use NixOS"
                            ];
                            text = splashMessages[Math.floor(Math.random() * splashMessages.length)];
                        }
                    }
            }

            McText {
                id: clockDate
                anchors.horizontalCenter: parent.horizontalCenter
                label: ""
                pixelSize: 18 * s
                textColor: root.txtGray
                Timer {
                    interval: 60000; running: true; repeat: true
                    onTriggered: clockDate.label = Qt.formatDate(new Date(), "dddd, MMMM d")
                }
                Component.onCompleted: clockDate.label = Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }

            // User Area

            McText {
                label: "Username"
                pixelSize: 14 * s
                textColor: root.txtWhite
            }

            McInputField {
                id: nameField
                width: parent.width
                height: 48 * s
                inputRef: nameInput
            }
            TextInput {
                id: nameInput
                parent: nameField.inputArea
                anchors.fill: parent; anchors.margins: 8 * s
                verticalAlignment: TextInput.AlignVCenter
                text: userModel.lastUser
                font.family: mcFont.name; font.pixelSize: 14 * s
                color: root.txtWhite
                clip: true
                KeyNavigation.backtab: rebootBtn
                KeyNavigation.tab: passInput
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        passInput.forceActiveFocus(); event.accepted = true
                    }
                }
            }
        }

            // Password Area

            McText {
                label: "Password"
                pixelSize: 14 * s
                textColor: root.txtWhite
            }

            McInputField {
                id: passField
                width: parent.width
                height: 48 * s
                inputRef: passInput
            }
            TextInput {
                id: passInput
                parent: passField.inputArea
                anchors.fill: parent; anchors.margins: 8 * s
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                font.family: mcFont.name; font.pixelSize: 14 * s; font.letterSpacing: 3 * s
                color: root.txtWhite
                clip: true

                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "Enter password..."
                    font.family: mcFont.name; font.pixelSize: 13 * s
                    color: "#555555"
                    visible: !passInput.text && !passInput.activeFocus
                }

                KeyNavigation.backtab: nameInput
                KeyNavigation.tab: loginBtn
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(nameInput.text, passInput.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }
        }

        // MESSAGE
        Text {
            id: errorMsg
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: ""
            color: root.txtRed
            font.family: mcFont.name; font.pixelSize: 13 * s
            height: text === "" ? 0 : implicitHeight + 6
            Behavior on height { NumberAnimation { duration: 150 } }
        }

        // LOGIN
        McButton {
            id: loginBtn
            width: parent.width
            height: 44 * s
            label: "Login"
            KeyNavigation.backtab: passInput
            KeyNavigation.tab: sessionBtn
            onClicked: sddm.login(nameInput.text, passInput.text, sessionIndex)
        }

        Item { width: 1 * s; height: 12 * s }

        // Selection Area
        Item {
            id: sessionSelector
            width: parent.width
            height: 44 * s
            z: 10

            McButton {
                id: sessionBtn
                width: parent.width
                height: 44 * s
                label: (sessionNameHelper.currentItem
                        ? sessionNameHelper.currentItem.sessionName
                        : "Select Session")
                     + (sessionDropdown.visible ? "  ▲" : "  ▼")
                KeyNavigation.backtab: loginBtn
                KeyNavigation.tab: shutdownBtn
                onClicked: sessionDropdown.visible = !sessionDropdown.visible
            }

            // Dropdown
            Item {
                id: sessionDropdown
                visible: false
                width: parent.width
                height: Math.min(sessionModel.rowCount() * 38, 152)
                // opens ABOVE the session button
                anchors.bottom: sessionBtn.top
                anchors.bottomMargin: 4 * s

                // Layer 1 — outer shadow slab (bottom-right, same as McButton)
                Rectangle {
                    anchors { fill: parent; topMargin: 2 * s; leftMargin: 2 * s }
                    color: root.btnShadow
                }
                // Layer 2 — highlight slab (top-left)
                Rectangle {
                    anchors { fill: parent; bottomMargin: 2 * s; rightMargin: 2 * s }
                    color: root.btnHighlight
                }
                // Layer 3 — stone face (inset 2px, same colour as button face)
                Rectangle {
                    id: dropFace
                    anchors { fill: parent; topMargin: 2 * s; leftMargin: 2 * s; bottomMargin: 2 * s; rightMargin: 2 * s }
                    color: root.btnFace
                    clip: true

                    // Thin darker inner-bevel strip at very top of the panel
                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 2 * s
                        color: root.btnShadow
                        opacity: 0.6
                    }

                    ListView {
                        id: sessionListView
                        anchors.fill: parent
                        anchors.topMargin: 2 * s
                        model: sessionModel
                        currentIndex: sessionIndex
                        clip: true

                        delegate: Item {
                            width: sessionListView.width
                            height: 38 * s

                            // Row background: hover = button-blue, selected = darker blue, else stone
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2 * s
                                color: sessionItemMouse.containsMouse
                                       ? root.btnHoverFace          // blue-hover tint
                                       : (index === sessionIndex
                                          ? Qt.darker(root.btnHoverFace, 1.3)  // selected darker blue
                                          : "transparent")
                            }

                            // Session name — shadow then foreground (pure x/y positioning)
                            Text {
                                x: 15 * s; y: (parent.height - implicitHeight) / 2 + 1
                                text: model.name || model.display || ""
                                color: root.txtShadow
                                font.family: mcFont.name; font.pixelSize: 13 * s
                            }
                            Text {
                                x: 14 * s; y: (parent.height - implicitHeight) / 2
                                text: model.name || model.display || ""
                                color: sessionItemMouse.containsMouse ? root.txtYellow : root.txtWhite
                                font.family: mcFont.name; font.pixelSize: 13 * s
                            }

                            // Checkmark for active session (shadowed green)
                            Text {
                                visible: index === sessionIndex
                                anchors.right: parent.right; anchors.rightMargin: 12 * s
                                y: (parent.height - implicitHeight) / 2 + 1
                                text: "✓"; color: root.txtShadow
                                font.family: mcFont.name; font.pixelSize: 13 * s
                            }
                            Text {
                                visible: index === sessionIndex
                                anchors.right: parent.right; anchors.rightMargin: 13 * s
                                y: (parent.height - implicitHeight) / 2
                                text: "✓"; color: root.txtGreen
                                font.family: mcFont.name; font.pixelSize: 13 * s
                            }

                            // Thin separator line between rows (darker stone edge)
                            Rectangle {
                                visible: index < sessionModel.rowCount() - 1
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                anchors.leftMargin: 6 * s; anchors.rightMargin: 6 * s
                                height: 1 * s
                                color: root.btnShadow
                                opacity: 0.5
                            }

                            MouseArea {
                                id: sessionItemMouse
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: { sessionIndex = index; sessionDropdown.visible = false }
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1 * s; height: 12 * s }

        // Power Area
        Row {
            width: parent.width
            spacing: 10 * s

            McButton {
                id: shutdownBtn
                width: (parent.width - 10) / 2
                height: 44 * s
                label: "Shutdown"
                KeyNavigation.backtab: sessionBtn
                KeyNavigation.tab: rebootBtn
                onClicked: sddm.powerOff()
            }
            McButton {
                id: rebootBtn
                width: (parent.width - 10) / 2
                height: 44 * s
                label: "Reboot"
                KeyNavigation.backtab: shutdownBtn
                KeyNavigation.tab: nameInput
                onClicked: sddm.reboot()
            }
        }
    }   // end Column


    // Shared Components

    // McText
    component McText: Item {
        property string label:     "Text"
        property int    pixelSize: 14 * s
        property color  textColor: root.txtWhite

        implicitWidth:  foreLabel.implicitWidth  + 2
        implicitHeight: foreLabel.implicitHeight + 2

        // shadow (offset 2,2)
        Text {
            x: 2 * s; y: 2 * s
            text: label
            font.family: mcFont.name; font.pixelSize: pixelSize
            color: root.txtShadow
        }
        // foreground
        Text {
            id: foreLabel
            x: 0 * s; y: 0 * s
            text: label
            font.family: mcFont.name; font.pixelSize: pixelSize
            color: textColor
        }
    }

    // McInputField
    component McInputField: Item {
        property var inputRef        // bind the TextInput to this property
        property alias inputArea: innerRect

        // outer 2px black frame
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            border.color: "#000000"; border.width: 1 * s
        }

        // inset shadow strips (darker top+left = "sunken" look)
        Rectangle { anchors { top:parent.top; left:parent.left; right:parent.right }
                    height: 2 * s; color: "#6E6E6E" }
        Rectangle { anchors { top:parent.top; left:parent.left; bottom:parent.bottom }
                    width: 2 * s; color: "#6E6E6E" }
        // highlight bottom + right
        Rectangle { anchors { bottom:parent.bottom; left:parent.left; right:parent.right }
                    height: 2 * s; color: root.fldBorderFoc; opacity: 0.12 }
        Rectangle { anchors { top:parent.top; right:parent.right; bottom:parent.bottom }
                    width: 2 * s; color: root.fldBorderFoc; opacity: 0.12 }

        // actual text area
        Rectangle {
            id: innerRect
            anchors { fill:parent; margins: 2 * s }
            color: "#000000"

            // focus border (1px bright inner)
            Rectangle {
                visible: inputRef && inputRef.activeFocus
                anchors.fill: parent
                color: "transparent"
                border.color: root.fldBorderFoc; border.width: 1 * s
            }
        }
    }

    // McButton
    component McButton: Item {
        id: btnRoot
        property string label:  "Button"
        signal clicked()

        // keyboard activation
        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
                clicked(); event.accepted = true
            }
        }

        // ── Layer 1: bottom-right shadow slab ──────────────────────────
        Rectangle {
            anchors { fill:parent; topMargin:2 * s; leftMargin:2 * s }
            color: hover.pressed ? root.btnShadow : root.btnShadow
        }
        // ── Layer 2: top-left highlight slab ───────────────────────────
        Rectangle {
            anchors { fill:parent; bottomMargin:2 * s; rightMargin:2 * s }
            color: hover.pressed ? root.btnPressface
                 : hover.containsMouse ? root.btnHoverHL
                 : root.btnHighlight
        }
        // ── Layer 3: face slab (inset 2px from each edge) ──────────────
        Rectangle {
            id: face
            anchors { fill:parent; topMargin:2 * s; leftMargin:2 * s; bottomMargin:2 * s; rightMargin:2 * s }
            color: hover.pressed          ? root.btnPressface
                 : hover.containsMouse    ? root.btnHoverFace
                 : root.btnFace

            scale: hover.containsMouse ? 1.02 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }

            // ── Text with drop-shadow ─────────────────────────────────
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 2 * s; anchors.verticalCenterOffset: 2 * s
                text: btnRoot.label
                font.family: mcFont.name; font.pixelSize: 14 * s
                color: root.txtShadow
            }
            Text {
                anchors.centerIn: parent
                text: btnRoot.label
                font.family: mcFont.name; font.pixelSize: 14 * s
                color: hover.pressed          ? root.txtGray
                     : hover.containsMouse    ? root.txtYellow
                     : root.txtWhite
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btnRoot.clicked()
        }
    }

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: { if (nameInput.text === "") nameInput.forceActiveFocus(); else passInput.forceActiveFocus() } }

    // ── Initial focus ──────────────────────────────────────────────────────
    Component.onCompleted: {
        if (nameInput.text === "") nameInput.forceActiveFocus()
        else                       passInput.forceActiveFocus()
    }
}
