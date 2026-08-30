// Ported from dumidulkdev/omarchy-orbital-lock (MIT): https://github.com/dumidulkdev/omarchy-orbital-lock.git
// Unchanged from the Omarchy Orbital Lock screen.
import QtQuick
import "ClockMath.js" as ClockMath

Item {
  id: root

  property var currentTime: new Date()
  property color foreground: "white"
  property color muted: Qt.rgba(1, 1, 1, 0.3)
  property bool showSecondsRing: true
  property bool authenticating: false
  property string hourFormat: "24"
  property real authBoost: 0

  readonly property real u: width / 960
  readonly property real minuteRadius: 305 * u
  readonly property real secondRadius: 445 * u
  readonly property real minuteRotation: ClockMath.visibleEdgeRotation(ClockMath.minuteAngle(currentTime)) - authBoost * 0.45
  readonly property real secondRotation: ClockMath.visibleEdgeRotation(ClockMath.secondAngle(currentTime)) - authBoost

  function alphaColor(colorValue, opacity) {
    return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
  }

  NumberAnimation {
    id: authenticationSpin
    target: root
    property: "authBoost"
    from: 0
    to: 360
    duration: 850
    loops: Animation.Infinite
    running: root.authenticating
    easing.type: Easing.InOutSine
    onStopped: root.authBoost = 0
  }

  Item {
    id: secondRing
    anchors.centerIn: parent
    width: root.secondRadius * 2
    height: width
    rotation: root.secondRotation
    visible: root.showSecondsRing

    Repeater {
      model: 60

      delegate: Item {
        required property int index
        readonly property real baseAngle: index * 6
        readonly property real radians: (baseAngle - 90) * Math.PI / 180
        readonly property bool major: index % 5 === 0
        readonly property real highlight: Math.max(0, 1 - ClockMath.angularDistance(baseAngle + secondRing.rotation, 0) / 24)
        x: secondRing.width / 2 + Math.cos(radians) * root.secondRadius
        y: secondRing.height / 2 + Math.sin(radians) * root.secondRadius

        Rectangle {
          anchors.centerIn: parent
          width: parent.major ? 2.2 * root.u : 1.2 * root.u
          height: parent.major ? 15 * root.u : 8 * root.u
          radius: width / 2
          rotation: parent.baseAngle
          color: root.foreground
          opacity: parent.major ? 0.28 + parent.highlight * 0.62 : 0.12 + parent.highlight * 0.42
        }

        Text {
          visible: parent.major
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.verticalCenter
          anchors.topMargin: 15 * root.u
          text: String(parent.index).padStart(2, "0")
          color: root.foreground
          opacity: 0.24 + parent.highlight * 0.76
          font.pixelSize: 16 * root.u
          font.weight: parent.highlight > 0.55 ? Font.Bold : Font.Normal
          font.letterSpacing: 1.5 * root.u
          rotation: parent.baseAngle
        }
      }
    }
  }

  Item {
    id: minuteRing
    anchors.centerIn: parent
    width: root.minuteRadius * 2
    height: width
    rotation: root.minuteRotation

    Repeater {
      model: 60

      delegate: Item {
        required property int index
        readonly property real baseAngle: index * 6
        readonly property real radians: (baseAngle - 90) * Math.PI / 180
        readonly property bool major: index % 5 === 0
        readonly property real highlight: Math.max(0, 1 - ClockMath.angularDistance(baseAngle + minuteRing.rotation, 0) / 24)
        x: minuteRing.width / 2 + Math.cos(radians) * root.minuteRadius
        y: minuteRing.height / 2 + Math.sin(radians) * root.minuteRadius

        Rectangle {
          anchors.centerIn: parent
          width: parent.major ? 3 * root.u : 1.5 * root.u
          height: parent.major ? 20 * root.u : 11 * root.u
          radius: width / 2
          rotation: parent.baseAngle
          color: root.foreground
          opacity: parent.major ? 0.34 + parent.highlight * 0.66 : 0.15 + parent.highlight * 0.48
        }

        Text {
          visible: parent.major
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.verticalCenter
          anchors.bottomMargin: 17 * root.u
          text: String(parent.index).padStart(2, "0")
          color: root.foreground
          opacity: 0.3 + parent.highlight * 0.7
          font.pixelSize: 23 * root.u
          font.weight: parent.highlight > 0.55 ? Font.Bold : Font.Normal
          font.letterSpacing: 2 * root.u
          rotation: parent.baseAngle
        }
      }
    }
  }

  Text {
    x: parent.width / 2 + 72 * root.u
    anchors.verticalCenter: parent.verticalCenter
    text: ClockMath.hourText(root.currentTime, root.hourFormat)
    color: root.foreground
    font.pixelSize: 118 * root.u
    font.weight: Font.Black
    font.letterSpacing: -7 * root.u
  }

}
