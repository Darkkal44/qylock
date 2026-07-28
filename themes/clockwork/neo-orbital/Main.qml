// SDDM Theme
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    id: root
    readonly property real s: Screen.height / 768
    width: Screen.width
    height: Screen.height
    color: "#faf0e6"

    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    // Colors
    readonly property color mainText: "#231c1a"
    readonly property color dimText: "#6a5a54"
    readonly property color outlineColor: "#161110"
    readonly property color pillBg: "#faf0e6"
    readonly property color peachAccent: "#ffb3a1"
    readonly property color greenAccent: "#c5e1a5"
    readonly property color lavenderAccent: "#e1bee7"
    readonly property color roseAccent: "#ffcbd5"

    // State
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real uiOpacity: 0
    readonly property real marginR: 80 * s

    // Time Engine
    property int curH: new Date().getHours()
    property int curM: new Date().getMinutes()
    property int curS: new Date().getSeconds()
    property int curMS: new Date().getMilliseconds()
    readonly property real localTimeMS: (curH * 3600000) + (curM * 60000) + (curS * 1000) + curMS

    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            var d = new Date()
            root.curH = d.getHours(); root.curM = d.getMinutes(); root.curS = d.getSeconds(); root.curMS = d.getMilliseconds()
        }
    }

    readonly property real smoothSecAngle: -((localTimeMS % 60000) / 60000.0) * 360.0
    readonly property real smoothMinAngle: -((localTimeMS % 3600000) / 3600000.0) * 360.0

    // Fonts
    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: outfitFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    TextConstants { id: textConstants }

    // Helpers
    ListView {
        id: userHelper; width: 1; height: 1; opacity: 0; currentIndex: root.userIndex
        model: typeof userModel !== "undefined" ? userModel : null
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }
    ListView {
        id: sessionHelper; width: 1; height: 1; opacity: 0; currentIndex: root.sessionIndex
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        delegate: Item { property string sName: model.name || "" }
    }

    // Logic
    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }
    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "uiOpacity"; from: 0; to: 1; duration: 1200; easing.type: Easing.OutCubic }

    // Background Image
    Image {
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.uiOpacity
    }

    // Layout Container
    Item {
        id: blastContainer
        anchors.fill: parent
        opacity: root.uiOpacity

        // Clock Section
        Item {
            id: clockContainer
            anchors.left: parent.left; anchors.leftMargin: 20 * s
            anchors.verticalCenter: parent.verticalCenter
            width: 700 * s; height: parent.height

            readonly property real cx: 0 * s 
            readonly property real cy: height * 0.5
            readonly property real minR: 270 * s 
            readonly property real secR: 420 * s 

            // Hour Box
            Item {
                id: hourBox
                x: 10 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 150 * s; height: 120 * s
                z: 100

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4 * s; anchors.leftMargin: 4 * s; anchors.bottomMargin: -4 * s; anchors.rightMargin: -4 * s
                    radius: 20 * s; color: root.outlineColor
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 20 * s; color: root.peachAccent
                    border.color: root.outlineColor; border.width: 2.5 * s

                    Text {
                        anchors.centerIn: parent
                        text: String(root.curH).padStart(2, '0')
                        font.family: outfitFont.name; font.pixelSize: 76 * s; font.weight: Font.Black
                        color: root.mainText
                    }
                }
            }

// Indicator Pill
            Item {
                id: indicatorPill; z: 10
                x: hourBox.x + hourBox.width + 24 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 260 * s; height: 76 * s

                // Glass Lens
                Rectangle {
                    anchors.fill: parent
                    radius: 38 * s
                    color: "#35faf0e6"
                    border.color: root.outlineColor
                    border.width: 2.5 * s

                    // Center Line
                    Rectangle {
                        x: 129 * s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2 * s; height: 32 * s
                        color: root.outlineColor
                        opacity: 0.35
                    }
                }
            }

            // Minute Ring
            Repeater {
                model: 60
                delegate: Item {
                    z: 10; property real base: index * 6
                    property real relAngle: { var a = (base + root.smoothMinAngle) % 360; if (a > 180) a -= 360; if (a < -180) a += 360; return a }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.0)
                    property bool isMajor: index % 5 == 0
                    property real disp: (base + root.smoothMinAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.minR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.minR * Math.sin(disp)
                    visible: tx > -600 * s && tx < 1800 * s

                    Rectangle {
                        x: parent.tx - width/2; y: parent.ty - height/2; width: isMajor ? 2.5 * s : 1.2 * s; height: isMajor ? 18 * s : 10 * s
                        color: root.outlineColor
                        rotation: disp * 180 / Math.PI + 90
                        antialiasing: true
                        transformOrigin: Item.Center
                    }
                    Text {
                        visible: isMajor; property real nRad: clockContainer.minR - 32 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width/2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height/2
                        text: String(index).padStart(2, '0'); font.family: outfitFont.name; font.pixelSize: 18 * s; font.weight: Font.Bold
                        color: root.mainText
                        rotation: disp * 180 / Math.PI; transformOrigin: Item.Center
                        antialiasing: true
                    }
                }
            }

            // Second Ring
            Repeater {
                model: 60
                delegate: Item {
                    z: 10; property real base: index * 6
                    property real relAngle: { var a = (base + root.smoothSecAngle) % 360; if (a > 180) a -= 360; if (a < -180) a += 360; return a }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.0)
                    property bool isMajor: index % 5 == 0
                    property real disp: (base + root.smoothSecAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.secR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.secR * Math.sin(disp)
                    visible: tx > -600 * s && tx < 1800 * s

                    Rectangle {
                        x: parent.tx - width/2; y: parent.ty - height/2; width: isMajor ? 2.0 * s : 1.0 * s; height: isMajor ? 14 * s : 8 * s
                        color: root.outlineColor
                        rotation: disp * 180 / Math.PI + 90
                        antialiasing: true
                        transformOrigin: Item.Center
                    }
                    Text {
                        visible: isMajor; property real nRad: clockContainer.secR - 28 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width/2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height/2
                        text: String(index).padStart(2, '0'); font.family: outfitFont.name; font.pixelSize: 14 * s; font.weight: Font.Bold
                        color: root.mainText
                        rotation: disp * 180 / Math.PI; transformOrigin: Item.Center
                        antialiasing: true
                    }
                }
            }

            // Date & Day Column
            Column {
                anchors.left: indicatorPill.right; anchors.leftMargin: 35 * s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * s

                Item {
                    width: 190 * s; height: 38 * s

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2.5 * s; anchors.leftMargin: 2.5 * s; anchors.bottomMargin: -2.5 * s; anchors.rightMargin: -2.5 * s
                        radius: 8 * s; color: root.outlineColor
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8 * s; color: root.greenAccent
                        border.color: root.outlineColor; border.width: 1.5 * s

                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()
                            font.family: outfitFont.name; font.pixelSize: 12 * s; font.letterSpacing: 2 * s; font.weight: Font.Bold
                            color: root.mainText
                        }
                    }
                }

                Item {
                    width: 190 * s; height: 42 * s

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2.5 * s; anchors.leftMargin: 2.5 * s; anchors.bottomMargin: -2.5 * s; anchors.rightMargin: -2.5 * s
                        radius: 8 * s; color: root.outlineColor
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8 * s; color: root.lavenderAccent
                        border.color: root.outlineColor; border.width: 1.5 * s

                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                            font.family: outfitFont.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s; font.weight: Font.Bold
                            color: root.mainText
                        }
                    }
                }
            }
        }
    }

    // HUD Actions
    Item {
        id: hudContainer; anchors.fill: parent; opacity: root.uiOpacity
        Row {
            anchors.right: parent.right; anchors.rightMargin: root.marginR; anchors.top: parent.top; anchors.topMargin: 40 * s; spacing: 14 * s

            CwAction {
                label: (sessionHelper.currentItem ? sessionHelper.currentItem.sName : "Session")
                bgColor: root.lavenderAccent
                onClicked: { if (typeof sessionModel !== "undefined") root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
            }

            CwAction {
                label: "Reboot"
                bgColor: root.peachAccent
                onClicked: { if (typeof sddm !== "undefined") sddm.reboot() }
            }

            CwAction {
                label: "Shutdown"
                bgColor: root.roseAccent
                onClicked: { if (typeof sddm !== "undefined") sddm.powerOff() }
            }
        }

        // Login Panel
        Column {
            id: loginPanel; anchors.right: parent.right; anchors.rightMargin: root.marginR; anchors.bottom: parent.bottom; anchors.bottomMargin: 80 * s; width: 320 * s; spacing: 12 * s

            // Username Button (Click Cycles Users)
            Item {
                width: parent.width; height: 46 * s; z: 5000

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3 * s; anchors.leftMargin: 3 * s; anchors.bottomMargin: -3 * s; anchors.rightMargin: -3 * s
                    radius: 12 * s; color: root.outlineColor
                }

                Rectangle {
                    anchors.fill: parent; radius: 12 * s
                    color: uMa.containsMouse ? root.peachAccent : "#f5ebe6"
                    border.color: root.outlineColor; border.width: 2.0 * s

                    transform: Translate {
                        x: uMa.pressed ? 3 * s : (uMa.containsMouse ? -2 * s : 0)
                        y: uMa.pressed ? 3 * s : (uMa.containsMouse ? -2 * s : 0)
                        Behavior on x { NumberAnimation { duration: 100 } }
                        Behavior on y { NumberAnimation { duration: 100 } }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10 * s; anchors.rightMargin: 12 * s
                        spacing: 10 * s

                        // User Socket
                        Item {
                            width: 32 * s; height: 32 * s
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 2 * s; anchors.leftMargin: 2 * s; anchors.bottomMargin: -2 * s; anchors.rightMargin: -2 * s
                                radius: 8 * s; color: root.outlineColor
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8 * s; color: root.greenAccent
                                border.color: root.outlineColor; border.width: 1.5 * s

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰨞"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16 * s; font.weight: Font.Bold
                                    color: root.mainText
                                }
                            }
                        }

                        Text {
                            width: parent.width - 70 * s
                            text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : ((typeof userModel !== "undefined" && userModel.lastUser) ? capitalizeFirst(userModel.lastUser) : "USER")).toUpperCase()
                            font.family: outfitFont.name; font.pixelSize: 12 * s; font.weight: Font.Bold; font.letterSpacing: 2 * s
                            color: root.mainText; anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅀"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12 * s; font.weight: Font.Bold
                            color: root.mainText; anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: uMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof userModel !== "undefined" && userModel.rowCount() > 0) {
                                root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                            }
                        }
                    }
                }
            }

            // Password Field
            Item {
                width: parent.width; height: 48 * s

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3 * s; anchors.leftMargin: 3 * s; anchors.bottomMargin: -3 * s; anchors.rightMargin: -3 * s
                    radius: 12 * s; color: root.outlineColor
                }

                Rectangle {
                    anchors.fill: parent; radius: 12 * s
                    color: errText.text !== "" ? root.roseAccent : "#faf0e6"
                    border.color: errText.text !== "" ? "#ff4444" : root.outlineColor
                    border.width: 2.0 * s

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10 * s; anchors.rightMargin: 12 * s
                        spacing: 12 * s

                        // Lock Socket
                        Item {
                            width: 32 * s; height: 32 * s
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 2 * s; anchors.leftMargin: 2 * s; anchors.bottomMargin: -2 * s; anchors.rightMargin: -2 * s
                                radius: 8 * s; color: root.outlineColor
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8 * s
                                color: errText.text !== "" ? root.roseAccent : root.lavenderAccent
                                border.color: root.outlineColor; border.width: 1.5 * s

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌆"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16 * s; font.weight: Font.Bold
                                    color: root.mainText
                                }
                            }
                        }

                        // Input Container
                        Item {
                            width: parent.width - 54 * s
                            height: parent.height
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true

                            TextInput {
                                id: passInput
                                anchors.fill: parent
                                echoMode: TextInput.NoEcho
                                color: "transparent"
                                focus: true
                                cursorVisible: false
                                cursorDelegate: Item { width: 0; height: 0 }

                                Keys.onReturnPressed: doLogin()
                            }

                            // Placeholder
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 2 * s
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Enter Password..."
                                font.family: outfitFont.name
                                font.pixelSize: 11 * s
                                font.letterSpacing: 1 * s
                                color: root.dimText
                                visible: passInput.text.length === 0
                            }

                            // Neobrutalist Keycaps
                            Row {
                                id: dotsRow
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 2 * s
                                spacing: 6 * s
                                visible: passInput.text.length > 0

                                Repeater {
                                    model: passInput.text.length
                                    delegate: Rectangle {
                                        width: 10 * s; height: 10 * s
                                        radius: 3 * s
                                        color: root.peachAccent
                                        border.color: root.outlineColor
                                        border.width: 1.5 * s
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Rectangle {
                                    width: 2 * s; height: 14 * s
                                    color: root.mainText
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: passInput.activeFocus

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: passInput.activeFocus
                                        NumberAnimation { from: 1.0; to: 0.1; duration: 450 }
                                        NumberAnimation { from: 0.1; to: 1.0; duration: 450 }
                                    }
                                }
                            }

                            // Empty Cursor
                            Rectangle {
                                width: 2 * s; height: 14 * s
                                color: root.mainText
                                anchors.left: parent.left
                                anchors.leftMargin: 2 * s
                                anchors.verticalCenter: parent.verticalCenter
                                visible: passInput.activeFocus && passInput.text.length === 0

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: passInput.activeFocus && passInput.text.length === 0
                                    NumberAnimation { from: 1.0; to: 0.1; duration: 450 }
                                    NumberAnimation { from: 0.1; to: 1.0; duration: 450 }
                                }
                            }
                        }
                    }
                }
            }

            // Submit Button
            Item {
                width: parent.width; height: 44 * s

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3 * s; anchors.leftMargin: 3 * s; anchors.bottomMargin: -3 * s; anchors.rightMargin: -3 * s
                    radius: 12 * s; color: root.outlineColor
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12 * s
                    color: btnMa.containsMouse ? "#ff9e85" : root.peachAccent
                    border.color: root.outlineColor; border.width: 2.0 * s

                    transform: Translate {
                        x: btnMa.pressed ? 3 * s : (btnMa.containsMouse ? -2 * s : 0)
                        y: btnMa.pressed ? 3 * s : (btnMa.containsMouse ? -2 * s : 0)
                        Behavior on x { NumberAnimation { duration: 100 } }
                        Behavior on y { NumberAnimation { duration: 100 } }
                    }

                    Row {
                        anchors.centerIn: parent; spacing: 8 * s
                        Text { text: "󰍁"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 * s; font.weight: Font.Bold; color: root.mainText; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "LOGIN"; font.family: outfitFont.name; font.pixelSize: 12 * s; font.weight: Font.Bold; font.letterSpacing: 2 * s; color: root.mainText; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea { id: btnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
                }
            }

            Text { id: errText; width: parent.width; height: 16 * s; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; text: ""; color: "#ff4444"; font.family: outfitFont.name; font.pixelSize: 11 * s; font.weight: Font.Bold; font.letterSpacing: 1 * s }
        }
    }

    // SDDM Connections
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            errText.text = "ACCESS DENIED";
            passInput.text = "";
            passInput.forceActiveFocus();
            shake.start();
        }
    }

    function doLogin() {
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "");
        if (typeof sddm !== "undefined") sddm.login(u, passInput.text, root.sessionIndex);
    }

    function capitalizeFirst(str) { if (!str) return ""; return str.charAt(0).toUpperCase() + str.slice(1) }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; from: root.marginR; to: root.marginR + 10 * s; duration: 50; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR - 10 * s; duration: 50; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR; duration: 50; easing.type: Easing.InOutSine }
    }

    // Action Component
    component CwAction: Item {
        id: actItem
        width: actTxt.implicitWidth + 32 * s
        height: 36 * s
        property string label: ""
        property color bgColor: root.peachAccent
        signal clicked()

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2.5 * s; anchors.leftMargin: 2.5 * s; anchors.bottomMargin: -2.5 * s; anchors.rightMargin: -2.5 * s
            radius: 8 * s; color: root.outlineColor
        }

        Rectangle {
            id: actPlate
            anchors.fill: parent
            radius: 8 * s
            color: actM.containsMouse ? root.peachAccent : bgColor
            border.color: root.outlineColor; border.width: 1.5 * s

            transform: Translate {
                x: actM.pressed ? 2.5 * s : (actM.containsMouse ? -1.5 * s : 0)
                y: actM.pressed ? 2.5 * s : (actM.containsMouse ? -1.5 * s : 0)
                Behavior on x { NumberAnimation { duration: 80 } }
                Behavior on y { NumberAnimation { duration: 80 } }
            }

            Text {
                id: actTxt; anchors.centerIn: parent
                text: label.toUpperCase(); color: root.mainText
                font.family: outfitFont.name; font.pixelSize: 11 * s; font.weight: Font.Bold; font.letterSpacing: 2 * s
            }

            MouseArea { id: actM; anchors.fill: parent; hoverEnabled: true; onClicked: actItem.clicked(); cursorShape: Qt.PointingHandCursor }
        }
    }
}
