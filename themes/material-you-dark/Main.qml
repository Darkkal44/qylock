import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#131218"

    // Background
    Image {
        anchors.fill: parent
        source: "bg.png"
        fillMode: Image.PreserveAspectCrop
    }

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    
    // UI States
    property real ui1: 0
    property real ui2: 0
    property string errorMessage: ""

    // Fonts
    FontLoader {
        id: customFont
        source: "font/GoogleSans-VariableFont_GRAD,opsz,wght.ttf"
    }
    
    readonly property string sansFont: customFont.name !== "" ? customFont.name : "Roboto, Inter, sans-serif"

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
        id: focusTimer
        interval: 300
        running: true
        onTriggered: pwd.forceActiveFocus()
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.errorMessage = "ACCESS DENIED";
            pwd.text = "";
            shakeAnim.start();
            errTimer.start();
        }
    }

    Timer {
        id: errTimer
        interval: 3000
        onTriggered: root.errorMessage = ""
    }

    Component.onCompleted: {
        fadeAnim.start();
        if (typeof keyboard !== "undefined") keyboard.numLock = true;
    }

    SequentialAnimation {
        id: fadeAnim
        PauseAnimation { duration: 500 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "ui1"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "ui2"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeTranslate; property: "x"; to: 15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -15*s; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 50 }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: pwd.forceActiveFocus()
    }

    // Layout Row
    Row {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 96 * s
        opacity: root.ui1
        scale: 0.96 + (0.04 * root.ui1)
        transform: Translate { y: (1 - root.ui1) * 30 * s }

        // Left Section
        Column {
            spacing: 24 * s
            anchors.verticalCenter: parent.verticalCenter
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    let d = new Date();
                    hText.text = Qt.formatTime(d, "hh");
                    mText.text = Qt.formatTime(d, "mm");
                    dateChipText.text = Qt.formatDate(d, "dddd, MMM d").toUpperCase();
                }
            }

            // Clock
            Column {
                spacing: -24 * s
                
                Text {
                    id: hText
                    text: Qt.formatTime(new Date(), "hh")
                    font.family: root.sansFont
                    font.pixelSize: 140 * s
                    font.weight: Font.Bold
                    color: "#E6E1E5"
                }
                
                Text {
                    id: mText
                    text: Qt.formatTime(new Date(), "mm")
                    font.family: root.sansFont
                    font.pixelSize: 140 * s
                    font.weight: Font.Bold
                    color: "#CBC2DB"
                }
            }

            // Date Pill
            Rectangle {
                width: dateChipText.implicitWidth + 32 * s
                height: 44 * s
                radius: 22 * s
                color: "#3A3247"
                
                Text {
                    id: dateChipText
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(), "dddd, MMM d").toUpperCase()
                    font.family: root.sansFont
                    font.pixelSize: 11 * s
                    font.bold: true
                    font.letterSpacing: 1 * s
                    color: "#E6E1E5"
                }
            }
        }

        // Right Section
        Column {
            spacing: 24 * s
            anchors.verticalCenter: parent.verticalCenter

            // Settings Title
            Text {
                text: "QUICK SETTINGS"
                font.family: root.sansFont
                font.pixelSize: 11 * s
                font.bold: true
                font.letterSpacing: 1.5 * s
                color: "#958DA5"
            }

            // Settings Grid
            Grid {
                columns: 2
                spacing: 16 * s
                
                // Power
                Rectangle {
                    id: powerTile
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: powerMouse.pressed ? "#1C1924" : (powerMouse.containsMouse ? "#322A3E" : "#25232A")
                    scale: powerMouse.pressed ? 0.95 : (powerMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s
                        
                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: "#3A3247"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Image {
                                id: powerIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><path d='M18.36 6.64a9 9 0 1 1-12.73 0'></path><line x1='12' y1='2' x2='12' y2='12'></line></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: powerIcon
                                source: powerIcon
                                color: "#E6E1E5"
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s
                            
                            Text {
                                text: "POWER"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: powerMouse.containsMouse ? "#E6E1E5" : "#CBC2DB"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "SHUT DOWN"
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: powerMouse.containsMouse ? "#CBC2DB" : "#958DA5"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!root.isQuickshell) sddm.powerOff();
                    }
                }
                
                // Session
                Rectangle {
                    id: sessionTile
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: sessionMouse.pressed ? "#1C1924" : (sessionMouse.containsMouse ? "#322A3E" : "#25232A")
                    scale: sessionMouse.pressed ? 0.95 : (sessionMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s
                        
                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: "#3A3247"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Image {
                                id: sessionIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='3'></circle><path d='M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z'></path></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: sessionIcon
                                source: sessionIcon
                                color: "#E6E1E5"
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s
                            
                            Text {
                                text: "SESSION"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: sessionMouse.containsMouse ? "#E6E1E5" : "#CBC2DB"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "PLASMA").toUpperCase()
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: sessionMouse.containsMouse ? "#CBC2DB" : "#958DA5"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                elide: Text.ElideRight
                                width: 90 * s
                            }
                        }
                    }
                    
                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.isQuickshell && typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                            }
                        }
                    }
                }

                // Reboot
                Rectangle {
                    id: rebootTile
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: rebootMouse.pressed ? "#1C1924" : (rebootMouse.containsMouse ? "#322A3E" : "#25232A")
                    scale: rebootMouse.pressed ? 0.95 : (rebootMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s
                        
                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: "#3A3247"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Image {
                                id: rebootIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><polyline points='23 4 23 10 17 10'></polyline><path d='M20.49 15a9 9 0 1 1-2.12-9.36L23 10'></path></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: rebootIcon
                                source: rebootIcon
                                color: "#E6E1E5"
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s
                            
                            Text {
                                text: "REBOOT"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: rebootMouse.containsMouse ? "#E6E1E5" : "#CBC2DB"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "RESTART"
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: rebootMouse.containsMouse ? "#CBC2DB" : "#958DA5"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!root.isQuickshell) sddm.reboot();
                    }
                }

                // Sleep
                Rectangle {
                    id: suspendTile
                    width: 180 * s; height: 76 * s; radius: 38 * s
                    color: suspendMouse.pressed ? "#1C1924" : (suspendMouse.containsMouse ? "#322A3E" : "#25232A")
                    scale: suspendMouse.pressed ? 0.95 : (suspendMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * s
                        anchors.rightMargin: 16 * s
                        spacing: 12 * s
                        
                        Rectangle {
                            width: 48 * s; height: 48 * s; radius: 24 * s
                            color: "#3A3247"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Image {
                                id: suspendIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><path d='M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z'></path></svg>"
                                anchors.centerIn: parent
                                width: 20 * s
                                height: 20 * s
                                sourceSize.width: 40 * s
                                sourceSize.height: 40 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: suspendIcon
                                source: suspendIcon
                                color: "#E6E1E5"
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s
                            
                            Text {
                                text: "SLEEP"
                                font.family: root.sansFont
                                font.pixelSize: 12 * s
                                font.bold: true
                                color: suspendMouse.containsMouse ? "#E6E1E5" : "#CBC2DB"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "SUSPEND"
                                font.family: root.sansFont
                                font.pixelSize: 9 * s
                                color: suspendMouse.containsMouse ? "#CBC2DB" : "#958DA5"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!root.isQuickshell) sddm.suspend();
                    }
                }
            }

            // Login Card
            Rectangle {
                id: notificationCard
                width: 376 * s
                height: 180 * s
                radius: 32 * s
                color: "#1C1B20"
                transform: Translate { id: shakeTranslate }
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 20 * s
                    spacing: 12 * s
                    
                    // Header
                    Row {
                        width: parent.width
                        spacing: 8 * s
                        
                        Item {
                            width: 12 * s
                            height: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: lockIcon
                                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='black' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='11' width='18' height='11' rx='2' ry='2'></rect><path d='M7 11V7a5 5 0 0 1 10 0v4'></path></svg>"
                                anchors.fill: parent
                                sourceSize.width: 24 * s
                                sourceSize.height: 24 * s
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcon
                                source: lockIcon
                                color: "#958DA5"
                            }
                        }
                        Text {
                            text: "SYSTEM UI"
                            font.family: root.sansFont
                            font.pixelSize: 10 * s
                            font.bold: true
                            font.letterSpacing: 1 * s
                            color: "#958DA5"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "•  now"
                            font.family: root.sansFont
                            font.pixelSize: 10 * s
                            color: "#958DA5"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Password Box
                    Rectangle {
                        width: parent.width
                        height: 52 * s
                        radius: 26 * s
                        color: "#2B2930"
                        border.color: root.errorMessage !== "" ? "#FFB4AB" : (pwd.activeFocus ? "#D0BCFF" : "transparent")
                        border.width: pwd.activeFocus ? 2 * s : 0
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        
                        TextInput {
                            id: pwd
                            anchors.fill: parent
                            anchors.leftMargin: 20 * s
                            anchors.rightMargin: 20 * s
                            font.family: root.sansFont
                            font.pixelSize: 18 * s
                            font.letterSpacing: 6 * s
                            color: "#E6E1E5"
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            
                            cursorVisible: false
                            cursorDelegate: Item { width: 0; height: 0 }
                            selectionColor: "#4F4461"
                            
                            property bool wasClicked: false
                            onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                            
                            Text {
                                anchors.centerIn: parent
                                text: root.errorMessage !== "" ? root.errorMessage : "PASSWORD REQUIRED"
                                font.family: root.sansFont
                                font.pixelSize: 11 * s
                                font.bold: true
                                font.letterSpacing: 1.5 * s
                                color: root.errorMessage !== "" ? "#FFB4AB" : "#958DA5"
                                opacity: pwd.text === "" && (!pwd.activeFocus || (!pwd.wasClicked && pwd.text.length === 0)) ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                            
                            // Cursor
                            Rectangle {
                                id: customCursor
                                width: 2 * s
                                height: 18 * s
                                color: "#D0BCFF"
                                anchors.verticalCenter: parent.verticalCenter
                                x: pwd.cursorRectangle.x
                                visible: pwd.activeFocus && (pwd.text.length > 0 || pwd.wasClicked) && root.errorMessage === ""
                                
                                SequentialAnimation {
                                    loops: Animation.Infinite
                                    running: customCursor.visible
                                    NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0; duration: 400; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: customCursor; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.InOutQuad }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: {
                                    pwd.wasClicked = true;
                                    pwd.forceActiveFocus();
                                }
                            }
                            
                            onAccepted: {
                                if (!root.isQuickshell && pwd.text !== "") {
                                    let currentUser = userHelper.currentItem ? userHelper.currentItem.uLogin : userModel.lastUser;
                                    sddm.login(currentUser, pwd.text, root.sessionIndex);
                                }
                            }
                        }
                    }

                    // Bottom Row
                    Row {
                        width: parent.width
                        spacing: 12 * s
                        
                        // User Switch
                        Rectangle {
                            width: userText.implicitWidth + 32 * s
                            height: 38 * s
                            radius: 19 * s
                            color: userMouse.pressed ? "#201E25" : (userMouse.containsMouse ? "#36343B" : "#2B2930")
                            scale: userMouse.pressed ? 0.95 : (userMouse.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            
                            Text {
                                id: userText
                                anchors.centerIn: parent
                                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "USER")).toUpperCase()
                                font.family: root.sansFont
                                font.pixelSize: 10 * s
                                font.bold: true
                                font.letterSpacing: 1 * s
                                color: "#CBC2DB"
                            }
                            
                            MouseArea {
                                id: userMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.isQuickshell && typeof userModel !== "undefined" && userModel.rowCount() > 0) {
                                        root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                                    }
                                }
                            }
                        }

                        // Unlock Pill
                        Item {
                            width: parent.width - (userText.implicitWidth + 32 * s) - 12 * s
                            height: 38 * s
                            
                            Rectangle {
                                anchors.right: parent.right
                                width: parent.width
                                height: 38 * s
                                radius: 19 * s
                                color: loginMouse.pressed ? "#2B2238" : (loginMouse.containsMouse ? "#4F4461" : "#3A3247")
                                scale: loginMouse.pressed ? 0.95 : (loginMouse.containsMouse ? 1.02 : 1.0)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6 * s
                                    
                                    Text {
                                        text: "UNLOCK"
                                        font.family: root.sansFont
                                        font.pixelSize: 10 * s
                                        font.bold: true
                                        font.letterSpacing: 1.5 * s
                                        color: "#E6E1E5"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "➔"
                                        font.family: root.sansFont
                                        font.pixelSize: 11 * s
                                        color: "#E6E1E5"
                                        anchors.verticalCenter: parent.verticalCenter
                                        transform: Translate {
                                            x: loginMouse.containsMouse ? 3 * s : 0
                                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: loginMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pwd.accepted()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}