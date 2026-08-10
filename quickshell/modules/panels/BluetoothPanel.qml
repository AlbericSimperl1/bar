import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell

Item {
    id: bluetoothPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property string fontFamily: "mononoki"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Apparatenlijst (Paired & Connected)
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6

            model: Bluetooth.devices.values

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                implicitHeight: 42
                radius: 8
                color: modelData.connected ? "#25ffffff" : "#10ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Text {
                        text: modelData.connected ? "󰂱" : "󰂯"
                        color: modelData.connected ? bluetoothPanelRoot.accentColor : bluetoothPanelRoot.fgColor
                        font.family: bluetoothPanelRoot.fontFamily
                        font.pixelSize: 18
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name !== "" ? modelData.name : modelData.address
                            color: bluetoothPanelRoot.fgColor
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.connected ? "Verbonden" : "Gekoppeld"
                            color: "#80fff7e5"
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    // Connect / Disconnect Knop
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 6
                        color: "#20ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "󰂲" : "󰂱"
                            color: bluetoothPanelRoot.fgColor
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    modelData.disconnect();
                                } else {
                                    modelData.connect();
                                }
                            }
                        }
                    }
                }
            }

            // Melding als er geen apparaten zijn
            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "Geen apparaten gevonden"
                color: "#66fff7e5"
                font.family: bluetoothPanelRoot.fontFamily
            }
        }
    }
}
