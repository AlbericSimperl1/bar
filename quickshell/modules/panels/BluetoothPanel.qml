import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: bluetoothPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "mononoki"

    // State om apparaten in op te slaan
    property var devices: []

    // Filter functies voor de lijsten
    function getConnectedDevices() {
        return devices.filter(d => d.connected === true);
    }

    function getPairedDevices() {
        return devices.filter(d => d.connected === false);
    }

    // Dit proces runt jouw Rust code en vangt de JSON op
    Process {
        id: btProcess
        // Zorg dat dit pad klopt!
        command: ["/home/alberic/bar/rust/target/debug/bar-backend"]

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

        stderr: SplitParser {
            onRead: line => {
                console.log("[Rust Backend Error]: " + line);
            }
        }
    }

    Component.onCompleted: {
        btProcess.running = true;
    }

    function sendCommand(cmd) {
        btProcess.write(cmd + "\n");
    }

    // UI Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

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

            // Scan Knop (Alleen tekst, geen achtergrond)
            Text {
                text: "Scan"
                color: scanMouseArea.containsMouse ? bluetoothPanelRoot.fgColor : bluetoothPanelRoot.accentColor
                font.family: bluetoothPanelRoot.fontFamily
                font.pixelSize: 14
                MouseArea {
                    id: scanMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: bluetoothPanelRoot.sendCommand("scan")
                }
            }
        }

        // Scrollable gebied voor de apparaten
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: mainColumn.implicitHeight
            interactive: true

            ColumnLayout {
                id: mainColumn
                width: parent.width
                spacing: 20

                // --- SECTIE 1: VERBONDEN APPARATEN ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: bluetoothPanelRoot.getConnectedDevices().length > 0

                    Text {
                        text: "Connected devices"
                        color: bluetoothPanelRoot.dimColor
                        font.family: bluetoothPanelRoot.fontFamily
                        font.pixelSize: 11
                        font.capitalization: Font.AllUppercase
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: bluetoothPanelRoot.getConnectedDevices()

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                Layout.bottomMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon || ""
                                    color: bluetoothPanelRoot.accentColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 18
                                }

                                Text {
                                    text: modelData.name || "Undiscovered device"
                                    color: bluetoothPanelRoot.fgColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Disconnect"
                                    color: disconnectMa.containsMouse ? bluetoothPanelRoot.fgColor : bluetoothPanelRoot.dimColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 13
                                    MouseArea {
                                        id: disconnectMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: bluetoothPanelRoot.sendCommand("disconnect " + modelData.mac)
                                    }
                                }
                            }

                            // De "Trace" (lijn onder het apparaat)
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: bluetoothPanelRoot.lineColor
                            }
                        }
                    }

                    // Als er alleen connected devices zijn, voeg extra ruimte toe
                    Item {
                        Layout.fillHeight: true
                        visible: bluetoothPanelRoot.getPairedDevices().length === 0
                    }
                }

                // --- SECTIE 2: GEKOPPELDE APPARATEN ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: bluetoothPanelRoot.getPairedDevices().length > 0

                    Text {
                        text: "Paired devices"
                        color: bluetoothPanelRoot.dimColor
                        font.family: bluetoothPanelRoot.fontFamily
                        font.pixelSize: 11
                        font.capitalization: Font.AllUppercase
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: bluetoothPanelRoot.getPairedDevices()

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                Layout.bottomMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon || ""
                                    color: bluetoothPanelRoot.fgColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 18
                                }

                                Text {
                                    text: modelData.name || "Undiscovered device"
                                    color: bluetoothPanelRoot.fgColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Unpair"
                                    color: unpairMa.containsMouse ? "#ff5555" : bluetoothPanelRoot.dimColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 13
                                    MouseArea {
                                        id: unpairMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: bluetoothPanelRoot.sendCommand("unpair " + modelData.mac)
                                    }
                                }

                                Text {
                                    text: "Connect"
                                    color: connectMa.containsMouse ? bluetoothPanelRoot.fgColor : bluetoothPanelRoot.accentColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 13
                                    MouseArea {
                                        id: connectMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: bluetoothPanelRoot.sendCommand("connect " + modelData.mac)
                                    }
                                }
                            }

                            // De "Trace" (lijn onder het apparaat)
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: bluetoothPanelRoot.lineColor
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Melding als er helemaal geen apparaten zijn
                Text {
                    visible: bluetoothPanelRoot.devices.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "No devices found"
                    color: bluetoothPanelRoot.dimColor
                    font.family: bluetoothPanelRoot.fontFamily
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
