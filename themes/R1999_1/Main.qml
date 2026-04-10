import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel

Item {
    id: root
    width: 1920
    height: 1080
    readonly property real s: width / 1920

    // Palette
    readonly property color fg:         "#fdfaf2" 
    readonly property color gold:       "#c9a063" 
    readonly property color goldDim:    "#8c6d45" 
    readonly property color orbitClr:    "#ffffff" 
    
    // State
    property int  userIndex:    userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int  sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool sessionMenuOpen: false
    property bool userMenuOpen: false

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    
    FontLoader {
        id: serifFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }

    ListView { 
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string sName: (model && model.name) ? model.name : ""
        }
    }
    
    ListView { 
        id: userHelper
        model: userModel
        currentIndex: root.userIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item { 
            property string uName: (model && (model.realName || model.name)) ? (model.realName || model.name) : ""
            property string uLogin: (model && model.name) ? model.name : "" 
        } 
    }

    function login() {
        var n = ""
        if (userHelper.currentItem && userHelper.currentItem.uName !== "") {
            n = userHelper.currentItem.uLogin
        } else {
            n = userModel.lastUser
        }
        sddm.login(n, passInput.text, root.sessionIndex)
    }

    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: -1000
    }
    
    MediaPlayer { 
        id: player
        source: "bg.mp4"
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        Component.onCompleted: {
            player.play()
        }
    }
    
    VideoOutput { 
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        z: -500 
    }
    
    Rectangle { 
        anchors.fill: parent
        z: -300
        gradient: Gradient { 
            GradientStop {
                position: 0.0
                color: "#45000000"
            }
            GradientStop {
                position: 1.0
                color: "#75000000"
            }
        } 
    }

    // Clock Widget
    Item {
        id: clockWidget
        anchors.right: parent.right
        anchors.rightMargin: 100 * s
        anchors.top: parent.top
        anchors.topMargin: 100 * s
        width: 450 * s
        height: 250 * s

        Item {
            id: orbitalSpace
            anchors.centerIn: timeLabels
            width: 320 * s
            height: 100 * s
            rotation: -18
            z: 10 

            property real t: 0
            NumberAnimation on t {
                from: 0; to: Math.PI * 2
                duration: 18000
                loops: Animation.Infinite
                running: true
            }

            Shape {
                anchors.fill: parent
                opacity: 0.25
                antialiasing: true
                ShapePath {
                    strokeWidth: 1.2
                    strokeColor: root.orbitClr
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathAngleArc {
                        centerX: 160 * s; centerY: 50 * s
                        radiusX: 160 * s; radiusY: 50 * s
                        startAngle: 0; sweepAngle: 360
                    }
                }
            }

            Rectangle {
                id: traveler
                width: 8 * s; height: 8 * s; radius: 4 * s
                color: root.orbitClr
                opacity: 0.6
                antialiasing: true
                x: (160 * s) + (160 * s * Math.cos(orbitalSpace.t)) - (width / 2)
                y: (50 * s) + (50 * s * Math.sin(orbitalSpace.t)) - (height / 2)
            }
        }

        Row {
            id: timeLabels
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15 * s
            z: 50 

            Text {
                id: hhLab
                text: Qt.formatTime(new Date(), "HH")
                font.family: serifFont.name
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.fg
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
            Text {
                id: mmLab
                text: Qt.formatTime(new Date(), "mm")
                font.family: serifFont.name
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.fg
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
        }

        Column {
            anchors.right: parent.right
            anchors.top: timeLabels.bottom
            anchors.topMargin: 0
            spacing: 5 * s
            z: 100 
            
            Text {
                text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                font.family: serifFont.name
                font.pixelSize: 16 * s
                font.letterSpacing: 8 * s
                color: root.gold
                opacity: 0.8
                anchors.right: parent.right
            }
            
            Row {
                anchors.right: parent.right
                spacing: 12 * s
                Rectangle { width: 40 * s; height: 1; color: root.gold; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: Qt.formatDate(new Date(), "MMM dd yyyy").toUpperCase()
                    font.family: serifFont.name
                    font.pixelSize: 12 * s
                    font.letterSpacing: 4 * s
                    color: root.fg
                    opacity: 0.6
                }
            }
        }

        Timer { 
            interval: 1000
            running: true
            repeat: true
            onTriggered: { 
                hhLab.text = Qt.formatTime(new Date(), "HH")
                mmLab.text = Qt.formatTime(new Date(), "mm") 
            } 
        }
    }

    // Identity System
    Column {
        id: identityStack
        anchors.right: parent.right
        anchors.rightMargin: 100 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s
        spacing: 12 * s
        width: 450 * s

        SequentialAnimation {
            id: typingAnim
            NumberAnimation {
                target: identityStack
                property: "scale"
                from: 1.0; to: 1.01
                duration: 40
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: identityStack
                property: "scale"
                from: 1.01; to: 1.0
                duration: 100
            }
        }

        Item {
            width: parent.width
            height: uLabel.height
            z: 2000
            Text {
                id: uLabel
                text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "UNKNOWN").toUpperCase()
                font.family: serifFont.name
                font.pixelSize: 48 * s
                font.letterSpacing: 4 * s
                color: (root.userMenuOpen || uMa.containsMouse) ? root.gold : root.fg
                anchors.right: parent.right
                scale: uMa.containsMouse ? 1.05 : 1.0
                transformOrigin: Item.Right
                
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
                
                MouseArea {
                    id: uMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.userMenuOpen = !root.userMenuOpen
                    }
                }
            }
            Item {
                id: uMenu
                anchors.bottom: uLabel.top
                anchors.bottomMargin: 20 * s
                anchors.right: parent.right
                width: 320 * s
                height: root.userMenuOpen ? (40 * s * userModel.count) + 20 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.gold
                    opacity: 0.4
                }
                Column {
                    anchors.fill: parent
                    anchors.rightMargin: 15 * s
                    anchors.topMargin: 10 * s
                    spacing: 8 * s
                    Repeater {
                        model: userModel
                        delegate: Item {
                            width: 300 * s
                            height: 32 * s
                            property bool itemHover: uItemMa.containsMouse
                            Text {
                                text: "✦"
                                font.pixelSize: 12 * s
                                color: root.gold
                                anchors.right: parent.right
                                opacity: (root.userIndex === index || uItemMa.containsMouse) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                text: (model.realName || model.name).toUpperCase()
                                font.family: serifFont.name
                                font.pixelSize: 14 * s
                                font.letterSpacing: 2 * s
                                color: root.fg
                                opacity: (root.userIndex === index || uItemMa.containsMouse) ? 1.0 : 0.4
                                anchors.right: parent.right
                                anchors.rightMargin: 25 * s
                                anchors.verticalCenter: parent.verticalCenter
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
        }
        Row {
            anchors.right: parent.right
            spacing: 12 * s
            Rectangle {
                width: 60 * s
                height: 1
                color: root.gold
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "✦"
                font.pixelSize: 10 * s
                color: root.gold
                opacity: 0.4
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 60 * s
                height: 1
                color: root.gold
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Item {
            id: inputWrapper
            width: parent.width
            height: 48 * s
            
            TextInput {
                id: passInput
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignRight
                echoMode: TextInput.Password
                passwordCharacter: "✦"
                font.family: serifFont.name
                font.pixelSize: 22 * s
                font.letterSpacing: 10 * s
                color: root.fg
                focus: true
                
                cursorVisible: false
                cursorDelegate: Item {
                    width: 0; height: 0
                }
                
                selectionColor: root.gold
                
                rightPadding: passInput.text.length > 0 ? 50 * s : 0
                Behavior on rightPadding {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }
                
                onTextChanged: {
                    typingAnim.restart()
                }
                
                onAccepted: {
                    root.login()
                }
                
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "W A I T I N G   F O R   P A S S W O R D"
                    font.family: serifFont.name
                    font.pixelSize: 12 * s
                    font.letterSpacing: 3 * s
                    color: root.gold
                    
                    // CINEMATIC FADE: Restores smoothly when deleting
                    opacity: passInput.text.length === 0 ? 0.4 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.InOutSine
                        }
                    }
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#aa000000"
                        radius: 3
                    }
                }
                
                Rectangle {
                    id: customCursor
                    width: 2 * s
                    height: 24 * s
                    color: root.gold
                    anchors.verticalCenter: parent.verticalCenter
                    x: passInput.cursorRectangle.x
                    visible: passInput.focus && passInput.text.length > 0
                    
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }
            }
            
            Item {
                id: loginBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32 * s
                height: 32 * s
                opacity: passInput.text.length > 0 ? 0.8 : 0
                scale: passInput.text.length > 0 ? 1.0 : 0.8
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutBack
                    }
                }
                
                Text {
                    text: "✦"
                    font.pixelSize: 14 * s
                    color: arrowMa.containsMouse ? root.gold : root.fg
                    anchors.centerIn: parent
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#aa000000"
                        radius: 4
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.gold
                    border.width: 1
                    opacity: 0.2
                    rotation: 45
                }
                
                MouseArea {
                    id: arrowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.login()
                    }
                }
            }
        }
    }

    // Logistics Menu
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 100 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s
        spacing: 15 * s
        z: 1000

        Item {
            width: sLabel.width
            height: sLabel.height
            Text {
                id: sLabel
                text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "WAYLAND").toUpperCase()
                font.family: serifFont.name
                font.pixelSize: 18 * s
                font.letterSpacing: 2 * s
                color: (root.sessionMenuOpen || sMa.containsMouse) ? root.gold : root.fg
                opacity: 0.8
                
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
                
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 4
                }
                
                MouseArea {
                    id: sMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionMenuOpen = !root.sessionMenuOpen
                    }
                }
            }
            Item {
                id: sMenu
                anchors.bottom: parent.top
                anchors.bottomMargin: 20 * s
                anchors.left: parent.left
                width: 320 * s
                height: root.sessionMenuOpen ? (40 * s * sessionModel.count) + 20 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.gold
                    opacity: 0.4
                }
                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 15 * s
                    anchors.topMargin: 10 * s
                    spacing: 8 * s
                    Repeater {
                        model: sessionModel
                        delegate: Item {
                            width: 250 * s
                            height: 32 * s
                            property bool itemHover: mMa.containsMouse
                            Text {
                                text: "✦"
                                font.pixelSize: 12 * s
                                color: root.gold
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: (root.sessionIndex === index || mMa.containsMouse) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                text: model.name.toUpperCase()
                                font.family: serifFont.name
                                font.pixelSize: 14 * s
                                font.letterSpacing: 2 * s
                                color: root.fg
                                opacity: (root.sessionIndex === index || mMa.containsMouse) ? 1.0 : 0.4
                                anchors.left: parent.left
                                anchors.leftMargin: 25 * s
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            MouseArea {
                                id: mMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.sessionIndex = index
                                    root.sessionMenuOpen = false
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            spacing: 25 * s
            Text { 
                text: "REBOOT"
                font.family: serifFont.name
                font.pixelSize: 12 * s
                font.letterSpacing: 2 * s
                color: root.fg
                opacity: rMa.containsMouse ? 1.0 : 0.4
                scale: rMa.containsMouse ? 1.05 : 1.0
                
                Behavior on scale {
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
                
                MouseArea {
                    id: rMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        sddm.reboot()
                    }
                }
            }
            Rectangle {
                width: 1
                height: 10 * s
                color: root.gold
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
            Text { 
                text: "SHUTDOWN"
                font.family: serifFont.name
                font.pixelSize: 12 * s
                font.letterSpacing: 2 * s
                color: root.fg
                opacity: pMa.containsMouse ? 1.0 : 0.4
                scale: pMa.containsMouse ? 1.05 : 1.0
                
                Behavior on scale {
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
                
                MouseArea {
                    id: pMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        sddm.powerOff()
                    }
                }
            }
        }
    }
}
