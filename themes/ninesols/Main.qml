// Header imports
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Root setup
Rectangle {
    id: root
    width: Screen.width; height: Screen.height
    readonly property real s: height / 768
    color: "#050608"
    focus: true

    // Cursor fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    // Screen metrics
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0

    // Key navigation
    property int activeMenuIndex: -1
    property bool keyboardNavActive: false

    // Focus controller
    onActiveMenuIndexChanged: {
        if (activeMenuIndex === 1) {
            pwd.forceActiveFocus()
        } else if (pwd.activeFocus) {
            root.forceActiveFocus()
        }
    }

    // Hover helpers
    readonly property bool mouseIsActive: loginMouse.containsMouse || pwdMouse.containsMouse || userMouse.containsMouse || (typeof sessionMouse !== "undefined" && sessionMouse.containsMouse) || restartMouse.containsMouse || shutdownMouse.containsMouse
    onMouseIsActiveChanged: {
        if (mouseIsActive) {
            keyboardNavActive = false
        } else if (!keyboardNavActive && !pwd.activeFocus) {
            root.activeMenuIndex = -1
        }
    }

    // State indicators
    readonly property bool isStartActive: root.activeMenuIndex === 0
    readonly property bool isPwdActive: root.activeMenuIndex === 1
    readonly property bool isUserActive: root.activeMenuIndex === 2
    readonly property bool isSessionActive: root.activeMenuIndex === 3
    readonly property bool isRestartActive: root.activeMenuIndex === 4
    readonly property bool isShutdownActive: root.activeMenuIndex === 5

    // Theme colors
    readonly property color goldActive: "#dfd59c"
    readonly property color goldDim: "#6a6245"
    readonly property color barDim: "#3a3525"

    // Load assets
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    TextConstants { id: textConstants }

    // Hidden helpers
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 1; height: 1; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Entry animation
    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic }

    // Backdrop image
    Image {
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.ui
    }

    // Side vignette
    Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: parent.width * 0.45
        opacity: root.ui
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#e6050608" }
            GradientStop { position: 0.6; color: "#b3050608" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Intro overlay
    Rectangle {
        anchors.fill: parent; visible: root.ui < 1.0; opacity: 1.0 - root.ui; color: "#050608"; z: 100
    }

    // Title logo
    Image {
        id: logo
        source: "logo.png"
        anchors.top: parent.top; anchors.left: parent.left
        anchors.topMargin: 100 * s; anchors.leftMargin: 120 * s
        width: 260 * s
        height: width * (implicitHeight / implicitWidth)
        fillMode: Image.PreserveAspectFit
        opacity: root.ui
    }

    // Selection menu
    Column {
        id: menuCol
        anchors.top: logo.bottom; anchors.left: logo.left
        anchors.topMargin: 50 * s
        spacing: 16 * s
        opacity: root.ui

        // Action item
        Item {
            width: 320 * s; height: 24 * s
            Row {
                spacing: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                x: root.isStartActive ? (loginMouse.pressed ? -6 * s : 0) : 24 * s
                scale: loginMouse.pressed ? 0.96 : 1.0

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text { text: "|"; color: root.isStartActive ? root.goldActive : root.barDim; opacity: root.isStartActive ? 1.0 : 0.45; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                Text { text: "Start Game"; color: root.isStartActive ? root.goldActive : root.goldDim; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } }
            }
            MouseArea {
                id: loginMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: { if (containsMouse) root.activeMenuIndex = 0 }
                onClicked: { root.activeMenuIndex = 0; doLogin() }
            }
        }

        // Input prompt
        Item {
            width: 320 * s; height: 24 * s
            Row {
                spacing: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                x: root.isPwdActive ? (pwdMouse.pressed ? -6 * s : 0) : 24 * s
                scale: pwdMouse.pressed ? 0.96 : 1.0

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text { text: "|"; color: root.isPwdActive ? root.goldActive : root.barDim; opacity: root.isPwdActive ? 1.0 : 0.45; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                Text { text: (pwd.text.length === 0 && !root.isPwdActive) ? "Enter Password" : ""; color: root.isPwdActive ? root.goldActive : root.goldDim; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } }
            }
            TextInput {
                id: pwd; anchors.fill: parent
                leftPadding: root.isPwdActive ? 24 * s : 48 * s
                Behavior on leftPadding { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                color: root.goldActive; font.family: mainFont.name; font.pixelSize: 18 * s
                echoMode: TextInput.Password; passwordCharacter: "•"; cursorVisible: false; focus: false
                cursorDelegate: Item { width: 0; height: 0 }
                onTextEdited: err.text = ""

                Keys.onUpPressed: root.decrementMenu()
                Keys.onDownPressed: root.incrementMenu()
                Keys.onReturnPressed: root.activateMenu()
                Keys.onEnterPressed: root.activateMenu()
                Keys.onEscapePressed: { pwd.text = ""; err.text = ""; root.forceActiveFocus() }
                onActiveFocusChanged: {
                    if (activeFocus) {
                        root.activeMenuIndex = 1
                    } else if (root.activeMenuIndex === 1) {
                        root.activeMenuIndex = -1
                    }
                }

                // Custom cursor
                Rectangle {
                    id: customCursor
                    width: 1.5 * s; height: 16 * s
                    color: root.goldActive
                    anchors.verticalCenter: parent.verticalCenter
                    x: pwd.cursorRectangle.x
                    visible: pwd.focus && pwd.text.length > 0

                    SequentialAnimation {
                        loops: Animation.Infinite; running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1.0; to: 0.1; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.1; to: 1.0; duration: 450 }
                    }
                }
            }
            MouseArea {
                id: pwdMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor
                onContainsMouseChanged: { if (containsMouse) root.activeMenuIndex = 1 }
                onClicked: { root.activeMenuIndex = 1; pwd.forceActiveFocus() }
            }
        }

        // Action item
        Item {
            width: 320 * s; height: 24 * s
            Row {
                spacing: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                x: root.isUserActive ? (userMouse.pressed ? -6 * s : 0) : 24 * s
                scale: userMouse.pressed ? 0.96 : 1.0

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text { text: "|"; color: root.isUserActive ? root.goldActive : root.barDim; opacity: root.isUserActive ? 1.0 : 0.45; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                Text { text: "Select User: " + ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : ((typeof userModel !== "undefined" && userModel) ? userModel.lastUser : "User")); color: root.isUserActive ? root.goldActive : root.goldDim; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } }
            }
            MouseArea {
                id: userMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: { if (containsMouse) root.activeMenuIndex = 2 }
                onClicked: { root.activeMenuIndex = 2; nextUser() }
            }
        }

        // Action item
        Item {
            width: 320 * s; height: 24 * s; visible: !root.isQuickshell
            Row {
                spacing: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                x: root.isSessionActive ? (sessionMouse.pressed ? -6 * s : 0) : 24 * s
                scale: sessionMouse.pressed ? 0.96 : 1.0

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text { text: "|"; color: root.isSessionActive ? root.goldActive : root.barDim; opacity: root.isSessionActive ? 1.0 : 0.45; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                Text { text: "Options: " + ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "Session"); color: root.isSessionActive ? root.goldActive : root.goldDim; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } }
            }
            MouseArea {
                id: sessionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: { if (containsMouse) root.activeMenuIndex = 3 }
                onClicked: { root.activeMenuIndex = 3; nextSession() }
            }
        }

        // Action item
        Item {
            width: 320 * s; height: 24 * s
            Row {
                spacing: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                x: root.isRestartActive ? (restartMouse.pressed ? -6 * s : 0) : 24 * s
                scale: restartMouse.pressed ? 0.96 : 1.0

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text { text: "|"; color: root.isRestartActive ? root.goldActive : root.barDim; opacity: root.isRestartActive ? 1.0 : 0.45; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                Text { text: "Restart System"; color: root.isRestartActive ? root.goldActive : root.goldDim; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } }
            }
            MouseArea {
                id: restartMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: { if (containsMouse) root.activeMenuIndex = 4 }
                onClicked: { root.activeMenuIndex = 4; if (typeof sddm !== "undefined") sddm.reboot() }
            }
        }

        // Action item
        Item {
            width: 320 * s; height: 24 * s
            Row {
                spacing: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                x: root.isShutdownActive ? (shutdownMouse.pressed ? -6 * s : 0) : 24 * s
                scale: shutdownMouse.pressed ? 0.96 : 1.0

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Text { text: "|"; color: root.isShutdownActive ? root.goldActive : root.barDim; opacity: root.isShutdownActive ? 1.0 : 0.45; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } }
                Text { text: "Exit Game"; color: root.isShutdownActive ? root.goldActive : root.goldDim; font.family: mainFont.name; font.pixelSize: 18 * s; Behavior on color { ColorAnimation { duration: 200 } } }
            }
            MouseArea {
                id: shutdownMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: { if (containsMouse) root.activeMenuIndex = 5 }
                onClicked: { root.activeMenuIndex = 5; if (typeof sddm !== "undefined") sddm.powerOff() }
            }
        }
    }

    // Status message
    Text {
        id: err
        anchors.top: menuCol.bottom; anchors.left: menuCol.left; anchors.topMargin: 20 * s
        text: ""; color: "#df5050"; font.family: mainFont.name; font.pixelSize: 14 * s; font.letterSpacing: 2 * s
        opacity: text.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // Button prompts
    Row {
        anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 40 * s; spacing: 24 * s
        opacity: root.ui

        Row {
            spacing: 8 * s
            Rectangle {
                width: 22 * s; height: 22 * s; radius: 11 * s
                color: "#0c0d10"; border.color: "#ffffff"; border.width: 1.5 * s
                Text { anchors.centerIn: parent; text: "A"; color: "#76e82a"; font.bold: true; font.pixelSize: 11 * s }
            }
            Text { text: "CONFIRM"; color: "#e3e4e6"; font.family: mainFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1.5 * s; anchors.verticalCenter: parent.verticalCenter }
        }

        Row {
            spacing: 8 * s
            Rectangle {
                width: 22 * s; height: 22 * s; radius: 11 * s
                color: "#0c0d10"; border.color: "#ffffff"; border.width: 1.5 * s
                Text { anchors.centerIn: parent; text: "B"; color: "#f23c34"; font.bold: true; font.pixelSize: 11 * s }
            }
            Text { text: "BACK"; color: "#e3e4e6"; font.family: mainFont.name; font.pixelSize: 12 * s; font.letterSpacing: 1.5 * s; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // System bindings
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { err.text = "AUTHENTICATION FAILED"; pwd.text = ""; pwd.focus = true }
    }

    // Keyboard capture
    Keys.onUpPressed: root.decrementMenu()
    Keys.onDownPressed: root.incrementMenu()
    Keys.onReturnPressed: root.activateMenu()
    Keys.onEnterPressed: root.activateMenu()

    // Custom logic
    function getValidIndices() {
        return root.isQuickshell ? [0, 1, 2, 4, 5] : [0, 1, 2, 3, 4, 5];
    }

    // Custom logic
    function incrementMenu() {
        root.keyboardNavActive = true
        var valid = getValidIndices()
        var currPos = valid.indexOf(root.activeMenuIndex)
        var nextPos = 0
        if (currPos === -1) {
            nextPos = 0
        } else {
            nextPos = (currPos + 1) % valid.length
        }
        root.activeMenuIndex = valid[nextPos]
    }

    // Custom logic
    function decrementMenu() {
        root.keyboardNavActive = true
        var valid = getValidIndices()
        var currPos = valid.indexOf(root.activeMenuIndex)
        var nextPos = 0
        if (currPos === -1) {
            nextPos = valid.length - 1
        } else {
            nextPos = (currPos - 1 + valid.length) % valid.length
        }
        root.activeMenuIndex = valid[nextPos]
    }

    // Custom logic
    function activateMenu() {
        if (root.keyboardNavActive) {
            switch (root.activeMenuIndex) {
                case 0:
                    doLogin()
                    break
                case 1:
                    pwd.forceActiveFocus()
                    break
                case 2:
                    nextUser()
                    break
                case 3:
                    nextSession()
                    break
                case 4:
                    if (typeof sddm !== "undefined") sddm.reboot()
                    break
                case 5:
                    if (typeof sddm !== "undefined") sddm.powerOff()
                    break
            }
        } else {
            doLogin()
        }
    }

    // Custom logic
    function nextUser() {
        if (typeof userModel === "undefined" || userModel === null) return
        var count = 0
        if (typeof userModel.rowCount === "function") {
            count = userModel.rowCount()
        } else if (typeof userModel.count !== "undefined") {
            count = userModel.count
        }
        if (count > 0) {
            root.userIndex = (root.userIndex + 1) % count
        }
    }

    // Custom logic
    function nextSession() {
        if (typeof sessionModel === "undefined" || sessionModel === null) return
        var count = 0
        if (typeof sessionModel.rowCount === "function") {
            count = sessionModel.rowCount()
        } else if (typeof sessionModel.count !== "undefined") {
            count = sessionModel.count
        }
        if (count > 0) {
            root.sessionIndex = (root.sessionIndex + 1) % count
        }
    }

    // Login procedure
    function doLogin() { 
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : ""); 
        if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex) 
    }
}
