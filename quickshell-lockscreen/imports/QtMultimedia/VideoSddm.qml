// SDDM-compatible Video shim — no Quickshell dependency.
// Copied into SDDM theme directories as QylockVideo.qml by the Nix build.
// Video files are co-located with the theme, so relative URLs resolve fine.
import QtQuick
import QtMultimedia

Item {
    id: root
    property url source
    property bool autoPlay: false
    property int loops: 1
    property bool muted: false
    property real volume: 1.0
    property int fillMode: 2

    MediaPlayer {
        id: _player
        source: root.source
        loops: root.loops
        videoOutput: _output
        audioOutput: _audio
    }

    AudioOutput {
        id: _audio
        muted: root.muted
        volume: root.volume
    }

    VideoOutput {
        id: _output
        anchors.fill: parent
        fillMode: root.fillMode
    }

    Component.onCompleted: {
        if (root.autoPlay)
            _player.play()
    }
}
