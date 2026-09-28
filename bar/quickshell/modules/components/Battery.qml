import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
    id: batteryPill

    readonly property var battery: UPower.displayDevice
    readonly property real percentage: battery ? battery.percentage : 0
    readonly property bool isCharging: battery ? (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged) : false

    implicitWidth: isCharging ? 18 : 6
    implicitHeight: isCharging ? 20 : 35

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignHCenter

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    // icon (net)
    Text {
        anchors.centerIn: parent
        visible: batteryPill.isCharging
        text: "󱐋"
        color: Qt.rgba(1, 1, 1, 0.95)
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 16
    }

    // pill (battery)
    Rectangle {
        id: bgPill
        anchors.fill: parent
        radius: 100
        color: Qt.rgba(1, 1, 1, 0.25)
        visible: !batteryPill.isCharging
        clip: true

        Rectangle {
            id: fillPill
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: parent.height * Math.max(0.05, batteryPill.percentage)
            radius: 100

            color: {
                if (batteryPill.percentage > 0.50) {
                    return Qt.rgba(1, 1, 1, 0.55);
                } else if (batteryPill.percentage >= 0.25) {
                    return "#e6c641";
                } else {
                    return "#e64141";
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }
    }
}
