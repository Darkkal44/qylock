// Ninja Gaiden Theme
import QtQuick 2.15
import QtQuick.Window 2.15
import Qt.labs.folderlistmodel 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#000000"

    readonly property real s: Screen.height / 768

    readonly property color cFg:       "#FFFFFF"
    readonly property color cFgDim:    "#4A4A4A"
    readonly property color cRed:      "#CC0020"
    readonly property color cBacking:  "#0D0003"

    property int sessionIndex: sessionModel && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string currentTime: Qt.formatTime(new Date(), "hh:mm")
    property string currentDate: Qt.formatDate(new Date(), "yyyy.MM.dd")
    property int currentMenu: 0
    property int currentUserIndex: 0

    TextConstants { id: textConstants }

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader { id: customFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    readonly property string fn: customFont.name

    // Auto-focus fix para Quickshell (Loader não propaga focus: true)
    Timer { interval: 300; running: true; onTriggered: pwInput.forceActiveFocus() }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root.currentTime = Qt.formatTime(new Date(), "hh:mm")
            root.currentDate = Qt.formatDate(new Date(), "yyyy.MM.dd")
        }
    }

    ListView {
        id: sessionHelper
        model: sessionModel; currentIndex: root.sessionIndex
        visible: true; width: 1; height: 1; opacity: 0; z: -100
        delegate: Item { property string sName: model.name || "" }
    }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
    }

    Item {
        x: 0; y: 0
        width: root.width * 0.40
        height: root.height
        opacity: 0.7
        Repeater {
            model: 25
            Rectangle {
                id: ember
                property real startY: 0
                property real animDuration: 9000
                property real maxOp: 0.4

                color: root.cRed
                width: 2 * s; height: 2 * s
                radius: width / 2
                opacity: 0

                Component.onCompleted: {
                    x = Math.random() * parent.width
                    startY = root.height * 0.5 + Math.random() * root.height * 0.5
                    animDuration = 10000 + Math.random() * 10000
                    maxOp = Math.random() * 0.5 + 0.15
                    var sz = (Math.random() * 2 + 1) * s
                    width = sz; height = sz; radius = sz / 2

                    yAnim.from = startY
                    yAnim.to = startY - root.height * 0.9
                    yAnim.duration = animDuration
                    opIn.to = maxOp; opIn.duration = animDuration * 0.3
                    opOut.duration = animDuration * 0.7
                    anim.start()
                }
                ParallelAnimation {
                    id: anim
                    loops: Animation.Infinite
                    NumberAnimation { id: yAnim; target: ember; property: "y" }
                    SequentialAnimation {
                        NumberAnimation { id: opIn; target: ember; property: "opacity"; from: 0 }
                        NumberAnimation { id: opOut; target: ember; property: "opacity"; to: 0 }
                        PauseAnimation { duration: Math.random() * 1500 }
                    }
                }
            }
        }
    }

    Item {
        anchors.top: parent.top;    anchors.topMargin:   50 * s
        anchors.right: parent.right; anchors.rightMargin: 50 * s
        width: 320 * s
        height: 110 * s

        Column {
            anchors.right: parent.right; anchors.rightMargin: 20 * s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12 * s

            Row {
                anchors.right: parent.right
                spacing: 15 * s
                
                Text {
                    text: root.currentTime
                    color: root.cFg
                    font.family: root.fn
                    font.pixelSize: 34 * s
                    font.letterSpacing: 4
                    anchors.bottom: parent.bottom; anchors.bottomMargin: -6 * s
                }
                
                Rectangle {
                    width: 2 * s; height: 32 * s
                    color: root.cRed
                    anchors.bottom: parent.bottom
                }
                
                Column {
                    anchors.bottom: parent.bottom
                    spacing: 2 * s
                    Text {
                        text: "SYS // DATE"
                        color: root.cFgDim
                        font.family: root.fn
                        font.pixelSize: 8 * s
                        font.letterSpacing: 2
                    }
                    Text {
                        text: root.currentDate
                        color: root.cRed
                        font.family: root.fn
                        font.pixelSize: 12 * s
                        font.letterSpacing: 2
                    }
                }
            }
            
            Item {
                anchors.right: parent.right
                width: 140 * s
                height: 12 * s
                clip: true
                
                Rectangle {
                    width: parent.width; height: 1
                    color: root.cFgDim; opacity: 0.15
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: slashBlade
                    height: 1.5 * s
                    y: (parent.height - height) / 2
                    
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.6; color: root.cRed }
                        GradientStop { position: 1.0; color: "#FFFFFF" }
                    }

                    SequentialAnimation {
                        id: slashAnim
                        running: false
                        
                        ParallelAnimation {
                            NumberAnimation { target: slashBlade; property: "x"; from: 140 * s; to: 0; duration: 180; easing.type: Easing.OutCubic }
                            NumberAnimation { target: slashBlade; property: "width"; from: 0; to: 140 * s; duration: 180; easing.type: Easing.OutCubic }
                            NumberAnimation { target: slashBlade; property: "opacity"; from: 0.0; to: 1.0; duration: 50 }
                        }
                        
                        ParallelAnimation {
                            NumberAnimation { target: slashBlade; property: "x"; to: 140 * s; duration: 1500; easing.type: Easing.OutSine }
                            NumberAnimation { target: slashBlade; property: "width"; to: 0; duration: 1500; easing.type: Easing.OutSine }
                            NumberAnimation { target: slashBlade; property: "opacity"; to: 0.0; duration: 1000 }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 40 * s
        anchors.right:  parent.right;  anchors.rightMargin:  50 * s
        width: 240 * s
        height: 90 * s

        Column {
            anchors.right: parent.right
            spacing: 6 * s

            Row {
                spacing: 3 * s
                height: 16 * s
                anchors.right: parent.right
                Repeater {
                    model: 7
                    Item {
                        width: 4 * s
                        height: 16 * s
                        Rectangle {
                            width: 4 * s
                            anchors.bottom: parent.bottom
                            color: root.cRed
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                NumberAnimation { to: 3 * s;  duration: 180 + index * 70; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 14 * s; duration: 180 + index * 70; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 200 * s; height: 1
                color: root.cRed
                opacity: 0.5
                anchors.right: parent.right
            }

            Text {
                text: "FIRMWARE VER 2.4.11"
                color: root.cFgDim
                font.family: root.fn
                font.pixelSize: 9 * s
                font.letterSpacing: 2
                anchors.right: parent.right
            }

            Text {
                text: "UNAUTHORIZED ACCESS PROHIBITED"
                color: root.cRed
                font.family: root.fn
                font.pixelSize: 9 * s
                font.letterSpacing: 1
                anchors.right: parent.right
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 900 }
                    NumberAnimation { to: 0.75; duration: 900 }
                }
            }

            Row {
                spacing: 2 * s
                anchors.right: parent.right
                Repeater {
                    model: 24
                    Rectangle {
                        width:  (index % 4 == 0 ? 3 * s : (index % 5 == 0 ? 4 * s : 1.5 * s))
                        height: (index % 3 == 0 ? 20 * s : 14 * s)
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.cFgDim
                    }
                }
            }
        }
    }

    Item {
        id: mainMenuContainer
        width: 600 * s
        height: 5 * 32 * s
        anchors.right:        parent.right
        anchors.rightMargin:  80 * s
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 30 * s

        Rectangle {
            id: divider
            width: 1; height: parent.height
            color: root.cRed
            opacity: 0.6
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        ListView {
            id: menuList
            width: parent.width / 2
            height: parent.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            interactive: false
            focus: true
            clip: false
            currentIndex: 1

            model: ["User Selection", "Passcode", "Desktop Session", "Reboot System", "Shutdown"]

            Keys.onUpPressed:    { currentIndex = Math.max(0, currentIndex - 1); pwInput.focus = false }
            Keys.onDownPressed:  { currentIndex = Math.min(model.length - 1, currentIndex + 1); pwInput.focus = false }
            Keys.onReturnPressed: { handleSelection(currentIndex) }

            delegate: Item {
                id: dlg
                width: menuList.width; height: 32 * s
                property bool isCurrent: menuList.currentIndex === index

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 20 * s
                    anchors.rightMargin: 2 * s
                    opacity: isCurrent ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.6; color: root.cBacking }
                        GradientStop { position: 1.0; color: Qt.rgba(0.8, 0, 0.1, 0.35) }
                    }
                }

                Text {
                    visible: isCurrent
                    text: "◆"
                    font.pixelSize: 5 * s
                    color: root.cRed
                    anchors.right: parent.left; anchors.rightMargin: 6 * s
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.9
                }

                Text {
                    text: modelData
                    font.family: root.fn
                    font.pixelSize: 12 * s
                    font.letterSpacing: 2
                    font.capitalization: Font.AllUppercase
                    color: isCurrent ? root.cFg : root.cFgDim
                    anchors.right: parent.right; anchors.rightMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: menuList.currentIndex = index
                    onClicked: handleSelection(index)
                }
            }
        }

        Item {
            width: parent.width / 2
            height: parent.height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Item {
                width: parent.width; height: 32 * s; y: 0
                Text {
                    visible: menuList.currentIndex !== 0
                    text: userModel && userModel.count > 0 ? userModel.data(userModel.index(root.currentUserIndex, 0), Qt.UserRole + 1) : "—"
                    font.family: root.fn; font.pixelSize: 12 * s
                    color: root.cFgDim
                    anchors.left: parent.left; anchors.leftMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
                ListView {
                    visible: menuList.currentIndex === 0
                    anchors.fill: parent; anchors.leftMargin: 14 * s
                    model: userModel; orientation: ListView.Horizontal; spacing: 14 * s
                    delegate: Text {
                        text: model.name || model.realName
                        color: root.currentUserIndex === index ? root.cFg : root.cFgDim
                        font.family: root.fn; font.pixelSize: 12 * s
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.currentUserIndex = index; menuList.currentIndex = 1; pwInput.forceActiveFocus() }
                        }
                    }
                }
            }

            Item {
                width: parent.width; height: 32 * s; y: 32 * s
                Text {
                    visible: menuList.currentIndex !== 1
                    text: "——————"
                    font.family: root.fn; font.pixelSize: 12 * s
                    color: root.cFgDim; opacity: 0.4
                    anchors.left: parent.left; anchors.leftMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    visible: menuList.currentIndex === 1
                    anchors.fill: parent
                    TextInput {
                        id: pwInput
                        width: parent.width - 28 * s; height: parent.height
                        anchors.left: parent.left; anchors.leftMargin: 14 * s
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.cFg
                        font.family: root.fn; font.pixelSize: 13 * s
                        echoMode: TextInput.Password; passwordCharacter: "▪"
                        focus: menuList.currentIndex === 1
                        verticalAlignment: TextInput.AlignVCenter
                        cursorVisible: activeFocus
                        Text {
                            text: "Enter passcode..."
                            visible: !parent.text && !parent.activeFocus
                            color: root.cFgDim; font: parent.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Keys.onReturnPressed: { doLogin() }
                        Keys.onEscapePressed:  { menuList.focus = true }
                        onTextChanged: {
                            if (text.length > 0) slashAnim.restart()
                        }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 4 * s
                        anchors.left: parent.left; anchors.leftMargin: 14 * s
                        width: parent.width - 28 * s; height: 1
                        color: root.cRed; opacity: 0.5
                    }
                }
            }

            Item {
                width: parent.width; height: 32 * s; y: 64 * s
                Text {
                    visible: menuList.currentIndex !== 2
                    text: sessionHelper.currentItem ? sessionHelper.currentItem.sName : (sessionModel && sessionModel.rowCount() > 0 ? sessionModel.data(sessionModel.index(root.sessionIndex, 0), 257) : "Default")
                    font.family: root.fn; font.pixelSize: 12 * s
                    color: root.cFgDim
                    anchors.left: parent.left; anchors.leftMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    visible: menuList.currentIndex === 2
                    anchors.fill: parent
                    Text {
                        text: sessionHelper.currentItem ? sessionHelper.currentItem.sName : (sessionModel && sessionModel.rowCount() > 0 ? sessionModel.data(sessionModel.index(root.sessionIndex, 0), 257) : "Default")
                        font.family: root.fn; font.pixelSize: 12 * s; color: root.cFg
                        anchors.left: parent.left; anchors.leftMargin: 14 * s
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (sessionModel && sessionModel.rowCount() > 0)
                                    root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                            }
                        }
                    }
                    Text {
                        text: "◂ ▸"
                        font.family: root.fn; font.pixelSize: 10 * s; color: root.cFgDim
                        anchors.left: parent.left; anchors.leftMargin: 110 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item {
                width: parent.width; height: 32 * s; y: 96 * s
                Text {
                    text: "Execute reboot"
                    font.family: root.fn; font.pixelSize: 12 * s
                    color: (menuList.currentIndex === 3 || rebootMa.containsMouse) ? root.cFg : root.cFgDim
                    anchors.left: parent.left; anchors.leftMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea { id: rebootMa; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot() }
                }
            }

            Item {
                width: parent.width; height: 32 * s; y: 128 * s
                Text {
                    text: "Terminate power"
                    font.family: root.fn; font.pixelSize: 12 * s
                    color: (menuList.currentIndex === 4 || pwrMa.containsMouse) ? root.cFg : root.cFgDim
                    anchors.left: parent.left; anchors.leftMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea { id: pwrMa; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff() }
                }
            }
        }
    }

    function handleSelection(index) {
        if (index === 0) {
            if (userModel && userModel.count > 0)
                root.currentUserIndex = (root.currentUserIndex + 1) % userModel.count
        } else if (index === 1) {
            doLogin()
        } else if (index === 2) {
            if (sessionModel && sessionModel.rowCount() > 0)
                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
        } else if (index === 3) {
            sddm.reboot()
        } else if (index === 4) {
            sddm.powerOff()
        }
    }

    function doLogin() {
        if (pwInput.text !== "") {
            var uname = userModel.data(userModel.index(root.currentUserIndex, 0), Qt.UserRole + 1)
            sddm.login(uname, pwInput.text, root.sessionIndex)
        }
    }

    Component.onCompleted: {
        if (userModel && userModel.lastIndex >= 0) root.currentUserIndex = userModel.lastIndex
        pwInput.forceActiveFocus()
    }
}