import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Window
import SddmComponents 2.0

// Theme
Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    id: root

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0
    // Palette (themeMode=light|dark in theme.conf)
    readonly property bool isDark: (config.themeMode || "light") === "dark"
    readonly property color cPink: "#da9ead"
    readonly property color cPinkLt: isDark ? "#e8b8c5" : "#f0cad5"
    readonly property color cPinkDim: "#c17d91"
    readonly property color cTealMd: "#6ea6a1"
    readonly property color cCream: isDark ? "#1f2a29" : "#fdfaf6"
    readonly property color cCreamy: isDark ? "#2f3d3c" : "#f2ece4"
    readonly property color cInk: isDark ? "#f2ece4" : "#324746"
    readonly property color cMuted: "#8fa8a6"
    readonly property color cField: isDark ? "#263332" : "#f8f4ef"
    readonly property color cBorder: isDark ? "#14ffffff" : "#18000000"
    readonly property color cError: isDark ? "#e07a86" : "#c15f6b"
    readonly property color cBtnText: isDark ? "#1f2a29" : cInk

    function doLogin() {
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "");
        if (typeof sddm !== "undefined")
            sddm.login(u, pwd.text, root.sessionIndex);

    }

    width: Screen.width
    height: Screen.height
    color: isDark ? "#1b2423" : "#6eb3ac"
    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }

    FolderListModel {
        id: fontFolder

        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader {
        id: pf

        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }

    ListView {
        id: sessionHelper

        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 100
        height: 100
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
        width: 100
        height: 100
        z: -100

        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }

    }

    Timer {
        interval: 300
        running: true
        onTriggered: pwd.forceActiveFocus()
    }

    NumberAnimation {
        id: fadeAnim

        target: root
        property: "ui"
        from: 0
        to: 1
        duration: 1200
        easing.type: Easing.OutCubic
    }

    // Background
    Image {
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // Dim the artwork behind the dark card
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.isDark ? 0.35 : 0
    }

    // Card
    Item {
        id: card

        x: root.width * 0.05
        anchors.verticalCenter: parent.verticalCenter
        width: 360 * s
        height: cardCol.height + 80 * s
        opacity: root.ui

        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 10 * s
            anchors.leftMargin: 8 * s
            radius: 24 * s
            color: "#252a403f"
            layer.enabled: true

            layer.effect: FastBlur {
                radius: 40
            }

        }

        // Surface
        Rectangle {
            id: cardBg

            anchors.fill: parent
            radius: 24 * s
            color: root.cCream

            // Border
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: root.cBorder
                border.width: 1
            }

        }

        // Content
        Column {
            id: cardCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 40 * s
            anchors.leftMargin: 40 * s
            anchors.rightMargin: 40 * s
            spacing: 0

            // Greeting
            Row {
                anchors.left: parent.left
                spacing: 6 * s

                Text {
                    text: "☕"
                    font.pixelSize: 16 * s
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: {
                        var h = new Date().getHours();
                        if (h < 12)
                            return "good morning";

                        if (h < 17)
                            return "good afternoon";

                        return "good evening";
                    }
                    color: root.cPink
                    font.family: pf.name
                    font.pixelSize: 14 * s
                    font.letterSpacing: 2 * s
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Item {
                width: 1
                height: 6 * s
            }

            // Clock
            Text {
                id: clockText

                anchors.left: parent.left
                text: Qt.formatTime(new Date(), "HH:mm")
                color: root.cInk
                font.family: pf.name
                font.pixelSize: 64 * s

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
                }

            }

            // Date
            Text {
                anchors.left: parent.left
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toLowerCase()
                color: root.cMuted
                font.family: pf.name
                font.pixelSize: 13 * s
                font.letterSpacing: 1 * s
            }

            Item {
                width: 1
                height: 24 * s
            }

            // Divider
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1 * s
                color: root.cCreamy
            }

            Item {
                width: 1
                height: 24 * s
            }

            // Username
            Row {
                anchors.left: parent.left
                spacing: 10 * s

                Rectangle {
                    width: 3 * s
                    height: 20 * s
                    radius: 1.5 * s
                    color: root.cPink
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: userNameText

                    text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "user")).toUpperCase()
                    color: userArea.containsMouse ? root.cPink : root.cInk
                    font.family: pf.name
                    font.pixelSize: 20 * s
                    font.letterSpacing: 0.5 * s
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        id: userArea

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (typeof userModel !== "undefined" && userModel.rowCount() > 0)
                                root.userIndex = (root.userIndex + 1) % userModel.rowCount();

                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

            }

            Item {
                width: 1
                height: 20 * s
            }

            // Password
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44 * s

                Rectangle {
                    anchors.fill: parent
                    radius: 14 * s
                    color: root.cField
                    border.width: 1.5 * s
                    border.color: pwd.activeFocus ? root.cPinkLt : root.cCreamy

                    // Shadow
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: parent.border.width
                        anchors.leftMargin: parent.border.width
                        anchors.rightMargin: parent.border.width
                        height: 8 * s
                        radius: 12 * s

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#0a000000"
                            }

                            GradientStop {
                                position: 1
                                color: "transparent"
                            }

                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 250
                        }

                    }

                }

                Text {
                    anchors.centerIn: parent
                    text: "password"
                    color: root.cMuted
                    opacity: pwd.text.length === 0 ? 0.6 : 0
                    font.family: pf.name
                    font.pixelSize: 13 * s
                    font.letterSpacing: 2 * s

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

                TextInput {
                    id: pwd

                    property bool wasClicked: false

                    color: root.cMuted
                    font.family: pf.name
                    font.pixelSize: 14 * s
                    font.letterSpacing: 8 * s
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    onTextEdited: {
                        errText.text = "";
                        errText.visible = false;
                    }
                    focus: true
                    clip: true
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    cursorVisible: false
                    onActiveFocusChanged: {
                        if (!activeFocus && text.length === 0) {
                            wasClicked = false;
                        }
                    }
                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed: doLogin()

                    anchors {
                        fill: parent
                        leftMargin: 20 * s
                        rightMargin: 20 * s
                    }

                    // Cursor
                    Rectangle {
                        id: needleCursor

                        width: 1.5 * s
                        height: 16 * s
                        radius: 0.75 * s
                        color: root.cPink
                        anchors.verticalCenter: parent.verticalCenter
                        x: pwd.cursorRectangle.x
                        visible: pwd.focus && (pwd.text.length > 0 || pwd.wasClicked)

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: needleCursor.visible

                            NumberAnimation {
                                target: needleCursor
                                property: "opacity"
                                from: 1
                                to: 0.1
                                duration: 450
                            }

                            NumberAnimation {
                                target: needleCursor
                                property: "opacity"
                                from: 0.1
                                to: 1
                                duration: 450
                            }

                        }

                    }

                    cursorDelegate: Item {
                        width: 0
                        height: 0
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        pwd.forceActiveFocus();
                        pwd.wasClicked = true;
                    }
                }

            }

            Item {
                width: 1
                height: 12 * s
            }

            // Error
            Text {
                id: errText

                text: ""
                visible: false
                anchors.left: parent.left
                anchors.leftMargin: 4 * s
                color: root.cError
                font.family: pf.name
                font.pixelSize: 11 * s
                font.letterSpacing: 1 * s
            }

            Item {
                width: 1
                height: 8 * s
            }

            // Button
            Item {
                id: loginBtn

                property bool hovered: sbm.containsMouse

                anchors.left: parent.left
                anchors.right: parent.right
                height: 44 * s

                Rectangle {
                    anchors.fill: parent
                    radius: 14 * s

                    // Soft light top edge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 1
                        anchors.leftMargin: 1
                        anchors.rightMargin: 1
                        height: parent.height * 0.4
                        radius: 13 * s

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#30ffffff"
                            }

                            GradientStop {
                                position: 1
                                color: "transparent"
                            }

                        }

                    }

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: loginBtn.hovered ? root.cPink : root.cPinkLt
                        }

                        GradientStop {
                            position: 1
                            color: loginBtn.hovered ? root.cPinkDim : root.cPink
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }

                    }

                }

                // Shadow
                Rectangle {
                    anchors.fill: loginBtn
                    z: -1
                    radius: 14 * s
                    color: "#15b17486"
                    anchors.topMargin: 4 * s
                    anchors.leftMargin: 2 * s
                    layer.enabled: true

                    layer.effect: FastBlur {
                        radius: 12
                    }

                }

                Text {
                    anchors.centerIn: parent
                    text: "LOGIN"
                    color: loginBtn.hovered ? "#ffffff" : root.cBtnText
                    opacity: loginBtn.hovered ? 1 : 0.8
                    font.family: pf.name
                    font.pixelSize: 14 * s
                    font.letterSpacing: 3 * s
                    font.weight: Font.Medium

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                MouseArea {
                    id: sbm

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }

            }

            Item {
                width: 1
                height: 24 * s
            }

            // Divider
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1 * s
                color: root.cCreamy
            }

            Item {
                width: 1
                height: 16 * s
            }

            // Actions
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16 * s

                // Sessions
                Item {
                    id: sessBtn

                    visible: !root.isQuickshell
                    width: sessLabel.implicitWidth + 10 * s
                    height: 32 * s

                    Text {
                        id: sessLabel

                        anchors.centerIn: parent
                        text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "session").toLowerCase()
                        color: sessArea.containsMouse ? root.cPink : root.cInk
                        opacity: sessArea.containsMouse ? 1 : 0.5
                        font.family: pf.name
                        font.pixelSize: 12 * s
                        font.letterSpacing: 0.5 * s

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }

                        }

                    }

                    // Underline
                    Rectangle {
                        anchors.horizontalCenter: sessLabel.horizontalCenter
                        anchors.top: sessLabel.bottom
                        anchors.topMargin: -2 * s
                        width: sessArea.containsMouse ? sessLabel.implicitWidth : 0
                        height: 1.5 * s
                        radius: 1
                        color: root.cPink
                        opacity: sessArea.containsMouse ? 0.7 : 0

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }

                        }

                    }

                    MouseArea {
                        id: sessArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();

                        }
                    }

                }

                // Power
                Repeater {
                    model: [{
                        "l": "restart",
                        "a": 0
                    }, {
                        "l": "shut down",
                        "a": 1
                    }]

                    delegate: Item {
                        id: pmBtn

                        width: pmLabel.implicitWidth + 10 * s
                        height: 32 * s

                        Text {
                            id: pmLabel

                            anchors.centerIn: parent
                            text: modelData.l
                            color: pmArea.containsMouse ? root.cPink : root.cInk
                            opacity: pmArea.containsMouse ? 1 : 0.5
                            font.family: pf.name
                            font.pixelSize: 12 * s
                            font.letterSpacing: 0.5 * s

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }

                            }

                        }

                        // Marker Underline
                        Rectangle {
                            anchors.horizontalCenter: pmLabel.horizontalCenter
                            anchors.top: pmLabel.bottom
                            anchors.topMargin: -2 * s
                            width: pmArea.containsMouse ? pmLabel.implicitWidth : 0
                            height: 1.5 * s
                            radius: 1
                            color: root.cPink
                            opacity: pmArea.containsMouse ? 0.7 : 0

                            Behavior on width {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 250
                                }

                            }

                        }

                        MouseArea {
                            id: pmArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.a === 0) {
                                    if (typeof sddm !== "undefined")
                                        sddm.reboot();

                                } else if (modelData.a === 1) {
                                    if (typeof sddm !== "undefined")
                                        sddm.powerOff();

                                }
                            }
                        }

                    }

                }

            }

            Item {
                width: 1
                height: 6 * s
            }

        }

    }

    // Wiring
    Connections {
        function onLoginFailed() {
            errText.text = "wrong password";
            errText.visible = true;
            pwd.text = "";
            pwd.focus = true;
        }

        target: typeof sddm !== "undefined" ? sddm : null
    }

}
