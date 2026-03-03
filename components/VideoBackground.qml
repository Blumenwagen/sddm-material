import QtQuick 2.15
import QtMultimedia 5.15

Video {
    id: videoBackground
    property string videoSource: ""

    anchors.fill: parent
    source: videoSource
    fillMode: VideoOutput.PreserveAspectCrop
    loops: MediaPlayer.Infinite
    muted: true

    onSourceChanged: {
        if (source.toString() !== "") {
            play();
        }
    }
}
