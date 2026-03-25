import QtQuick
import QtMultimedia

Item {
    id: root
    property url source
    property bool autoPlay: false
    property int loops: 1
    property bool muted: false
    property int fillMode: VideoOutput.PreserveAspectFit

    MediaPlayer {
        id: _player
        source: root.source
        loops: root.loops
        autoPlay: root.autoPlay
        videoOutput: _output
        audioOutput: _audio
    }

    AudioOutput {
        id: _audio
        muted: root.muted
    }

    VideoOutput {
        id: _output
        anchors.fill: parent
        fillMode: root.fillMode
    }
}
