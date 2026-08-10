import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: bluetoothPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color cardColor: "#15ffffff"
    property string fontFamily: "mononoki"

    // State om apparaten in op te slaan
    property var devices: []

    // Dit proces runt jouw Rust code en vangt de JSON op
    Process {
        id: btProcess
        // PAS DIT AAN naar het absolute pad van jouw gecompileerde Rust binary!
        command: ["/home/alberic/.config/bar/rust/target/debug/bar-backend"]

        stdout: SplitParser {
            onRead: line => {
                try {
                    let state = JSON.parse(line);
                    if (state.devices) {
                        let sortedDevices = [...state.devices].sort((a, b) => {
                            return (a.connected === b.connected) ? 0 : a.connected ? -1 : 1;
                        });
                        bluetoothPanelRoot.devices = sortedDevices;
                    }
                } catch (e) {
                    console.log("JSON Parse error:", e, "Data:", line);
                }
            }
        }

        // Vang ook errors (stderr) op uit Rust
        stderr: SplitParser {
            onRead: line => {
                console.log("[Rust Backend Error]: " + line);
            }
        }
    }

    Component.onCompleted: {
        btProcess.running = true;
    }

    // Hulpfunctie om commando's naar Rust te sturen
    function sendCommand(cmd) {
        btProcess.write(cmd + "\n");
    }

    // UI Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Bluetooth"
                color: bluetoothPanelRoot.fgColor
                font.family: bluetoothPanelRoot.fontFamily
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            // Scan Knop
            Rectangle {
                implicitWidth: 90
                implicitHeight: 34
                radius: 8
                color: scanMouseArea.containsMouse ? "#40ffffff" : "#20ffffff"

                Text {
                    anchors.centerIn: parent
                    text: "󰈬 Scan"
                    color: bluetoothPanelRoot.accentColor
                    font.family: bluetoothPanelRoot.fontFamily
                    font.pixelSize: 13
                }

                MouseArea {
                    id: scanMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bluetoothPanelRoot.sendCommand("scan")
                }
            }
        }

        // Apparatenlijst
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: bluetoothPanelRoot.devices

            delegate: Rectangle {
                required property var modelData
                width: deviceList.width
                height: 60
                radius: 10
                color: modelData.connected ? "#30ffffff" : bluetoothPanelRoot.cardColor
                border.color: modelData.connected ? "#50ebd9b9" : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: modelData.icon || ""
                        color: modelData.connected ? bluetoothPanelRoot.accentColor : bluetoothPanelRoot.fgColor
                        font.family: bluetoothPanelRoot.fontFamily
                        font.pixelSize: 22
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name || "Onbekend apparaat"
                            color: bluetoothPanelRoot.fgColor
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.connected ? "Verbonden" : "Gekoppeld"
                            color: modelData.connected ? bluetoothPanelRoot.accentColor : "#80fff7e5"
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    // Unpair Knop
                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 6
                        color: unpairMouseArea.containsMouse ? "#40ff5555" : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "" // Prullenbak icoon
                            color: "#99fff7e5"
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: unpairMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bluetoothPanelRoot.sendCommand("unpair " + modelData.mac)
                        }
                    }

                    // Connect / Disconnect Knop
                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 6
                        color: connectMouseArea.containsMouse ? "#40ffffff" : "#20ffffff"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "󰂲" : "󰂱"
                            color: bluetoothPanelRoot.fgColor
                            font.family: bluetoothPanelRoot.fontFamily
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: connectMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    bluetoothPanelRoot.sendCommand("disconnect " + modelData.mac);
                                } else {
                                    bluetoothPanelRoot.sendCommand("connect " + modelData.mac);
                                }
                            }
                        }
                    }
                }
            }

            // Melding als er geen apparaten zijn
            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0
                text: "Geen apparaten gevonden"
                color: "#66fff7e5"
                font.family: bluetoothPanelRoot.fontFamily
                font.pixelSize: 14
            }
        }
    }
}
