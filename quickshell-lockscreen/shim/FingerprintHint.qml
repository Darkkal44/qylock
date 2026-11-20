import QtQuick
import Quickshell

Item {
    id: root

    required property var fingerprint
    readonly property bool hintEnabled: (Quickshell.env("QS_FINGERPRINT_HINT") || "1") !== "0"
    readonly property bool shown: hintEnabled && fingerprint.enabled && fingerprint.available
        && fingerprint.status !== "idle" && fingerprint.status !== "success"

    readonly property string text: {
        switch (fingerprint.status) {
        case "waiting":
            return "Touch the fingerprint sensor to unlock";
        case "failed":
            return "Fingerprint not recognised (" + fingerprint.tries + "/" + fingerprint.maxTries + ")";
        case "exhausted":
            return "Too many fingerprint attempts, use your password";
        case "error":
            return fingerprint.message ? "Fingerprint: " + fingerprint.message : "Fingerprint reader unavailable";
        default:
            return "";
        }
    }

    anchors.fill: parent

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: row.implicitWidth + 36
        height: row.implicitHeight + 18
        radius: height / 2
        color: "#a6000000"
        border.color: "#33ffffff"
        border.width: 1
        opacity: root.shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                id: dot
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: root.fingerprint.status === "waiting" ? "#8be9a8" : "#ffb4ab"

                SequentialAnimation on opacity {
                    running: root.fingerprint.status === "waiting" && root.shown
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: root.text
                color: root.fingerprint.status === "waiting" ? "#e8e8e8" : "#ffb4ab"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
