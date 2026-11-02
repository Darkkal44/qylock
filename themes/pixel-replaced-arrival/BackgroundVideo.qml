import QtQuick
import QtQuick.Window
import QtMultimedia

Item {
    anchors.fill: parent

    // Статичный последний кадр (по умолчанию скрыт)
    Image {
        id: lastFrame
        anchors.fill: parent
        source: "lastframe.png"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    // Вывод видео
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: !lastFrame.visible
    }

    MediaPlayer {
        id: player
        source: "bg.mp4"
        autoPlay: true
        loops: 1
        videoOutput: videoOutput

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                // Сначала показываем изображение...
                lastFrame.visible = true

                // ...затем останавливаем плеер
                stop()
            }
        }
    }
}
