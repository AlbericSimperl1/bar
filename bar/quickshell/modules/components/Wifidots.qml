import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Networking

Item {
    id: wifiDotsRoot

    implicitWidth: 14
    implicitHeight: 22
    Layout.preferredWidth: 14
    Layout.preferredHeight: 22
    Layout.alignment: Qt.AlignHCenter

    signal clicked

    // Haal de Wi-Fi adapter op via Quickshell Networking
    readonly property var wifiDevice: {
        if (!Networking.devices)
            return null;
        var devList = Networking.devices.values;
        for (var i = 0; i < devList.length; i++) {
            if (devList[i] && devList[i].type === DeviceType.Wifi)
                return devList[i];
        }
        return null;
    }

    // Zoek het momenteel verbonden netwerk
    readonly property var connectedWifi: {
        if (!wifiDevice || !wifiDevice.networks)
            return null;
        var netList = wifiDevice.networks.values;
        for (var i = 0; i < netList.length; i++) {
            if (netList[i] && netList[i].connected)
                return netList[i];
        }
        return null;
    }

    readonly property bool isConnected: connectedWifi !== null
    readonly property real signalStrength: connectedWifi ? (connectedWifi.signalStrength || 0) : 0

    // Bepaal het aantal actieve stippen (0 tot 3)
    readonly property int activeDots: {
        if (!isConnected)
            return 0;
        if (signalStrength >= 0.75)
            return 3;
        if (signalStrength >= 0.33)
            return 2;
        return 1;
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        // Bovenste stip
        Rectangle {
            width: 6
            height: 6
            radius: 6
            anchors.horizontalCenter: parent.horizontalCenter
            color: wifiDotsRoot.activeDots >= 3 ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.25)
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        // Middelste stip
        Rectangle {
            width: 6
            height: 6
            radius: 6
            anchors.horizontalCenter: parent.horizontalCenter
            color: wifiDotsRoot.activeDots >= 2 ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.25)
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        // Onderste stip
        Rectangle {
            width: 6
            height: 6
            radius: 6
            anchors.horizontalCenter: parent.horizontalCenter
            color: wifiDotsRoot.activeDots >= 1 ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.25)
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: wifiDotsRoot.clicked()
    }
}
