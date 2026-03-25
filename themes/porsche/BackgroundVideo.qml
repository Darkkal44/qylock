import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia

Item {
    readonly property real s: Screen.height / 768
    anchors.fill: parent

    MediaPlayer {
        id: player
        source: "bg.mp4"
        videoOutput: output
        loops: MediaPlayer.Infinite
        autoPlay: true
        audioOutput: AudioOutput { muted: true }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
