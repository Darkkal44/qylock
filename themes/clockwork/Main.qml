import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

// Clockwork Theme
Rectangle {
    id: root
    readonly property real s: Screen.height / 768
    width: Screen.width
    height: Screen.height
    color: root.bgColor

    // Theme Config
    readonly property string themeMode: config.themeMode || "dark"
    readonly property bool enableWindup: config.enableWindup === "true"
    readonly property bool isLight: themeMode === "light"

    readonly property color bgColor: isLight ? "#ffffff" : "#000000"
    readonly property color mainText: isLight ? "#000000" : "#ffffff"
    readonly property color dimText: isLight ? "#666666" : "#666666"
    readonly property color subColor: isLight ? "#666666" : "#555555"
    readonly property color pillColor: isLight ? "#e8e8e8" : "#080808"
    readonly property color pillBorder: isLight ? (root.isWindup ? "#aaaaaa" : "#cccccc") : (root.isWindup ? "#444" : "#1a1a1a")
    readonly property color pillInnerLine: isLight ? (root.isWindup ? "#000000" : "#bbbbbb") : (root.isWindup ? "#ffffff" : "#222222")
    readonly property color sparkColor: isLight ? "#000000" : "#ffffff"
    readonly property color blastColor: isLight ? "#000000" : "#ffffff"
    readonly property color userItemInactive: isLight ? "#cccccc" : "#444"
    readonly property color inputWaitColor: isLight ? "#bbbbbb" : "#333333"

    // State Props
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property bool userMenuOpen: false
    property bool isWindup: false
    property real uiOpacity: 0
    readonly property real marginR: 80 * s

    // Time Engine
    property int curH: new Date().getHours()
    property int curM: new Date().getMinutes()
    property int curS: new Date().getSeconds()
    property int curMS: new Date().getMilliseconds()
    readonly property real localTimeMS: (curH * 3600000) + (curM * 60000) + (curS * 1000) + curMS

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            root.curH = d.getHours()
            root.curM = d.getMinutes()
            root.curS = d.getSeconds()
            root.curMS = d.getMilliseconds()
        }
    }

    // Blast Engine
    property real windupOffset: 0
    property real windupProgress: windupOffset / 150000
    property real boomScale: 1.0
    property real boomOpacity: 0.0
    property real jitterX: 0
    property real jitterY: 0
    property real sparkIntensity: 0.0

    Timer {
        interval: 16
        running: root.isWindup
        repeat: true
        onTriggered: {
            var intensity = root.windupProgress * 32 * s
            root.jitterX = (Math.random() - 0.5) * intensity
            root.jitterY = (Math.random() - 0.5) * intensity
            root.sparkIntensity = root.windupProgress > 0.2 ? (root.windupProgress - 0.2) * 2.2 : 0
        }
    }

    NumberAnimation {
        id: windupAnim
        target: root
        property: "windupOffset"
        from: 0
        to: 150000
        duration: 1600
        easing.type: Easing.InQuint
    }

    ParallelAnimation {
        id: boomSequence
        NumberAnimation {
            target: root
            property: "boomScale"
            to: 35.0
            duration: 150
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "boomOpacity"
            to: 1.0
            duration: 120
            easing.type: Easing.InQuad
        }
    }

    readonly property real smoothSecAngle: -((localTimeMS % 60000) / 60000.0) * 360.0 - windupOffset * 10.0
    readonly property real smoothMinAngle: -((localTimeMS % 3600000) / 3600000.0) * 360.0 - windupOffset * 5.0

    // Assets
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader {
        id: outfitFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }
    TextConstants {
        id: textConstants
    }

    // Bridges
    ListView {
        id: userHelper
        model: userModel
        currentIndex: root.userIndex
        width: 1
        height: 1
        opacity: 0
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }
    ListView {
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        width: 1
        height: 1
        opacity: 0
        delegate: Item {
            property string sName: model.name || ""
        }
    }

    // Autofocus 
    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    Component.onCompleted: {
        fadeIn.start()
    }
    NumberAnimation {
        id: fadeIn
        target: root
        property: "uiOpacity"
        to: 1
        duration: 350
        easing.type: Easing.OutCubic
    }

    // CORE CLOCKWORK
    Item {
        id: blastContainer
        anchors.fill: parent
        opacity: root.uiOpacity
        x: root.jitterX
        y: root.jitterY
        transform: Scale {
            origin.x: 400 * s
            origin.y: parent.height * 0.5
            xScale: root.boomScale
            yScale: root.boomScale
        }

        Item {
            id: clockContainer
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 800 * s
            height: parent.height
            readonly property real cx: 40 * s 
            readonly property real cy: height * 0.5
            readonly property real minR: 320 * s 
            readonly property real secR: 480 * s 

            Rectangle {
                id: indicatorPill
                z: 1
                x: clockContainer.cx + 230 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 330 * s
                height: 90 * s
                radius: 45 * s
                color: root.pillColor
                border.color: root.pillBorder
                border.width: 1 * s
                Rectangle {
                    x: 170 * s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1 * s
                    height: 35 * s
                    color: root.pillInnerLine
                }
            }

            Repeater {
                model: 60
                delegate: Rectangle {
                    z: 50
                    property real randA: Math.random() * 6.28
                    property real randV: 400 * s + Math.random() * 900 * s
                    x: (clockContainer.cx + 400 * s) + Math.cos(randA) * (randV * root.sparkIntensity)
                    y: (clockContainer.cy) + Math.sin(randA) * (randV * root.sparkIntensity)
                    width: (1 + Math.random() * 2) * s
                    height: (1 + 12 * root.sparkIntensity) * s 
                    rotation: randA * 180 / Math.PI + 90
                    radius: width / 2
                    color: root.sparkColor
                    opacity: root.sparkIntensity * (Math.random() > 0.4 ? 1.0 : 0.2)
                    visible: root.sparkIntensity > 0
                }
            }

            Repeater {
                model: 60
                delegate: Item {
                    z: 10
                    property real base: index * 6
                    property real relAngle: {
                        var a = (base + root.smoothMinAngle) % 360
                        if (a > 180) a -= 360
                        if (a < -180) a += 360
                        return a
                    }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.0)
                    property bool isMajor: index % 5 == 0
                    property real disp: (base + root.smoothMinAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.minR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.minR * Math.sin(disp)
                    visible: tx > -600 * s && tx < 1800 * s
                    Rectangle {
                        x: parent.tx - width/2
                        y: parent.ty - height/2
                        width: isMajor ? 2 * s : 1 * s
                        height: isMajor ? 18 * s : 10 * s
                        color: isLight ? Qt.rgba(0, 0, 0, spotlight > 0 ? 1.0 : (isMajor ? 0.8 : 0.6)) : Qt.rgba(1, 1, 1, spotlight > 0 ? 1.0 : (isMajor ? 0.3 : 0.15))
                        rotation: disp * 180 / Math.PI + 90
                    }
                    Text {
                        visible: isMajor
                        property real nRad: clockContainer.minR - 35 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width/2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height/2
                        text: String(index).padStart(2, '0')
                        font.family: outfitFont.name
                        font.pixelSize: 22 * s
                        font.weight: spotlight > 0.5 ? Font.Bold : Font.Normal
                        color: isLight ? Qt.rgba(0, 0, 0, spotlight > 0 ? (0.6 + 0.4 * spotlight) : 0.6) : Qt.rgba(1, 1, 1, spotlight > 0 ? (0.4 + spotlight * 0.6) : 0.25)
                        rotation: disp * 180 / Math.PI
                        transformOrigin: Item.Center
                    }
                }
            }

            Repeater {
                model: 60
                delegate: Item {
                    z: 10
                    property real base: index * 6
                    property real relAngle: {
                        var a = (base + root.smoothSecAngle) % 360
                        if (a > 180) a -= 360
                        if (a < -180) a += 360
                        return a
                    }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 4.0)
                    property bool isMajor: index % 5 == 0
                    property real disp: (base + root.smoothSecAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.secR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.secR * Math.sin(disp)
                    visible: tx > -600 * s && tx < 1800 * s
                    Rectangle {
                        x: parent.tx - width/2
                        y: parent.ty - height/2
                        width: isMajor ? 1.5 * s : 1 * s
                        height: isMajor ? 13 * s : 8 * s
                        color: isLight ? Qt.rgba(0, 0, 0, spotlight > 0 ? 1.0 : (isMajor ? 0.8 : 0.6)) : Qt.rgba(1, 1, 1, spotlight > 0 ? 1.0 : (isMajor ? 0.3 : 0.15))
                        rotation: disp * 180 / Math.PI + 90
                    }
                    Text {
                        visible: isMajor
                        property real nRad: clockContainer.secR - 30 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width/2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height/2
                        text: String(index).padStart(2, '0')
                        font.family: outfitFont.name
                        font.pixelSize: 16 * s
                        font.weight: spotlight > 0.5 ? Font.Bold : Font.Normal
                        color: isLight ? Qt.rgba(0, 0, 0, spotlight > 0 ? (0.6 + 0.4 * spotlight) : 0.6) : Qt.rgba(1, 1, 1, spotlight > 0 ? (0.4 + spotlight * 0.6) : 0.25)
                        rotation: disp * 180 / Math.PI
                        transformOrigin: Item.Center
                    }
                }
            }

            Text {
                anchors.right: indicatorPill.left
                anchors.rightMargin: 40 * s
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.curH).padStart(2, '0')
                font.family: outfitFont.name
                font.pixelSize: 110 * s
                font.weight: Font.Black
                color: root.mainText
            }
            Column {
                anchors.left: indicatorPill.right
                anchors.leftMargin: 110 * s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5 * s
                Text {
                    text: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()
                    font.family: outfitFont.name
                    font.pixelSize: 13 * s
                    font.letterSpacing: 4 * s
                    color: root.subColor
                }
                Text {
                    text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                    font.family: outfitFont.name
                    font.pixelSize: 18 * s
                    font.letterSpacing: 8 * s
                    font.weight: Font.Bold
                    color: root.mainText
                }
            }
        }
    }

    // Whiteout
    Rectangle {
        anchors.fill: parent
        color: root.blastColor
        opacity: root.boomOpacity
        z: 9999
    }

    // State HUD
    Item {
        id: hudContainer
        anchors.fill: parent
        opacity: root.uiOpacity * (root.boomOpacity > 0 ? 0 : 1)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.top: parent.top
            anchors.topMargin: 50 * s
            spacing: 25 * s
            CwAction {
                label: (sessionHelper.currentItem ? sessionHelper.currentItem.sName : "Session")
                onClicked: {
                    root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                }
            }
            Rectangle {
                width: 1 * s
                height: 10 * s
                color: root.pillBorder
                anchors.verticalCenter: parent.verticalCenter
            }
            CwAction {
                label: "Reboot"
                onClicked: {
                    sddm.reboot()
                }
            }
            Rectangle {
                width: 1 * s
                height: 10 * s
                color: root.pillBorder
                anchors.verticalCenter: parent.verticalCenter
            }
            CwAction {
                label: "Shutdown"
                onClicked: {
                    sddm.powerOff()
                }
            }
        }
        Column {
            id: loginPanel
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80 * s
            width: 350 * s
            spacing: 8 * s
            Item {
                width: parent.width
                height: 32 * s
                z: 5000
                Item {
                    id: uMenuContainer
                    anchors.bottom: userNameDisp.top
                    anchors.bottomMargin: 15 * s
                    anchors.right: parent.right
                    width: 280 * s
                    height: root.userMenuOpen ? (userModel.rowCount() * 30 * s) + 20 * s : 0
                    clip: true
                    Behavior on height {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutExpo
                        }
                    }
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        spacing: 6 * s
                        Repeater {
                            model: userModel
                            delegate: Item {
                                width: 260 * s
                                height: 26 * s
                                property bool itemHover: uItemMa.containsMouse
                                Text {
                                    id: uItemTxt
                                    text: (model.realName || model.name || "").toUpperCase()
                                    font.family: outfitFont.name
                                    font.pixelSize: 13 * s
                                    font.letterSpacing: 2 * s
                                    color: (root.userIndex === index || itemHover) ? root.mainText : root.userItemInactive
                                    anchors.right: parent.right
                                    anchors.rightMargin: itemHover ? 30 * s : 10 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on anchors.rightMargin {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Text {
                                    text: "✦"
                                    anchors.left: uItemTxt.right
                                    anchors.leftMargin: 8 * s
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.mainText
                                    opacity: itemHover ? 1.0 : 0
                                    font.pixelSize: 10 * s
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                MouseArea {
                                    id: uItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.userIndex = index
                                        root.userMenuOpen = false
                                    }
                                }
                            }
                        }
                    }
                }
                Text {
                    id: userNameDisp
                    anchors.right: parent.right
                    anchors.rightMargin: (uMa.containsMouse || root.userMenuOpen) ? 25 * s : 0
                    text: (userHelper.currentItem ? userHelper.currentItem.uName : (userModel.lastUser ? capitalizeFirst(userModel.lastUser) : "ACHLYS")).toUpperCase()
                    font.family: outfitFont.name
                    font.pixelSize: 18 * s
                    font.weight: Font.Bold
                    font.letterSpacing: 8 * s
                    color: (uMa.containsMouse || root.userMenuOpen) ? root.mainText : root.dimText
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Text {
                    text: "✦"
                    anchors.left: userNameDisp.right
                    anchors.leftMargin: 8 * s
                    anchors.verticalCenter: userNameDisp.verticalCenter
                    color: root.mainText
                    opacity: (uMa.containsMouse || root.userMenuOpen) ? 1.0 : 0
                    font.pixelSize: 12 * s
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
                MouseArea {
                    id: uMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.userMenuOpen = !root.userMenuOpen
                    }
                }
            }
            Item {
                width: parent.width
                height: 30 * s
                TextInput {
                    id: passInput
                    anchors.fill: parent
                    echoMode: TextInput.Password
                    passwordCharacter: "✦"
                    color: root.dimText
                    font.family: outfitFont.name
                    font.pixelSize: 14 * s
                    font.letterSpacing: 10 * s
                    horizontalAlignment: TextInput.AlignRight
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    property bool wasClicked: false
                    cursorVisible: false
                    cursorDelegate: Item { width: 0; height: 0 }
                    Keys.onReturnPressed: {
                        startLoginSequence()
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WAITING FOR KEY"
                        font.family: outfitFont.name
                        font.pixelSize: 10 * s
                        font.letterSpacing: 4 * s
                        color: root.inputWaitColor
                        
                        opacity: passInput.text.length === 0 ? 0.4 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                    Rectangle {
                        id: needleCursor
                        width: 1.5 * s
                        height: 12 * s
                        color: root.mainText
                        anchors.verticalCenter: parent.verticalCenter
                        x: passInput.cursorRectangle.x
                        visible: passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: needleCursor.visible
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 1; to: 0.1; duration: 450 }
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 0.1; to: 1; duration: 450 }
                        }
                    }
                }
                MouseArea {
                    id: pMa_FixedFinal_Simple
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        passInput.forceActiveFocus()
                        passInput.wasClicked = true
                    }
                }
            }
            Item {
                width: parent.width
                height: 40 * s
                Text {
                    id: loginBtn
                    anchors.right: parent.right
                    anchors.rightMargin: btnMa.containsMouse ? 25 * s : 0
                    text: "ENTER KEY"
                    font.family: outfitFont.name
                    font.pixelSize: 11 * s
                    font.letterSpacing: 4 * s
                    font.weight: Font.Bold
                    color: passInput.text.length > 0 ? (btnMa.containsMouse ? root.mainText : root.dimText) : "transparent"
                    opacity: passInput.text.length > 0 ? 1.0 : 0
                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Text {
                    text: "✦"
                    anchors.left: loginBtn.right
                    anchors.leftMargin: 8 * s
                    anchors.verticalCenter: loginBtn.verticalCenter
                    color: root.mainText
                    opacity: (btnMa.containsMouse && passInput.text.length > 0) ? 1.0 : 0
                    font.pixelSize: 10 * s
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
                MouseArea {
                    id: btnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        startLoginSequence()
                    }
                }
            }
            Text {
                id: errText
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: ""
                color: "#ff4444"
                font.family: outfitFont.name
                font.pixelSize: 10 * s
                font.letterSpacing: 2 * s
            }
        }
    }

    Timer {
        id: boomTriggerTimer
        interval: 1450
        onTriggered: {
            boomSequence.start()
        }
    }
    Timer {
        id: loginCommitTimer
        interval: 1600
        onTriggered: {
            doLogin()
        }
    }
    function startLoginSequence() {
        if (passInput.text.length === 0) return
        if (root.enableWindup) {
            isWindup = true
            windupAnim.start()
            boomTriggerTimer.start()
            loginCommitTimer.start()
        } else {
            doLogin()
        }
    }
    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(uname, passInput.text, root.sessionIndex)
    }
    function capitalizeFirst(str) {
        if (!str) return ""
        return str.charAt(0).toUpperCase() + str.slice(1)
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            isWindup = false
            windupAnim.stop()
            boomTriggerTimer.stop()
            loginCommitTimer.stop()
            root.windupOffset = 0
            root.boomScale = 1.0
            root.boomOpacity = 0.0
            root.sparkIntensity = 0
            errText.text = "ACCESS DENIED"
            passInput.text = ""
            passInput.forceActiveFocus()
            shake.start()
        }
    }
    SequentialAnimation {
        id: shake
        NumberAnimation {
            target: loginPanel
            property: "anchors.rightMargin"
            from: root.marginR
            to: root.marginR + 10 * s
            duration: 50
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: loginPanel
            property: "anchors.rightMargin"
            to: root.marginR - 10 * s
            duration: 50
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: loginPanel
            property: "anchors.rightMargin"
            to: root.marginR
            duration: 50
            easing.type: Easing.InOutSine
        }
    }
    component CwAction: Item {
        id: actItem
        width: actTxt.width + 20 * s
        height: 15 * s
        property string label: ""
        signal clicked()
        Text {
            id: actTxt
            anchors.right: parent.right
            anchors.rightMargin: actM.containsMouse ? 15 * s : 0
            text: label.toUpperCase()
            color: actM.containsMouse ? root.mainText : root.dimText
            font.family: outfitFont.name
            font.pixelSize: 10 * s
            font.letterSpacing: 3 * s
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
            Behavior on anchors.rightMargin {
                NumberAnimation {
                    duration: 200
                }
            }
        }
        Text {
            text: "✦"
            anchors.left: actTxt.right
            anchors.leftMargin: 4 * s
            anchors.verticalCenter: actTxt.verticalCenter
            color: root.mainText
            opacity: actM.containsMouse ? 1.0 : 0
            font.pixelSize: 8 * s
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }
        MouseArea {
            id: actM
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                actItem.clicked()
            }
            cursorShape: Qt.PointingHandCursor
        }
    }
}
