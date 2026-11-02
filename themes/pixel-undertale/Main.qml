import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    // Wayland Cursor Fix & Global Refocus on background click
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: {
            root.boxState = "normal"
            root.activeMenuRow = 1
            pwd.forceActiveFocus()
        }
    }
    
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "black"
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0

    // Undertale Theme Properties
    property var hoveredButton: null
    property int activeMenuRow: 1 // 0: User, 1: Password, 2: Session
    property int maxHP: 99
    property int currentHP: 99
    property string boxState: "normal" // "normal" or "mercy"
    
    property var buttonHoverTexts: [
        "* ready to fight?",
        "* preparing an action?",
        "* check your inventory.",
        "* show some mercy?"
    ]
    
    property var failedQuotes: [
        "* that all you got?",
        "* guess you're not ready.",
        "* you're gonna have a bad time.",
        "* wrong. try again.",
        "* look, i'm not even moving.",
        "* maybe check caps lock?"
    ]
    property int failedCount: 0

    onBoxStateChanged: {
        if (boxState === "mercy") {
            pwd.focus = false
            activeMenuRow = 0
        }
    }

    // Global keyboard navigation
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Up) {
            if (root.boxState === "normal") {
                root.activeMenuRow = (root.activeMenuRow - 1 + 3) % 3
                if (root.activeMenuRow === 1) pwd.forceActiveFocus()
                else root.forceActiveFocus()
            } else {
                root.activeMenuRow = (root.activeMenuRow - 1 + 3) % 3
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            if (root.boxState === "normal") {
                root.activeMenuRow = (root.activeMenuRow + 1) % 3
                if (root.activeMenuRow === 1) pwd.forceActiveFocus()
                else root.forceActiveFocus()
            } else {
                root.activeMenuRow = (root.activeMenuRow + 1) % 3
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            triggerActiveSelection()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            if (root.boxState === "mercy") {
                root.boxState = "normal"
                root.activeMenuRow = 1
                pwd.forceActiveFocus()
            }
            event.accepted = true
        } else {
            // Typing redirect: if not focused on password input and typing text, redirect it
            if (!pwd.activeFocus && event.text.length > 0 && event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab) {
                root.boxState = "normal"
                root.activeMenuRow = 1
                pwd.forceActiveFocus()
                pwd.text += event.text
                event.accepted = true
            }
        }
    }

    FontLoader { id: pf; source: "font/MonsterFriendBack.otf" }
    FontLoader { id: quoteFont; source: "font/Sans-UT-Battle.ttf" }
    
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100
        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }
    }
    
    // Auto-focus fix
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: { 
        fadeAnim.start()
        if (typeof keyboard !== "undefined") {
            keyboard.numLock = true
        }
        showSansDialogue("* hey.\n* ready to log in?", 4000)
    }
    
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 2000; easing.type: Easing.InOutQuad }

    // Screen Shake Animation for login failure damage
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: rootContent; property: "x"; from: 0; to: -15 * s; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: rootContent; property: "x"; from: -15 * s; to: 15 * s; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: rootContent; property: "x"; from: 15 * s; to: -10 * s; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: rootContent; property: "x"; from: -10 * s; to: 10 * s; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: rootContent; property: "x"; from: 10 * s; to: -5 * s; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: rootContent; property: "x"; from: -5 * s; to: 5 * s; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: rootContent; property: "x"; from: 5 * s; to: 0; duration: 40; easing.type: Easing.InQuad }
    }

    // Stars Background
    Repeater {
        model: 45
        delegate: Rectangle {
            id: star
            width: (2 + Math.floor(Math.random() * 3)) * s
            height: width
            color: "white"
            opacity: 0.1 + Math.random() * 0.7
            x: Math.random() * root.width
            y: Math.random() * root.height
            
            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: Math.random() * 5000 }
                NumberAnimation { target: star; property: "opacity"; to: 0.1; duration: 1500 }
                NumberAnimation { target: star; property: "opacity"; to: 0.8; duration: 1500 }
            }
            
            NumberAnimation on y {
                from: root.height + 10
                to: -10
                duration: 18000 + Math.random() * 12000
                loops: Animation.Infinite
            }
        }
    }

    Item {
        id: rootContent
        anchors.fill: parent
        opacity: root.ui

        // Top Left Info HUD
        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 40 * s
            text: "SYSTEM: " + (typeof sddm !== "undefined" ? sddm.hostName.toUpperCase() : "QYLOCK")
            color: "#8498ab"
            font.family: pf.name
            font.pixelSize: 12 * s
            font.letterSpacing: 2 * s
        }

        // Top Right Clock HUD
        Text {
            id: clockText
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 40 * s
            text: Qt.formatDate(new Date(), "ddd, MMM d").toUpperCase() + "  " + Qt.formatTime(new Date(), "HH:mm")
            color: "#8498ab"
            font.family: pf.name
            font.pixelSize: 12 * s
            font.letterSpacing: 2 * s
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatDate(new Date(), "ddd, MMM d").toUpperCase() + "  " + Qt.formatTime(new Date(), "HH:mm") }
        }

        // Sans Character Sprite Area
        Item {
            id: monsterArea
            width: 250 * s
            height: 250 * s
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 60 * s
            
            Image {
                id: sansSprite
                source: "sans.png"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: false
                
                // Swaying & Breathing animation
                SequentialAnimation on anchors.horizontalCenterOffset {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 8 * s; duration: 1200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -8 * s; duration: 1200; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on anchors.verticalCenterOffset {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 4 * s; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 600; easing.type: Easing.InOutSine }
                }
            }
        }

        // Speech Bubble next to Sans
        Item {
            id: speechBubble
            x: (root.width - 250 * s) / 2 + 205 * s
            y: 60 * s + 30 * s
            width: 180 * s
            height: 90 * s
            opacity: 0
            visible: opacity > 0
            
            Rectangle {
                anchors.fill: parent
                color: "white"
                border.color: "black"
                border.width: 3 * s
                radius: 12 * s
                
                Text {
                    id: bubbleText
                    anchors.fill: parent
                    anchors.margins: 12 * s
                    text: ""
                    color: "black"
                    font.family: quoteFont.name
                    font.pixelSize: 13 * s
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }
            }
            
            // Pointer pointing to Sans
            Rectangle {
                width: 14 * s
                height: 14 * s
                color: "white"
                border.color: "black"
                border.width: 3 * s
                rotation: 45
                x: -7 * s
                y: 35 * s
                z: -1
                
                Rectangle {
                    width: 12 * s
                    height: 12 * s
                    color: "white"
                    x: 2 * s
                    y: 2 * s
                }
            }
            
            // Cover outline
            Rectangle {
                width: 10 * s
                height: 20 * s
                color: "white"
                x: 1 * s
                y: 32 * s
                z: 1
            }
            
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        // Dialogue Box
        Rectangle {
            id: dialogueBox
            width: 580 * s
            height: 160 * s
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: monsterArea.bottom
            anchors.topMargin: 20 * s
            color: "black"
            border.color: "white"
            border.width: 5 * s
            
            Item {
                anchors.fill: parent
                anchors.margins: 20 * s
                
                // Normal User / Pass / Session Menu
                Column {
                    visible: root.boxState === "normal"
                    anchors.fill: parent
                    spacing: 12 * s
                    
                    // User selection row
                    Item {
                        width: parent.width
                        height: 20 * s
                        
                        Row {
                            spacing: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Item { width: 30 * s; height: 1 } 
                            
                            Text {
                                text: "* USER:"
                                color: "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                            
                            Text {
                                text: (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName.toUpperCase() : "USER"
                                color: (root.activeMenuRow === 0 && !pwd.activeFocus) ? "#f3ee32" : "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: { root.activeMenuRow = 0; pwd.focus = false; root.forceActiveFocus() }
                            onClicked: { cycleUser() }
                        }
                    }
                    
                    // Password input row
                    Item {
                        width: parent.width
                        height: 20 * s
                        
                        Row {
                            spacing: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Item { width: 30 * s; height: 1 }
                            
                            Text {
                                text: "* PASS:"
                                color: "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                            
                            Item {
                                width: 300 * s
                                height: 20 * s
                                
                                TextInput {
                                    id: pwd
                                    anchors.fill: parent
                                    color: (pwd.activeFocus) ? "#f3ee32" : "white"
                                    font.family: pf.name
                                    font.pixelSize: 16 * s
                                    echoMode: TextInput.Password
                                    passwordCharacter: "*"
                                    onTextEdited: err.text = ""
                                    focus: true
                                    clip: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    cursorVisible: false
                                    selectionColor: "#555"
                                    
                                    Keys.onUpPressed: { root.activeMenuRow = 0; root.forceActiveFocus() }
                                    Keys.onDownPressed: { root.activeMenuRow = 2; root.forceActiveFocus() }
                                    Keys.onReturnPressed: triggerActiveSelection()
                                    Keys.onEnterPressed: triggerActiveSelection()
                                }
                                
                                Text {
                                    anchors.fill: parent
                                    text: "enter password..."
                                    color: "#555"
                                    font.family: pf.name
                                    font.pixelSize: 16 * s
                                    verticalAlignment: TextInput.AlignVCenter
                                    opacity: pwd.text.length === 0 ? 0.6 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                                
                                Rectangle {
                                    id: customCursor
                                    width: 10 * s
                                    height: 2 * s
                                    color: "white"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2 * s
                                    x: pwd.cursorRectangle.x
                                    visible: pwd.focus
                                    
                                    SequentialAnimation {
                                        loops: Animation.Infinite; running: customCursor.visible
                                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0; duration: 400 }
                                        NumberAnimation { target: customCursor; property: "opacity"; from: 0; to: 1; duration: 400 }
                                    }
                                }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: { root.activeMenuRow = 1; pwd.forceActiveFocus() }
                            onClicked: pwd.forceActiveFocus()
                        }
                    }
                    
                    // Session Selection Row
                    Item {
                        width: parent.width
                        height: 20 * s
                        
                        Row {
                            spacing: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Item { width: 30 * s; height: 1 }
                            
                            Text {
                                text: "* SESSION:"
                                color: "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                            
                            Text {
                                text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "Session").toUpperCase()
                                color: (root.activeMenuRow === 2 && !pwd.activeFocus) ? "#f3ee32" : "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: { root.activeMenuRow = 2; pwd.focus = false; root.forceActiveFocus() }
                            onClicked: { cycleSession() }
                        }
                    }
                }
                
                // Mercy Power / Options Menu
                Column {
                    visible: root.boxState === "mercy"
                    anchors.fill: parent
                    spacing: 12 * s
                    
                    // Spare (Reboot) row
                    Item {
                        width: parent.width
                        height: 20 * s
                        
                        Row {
                            spacing: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Item { width: 30 * s; height: 1 }
                            Text {
                                text: "* SPARE (REBOOT)"
                                color: (root.activeMenuRow === 0) ? "#f3ee32" : "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.activeMenuRow = 0
                            onClicked: {
                                if (typeof sddm !== "undefined") sddm.reboot()
                            }
                        }
                    }
                    
                    // Flee (Shut down) row
                    Item {
                        width: parent.width
                        height: 20 * s
                        
                        Row {
                            spacing: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Item { width: 30 * s; height: 1 }
                            Text {
                                text: "* FLEE (SHUT DOWN)"
                                color: (root.activeMenuRow === 1) ? "#f3ee32" : "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.activeMenuRow = 1
                            onClicked: {
                                if (typeof sddm !== "undefined") sddm.powerOff()
                            }
                        }
                    }
                    
                    // Back row
                    Item {
                        width: parent.width
                        height: 20 * s
                        
                        Row {
                            spacing: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Item { width: 30 * s; height: 1 }
                            Text {
                                text: "* BACK"
                                color: (root.activeMenuRow === 2) ? "#f3ee32" : "white"
                                font.family: pf.name
                                font.pixelSize: 16 * s
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.activeMenuRow = 2
                            onClicked: {
                                root.boxState = "normal"
                                root.activeMenuRow = 1
                                pwd.forceActiveFocus()
                            }
                        }
                    }
                }
                
                // Login Failure Text (Access Denied)
                Text {
                    id: err
                    text: ""
                    color: "#ff0000"
                    font.family: pf.name
                    font.pixelSize: 12 * s
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10 * s
                }
            }
        }

        // Stats HUD Row
        Item {
            id: statsRow
            width: 580 * s
            height: 30 * s
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dialogueBox.bottom
            anchors.topMargin: 15 * s
            
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16 * s
                
                Text {
                    text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "USER").toUpperCase()
                    color: "white"
                    font.family: pf.name
                    font.pixelSize: 18 * s
                }
                
                Text {
                    text: "LV 99"
                    color: "white"
                    font.family: pf.name
                    font.pixelSize: 18 * s
                }
                
                Text {
                    text: "HP"
                    color: "#f3ee32"
                    font.family: pf.name
                    font.pixelSize: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Rectangle {
                    width: 100 * s
                    height: 18 * s
                    color: "#ff0000"
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Rectangle {
                        width: parent.width * (root.currentHP / root.maxHP)
                        height: parent.height
                        color: "#f3ee32"
                    }
                }
                
                Text {
                    text: root.currentHP + " / " + root.maxHP
                    color: "white"
                    font.family: pf.name
                    font.pixelSize: 18 * s
                }
            }
            
            // Damage popup text
            Text {
                id: damageText
                color: "#ff0000"
                font.family: pf.name
                font.pixelSize: 24 * s
                text: ""
                opacity: 0
                z: 200
                x: 350 * s
                
                NumberAnimation on y {
                    id: damageFloat
                    from: -10 * s
                    to: -50 * s
                    duration: 1000
                    running: false
                }
                NumberAnimation on opacity {
                    id: damageFade
                    from: 1.0
                    to: 0
                    duration: 1000
                    running: false
                }
            }
        }

        // Battle Buttons Row (FIGHT, ACT, ITEM, MERCY)
        Row {
            id: buttonsRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60 * s
            spacing: 30 * s
            
            Repeater {
                model: [
                    { idName: "fight", label: "FIGHT", iconSource: "fight.svg", action: 0 },
                    { idName: "act", label: "ACT", iconSource: "act.svg", action: 1 },
                    { idName: "item", label: "ITEM", iconSource: "item.svg", action: 2 },
                    { idName: "mercy", label: "MERCY", iconSource: "mercy.svg", action: 3 }
                ]
                
                delegate: Rectangle {
                    id: btn
                    objectName: "btn_" + modelData.action
                    width: 120 * s
                    height: 42 * s
                    color: "black"
                    border.width: 2 * s
                    
                    property bool isHovered: sm.containsMouse
                    border.color: isHovered ? "#f3ee32" : "#e58026"
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 6 * s
                        
                        Item {
                            width: btn.isHovered ? 14 * s : 0
                            height: 1 * s
                            Behavior on width { NumberAnimation { duration: 100 } }
                        }
                        
                        Image {
                            id: btnIcon
                            source: modelData.iconSource
                            width: 16 * s
                            height: 16 * s
                            fillMode: Image.PreserveAspectFit
                            
                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: btn.isHovered ? "#f3ee32" : "#e58026"
                            }
                        }
                        
                        Text {
                            text: modelData.label
                            color: btn.isHovered ? "#f3ee32" : "#e58026"
                            font.family: pf.name
                            font.pixelSize: 14 * s
                            font.letterSpacing: 2 * s
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: {
                            root.hoveredButton = btn
                            showSansDialogue(root.buttonHoverTexts[modelData.action], 3000)
                        }
                        onExited: {
                            if (root.hoveredButton === btn) {
                                root.hoveredButton = null
                            }
                        }
                        onClicked: {
                            triggerButtonAction(modelData.action)
                        }
                    }
                }
            }
        }

        // Global sliding red Soul heart cursor
        Image {
            id: soulHeart
            source: "heart.svg"
            width: 16 * s
            height: 16 * s
            fillMode: Image.PreserveAspectFit
            z: 100
            
            property real targetX: {
                if (rootContent && dialogueBox) {
                    if (root.hoveredButton) {
                        var idx = 0
                        if (root.hoveredButton.objectName === "btn_1") idx = 1
                        else if (root.hoveredButton.objectName === "btn_2") idx = 2
                        else if (root.hoveredButton.objectName === "btn_3") idx = 3
                        
                        var bx = (root.width - 570 * s) / 2
                        return bx + idx * 150 * s + 8 * s
                    } else {
                        var dbx = (root.width - 580 * s) / 2
                        return dbx + 24 * s
                    }
                }
                return 0
            }
            
            property real targetY: {
                if (rootContent && dialogueBox) {
                    if (root.hoveredButton) {
                        var by = root.height - 60 * s - 42 * s
                        return by + (42 * s - 16 * s) / 2
                    } else {
                        var dby = 60 * s + 250 * s + 20 * s
                        var rowY = 0
                        if (root.boxState === "normal") {
                            if (pwd.activeFocus) rowY = 36 * s
                            else if (root.activeMenuRow === 0) rowY = 4 * s
                            else rowY = 68 * s
                        } else {
                            if (root.activeMenuRow === 0) rowY = 4 * s
                            else if (root.activeMenuRow === 1) rowY = 36 * s
                            else rowY = 68 * s
                        }
                        return dby + 20 * s + rowY + 2 * s
                    }
                }
                return 0
            }
            
            x: targetX
            y: targetY
            
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            handleLoginFailed()
        }
    }

    // Helper functions
    function cycleUser() {
        if (typeof userModel !== "undefined" && userModel.rowCount() > 0) {
            root.userIndex = (root.userIndex + 1) % userModel.rowCount()
        }
    }

    function cycleSession() {
        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
        }
    }

    function triggerButtonAction(action) {
        if (action === 0) {
            doLogin()
        } else if (action === 1) {
            cycleSession()
        } else if (action === 2) {
            cycleUser()
        } else if (action === 3) {
            root.boxState = root.boxState === "mercy" ? "normal" : "mercy"
        }
    }

    function showSansDialogue(msg, duration) {
        bubbleText.text = msg
        speechBubble.opacity = 1.0
        bubbleTimerRestart.interval = duration || 3000
        bubbleTimerRestart.restart()
    }

    Timer {
        id: bubbleTimerRestart
        onTriggered: speechBubble.opacity = 0.0
    }

    function takeDamage(dmg) {
        root.currentHP = Math.max(1, root.currentHP - dmg)
        damageText.text = "-" + dmg
        damageFloat.restart()
        damageFade.restart()
        shakeAnim.restart()
    }

    function handleLoginFailed() {
        err.text = "ACCESS DENIED"
        takeDamage(15 + Math.floor(Math.random() * 15))
        var quote = failedQuotes[failedCount % failedQuotes.length]
        failedCount++
        showSansDialogue(quote, 4000)
        pwd.text = ""
        pwd.forceActiveFocus()
    }

    function triggerActiveSelection() {
        if (root.boxState === "normal") {
            if (root.activeMenuRow === 0) {
                cycleUser()
            } else if (root.activeMenuRow === 1) {
                doLogin()
            } else if (root.activeMenuRow === 2) {
                cycleSession()
            }
        } else if (root.boxState === "mercy") {
            if (root.activeMenuRow === 0) {
                if (typeof sddm !== "undefined") sddm.reboot()
            } else if (root.activeMenuRow === 1) {
                if (typeof sddm !== "undefined") sddm.powerOff()
            } else if (root.activeMenuRow === 2) {
                root.boxState = "normal"
                root.activeMenuRow = 1
                pwd.forceActiveFocus()
            }
        }
    }

    function doLogin() { 
        var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : ""); 
        if (typeof sddm !== "undefined") {
            sddm.login(u, pwd.text, root.sessionIndex)
        }
    }
}
