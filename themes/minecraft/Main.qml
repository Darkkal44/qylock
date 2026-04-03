import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Minecraft Theme — Final Polished Refactor
Rectangle {
    id: root
    readonly property real s: Screen.height / 768
    width: Screen.width; height: Screen.height
    color: "#1e1e1e"

    // --- State Properties ---
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: 0
    property bool sessionPopupOpen: false
    property real uiOpacity: 0
    
    // --- Minecraft Color Palette ---
    readonly property color mcBtnFace:      "#8b8b8b"
    readonly property color mcBtnHighlight: "#bcbcbc"
    readonly property color mcBtnShadow:    "#373737"
    readonly property color mcBtnHover:     "#9090c0" 
    readonly property color mcBtnPress:     "#585858"
    
    readonly property color mcTextWhite:    "#ffffff"
    readonly property color mcTextShadow:   "#3f3f3f"
    readonly property color mcTextYellow:   "#ffff55"
    readonly property color mcTextGray:     "#aaaaaa"
    readonly property color mcTextRed:      "#ff5555"
    readonly property color mcTextGreen:    "#55ff55"
    
    readonly property color mcFldBg:        "#000000"
    readonly property color mcFldBorder:    "#a0a0a0"

    // --- Fonts ---
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mcFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    TextConstants { id: textConstants }

    // --- Background (Tiled Dirt) ---
    Item {
        anchors.fill: parent
        Image {
            anchors.fill: parent
            source: "background.png"
            fillMode: Image.Tile
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignTop
            scale: 2.0 
            transformOrigin: Item.Center
        }
    }

    // --- Standard Bridges (Quickshell Compatibility) ---
    ListView {
        id: sessionHelper
        model: sessionModel; currentIndex: root.sessionIndex
        opacity: 0; width: 100; height: 100; z: -100; visible: true
        delegate: Item { property string sName: model.name || "" }
    }
    ListView {
        id: userHelper
        model: userModel; currentIndex: root.userIndex
        opacity: 0; width: 100; height: 100; z: -100; visible: true
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }

    // --- Main UI Layout ---
    Column {
        id: mainStack
        anchors.centerIn: parent
        width: 420 * s; spacing: 20 * s; opacity: root.uiOpacity

        // --- Header Block ---
        Item {
            width: parent.width; height: 140 * s
            Column {
                anchors.centerIn: parent; spacing: 4 * s
                McText {
                    id: clockTime; label: Qt.formatTime(new Date(), "HH:mm")
                    pixelSize: 96 * s; textColor: root.mcTextYellow
                    anchors.horizontalCenter: parent.horizontalCenter
                    Timer { interval: 1000; running: true; repeat: true; onTriggered: clockTime.label = Qt.formatTime(new Date(), "HH:mm") }
                }
                McText {
                    label: Qt.formatDate(new Date(), "dddd, MMMM d")
                    pixelSize: 20 * s; textColor: root.mcTextGray; anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Animated Splash
            Text {
                id: splashText; anchors.left: parent.horizontalCenter; anchors.leftMargin: 80 * s
                anchors.top: parent.top; anchors.topMargin: -10 * s
                text: "GNU/Linux!"; font.family: mcFont.name; font.pixelSize: 22 * s
                color: root.mcTextYellow; rotation: -20; style: Text.Outline; styleColor: "black"
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.18; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.18; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                }
                Component.onCompleted: {
                    var splashes = ["I use Arch btw", "RTFM!", "sudo rm -rf /", "Kernel Panic!", "Btw I use NixOS!", "Pacman -Syu", "chmod 777", "Segmentation Fault"];
                    text = splashes[Math.floor(Math.random() * splashes.length)];
                }
            }
        }

        Item { width: 1; height: 12 * s } 

        // --- Username Area (Clickable Toggler) ---
        Column {
            width: parent.width; spacing: 10 * s
            McText { label: "Logged in as:"; pixelSize: 15 * s; textColor: root.mcTextGray }
            McTextField {
                id: userBox; width: parent.width; height: 44 * s; inputRef: userMouse
                McText {
                    anchors.left: parent.left; anchors.leftMargin: 12 * s
                    anchors.verticalCenter: parent.verticalCenter
                    label: (userHelper.currentItem && userHelper.currentItem.uLogin !== "") ? userHelper.currentItem.uLogin : (userModel.lastUser || "User")
                    pixelSize: 18 * s; textColor: root.mcTextWhite
                }
                MouseArea {
                    id: userMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: root.userIndex = (root.userIndex + 1) % userModel.rowCount()
                    property bool isHighlighted: containsMouse || pressed
                }
            }
        }

        // --- Password Area ---
        Column {
            width: parent.width; spacing: 10 * s
            McText { label: "Enter Password:"; pixelSize: 15 * s; textColor: root.mcTextGray }
            McTextField {
                id: passField; width: parent.width; height: 42 * s; inputRef: passInput
                TextInput {
                    id: passInput; anchors.fill: parent; anchors.leftMargin: 12 * s; anchors.rightMargin: 12 * s
                    echoMode: TextInput.Password; passwordCharacter: "*"; color: "white"
                    font.family: mcFont.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                    verticalAlignment: TextInput.AlignVCenter; clip: true; focus: true
                    KeyNavigation.tab: loginBtn; KeyNavigation.backtab: rebootBtn
                    Keys.onReturnPressed: doLogin()
                    
                    Text {
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter; anchors.leftMargin: 2 * s
                        text: "Enter password..."; color: "#555555"; font.family: mcFont.name; font.pixelSize: 14 * s
                        visible: !parent.text && !parent.activeFocus
                    }
                }
            }
        }

        Text {
            id: errText; width: parent.width; horizontalAlignment: Text.AlignHCenter
            text: ""; color: root.mcTextRed; font.family: mcFont.name; font.pixelSize: 14 * s
            visible: text !== ""
        }

        Item { width: 1; height: 10 * s } // Spacer

        // --- Action Buttons ---
        McButton { 
            id: loginBtn; width: parent.width; height: 48 * s; label: "Login"
            onClicked: doLogin(); KeyNavigation.tab: sessionBtn; KeyNavigation.backtab: passInput
        }

        McButton {
            id: sessionBtn; width: parent.width; height: 48 * s
            label: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "SESSION")
            onClicked: root.sessionPopupOpen = true; KeyNavigation.tab: shutdownBtn; KeyNavigation.backtab: loginBtn
        }

        Row {
            width: parent.width; spacing: 12 * s
            McButton { id: shutdownBtn; width: (parent.width - 12 * s) / 2; height: 48 * s; label: "Shutdown"; onClicked: sddm.powerOff(); KeyNavigation.tab: rebootBtn }
            McButton { id: rebootBtn; width: (parent.width - 12 * s) / 2; height: 48 * s; label: "Reboot"; onClicked: sddm.reboot(); KeyNavigation.tab: passInput }
        }
    }

    // --- Overlay Session Switcher ---
    Item {
        id: sessionOverlay
        anchors.fill: parent; visible: root.sessionPopupOpen; z: 5000
        
        // Background Tint (High Opacity)
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.88 }
        
        Column {
            anchors.centerIn: parent; width: 420 * s; spacing: 16 * s
            
            McText {
                label: "SELECT SESSION"; pixelSize: 24 * s; textColor: root.mcTextYellow
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Item { width: 1; height: 10 * s }

            Column {
                width: parent.width; spacing: 8 * s
                Repeater {
                    model: sessionModel
                    McButton {
                        width: 420 * s; height: 44 * s
                        label: model.name || "Default"
                        // Highlight current
                        Rectangle {
                            anchors.fill: parent; color: "transparent"; border.color: root.mcTextYellow; border.width: 2 * s
                            visible: index === root.sessionIndex
                        }
                        onClicked: { root.sessionIndex = index; root.sessionPopupOpen = false }
                    }
                }
            }
            
            Item { width: 1; height: 12 * s }

            McButton {
                width: 200 * s; height: 44 * s; label: "Cancel"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: root.sessionPopupOpen = false
            }
        }

        // Close on ESC
        Keys.onEscapePressed: root.sessionPopupOpen = false
        focus: visible
    }

    // --- Fade-in ---
    NumberAnimation { id: fadeIn; target: root; property: "uiOpacity"; to: 1; duration: 1000; easing.type: Easing.OutCubic }
    Component.onCompleted: fadeIn.start()

    function doLogin() { 
        var lName = (userHelper.currentItem && userHelper.currentItem.uLogin !== "") ? userHelper.currentItem.uLogin : (userModel.lastUser || "")
        sddm.login(lName, passInput.text, root.sessionIndex) 
    }
    Connections { target: sddm; function onLoginFailed() { errText.text = "INVALID CREDENTIALS"; passInput.text = ""; passInput.forceActiveFocus() } }

    // --- Minecraft Components ---
    component McText: Item {
        property string label: ""; property int pixelSize: 16 * s; property color textColor: root.mcTextWhite
        implicitWidth: fore.implicitWidth + 2 * s; implicitHeight: fore.implicitHeight + 2 * s
        Text { x: 2 * s; y: 2 * s; text: label; color: root.mcTextShadow; font.family: mcFont.name; font.pixelSize: pixelSize }
        Text { id: fore; text: label; color: textColor; font.family: mcFont.name; font.pixelSize: pixelSize }
    }
    component McTextField: Item {
        property var inputRef
        Rectangle {
            anchors.fill: parent; color: "black"
            border.color: "#808080"; border.width: 2 * s
            Rectangle {
                anchors.fill: parent; anchors.margins: 2 * s; color: "#0a0a0a"
                Rectangle {
                    visible: inputRef && (inputRef.activeFocus || (inputRef.isHighlighted === true))
                    anchors.fill: parent; color: "transparent"; border.color: "#ffffff"; border.width: 1 * s
                }
            }
        }
    }
    component McButton: Item {
        id: mcBtn; property string label: ""; signal clicked()
        Rectangle {
            anchors.fill: parent; color: "black"
            Rectangle {
                anchors.fill: parent; anchors.margins: 1.5 * s
                color: mcMouse.pressed ? root.mcBtnPress : (mcMouse.containsMouse ? root.mcBtnHover : root.mcBtnFace)
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 2.5 * s; color: root.mcBtnHighlight; opacity: mcMouse.pressed ? 0.2 : 0.8 }
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.bottom: parent.bottom; width: 2.5 * s; color: root.mcBtnHighlight; opacity: mcMouse.pressed ? 0.2 : 0.8 }
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 2.5 * s; color: root.mcBtnShadow }
                Rectangle { anchors.top: parent.top; anchors.right: parent.right; anchors.bottom: parent.bottom; width: 2.5 * s; color: root.mcBtnShadow }
                McText { anchors.centerIn: parent; label: mcBtn.label; textColor: mcMouse.containsMouse ? root.mcTextYellow : root.mcTextWhite; pixelSize: 18 * s }
            }
            Rectangle { anchors.fill: parent; color: "transparent"; border.color: "white"; border.width: 1.5 * s; visible: mcMouse.containsMouse && !mcMouse.pressed }
        }
        MouseArea { id: mcMouse; anchors.fill: parent; hoverEnabled: true; onClicked: mcBtn.clicked() }
    }
}
