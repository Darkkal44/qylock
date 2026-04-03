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
    color: "#1B8FBF"

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0)
                               ? sessionModel.lastIndex : 0
    property real fadeIn: 0
    property int currentUserIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: customFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    readonly property string customFontName: fontFolder.count > 0 ? customFont.name : "Segoe UI, Ubuntu, sans-serif"

    TextConstants { id: textConstants }

    Component.onCompleted: bootAnim.start()

    Timer {
        interval: 300
        running: true
        onTriggered: inputFocus.forceActiveFocus()
    }
    NumberAnimation {
        id: bootAnim
        target: root; property: "fadeIn"
        from: 0; to: 1; duration: 700
        easing.type: Easing.OutCubic
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            statusLabel.text   = "Welcome"
            statusLabel.color  = "#a0e0a0"
            errorMsg.visible   = false
        }
        function onLoginFailed() {
            statusLabel.text   = "Locked"
            statusLabel.color  = "#c8dce8"
            errorMsg.text      = "The password is incorrect. Please try again."
            errorMsg.visible   = true
            passwordField.text = ""
            shakeAnim.start()
        }
    }

    ListView {
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sName: model.name || "" }
    }

    ListView {
        id: userList
        model: userModel
        currentIndex: root.currentUserIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string uName: model.name || model.realName || "" }
    }

    Image {
        id: bg
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: root.fadeIn
    }

    RadialGradient {
        anchors.fill: parent
        opacity: 0.35 * root.fadeIn
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#1a0d1a30" }
        }
    }

    Column {
        id: loginPanel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10 * s
        spacing: 0 * s
        opacity: root.fadeIn

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: loginPanel; property: "x"
                              to: loginPanel.x + 12; duration: 50 }
            NumberAnimation { target: loginPanel; property: "x"
                              to: loginPanel.x - 10; duration: 50 }
            NumberAnimation { target: loginPanel; property: "x"
                              to: loginPanel.x + 8;  duration: 50 }
            NumberAnimation { target: loginPanel; property: "x"
                              to: loginPanel.x - 6;  duration: 50 }
            NumberAnimation { target: loginPanel; property: "x"
                              to: loginPanel.x;       duration: 50 }
        }

        Item {
            id: pfpFrame
            width: 132 * s; height: 132 * s
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: 18 * s
                color: "transparent"
                border.color: "#99d0e8f8"
                border.width: 2 * s

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0; verticalOffset: 2
                    radius: 16 * s; samples: 24; color: "#70000000"
                }
            }

            Rectangle {
                id: glassFrame
                anchors.fill: parent
                anchors.margins: 2 * s
                radius: 16 * s
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#e0f8ffff" }
                    GradientStop { position: 0.20; color: "#99b8ddf0" }
                    GradientStop { position: 0.50; color: "#446090b8" }
                    GradientStop { position: 0.85; color: "#993a7aaa" }
                    GradientStop { position: 1.00; color: "#e05090c0" }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5 * s
                    radius: 12 * s
                    color: "transparent"
                    border.color: "#40000000"
                    border.width: 1 * s
                    z: 10
                }

                Canvas {
                    id: pfpCanvas
                    anchors.fill: parent
                    anchors.margins: 5 * s
                    z: 5
                    antialiasing: true

                    property var pfpSource: Image { id: pfpImg; source: "pfp.png"; visible: false; onStatusChanged: if (status == Image.Ready) pfpCanvas.requestPaint() }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.beginPath();
                        ctx.roundedRect(0, 0, width, height, 8 * s, 8 * s);
                        ctx.clip();
                        ctx.drawImage(pfpImg, 0, 0, width, height);
                    }
                }

                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 2 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 12 * s; height: parent.height * 0.45
                    radius: 12 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#70ffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    z: 15
                }
            }
        }

        Item { width: 1 * s; height: 18 * s }

        Text {
            id: userNameText
            anchors.horizontalCenter: parent.horizontalCenter
            text: (userList.currentItem && userList.currentItem.uName)
                  ? userList.currentItem.uName
                  : (userModel.lastUser || "User")
            font.family: root.customFontName
            font.pixelSize: 26 * s
            font.weight: Font.Normal
            color: "white"
            style: Text.Raised
            styleColor: "#40000000"
        }

        Item { width: 1 * s; height: 4 * s }

        Text {
            id: statusLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Locked"
            font.family: root.customFontName
            font.pixelSize: 14 * s
            color: "#c8dce8"
            style: Text.Raised
            styleColor: "#40000000"
        }

        Item { width: 1 * s; height: 14 * s }

        Item {
            id: passwordRow
            anchors.horizontalCenter: parent.horizontalCenter
            width: inputBox.width 
            height: 28 * s

            Rectangle {
                id: inputBox
                anchors.centerIn: parent
                width: 240 * s; height: 28 * s
                radius: 2 * s
                color: "#f8fdff"
                border.color: inputFocus.activeFocus ? "#3c7fb1" : "#40708898"
                border.width: 1 * s

                Rectangle {
                    anchors.fill: parent; anchors.margins: 1 * s; radius: 1 * s; color: "transparent"
                    border.color: "#15000000"; border.width: 1 * s
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6 * s
                    text: "Password"
                    font.family: root.customFontName; font.pixelSize: 13 * s; color: "#80404050"
                    visible: inputFocus.text === "" && !inputFocus.activeFocus
                }

                Row {
                    id: dotRow
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 6 * s
                    spacing: 4 * s
                    Repeater {
                        model: 32 
                        Rectangle {
                            width: 7 * s; height: 7 * s; radius: 3.5 * s; color: "#101820"
                            opacity: index < inputFocus.text.length ? 1 : 0
                            scale: index < inputFocus.text.length ? 1 : 0
                            
                            onOpacityChanged: {
                                if (opacity > 0 && index == inputFocus.text.length - 1) {
                                    scaleFixedAnim.start();
                                }
                            }

                            NumberAnimation on scale { id: scaleFixedAnim; from: 0; to: 1; duration: 150; easing.type: Easing.OutBack }
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }
                    }
                }

                Rectangle {
                    id: customCursor
                    width: 1 * s; height: 16 * s; color: "#101820"
                    anchors.verticalCenter: parent.verticalCenter
                    x: 6 * s + (inputFocus.cursorPosition * (7 * s + 4 * s))
                    visible: inputFocus.activeFocus && cursorFlash.flashVisible
                    Timer {
                        id: cursorFlash
                        property bool flashVisible: true
                        interval: 500; running: inputFocus.activeFocus; repeat: true
                        onTriggered: flashVisible = !flashVisible
                        onRunningChanged: if (!running) flashVisible = true
                    }
                }

                TextInput {
                    id: inputFocus
                    anchors.fill: parent; anchors.leftMargin: 6 * s; anchors.rightMargin: 6 * s
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.customFontName; font.pixelSize: 13 * s; color: "transparent"
                    echoMode: TextInput.Normal 
                    focus: true; clip: true
                    selectionColor: "#3399ff"
                    cursorVisible: false
                    cursorDelegate: Item {}
                    
                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed:  doLogin()
                }
            }

            Item {
                id: arrowBtn
                anchors.left: inputBox.right; anchors.leftMargin: 8 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 28 * s; height: 28 * s

                Rectangle {
                    anchors.fill: parent; radius: 14 * s
                    color: "transparent"
                    border.color: arrowMouse.containsMouse ? "#80b0ccee" : "#40708898"
                    border.width: 1 * s
                }

                Rectangle {
                    anchors.fill: parent; anchors.margins: 1 * s; radius: 13 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: arrowMouse.containsMouse ? "#88c8e0ff" : "#60a0c4e8" }
                        GradientStop { position: 0.5; color: arrowMouse.containsMouse ? "#666090b4" : "#404870a0" }
                        GradientStop { position: 1.0; color: arrowMouse.containsMouse ? "#886090b8" : "#505888b0" }
                    }
                }

                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 2 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 8 * s; height: 11 * s; radius: 7 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#45ffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    z: 2
                }
                
                Canvas {
                    anchors.fill: parent; anchors.margins: 6 * s
                    z: 5
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "white"; ctx.lineWidth = 2.2 * s;
                        ctx.lineCap = "round"; ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(2, height/2); ctx.lineTo(width-2, height/2);
                        ctx.moveTo(width-6, height/2-4); ctx.lineTo(width-2, height/2); ctx.lineTo(width-6, height/2+4);
                        ctx.stroke();
                    }
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }

                scale: arrowMouse.pressed ? 0.92 : (arrowMouse.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100 } }
            }
        }

        Item { width: 1 * s; height: 8 * s }

        Text {
            id: errorMsg
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            opacity: 0; z: -100
            font.family: root.customFontName
            font.pixelSize: 12 * s
            color: "#ffddaa"
            style: Text.Raised
            styleColor: "#60000000"
            wrapMode: Text.WordWrap
            width: 318 * s
            horizontalAlignment: Text.AlignHCenter
        }

        Item { width: 1 * s; height: 20 * s }

        Item {
            id: switchUserBtn
            anchors.horizontalCenter: parent.horizontalCenter
            width: switchUserText.implicitWidth + 36
            height: 26 * s

            Rectangle {
                anchors.fill: parent
                radius: 3 * s
                color: "transparent"
                border.color: switchMouse.containsMouse ? "#80b0ccee" : "#40708898"
                border.width: 1 * s
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1 * s
                radius: 2 * s
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: switchMouse.containsMouse ? "#88c8e0ff" : "#60a0c4e8"
                    }
                    GradientStop {
                        position: 0.5
                        color: switchMouse.containsMouse ? "#666090b4" : "#404870a0"
                    }
                    GradientStop {
                        position: 1.0
                        color: switchMouse.containsMouse ? "#886090b8" : "#505888b0"
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.topMargin: 1 * s
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 2 * s
                height: 10 * s; radius: 3 * s
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#40ffffff" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Text {
                id: switchUserText
                anchors.centerIn: parent
                text: "Switch User"
                font.family: root.customFontName
                font.pixelSize: 13 * s
                color: "white"
                style: Text.Raised
                styleColor: "#30000000"
            }

            MouseArea {
                id: switchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (userModel.rowCount() > 0)
                        root.currentUserIndex = (root.currentUserIndex + 1) % userModel.rowCount()
                }
            }
        }
    } 

    Item {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52 * s
        opacity: root.fadeIn

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#28000010" }
                GradientStop { position: 1.0; color: "#60001030" }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left; anchors.right: parent.right
            height: 1 * s
            color: "#30a0c8e0"
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20 * s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * s

            Text {
                text: "Session:"
                font.family: root.customFontName
                font.pixelSize: 12 * s
                color: "#c0d8e8"
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: sessionPill
                width: sessionPillText.implicitWidth + 24
                height: 24 * s
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 3 * s
                    color: "transparent"
                    border.color: sessionPillMouse.containsMouse ? "#80b0ccee" : "#40607888"
                    border.width: 1 * s
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: 1 * s
                    radius: 2 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#503060a0" }
                        GradientStop { position: 1.0; color: "#702060b0" }
                    }
                }
                Text {
                    id: sessionPillText
                    anchors.centerIn: parent
                text: (sessionModel && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0)
                      ? sessionHelper.currentItem.sName : "Session"
                    font.family: root.customFontName
                    font.pixelSize: 12 * s
                    color: "white"
                }
                MouseArea {
                    id: sessionPillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (sessionModel && sessionModel.rowCount() > 0)
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20 * s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * s

            Win7PowerBtn {
                label: "Restart"
                onClicked: sddm.reboot()
            }
            Win7PowerBtn {
                label: "Shut down"
                onClicked: sddm.powerOff()
            }
        }
    } 

    function doLogin() {
        errorMsg.visible = false
        var uname = (userList.currentItem && userList.currentItem.uName)
                    ? userList.currentItem.uName : userModel.lastUser
        sddm.login(uname, inputFocus.text, root.sessionIndex)
    }

    component Win7PowerBtn: Item {
        property string label: ""
        signal clicked()

        width:  pwText.implicitWidth + 24
        height: 26 * s

        Rectangle {
            anchors.fill: parent; radius: 3 * s
            color: "transparent"
            border.color: pwMouse.containsMouse ? "#80b8d4f0" : "#40607888"
            border.width: 1 * s
        }
        Rectangle {
            anchors.fill: parent; anchors.margins: 1 * s; radius: 2 * s
            gradient: Gradient {
                GradientStop { position: 0.0; color: pwMouse.containsMouse ? "#883860a8" : "#602858a0" }
                GradientStop { position: 0.5; color: pwMouse.containsMouse ? "#663050a0" : "#502050a0" }
                GradientStop { position: 1.0; color: pwMouse.containsMouse ? "#883060a8" : "#602858a0" }
            }
        }
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1 * s
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 2 * s; height: 9 * s; radius: 3 * s
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#40ffffff" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        Text {
            id: pwText
            anchors.centerIn: parent
            text: parent.label
            font.family: root.customFontName
            font.pixelSize: 13 * s
            color: "white"
        }
        MouseArea {
            id: pwMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
