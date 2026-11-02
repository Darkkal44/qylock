import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#e8ebed" }
            GradientStop { position: 1.0; color: "#d2d6d9" }
        }
        z: -100
    }

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined"
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0

    function getUserLogin() {
        if (userHelper.currentItem && userHelper.currentItem.uLogin) {
            return userHelper.currentItem.uLogin;
        }
        if (typeof userModel !== "undefined" && userModel) {
            if (typeof userModel.data === "function" && typeof userModel.index === "function") {
                var dataName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1);
                if (dataName) return dataName;
            }
            if (userModel.lastUser) return userModel.lastUser;
        }
        return "";
    }

    function getUserDisplayName() {
        if (userHelper.currentItem && userHelper.currentItem.uName) {
            return userHelper.currentItem.uName;
        }
        if (typeof userModel !== "undefined" && userModel) {
            if (typeof userModel.data === "function" && typeof userModel.index === "function") {
                var realName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 2);
                if (realName) return realName;
                var dataName = userModel.data(userModel.index(root.userIndex, 0), Qt.UserRole + 1);
                if (dataName) return dataName;
            }
            if (userModel.lastUser) return userModel.lastUser;
        }
        return "USER";
    }
    
    // UI States
    property real ui1: 0
    property real ui2: 0
    property real ui3: 0
    property string errorMessage: ""

    FontLoader { id: pfDot; source: "font/NDot55.otf" }
    readonly property string sansFont: "Roboto, Inter, sans-serif"

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
            NumberAnimation { target: root; property: "ui3"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
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

    // Logo
    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 40 * s
        text: "AUTHENTICATE"
        font.family: pfDot.name
        font.pixelSize: 24 * s
        color: "#111111"
        opacity: root.ui1
        transform: Translate { y: (1 - root.ui1) * -20 * s }
    }

    // Layout
    Row {
        id: widgetGrid
        anchors.centerIn: parent
        spacing: 24 * s

        // Clock
        Rectangle {
            width: 280 * s
            height: 280 * s
            radius: 48 * s
            color: "#111111"
            opacity: root.ui1
            scale: 0.95 + (0.05 * root.ui1)
            transform: Translate { y: (1 - root.ui1) * 40 * s }
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    let d = new Date();
                    hourText.text = Qt.formatTime(d, "hh");
                    minText.text = Qt.formatTime(d, "mm");
                    dayText.text = Qt.formatDate(d, "dddd").toUpperCase();
                    dateText.text = Qt.formatDate(d, "MMM d").toUpperCase();
                }
            }
            
            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -16 * s
                spacing: 4 * s
                
                Text {
                    id: hourText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "hh")
                    font.family: pfDot.name
                    font.pixelSize: 110 * s
                    font.letterSpacing: 4 * s
                    color: "#ffffff"
                    height: 84 * s
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    id: minText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "mm")
                    font.family: pfDot.name
                    font.pixelSize: 110 * s
                    font.letterSpacing: 4 * s
                    color: "#ea1821"
                    height: 84 * s
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32 * s
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8 * s
                
                Text {
                    id: dayText
                    text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                    font.family: root.sansFont
                    font.pixelSize: 11 * s
                    font.letterSpacing: 1.5 * s
                    font.bold: true
                    color: "#888888"
                }
                Text {
                    id: dateText
                    text: Qt.formatDate(new Date(), "MMM d").toUpperCase()
                    font.family: root.sansFont
                    font.pixelSize: 11 * s
                    font.letterSpacing: 1.5 * s
                    font.bold: true
                    color: "#ffffff"
                }
            }
        }

        // Login
        Rectangle {
            id: loginWidget
            width: 320 * s
            height: 280 * s
            radius: 48 * s
            color: "#111111"
            opacity: root.ui2
            scale: 0.95 + (0.05 * root.ui2)
            transform: [
                Translate { id: shakeTranslate },
                Translate { y: (1 - root.ui2) * 40 * s }
            ]
            
            Column {
                anchors.centerIn: parent
                spacing: 24 * s
                width: 250 * s

                // Username
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, (userNameText.implicitWidth + 48 * s))
                    height: 40 * s
                    radius: 20 * s
                    color: userMouse.pressed ? "#b31018" : (userMouse.containsMouse ? "#ea1821" : "#222222")
                    border.color: userMouse.containsMouse ? "#ea1821" : "#2a2a2a"
                    border.width: 1 * s
                    scale: userMouse.pressed ? 0.96 : (userMouse.containsMouse ? 1.02 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8 * s
                        
                        Text {
                            text: "•"
                            font.family: pfDot.source !== "" ? pfDot.name : root.sansFont
                            font.pixelSize: 14 * s
                            color: userMouse.containsMouse ? "#ffffff" : "#ea1821"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            id: userNameText
                            text: root.getUserDisplayName().toUpperCase()
                            font.family: pfDot.source !== "" ? pfDot.name : root.sansFont
                            font.pixelSize: 16 * s
                            font.letterSpacing: 1.5 * s
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "•"
                            font.family: pfDot.source !== "" ? pfDot.name : root.sansFont
                            font.pixelSize: 14 * s
                            color: userMouse.containsMouse ? "#ffffff" : "#ea1821"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        id: userMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof userModel !== "undefined" && userModel && userModel.rowCount() > 0) {
                                root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                            }
                        }
                    }
                }

                // Password
                Rectangle {
                    width: parent.width
                    height: 52 * s
                    radius: 26 * s
                    color: pwd.activeFocus ? "#1a1a1a" : "#222222"
                    border.color: root.errorMessage !== "" ? "#ea1821" : (pwd.activeFocus ? "#ffffff" : "#2a2a2a")
                    border.width: 1.5 * s
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    
                    TextInput {
                        id: pwd
                        anchors.fill: parent
                        anchors.leftMargin: 24 * s
                        anchors.rightMargin: 24 * s
                        font.family: root.sansFont
                        font.pixelSize: 20 * s
                        font.letterSpacing: 8 * s
                        color: "#ffffff"
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        
                        cursorVisible: false
                        cursorDelegate: Item { width: 0; height: 0 }
                        selectionColor: "#d0d4d8"
                        
                        property bool wasClicked: false
                        onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.errorMessage !== "" ? root.errorMessage : "PASSWORD"
                            font.family: pfDot.source !== "" ? pfDot.name : root.sansFont
                            font.pixelSize: 11 * s
                            font.letterSpacing: 1 * s
                            color: root.errorMessage !== "" ? "#ea1821" : "#888888"
                            opacity: pwd.text === "" && (!pwd.activeFocus || (!pwd.wasClicked && pwd.text.length === 0)) ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        
                        // Cursor
                        Rectangle {
                            id: customCursor
                            width: 2 * s
                            height: 20 * s
                            color: "#ea1821" // Cursor Color
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
                            if (typeof sddm !== "undefined" && sddm && pwd.text !== "") {
                                let currentUser = root.getUserLogin();
                                sddm.login(currentUser, pwd.text, root.sessionIndex);
                            }
                        }
                    }
                }

                // Login Button
                Rectangle {
                    width: parent.width
                    height: 52 * s
                    radius: 26 * s
                    color: loginMouse.pressed ? "#b31018" : (loginMouse.containsMouse ? "#ea1821" : "#ffffff")
                    scale: loginMouse.pressed ? 0.96 : (loginMouse.containsMouse ? 1.02 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8 * s
                        
                        Text {
                            text: "UNLOCK"
                            font.family: root.sansFont
                            font.pixelSize: 14 * s
                            font.letterSpacing: 2 * s
                            font.bold: true
                            color: loginMouse.containsMouse ? "#ffffff" : "#111111"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "→"
                            font.family: pfDot.source !== "" ? pfDot.name : root.sansFont
                            font.pixelSize: 16 * s
                            color: loginMouse.containsMouse ? "#ffffff" : "#111111"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            transform: Translate {
                                x: loginMouse.containsMouse ? 4 * s : 0
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: loginMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (pwd.text === "") {
                                pwd.forceActiveFocus();
                            } else {
                                pwd.accepted();
                            }
                        }
                    }
                }
            }
        }

        // Actions
        Rectangle {
            width: 280 * s
            height: 280 * s
            radius: 48 * s
            color: "#111111"
            opacity: root.ui3
            scale: 0.95 + (0.05 * root.ui3)
            transform: Translate { y: (1 - root.ui3) * 40 * s }

            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: 16 * s
                
                // Power
                Rectangle {
                    width: 108 * s; height: 108 * s; radius: 54 * s
                    color: powerMouse.pressed ? "#b31018" : (powerMouse.containsMouse ? "#ea1821" : "#222222")
                    border.color: powerMouse.containsMouse ? "#ea1821" : "#2a2a2a"
                    border.width: 1 * s
                    scale: powerMouse.pressed ? 0.92 : (powerMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2 * s
                        Text {
                            text: "P"
                            font.family: pfDot.name
                            font.pixelSize: 36 * s
                            color: "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "POWER"
                            font.family: root.sansFont
                            font.pixelSize: 9 * s
                            font.bold: true
                            font.letterSpacing: 1 * s
                            color: powerMouse.containsMouse ? "#ffffff" : "#888888"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm && sddm.powerOff) sddm.powerOff();
                    }
                }
                
                // Session
                Rectangle {
                    width: 108 * s; height: 108 * s; radius: 54 * s
                    color: sessionMouse.pressed ? "#d0d0d0" : (sessionMouse.containsMouse ? "#ffffff" : "#222222")
                    border.color: sessionMouse.containsMouse ? "#ffffff" : "#2a2a2a"
                    border.width: 1 * s
                    scale: sessionMouse.pressed ? 0.92 : (sessionMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2 * s
                        width: parent.width - 16 * s
                        Text {
                            text: "S"
                            font.family: pfDot.name
                            font.pixelSize: 36 * s
                            color: sessionMouse.containsMouse ? "#111111" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "PLASMA").toUpperCase()
                            font.family: root.sansFont
                            font.pixelSize: 8 * s
                            font.bold: true
                            font.letterSpacing: 0.5 * s
                            color: sessionMouse.containsMouse ? "#111111" : "#888888"
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sessionModel !== "undefined" && sessionModel && sessionModel.rowCount() > 0) {
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                            }
                        }
                    }
                }

                // Reboot
                Rectangle {
                    width: 108 * s; height: 108 * s; radius: 54 * s
                    color: rebootMouse.pressed ? "#d0d0d0" : (rebootMouse.containsMouse ? "#ffffff" : "#222222")
                    border.color: rebootMouse.containsMouse ? "#ffffff" : "#2a2a2a"
                    border.width: 1 * s
                    scale: rebootMouse.pressed ? 0.92 : (rebootMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2 * s
                        Text {
                            text: "R"
                            font.family: pfDot.name
                            font.pixelSize: 36 * s
                            color: rebootMouse.containsMouse ? "#111111" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "REBOOT"
                            font.family: root.sansFont
                            font.pixelSize: 9 * s
                            font.bold: true
                            font.letterSpacing: 1 * s
                            color: rebootMouse.containsMouse ? "#111111" : "#888888"
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm && sddm.reboot) sddm.reboot();
                    }
                }

                // Suspend
                Rectangle {
                    width: 108 * s; height: 108 * s; radius: 54 * s
                    color: suspendMouse.pressed ? "#1a1a1a" : (suspendMouse.containsMouse ? "#333333" : "#222222")
                    border.color: suspendMouse.containsMouse ? "#444444" : "#2a2a2a"
                    border.width: 1 * s
                    scale: suspendMouse.pressed ? 0.92 : (suspendMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2 * s
                        Text {
                            text: "Z"
                            font.family: pfDot.name
                            font.pixelSize: 36 * s
                            color: "#ea1821"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "SLEEP"
                            font.family: root.sansFont
                            font.pixelSize: 9 * s
                            font.bold: true
                            font.letterSpacing: 1 * s
                            color: suspendMouse.containsMouse ? "#ffffff" : "#888888"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm && sddm.suspend) sddm.suspend();
                    }
                }
            }
        }
    }
}
