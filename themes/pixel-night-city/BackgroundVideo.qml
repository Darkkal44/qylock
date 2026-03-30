import QtQuick
import QtQuick.Window
import QtMultimedia

Item {
    readonly property real s: Screen.height / 768
    anchors.fill: parent

    MediaPlayer {
        id: mediaPlayer
        videoOutput: videoWidget 
        source: "bg.mp4"
        loops: MediaPlayer.Infinite
        Component.onCompleted: mediaPlayer.play()
    }

    VideoOutput {
        id: videoWidget
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
