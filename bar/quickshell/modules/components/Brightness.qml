// quickshell/modules/components/BrightnessWidget.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell

Item {
    id: brightnessWidgetRoot

    implicitWidth: 20
    implicitHeight: 20
    Layout.preferredWidth: 20
    Layout.preferredHeight: 20
    Layout.alignment: Qt.AlignHCenter

    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"

    property int currentBrightness: 50
    property bool nightlightActive: false

    signal clicked
    signal rightClicked

    // Bepaal het dynamische icoon in 4 stappen (zon vs maan)
    readonly property string icon: {
        let step = Math.min(3, Math.floor(currentBrightness / 25.01));
        if (nightlightActive) {
            let moonIcons = ["󰽤", "󰽥", "󰽦", "󰽢"];
            return moonIcons[step];
        } else {
            let sunIcons = ["󰃞", "󰃟", "󰃝", "󰃠"];
            return sunIcons[step];
        }
    }

    Text {
        anchors.centerIn: parent
        text: brightnessWidgetRoot.icon
        color: brightnessWidgetRoot.nightlightActive ? brightnessWidgetRoot.accentColor : brightnessWidgetRoot.fgColor
        font.family: brightnessWidgetRoot.fontFamily
        font.pixelSize: 23

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                brightnessWidgetRoot.clicked();
            } else if (mouse.button === Qt.RightButton) {
                brightnessWidgetRoot.nightlightActive = !brightnessWidgetRoot.nightlightActive;
                Quickshell.execDetached(["noctalia", "msg", "nightlight-force-toggle"]);
                brightnessWidgetRoot.rightClicked();
            }
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                brightnessWidgetRoot.currentBrightness = Math.min(100, brightnessWidgetRoot.currentBrightness + 5);
                Quickshell.execDetached(["noctalia", "msg", "brightness-up"]);
            } else if (wheel.angleDelta.y < 0) {
                brightnessWidgetRoot.currentBrightness = Math.max(0, brightnessWidgetRoot.currentBrightness - 5);
                Quickshell.execDetached(["noctalia", "msg", "brightness-down"]);
            }
        }
    }
}
