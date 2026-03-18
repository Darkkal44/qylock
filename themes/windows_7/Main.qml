import QtQuick 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Qt.labs.folderlistmodel 2.15
import SddmComponents 2.0

Rectangle {
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#1B8FBF"

    // Properties
    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0)
                               ? sessionModel.lastIndex : 0
    property real fadeIn: 0
    property int currentUserIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0

    FolderListModel {
        id: fontFolder
        folder: "font"
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: customFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    readonly property string customFontName: fontFolder.count > 0 ? customFont.name : "Segoe UI, Ubuntu, sans-serif"

    TextConstants { id: textConstants }

    // Boot
    Component.onCompleted: bootAnim.start()
    NumberAnimation {
        id: bootAnim
        target: root; property: "fadeIn"
        from: 0; to: 1; duration: 700
        easing.type: Easing.OutCubic
    }

    // Connections
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

    // Session Helper
    ListView {
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sName: model.name || "" }
    }

    // User Helper
    ListView {
        id: userList
        model: userModel
        currentIndex: root.currentUserIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string uName: model.name || model.realName || "" }
    }

    // Background
    Image {
        id: bg
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: root.fadeIn
    }

    // Vignette
    RadialGradient {
        anchors.fill: parent
        opacity: 0.35 * root.fadeIn
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#1a0d1a30" }
        }
    }

    // Login
    Column {
        id: loginPanel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10 * s
        spacing: 0 * s
        opacity: root.fadeIn

        // Shake
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

        // Profile
        Item {
            id: pfpFrame
            width: 148 * s; height: 148 * s
            anchors.horizontalCenter: parent.horizontalCenter

            // Outer glass border glow
            Rectangle {
                anchors.fill: parent
                radius: 18 * s
                color: "transparent"
                border.color: "#80c8e8f8"
                border.width: 3 * s

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 18 * s
                    samples: 32
                    color: "#60000000"
                }
            }

            // Glass frame body — multi-stop gradient to mimic Aero glass
            Rectangle {
                id: glassFrame
                anchors.fill: parent
                anchors.margins: 3 * s
                radius: 15 * s

                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#cce8f8ff" }
                    GradientStop { position: 0.12; color: "#88b8ddf0" }
                    GradientStop { position: 0.45; color: "#556090b8" }
                    GradientStop { position: 0.88; color: "#883a7aaa" }
                    GradientStop { position: 1.00; color: "#cc5090c0" }
                }

                // Inner highlight shine at top
                Rectangle {
                    x: 6 * s; y: 4 * s
                    width: parent.width - 12
                    height: parent.height * 0.35
                    radius: 10 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#60ffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    z: 2
                }

                // Actual profile image clipped inside
                Image {
                    id: pfpImage
                    anchors.fill: parent
                    anchors.margins: 4 * s
                    source: "pfp.png"
                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: pfpImage.width; height: pfpImage.height
                            radius: 12 * s
                        }
                    }
                }
            }

            // Reflection
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3 * s
                width: parent.width * 0.6
                height: 3 * s
                radius: 2 * s
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#80a0d4f0" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        Item { width: 1 * s; height: 18 * s }

        // Username
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

        // Status
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

        // Password Row
        // Container width: 318 * s (242 box + 38 padding each side to keep box centered)
        Item {
            id: passwordRow
            anchors.horizontalCenter: parent.horizontalCenter
            width: 318 * s
            height: 30 * s

            // Password input box — white translucent Aero style
            Rectangle {
                id: inputBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: 242 * s; height: 30 * s
                color: "transparent"

                // Outer border (blue glass tone)
                Rectangle {
                    anchors.fill: parent
                    radius: 3 * s
                    color: "transparent"
                    border.color: inputFocus.activeFocus ? "#80a0d0ff" : "#50607890"
                    border.width: 1 * s
                }

                // Fill
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1 * s
                    radius: 2 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#e5f8ffff" }
                        GradientStop { position: 0.4; color: "#d0e8f8ff" }
                        GradientStop { position: 1.0; color: "#c8daeeff" }
                    }
                }

                // Inner top highlight line
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1 * s
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 2 * s
                    height: 1 * s
                    color: "#40ffffff"
                    radius: 1 * s
                }

                // Placeholder text
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 9 * s
                    text: "Password"
                    font.family: root.customFontName
                    font.pixelSize: 14 * s
                    color: "#80404050"
                    visible: inputFocus.text === "" && !inputFocus.activeFocus
                }

                // Actual password input
                TextInput {
                    id: inputFocus
                    anchors.fill: parent
                    anchors.leftMargin: 9 * s
                    anchors.rightMargin: 6 * s
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.customFontName
                    font.pixelSize: 14 * s
                    color: "#101820"
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    focus: true
                    clip: true

                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed:  doLogin()
                }
            }

            // Arrow submit button — circular, matches Aero glass palette of Switch User
            Item {
                id: arrowBtn
                anchors.left: inputBox.right
                anchors.leftMargin: 8 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * s; height: 30 * s

                // Outer ring border
                Rectangle {
                    anchors.fill: parent
                    radius: 15 * s
                    color: "transparent"
                    border.color: arrowMouse.containsMouse ? "#90b4d0f0" : "#6090aac8"
                    border.width: 1 * s
                }

                // Glass fill — lighter Aero glass matching Switch User / power buttons
                Rectangle {
                    anchors.fill: parent; anchors.margins: 1 * s
                    radius: 14 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: arrowMouse.containsMouse ? "#99c8e0ff" : "#88b0ccec" }
                        GradientStop { position: 0.5; color: arrowMouse.containsMouse ? "#775888c0" : "#605070b0" }
                        GradientStop { position: 1.0; color: arrowMouse.containsMouse ? "#886898cc" : "#706090c0" }
                    }
                }

                // Top shine
                Rectangle {
                    x: 4 * s; y: 3 * s
                    width: parent.width - 8; height: 10 * s
                    radius: 7 * s
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#55ffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Glyph
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1 * s
                    text: "\u2192"
                    font.pixelSize: 15 * s
                    font.bold: true
                    color: "white"
                    style: Text.Raised
                    styleColor: "#40000000"
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }

                // Scale on hover
                scale: arrowMouse.containsMouse ? 1.10 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            }
        }

        Item { width: 1 * s; height: 8 * s }

        // Message
        Text {
            id: errorMsg
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            visible: false
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

        // Switch User
        Item {
            id: switchUserBtn
            anchors.horizontalCenter: parent.horizontalCenter
            width: switchUserText.implicitWidth + 36
            height: 26 * s

            // Outer border
            Rectangle {
                anchors.fill: parent
                radius: 3 * s
                color: "transparent"
                border.color: switchMouse.containsMouse ? "#80b0ccee" : "#40708898"
                border.width: 1 * s
            }

            // Aero glass fill
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

            // Shine
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
                    // Cycle to next user via tracked property (lastIndex is read-only)
                    if (userModel.rowCount() > 0)
                        root.currentUserIndex = (root.currentUserIndex + 1) % userModel.rowCount()
                }
            }
        }
    } // loginPanel

    // Bottom Bar
    Item {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52 * s
        opacity: root.fadeIn

        // Glass bar background
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#28000010" }
                GradientStop { position: 1.0; color: "#60001030" }
            }
        }

        // Separator line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left; anchors.right: parent.right
            height: 1 * s
            color: "#30a0c8e0"
        }

        // Left: Session selector
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

            // Session pill button
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
                    text: (sessionHelper.currentItem && sessionHelper.currentItem.sName)
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

        // Right: Power buttons
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
    } // bottomBar

    // Logic
    function doLogin() {
        errorMsg.visible = false
        var uname = (userList.currentItem && userList.currentItem.uName)
                    ? userList.currentItem.uName : userModel.lastUser
        sddm.login(uname, inputFocus.text, root.sessionIndex)
    }

    // Win7PowerBtn
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
        // Top shine
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1 * s
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 2 * s; height: 9 * s; radius: 3 * s
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#35ffffff" }
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
