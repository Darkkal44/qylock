import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia 5.15

Item {
    readonly property real s: Screen.height / 768
    anchors.fill: parent
    Video {
        id: video
        anchors.fill: parent
        source: "bg.mp4"
        autoPlay: true
        loops: MediaPlayer.Infinite
        fillMode: VideoOutput.PreserveAspectCrop
        muted: true
    }
}
