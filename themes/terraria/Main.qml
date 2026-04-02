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
    color: "#000000"

    property real bootProgress: 0
    property real uiOpacity: 0

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string activeUser: userModel.lastUser

    // Background Mode Logic
    readonly property string bgMode: config.background_mode || "random"
    readonly property int bgIndex: {
        if (bgMode === "static") {
            return parseInt(config.background_index) || 1;
        } else if (bgMode === "time") {
            var date = new Date();
            var hour = date.getHours();
            if (hour >= 5 && hour < 9) return 5;      // Early morning (Icy cold mountains)
            if (hour >= 9 && hour < 17) return 1;     // Noonish (Forest mountains)
            if (hour >= 17 && hour < 20) return 3;    // Sunsetish (Halloween land)
            return 4;                                 // Night (Midnight scary)
        } else {
            // Default to random
            return Math.floor(Math.random() * 5) + 1;
        }
    }

    // Palettes
    readonly property var bgPalettes: [
        ["#70e8a0", "#80c8ff", "#ffe870",  "#4caf50", "#81c784", "#a5d6a7", "#6d4c41"],
        ["#b0d8ff", "#e0e8ff", "#fff0c0",  "#78909c", "#90a4ae", "#b0bec5", "#546e7a"],
        ["#ff4040", "#ff8040", "#ffcc80",  "#b71c1c", "#d32f2f", "#8d6e63", "#e0d0b0"],
        ["#a060ff", "#60ffb0", "#c0c0ff",  "#4a148c", "#6a1b9a", "#455a64", "#37474f"],
        ["#80e8ff", "#d0f0ff", "#ffffff",  "#b3e5fc", "#e0f7fa", "#cfd8dc", "#78909c"]
    ]
    // Convenience helpers
    readonly property var activePalette: bgPalettes[bgIndex - 1]
    readonly property color particleA: activePalette[0]
    readonly property color particleB: activePalette[1]
    readonly property color particleC: activePalette[2]
    readonly property color leafA: activePalette[3]
    readonly property color leafB: activePalette[4]
    readonly property color leafC: activePalette[5]
    readonly property color leafD: activePalette[6]
    
    // Colors matching Terraria Reference
    readonly property color txtShadow: "#000000"
    readonly property color txtColor: "#ffffff"
    readonly property color outlineOuter: "#000000"
    readonly property color outlineInner: "#3b4a8e"
    readonly property color panelBg: "#20274e"
    
    readonly property color itemOutlineInner: "#3e4a8d"
    readonly property color itemBg: "#2d3560"
    
    readonly property color highlightOuter: "#000000"
    readonly property color highlightInner: "#fff200"
    readonly property color highlightBg: "#435293"

    readonly property string fontName: mainFont.name

    TextConstants { id: textConstants }

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader { id: mainFont; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }

    ListView {
        id: sessionNameHelper
        model: sessionModel; currentIndex: root.sessionIndex
        visible: false; width: 0 * s; height: 0 * s
        delegate: Item { property string sessionName: model.name || "" }
    }

    // ──────────────────────────────────────────────
    // BACKGROUND SCENE (Terraria-style animated sky)
    // ──────────────────────────────────────────────
    Item {
        id: bgScene
        anchors.fill: parent
        clip: true

        // Image
        Image {
            id: bgImage
            width: parent.width * 1.08; height: parent.height * 1.08
            source: "ter" + root.bgIndex + ".png"
            fillMode: Image.PreserveAspectCrop
            anchors.centerIn: parent
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { from: -bgScene.width * 0.04; to: bgScene.width * 0.04; duration: 40000; easing.type: Easing.InOutSine }
                NumberAnimation { from: bgScene.width * 0.04; to: -bgScene.width * 0.04; duration: 40000; easing.type: Easing.InOutSine }
            }
        }


        // Biomes

        // BG1
        Item {
            anchors.fill: parent; visible: root.bgIndex === 1

            // Soft green/gold fireflies
            Repeater {
                model: 18
                Item {
                    id: ff1
                    property real ffx: Math.random() * root.width
                    property real ffy: root.height * 0.3 + Math.random() * root.height * 0.6
                    property real ffsz: 3 + Math.random() * 3
                    property int ffDur: 3500 + index * 350
                    property int ffDelay: index * 180
                    property color ffCol: index % 3 === 0 ? "#70e8a0" : index % 3 === 1 ? "#ffe870" : "#80c8ff"
                    x: ffx; y: ffy
                    SequentialAnimation on y {
                        loops: Animation.Infinite; PauseAnimation { duration: ff1.ffDelay }
                        NumberAnimation { from: ff1.ffy; to: ff1.ffy - 100; duration: ff1.ffDur * 2; easing.type: Easing.InOutSine }
                        NumberAnimation { from: ff1.ffy - 100; to: ff1.ffy; duration: ff1.ffDur * 2; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation on x {
                        loops: Animation.Infinite; PauseAnimation { duration: ff1.ffDelay }
                        NumberAnimation { from: ff1.ffx - 20; to: ff1.ffx + 20; duration: ff1.ffDur; easing.type: Easing.InOutSine }
                        NumberAnimation { from: ff1.ffx + 20; to: ff1.ffx - 20; duration: ff1.ffDur; easing.type: Easing.InOutSine }
                    }
                    Rectangle { width: ff1.ffsz * 4; height: ff1.ffsz * 4; radius: ff1.ffsz * 2; color: ff1.ffCol; opacity: 0; anchors.centerIn: parent
                        SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: ff1.ffDelay }
                            NumberAnimation { from: 0; to: 0.25; duration: ff1.ffDur; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.25; to: 0; duration: ff1.ffDur; easing.type: Easing.InOutSine } } }
                    Rectangle { width: ff1.ffsz; height: ff1.ffsz; radius: ff1.ffsz / 2; color: ff1.ffCol; anchors.centerIn: parent; opacity: 0
                        SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: ff1.ffDelay }
                            NumberAnimation { from: 0.1; to: 0.9; duration: ff1.ffDur; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.9; to: 0.1; duration: ff1.ffDur; easing.type: Easing.InOutSine } } }
                }
            }
            // Green leaves drifting down
            Repeater {
                model: 14
                Item {
                    id: leaf1
                    property real sx: Math.random() * root.width
                    property int dur: 11000 + index * 700
                    property int del: index * 500
                    property color col: index % 3 === 0 ? "#4caf50" : index % 3 === 1 ? "#81c784" : "#a5d6a7"
                    property real sz: 4 + (index % 3) * 2
                    x: sx; y: -10 * s
                    SequentialAnimation on y { loops: Animation.Infinite; PauseAnimation { duration: leaf1.del }
                        NumberAnimation { from: -10; to: root.height + 10; duration: leaf1.dur; easing.type: Easing.Linear } }
                    SequentialAnimation on x { loops: Animation.Infinite; PauseAnimation { duration: leaf1.del }
                        NumberAnimation { from: leaf1.sx - 25; to: leaf1.sx + 25; duration: leaf1.dur / 3; easing.type: Easing.InOutSine }
                        NumberAnimation { from: leaf1.sx + 25; to: leaf1.sx - 25; duration: leaf1.dur / 3; easing.type: Easing.InOutSine }
                        NumberAnimation { from: leaf1.sx - 25; to: leaf1.sx + 25; duration: leaf1.dur / 3; easing.type: Easing.InOutSine } }
                    Rectangle { width: leaf1.sz; height: leaf1.sz; color: leaf1.col; opacity: 0.8; radius: 1 * s; border.color: Qt.darker(leaf1.col, 1.4); border.width: 1 * s }
                }
            }
        }

        // BG2
        Item {
            anchors.fill: parent; visible: root.bgIndex === 2

            // Fast-moving horizontal wind streaks
            Repeater {
                model: 24
                Rectangle {
                    id: wind2
                    property real sy: 50 + (index * 30) % root.height
                    property int wDur: 1200 + (index % 5) * 300
                    property int wDelay: index * 150
                    width: 150 * s + index * 10; height: 1.2; radius: 1 * s
                    color: "#f0f8ff"; opacity: 0
                    x: -width; y: sy
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        PauseAnimation { duration: wind2.wDelay }
                        NumberAnimation { from: -wind2.width; to: root.width + wind2.width; duration: wind2.wDur; easing.type: Easing.Linear }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation { duration: wind2.wDelay }
                        NumberAnimation { from: 0; to: 0.35; duration: wind2.wDur * 0.1 }
                        NumberAnimation { from: 0.35; to: 0.35; duration: wind2.wDur * 0.8 }
                        NumberAnimation { from: 0.35; to: 0; duration: wind2.wDur * 0.1 }
                    }
                }
            }
        }

        // BG3
        Item {
            anchors.fill: parent; visible: root.bgIndex === 3

            // Bats
            Repeater {
                model: 6
                Item {
                    id: bat3
                    property real by: 50 + index * 65
                    property int bspeed: 16000 + index * 4000
                    property bool flipped: index % 2 === 0
                    y: by; x: flipped ? root.width + 15 : -25
                    NumberAnimation on x { from: bat3.flipped ? root.width + 15 : -25; to: bat3.flipped ? -25 : root.width + 15
                        duration: bat3.bspeed; loops: Animation.Infinite; running: true }
                    SequentialAnimation on y { loops: Animation.Infinite
                        NumberAnimation { from: bat3.by - 20; to: bat3.by + 20; duration: 1200 + index * 200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: bat3.by + 20; to: bat3.by - 20; duration: 1200 + index * 200; easing.type: Easing.InOutSine } }
                    Canvas {
                        width: 18 * s; height: 10 * s
                        transform: Scale { xScale: bat3.flipped ? -1 : 1; origin.x: 9 * s }
                        property real wingA: 0
                        SequentialAnimation on wingA { loops: Animation.Infinite
                            NumberAnimation { from: 0; to: 1; duration: 350 }
                            NumberAnimation { from: 1; to: 0; duration: 350 } }
                        onWingAChanged: requestPaint()
                        onPaint: { var ctx = getContext("2d"); ctx.clearRect(0,0,width,height); ctx.fillStyle = "#1a1010"
                            ctx.beginPath(); ctx.ellipse(7, 5, 4, 2.5); ctx.fill()
                            var wy = 5 - wingA * 6
                            ctx.beginPath(); ctx.moveTo(7,5); ctx.quadraticCurveTo(3,wy,0,6); ctx.lineTo(7,6); ctx.fill()
                            ctx.beginPath(); ctx.moveTo(11,5); ctx.quadraticCurveTo(15,wy,18,6); ctx.lineTo(11,6); ctx.fill() } }
                }
            }
            // Embers
            Repeater {
                model: 20
                Item {
                    id: ember3
                    property real ex: Math.random() * root.width
                    property int eDur: 5000 + index * 500
                    property int eDelay: index * 300
                    property real esz: 2 + Math.random() * 3
                    property color ecol: index % 3 === 0 ? "#ff4040" : index % 3 === 1 ? "#ff8040" : "#ffcc80"
                    x: ex; y: root.height + 5
                    SequentialAnimation on y { loops: Animation.Infinite; PauseAnimation { duration: ember3.eDelay }
                        NumberAnimation { from: root.height + 5; to: -10; duration: ember3.eDur; easing.type: Easing.OutQuad } }
                    SequentialAnimation on x { loops: Animation.Infinite; PauseAnimation { duration: ember3.eDelay }
                        NumberAnimation { from: ember3.ex - 15; to: ember3.ex + 15; duration: ember3.eDur / 3; easing.type: Easing.InOutSine }
                        NumberAnimation { from: ember3.ex + 15; to: ember3.ex - 15; duration: ember3.eDur / 3; easing.type: Easing.InOutSine }
                        NumberAnimation { from: ember3.ex - 15; to: ember3.ex + 15; duration: ember3.eDur / 3; easing.type: Easing.InOutSine } }
                    Rectangle { width: ember3.esz; height: ember3.esz; radius: ember3.esz / 2; color: ember3.ecol; opacity: 0
                        SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: ember3.eDelay }
                            NumberAnimation { from: 0; to: 0.9; duration: ember3.eDur * 0.3 }
                            NumberAnimation { from: 0.9; to: 0; duration: ember3.eDur * 0.7 } } }
                }
            }
        }

        // BG4
        Item {
            anchors.fill: parent; visible: root.bgIndex === 4

            // Wisps
            Repeater {
                model: 15
                Item {
                    id: wisp4
                    property real wx: Math.random() * root.width
                    property real wy: Math.random() * root.height
                    property real wsz: 4 + Math.random() * 5
                    property int wDur: 4000 + index * 500
                    property int wDelay: index * 250
                    property color wcol: index % 3 === 0 ? "#a060ff" : index % 3 === 1 ? "#60ffb0" : "#c0c0ff"
                    x: wx; y: wy
                    SequentialAnimation on y { loops: Animation.Infinite; PauseAnimation { duration: wisp4.wDelay }
                        NumberAnimation { from: wisp4.wy; to: wisp4.wy - 140; duration: wisp4.wDur * 2; easing.type: Easing.InOutSine }
                        NumberAnimation { from: wisp4.wy - 140; to: wisp4.wy; duration: wisp4.wDur * 2; easing.type: Easing.InOutSine } }
                    SequentialAnimation on x { loops: Animation.Infinite; PauseAnimation { duration: wisp4.wDelay }
                        NumberAnimation { from: wisp4.wx - 30; to: wisp4.wx + 30; duration: wisp4.wDur; easing.type: Easing.InOutSine }
                        NumberAnimation { from: wisp4.wx + 30; to: wisp4.wx - 30; duration: wisp4.wDur; easing.type: Easing.InOutSine } }
                    Rectangle { width: wisp4.wsz * 4; height: wisp4.wsz * 4; radius: wisp4.wsz * 2; color: wisp4.wcol; opacity: 0; anchors.centerIn: parent
                        SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: wisp4.wDelay }
                            NumberAnimation { from: 0; to: 0.18; duration: wisp4.wDur; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.18; to: 0; duration: wisp4.wDur; easing.type: Easing.InOutSine } } }
                    Rectangle { width: wisp4.wsz; height: wisp4.wsz; radius: wisp4.wsz / 2; color: wisp4.wcol; anchors.centerIn: parent; opacity: 0
                        SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: wisp4.wDelay }
                            NumberAnimation { from: 0; to: 0.8; duration: wisp4.wDur; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.8; to: 0; duration: wisp4.wDur; easing.type: Easing.InOutSine } } }
                }
            }
            // Moths
            Repeater {
                model: 6
                Item {
                    id: moth4
                    property real my: 100 + index * 80
                    property int mspeed: 16000 + index * 4000
                    property bool flipped: index % 2 === 0
                    y: my; x: flipped ? root.width + 10 : -20
                    NumberAnimation on x { from: moth4.flipped ? root.width + 10 : -20; to: moth4.flipped ? -20 : root.width + 10
                        duration: moth4.mspeed; loops: Animation.Infinite; running: true }
                    SequentialAnimation on y { loops: Animation.Infinite
                        NumberAnimation { from: moth4.my - 12; to: moth4.my + 12; duration: 1000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: moth4.my + 12; to: moth4.my - 12; duration: 1000; easing.type: Easing.InOutSine } }
                    Canvas {
                        width: 14 * s; height: 10 * s
                        transform: Scale { xScale: moth4.flipped ? -1 : 1; origin.x: 7 * s }
                        property real wingA: 0
                        SequentialAnimation on wingA { loops: Animation.Infinite
                            NumberAnimation { from: 0; to: 1; duration: 400 }
                            NumberAnimation { from: 1; to: 0; duration: 400 } }
                        onWingAChanged: requestPaint()
                        onPaint: { var ctx = getContext("2d"); ctx.clearRect(0,0,width,height); ctx.fillStyle = "#c8b8d8"
                            ctx.beginPath(); ctx.ellipse(5, 5, 4, 2); ctx.fill()
                            var wy = 5 - wingA * 5
                            ctx.beginPath(); ctx.moveTo(5,5); ctx.quadraticCurveTo(2,wy,0,6); ctx.lineTo(5,6); ctx.fill()
                            ctx.beginPath(); ctx.moveTo(9,5); ctx.quadraticCurveTo(12,wy,14,6); ctx.lineTo(9,6); ctx.fill() } }
                }
            }
        }

        // BG5
        Item {
            anchors.fill: parent; visible: root.bgIndex === 5

            // Snow
            Repeater {
                model: 30
                Item {
                    id: snow5
                    property real sx: Math.random() * root.width
                    property int sDur: 8000 + index * 400
                    property int sDelay: index * 300
                    property real ssz: 2 + Math.random() * 4
                    x: sx; y: -10 * s
                    SequentialAnimation on y { loops: Animation.Infinite; PauseAnimation { duration: snow5.sDelay }
                        NumberAnimation { from: -10; to: root.height + 10; duration: snow5.sDur; easing.type: Easing.Linear } }
                    SequentialAnimation on x { loops: Animation.Infinite; PauseAnimation { duration: snow5.sDelay }
                        NumberAnimation { from: snow5.sx - 20; to: snow5.sx + 20; duration: snow5.sDur / 3; easing.type: Easing.InOutSine }
                        NumberAnimation { from: snow5.sx + 20; to: snow5.sx - 20; duration: snow5.sDur / 3; easing.type: Easing.InOutSine }
                        NumberAnimation { from: snow5.sx - 20; to: snow5.sx + 20; duration: snow5.sDur / 3; easing.type: Easing.InOutSine } }
                    Rectangle { width: snow5.ssz; height: snow5.ssz; radius: snow5.ssz / 2; color: "#ffffff"; opacity: 0.6 + Math.random() * 0.35 }
                }
            }
            // Aurora
            Repeater {
                model: 4
                Rectangle {
                    id: aurora5
                    property real ax: root.width * 0.1 + index * root.width * 0.2
                    property real ay: 30 + index * 25
                    width: root.width * 0.35; height: 6 * s + index * 2; radius: height / 2
                    x: ax; y: ay
                    color: index % 3 === 0 ? "#80e8ff" : index % 3 === 1 ? "#a0ffb0" : "#d0b0ff"
                    opacity: 0
                    SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: index * 1500 }
                        NumberAnimation { from: 0; to: 0.2; duration: 4000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.2; to: 0; duration: 4000; easing.type: Easing.InOutSine } }
                    SequentialAnimation on x { loops: Animation.Infinite; PauseAnimation { duration: index * 1500 }
                        NumberAnimation { from: aurora5.ax - 30; to: aurora5.ax + 30; duration: 6000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: aurora5.ax + 30; to: aurora5.ax - 30; duration: 6000; easing.type: Easing.InOutSine } }
                }
            }

            // Sparkles
            Repeater {
                model: 25
                Rectangle {
                    id: sparkle5
                    property real sx: Math.random() * root.width
                    property real sy: Math.random() * root.height
                    property int sDur: 2000 + Math.random() * 3000
                    property int sDel: Math.random() * 5000
                    x: sx; y: sy; width: 2 * s; height: 2 * s; color: "#ffffff"; opacity: 0
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation { duration: sparkle5.sDel }
                        NumberAnimation { from: 0; to: 0.8; duration: sparkle5.sDur * 0.2; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.8; to: 0; duration: sparkle5.sDur * 0.8; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 2000 }
                    }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        PauseAnimation { duration: sparkle5.sDel }
                        NumberAnimation { from: 0.5; to: 1.2; duration: sparkle5.sDur * 0.5; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.2; to: 0.5; duration: sparkle5.sDur * 0.5; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }

        // Darken atmospheric overlay
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.18
        }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        opacity: root.uiOpacity

        Component.onCompleted: {
            startupAnim.start()
        }

        SequentialAnimation {
            id: startupAnim
            PauseAnimation { duration: 300 }
            ParallelAnimation {
                NumberAnimation { target: root; property: "uiOpacity"; from: 0; to: 1; duration: 800; easing.type: Easing.OutQuad }
                NumberAnimation { target: layoutCol; property: "scale"; from: 0.95; to: 1.0; duration: 800; easing.type: Easing.OutBack }
            }
        }

        Column {
            id: layoutCol
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 10 * s
            spacing: 20 * s
            z: 100

            // LOGO
            Item {
                width: 700 * s; height: 160 * s
                z: 110
                Image {
                    id: logoImage
                    source: "terraria_logo.png"
                    width: 440 * s; fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    
                    transformOrigin: Item.Center
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.04; duration: 3200; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.04; to: 1.0; duration: 3200; easing.type: Easing.InOutQuad }
                    }
                    SequentialAnimation on rotation {
                        loops: Animation.Infinite
                        NumberAnimation { from: -1.5; to: 1.5; duration: 3500; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.5; to: -1.5; duration: 3500; easing.type: Easing.InOutSine }
                    }

                    // Subtle shadow to add depth while keeping it 'light'
                    DropShadow {
                        anchors.fill: parent
                        transparentBorder: true
                        horizontalOffset: 2; verticalOffset: 2
                        radius: 5 * s; samples: 10; color: Qt.rgba(0,0,0,0.6)
                        source: logoImage
                    }
                }
            }

            // Panel
            Item {
                width: 760 * s; height: 420 * s
                anchors.horizontalCenter: parent.horizontalCenter

                // Bubble
                Item {
                    id: selectBubble
                    width: 280 * s; height: 48 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: -24 * s
                    z: 10
                    
                    Rectangle {
                        anchors.fill: parent; color: root.outlineOuter; radius: 24 * s
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 2 * s; color: root.outlineInner; radius: 22 * s
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 2 * s; color: root.panelBg; radius: 20 * s
                                Text {
                                    text: "Select Player"
                                    anchors.centerIn: parent; anchors.verticalCenterOffset: 2 * s
                                    font.family: mainFont.name; font.pixelSize: 32 * s; color: root.txtColor
                                    style: Text.Outline; styleColor: root.txtShadow
                                }
                            }
                        }
                    }
                }

                // Box
                Rectangle {
                    anchors.fill: parent; color: root.outlineOuter; radius: 14 * s
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 2 * s; color: root.outlineInner; radius: 12 * s
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 2 * s; color: root.panelBg; radius: 10 * s; clip: true

                            // Player List
                            ListView {
                                id: userList
                                width: parent.width; anchors.top: parent.top; anchors.bottom: bottomBar.top
                                anchors.topMargin: 35 * s // Space for bubble
                                anchors.bottomMargin: 5 * s
                                anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 15 * s; anchors.rightMargin: 15 * s
                                model: userModel
                                currentIndex: userModel.lastIndex
                                spacing: 8 * s
                                focus: true

                                delegate: Item {
                                    id: delegateRoot
                                    width: userList.width; height: 110 * s
                                    property alias delegateAvatar: avatarItem
                                    
                                    function jump() { avatarJump.restart() }
                                    
                                    Rectangle {
                                        anchors.fill: parent; color: root.outlineOuter; radius: 10 * s
                                        Rectangle {
                                            id: innerBorder
                                            anchors.fill: parent; anchors.margins: 2 * s; radius: 8 * s
                                            color: (userList.currentIndex === index || rowMouse.containsMouse) ? root.highlightInner : root.itemOutlineInner
                                            
                                            // Selected Pulse Animation
                                            SequentialAnimation on color {
                                                running: userList.currentIndex === index
                                                loops: Animation.Infinite
                                                ColorAnimation { from: root.highlightInner; to: "#a39900"; duration: 800 }
                                                ColorAnimation { from: "#a39900"; to: root.highlightInner; duration: 800 }
                                            }

                                            Rectangle {
                                                anchors.fill: parent; anchors.margins: 2 * s; radius: 6 * s
                                                color: (userList.currentIndex === index || rowMouse.containsMouse) ? root.highlightBg : root.itemBg
                                                
                                                MouseArea {
                                                    id: rowMouse
                                                    anchors.fill: parent; hoverEnabled: true
                                                    onClicked: { userList.currentIndex = index; passwordInput.focus = true }
                                                }

                                                // --- Avatar ---
                                                Rectangle {
                                                    width: 44 * s; height: 44 * s; x: 10 * s; y: 10 * s
                                                    color: root.outlineOuter; radius: 6 * s
                                                    Rectangle {
                                                        anchors.fill: parent; anchors.margins: 2 * s; color: root.itemOutlineInner; radius: 4 * s
                                                        Rectangle {
                                                            anchors.fill: parent; anchors.margins: 2 * s; color: "#11162e"; radius: 2 * s; clip: true
                                                            Item {
                                                                id: avatarItem
                                                                anchors.fill: parent
                                                                function jump() { avatarJump.restart() }
                                                                Image {
                                                                    anchors.fill: parent; source: "avatar.png"; fillMode: Image.PreserveAspectCrop
                                                                    scale: avatarJump.running ? 1.25 : 1.0
                                                                    Behavior on scale { NumberAnimation { duration: 60 } }
                                                                }
                                                                SequentialAnimation {
                                                                    id: avatarJump
                                                                    PauseAnimation { duration: 100 }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // --- Text Details ---
                                                Text {
                                                    x: 64 * s; y: 10 * s
                                                    text: model.realName || model.name
                                                    font.family: mainFont.name; font.pixelSize: 22 * s; color: (userList.currentIndex === index) ? root.highlightInner : root.txtColor
                                                    style: Text.Outline; styleColor: root.txtShadow
                                                }

                                                // Stats Row
                                                Row {
                                                    x: 64 * s; y: 38 * s; spacing: 15 * s
                                                    // Heart + HP
                                                    Row {
                                                        spacing: 4 * s
                                                        Canvas {
                                                            width: 14 * s; height: 14 * s; anchors.verticalCenter: parent.verticalCenter; y: 2 * s
                                                            onPaint: {
                                                                var ctx = getContext("2d"); ctx.fillStyle = "#ff2222"; ctx.strokeStyle = "#000"; ctx.lineWidth=1;
                                                                ctx.beginPath(); ctx.moveTo(7, 4); ctx.bezierCurveTo(7, 1, 1, 1, 1, 6);
                                                                ctx.bezierCurveTo(1, 10, 7, 13, 7, 13); ctx.bezierCurveTo(7, 13, 13, 10, 13, 6);
                                                                ctx.bezierCurveTo(13, 1, 7, 1, 7, 4); ctx.fill(); ctx.stroke();
                                                            }
                                                        }
                                                        Text { text: (index * 100 + 100) + " HP"; font.family: mainFont.name; font.pixelSize: 16 * s; color: "#ffffff"; style: Text.Outline; styleColor: "#000" }
                                                    }
                                                    // Star + MP
                                                    Row {
                                                        spacing: 4 * s
                                                        Canvas {
                                                            width: 14 * s; height: 14 * s; anchors.verticalCenter: parent.verticalCenter; y: 1 * s
                                                            onPaint: {
                                                                var ctx = getContext("2d"); ctx.fillStyle = "#2255ff"; ctx.strokeStyle = "#000"; ctx.lineWidth=1;
                                                                ctx.beginPath();
                                                                for(var i=0; i<5; i++) {
                                                                    ctx.lineTo(Math.cos((18+i*72)/180*Math.PI)*7+7, -Math.sin((18+i*72)/180*Math.PI)*7+7);
                                                                    ctx.lineTo(Math.cos((54+i*72)/180*Math.PI)*3.5+7, -Math.sin((54+i*72)/180*Math.PI)*3.5+7);
                                                                }
                                                                ctx.closePath(); ctx.fill(); ctx.stroke();
                                                            }
                                                        }
                                                        Text { text: (index * 20 + 20) + " MP"; font.family: mainFont.name; font.pixelSize: 16 * s; color: "#ffffff"; style: Text.Outline; styleColor: "#000" }
                                                    }
                                                    Text { text: "Classic"; font.family: mainFont.name; font.pixelSize: 16 * s; color: "#ffffff"; style: Text.Outline; styleColor: "#000" }
                                                }
                                                // Playtime Align Right
                                                Text {
                                                    anchors.right: parent.right; anchors.rightMargin: 14 * s; y: 38 * s
                                                    text: "00:00:00"
                                                    font.family: mainFont.name; font.pixelSize: 16 * s; color: "#ffffff"; style: Text.Outline; styleColor: "#000"
                                                }

                                                // Inner Separator Line
                                                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 2 * s; anchors.rightMargin: 2 * s; height: 2 * s; y: 70 * s; color: root.outlineOuter }
                                                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 2 * s; anchors.rightMargin: 2 * s; height: 2 * s; y: 72 * s; color: root.itemOutlineInner }

                                                // Decorative Small Icons under line
                                                Row {
                                                    x: 10 * s; y: 80 * s; spacing: 6 * s
                                                    
                                                    // Play Icon
                                                    Rectangle {
                                                        width: 16 * s; height: 16 * s; color: root.itemBg; border.color: root.itemOutlineInner; border.width: 1 * s * s; radius: 2 * s
                                                        Rectangle { width: 18 * s; height: 18 * s; color: "transparent"; border.color: root.outlineOuter; radius: 3 * s; anchors.centerIn: parent }
                                                        Canvas {
                                                            width: 10 * s; height: 10 * s; anchors.centerIn: parent
                                                            onPaint: {
                                                                var ctx = getContext("2d"); ctx.fillStyle = "#a8e058"; ctx.strokeStyle = "#000"; ctx.lineWidth = 1;
                                                                ctx.beginPath(); ctx.moveTo(1, 1); ctx.lineTo(9, 5); ctx.lineTo(1, 9); ctx.closePath();
                                                                ctx.fill(); ctx.stroke();
                                                            }
                                                        }
                                                    }
                                                    
                                                    // Favorite (Star)
                                                    Rectangle {
                                                        width: 16 * s; height: 16 * s; color: root.itemBg; border.color: root.itemOutlineInner; border.width: 1 * s * s; radius: 2 * s
                                                        Rectangle { width: 18 * s; height: 18 * s; color: "transparent"; border.color: root.outlineOuter; radius: 3 * s; anchors.centerIn: parent }
                                                        Canvas {
                                                            width: 12 * s; height: 12 * s; anchors.centerIn: parent
                                                            onPaint: {
                                                                var ctx = getContext("2d"); ctx.fillStyle = "#fff200"; ctx.strokeStyle = "#000"; ctx.lineWidth = 1;
                                                                ctx.beginPath();
                                                                for(var i=0; i<5; i++) {
                                                                    ctx.lineTo(Math.cos((18+i*72)/180*Math.PI)*5+6, -Math.sin((18+i*72)/180*Math.PI)*5+6);
                                                                    ctx.lineTo(Math.cos((54+i*72)/180*Math.PI)*2+6, -Math.sin((54+i*72)/180*Math.PI)*2+6);
                                                                }
                                                                ctx.closePath(); ctx.fill(); ctx.stroke();
                                                            }
                                                        }
                                                    }
                                                    
                                                    // Cloud
                                                    Rectangle {
                                                        width: 16 * s; height: 16 * s; color: root.itemBg; border.color: root.itemOutlineInner; border.width: 1 * s * s; radius: 2 * s
                                                        Rectangle { width: 18 * s; height: 18 * s; color: "transparent"; border.color: root.outlineOuter; radius: 3 * s; anchors.centerIn: parent }
                                                        Canvas {
                                                            width: 12 * s; height: 12 * s; anchors.centerIn: parent
                                                            onPaint: {
                                                                var ctx = getContext("2d"); ctx.fillStyle = "#b5c4d6"; ctx.strokeStyle = "#000"; ctx.lineWidth = 1;
                                                                ctx.beginPath(); ctx.arc(6, 6, 3, 0, Math.PI*2); ctx.arc(4, 8, 2, 0, Math.PI*2); ctx.arc(9, 7.5, 2.5, 0, Math.PI*2); 
                                                                ctx.fill(); ctx.stroke();
                                                            }
                                                        }
                                                    }
                                                    
                                                    // Tree / Wood sign
                                                    Rectangle {
                                                        width: 16 * s; height: 16 * s; color: root.itemBg; border.color: root.itemOutlineInner; border.width: 1 * s * s; radius: 2 * s
                                                        Rectangle { width: 18 * s; height: 18 * s; color: "transparent"; border.color: root.outlineOuter; radius: 3 * s; anchors.centerIn: parent }
                                                        Canvas {
                                                            width: 12 * s; height: 12 * s; anchors.centerIn: parent
                                                            onPaint: {
                                                                var ctx = getContext("2d"); 
                                                                ctx.fillStyle = "#7b5b37"; ctx.strokeStyle = "#000"; ctx.lineWidth = 1;
                                                                ctx.beginPath(); ctx.rect(5, 5, 2, 5); ctx.fill(); ctx.stroke();
                                                                ctx.fillStyle = "#5c9f39";
                                                                ctx.beginPath(); ctx.arc(6, 4, 3.5, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                // Decorative Trash bin right
                                                Rectangle {
                                                    anchors.right: parent.right; anchors.rightMargin: 10 * s; y: 80 * s
                                                    width: 16 * s; height: 16 * s; color: root.itemBg; border.color: root.itemOutlineInner; border.width: 1 * s * s; radius: 2 * s
                                                    Rectangle { width: 18 * s; height: 18 * s; color: "transparent"; border.color: root.outlineOuter; radius: 3 * s; anchors.centerIn: parent }
                                                    Canvas {
                                                        width: 10 * s; height: 12 * s; anchors.centerIn: parent
                                                        onPaint: {
                                                            var ctx = getContext("2d"); ctx.fillStyle = "#8a9eb3"; ctx.strokeStyle = "#000"; ctx.lineWidth = 1;
                                                            ctx.beginPath(); ctx.rect(2, 2, 6, 8); ctx.rect(0, 0, 10, 2); ctx.fill(); ctx.stroke();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Password
                            Item {
                                id: bottomBar
                                width: parent.width; height: 38 * s
                                anchors.bottom: parent.bottom

                                Rectangle { width: parent.width; height: 2 * s; y: 0 * s; color: root.outlineOuter }
                                Rectangle { width: parent.width; height: 2 * s; y: 2 * s; color: root.outlineInner }

                                Rectangle {
                                    anchors.fill: parent; anchors.topMargin: 4 * s
                                    color: (passwordInput.activeFocus) ? "#151a37" : "transparent"
                                    
                                    TextInput {
                                        id: passwordInput
                                        anchors.fill: parent; anchors.leftMargin: 14 * s; anchors.rightMargin: 40 * s
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: mainFont.name; font.pixelSize: 20 * s; color: "#ffffff"
                                        echoMode: TextInput.Password; focus: true; passwordCharacter: "*"
                                        clip: true

                                        onTextChanged: {
                                            if (text.length > 0) {
                                                if (userList.currentItem && userList.currentItem.delegateAvatar)
                                                    userList.currentItem.delegateAvatar.jump()
                                            }
                                        }

                                        Text {
                                            text: "Enter Passphrase... "
                                            visible: !parent.text && !parent.activeFocus
                                            color: "#a0a0a0"; font: parent.font; style: Text.Outline; styleColor: "#000"
                                            anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 1 * s
                                        }

                                        Keys.onPressed: {
                                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                var username = userList.model.data(userList.model.index(userList.currentIndex, 0), Qt.UserRole + 1)
                                                sddm.login(username, passwordInput.text, root.sessionIndex)
                                            }
                                        }
                                    }

                                    // Fake submit arrow
                                    Rectangle {
                                        id: submitArrow
                                        anchors.right: parent.right; anchors.rightMargin: 10 * s; anchors.verticalCenter: parent.verticalCenter
                                        width: 26 * s; height: 26 * s; radius: 4 * s; border.color: "#000000"
                                        color: arrowMouse.pressed ? "#1d2540" : (arrowMouse.containsMouse ? "#435293" : "#2d3560")
                                        scale: arrowMouse.pressed ? 0.9 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                        Text { text: "▶"; color: "#fff"; anchors.centerIn: parent; font.pixelSize: 12 * s }
                                        MouseArea {
                                            id: arrowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                var username = userList.model.data(userList.model.index(userList.currentIndex, 0), Qt.UserRole + 1)
                                                sddm.login(username, passwordInput.text, root.sessionIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Big Action Buttons Row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 40 * s

                TerraButton { text: "Poweroff"; fontPixelSize: 32; onClicked: sddm.powerOff() }
                
                // Session dropdown button mapped to World
                TerraButton {
                    text: (sessionNameHelper.currentItem && sessionNameHelper.currentItem.sessionName) ? "World: " + sessionNameHelper.currentItem.sessionName : "Select World"
                    fontPixelSize: 24
                    onClicked: {
                        if (sessionModel && sessionModel.rowCount() > 0) {
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                        }
                    }
                }
                
                TerraButton { 
                    text: "Reboot"; fontPixelSize: 32
                    onClicked: {
                        sddm.reboot()
                    }
                }
            }
        }
    }
}
