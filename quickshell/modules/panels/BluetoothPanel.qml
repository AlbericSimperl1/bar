import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: bluetoothPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color softFill: "#10ffffff"     // Achtergrondkleur van de hokjes
    property color borderCol: "#20ffffff"    // Randkleur van de hokjes
    property string fontFamily: "mononoki"

    property var devices: []

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
        command: ["/home/alberic/.config/bar/rust/target/debug/bar-backend"]

        stdout: SplitParser {
            onRead: line => {
                try {
                    let state = JSON.parse(line);
                    if (state.devices) {
                        bluetoothPanelRoot.devices = [...state.devices];
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
        anchors.margins: 12
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Bluetooth"
                color: bluetoothPanelRoot.fgColor
                font.family: bluetoothPanelRoot.fontFamily
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            // Scan Knop (Hokje stijl)
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 1
                color: scanMouseArea.containsMouse ? "#20ffffff" : bluetoothPanelRoot.softFill
                border.color: bluetoothPanelRoot.borderCol
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰑐" // Scan icoon
                    color: bluetoothPanelRoot.accentColor
                    font.family: bluetoothPanelRoot.fontFamily
                    font.pixelSize: 16
                }

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
                spacing: 12

                // --- SECTIE 1: VERBONDEN APPARATEN ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: bluetoothPanelRoot.getConnectedDevices().length > 0

                    Text {
                        text: "CONNECTED"
                        color: bluetoothPanelRoot.dimColor
                        font.family: bluetoothPanelRoot.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        Layout.leftMargin: 4
                    }

                    Repeater {
                        model: bluetoothPanelRoot.getConnectedDevices()

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 1
                            // Lichte accentkleur achtergrond als verbonden
                            color: Qt.rgba(bluetoothPanelRoot.accentColor.r, bluetoothPanelRoot.accentColor.g, bluetoothPanelRoot.accentColor.b, 0.25)
                            border.color: bluetoothPanelRoot.accentColor
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 8

                                Text {
                                    text: modelData.icon || "󰂱"
                                    color: bluetoothPanelRoot.accentColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: modelData.name || "Undiscovered"
                                    color: bluetoothPanelRoot.fgColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Disconnect Knop (Hokje)
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 1
                                    color: disconnectMa.containsMouse ? "#20ffffff" : "transparent"
                                    border.color: bluetoothPanelRoot.borderCol
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰂲" // Disconnect icoon
                                        color: bluetoothPanelRoot.fgColor
                                        font.family: bluetoothPanelRoot.fontFamily
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: disconnectMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: bluetoothPanelRoot.sendCommand("disconnect " + modelData.mac)
                                    }
                                }
                            }
                        }
                    }
                }

                // --- SECTIE 2: GEKOPPELDE APPARATEN ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: bluetoothPanelRoot.getPairedDevices().length > 0

                    Text {
                        text: "PAIRED"
                        color: bluetoothPanelRoot.dimColor
                        font.family: bluetoothPanelRoot.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        Layout.leftMargin: 4
                    }

                    Repeater {
                        model: bluetoothPanelRoot.getPairedDevices()

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 1
                            color: bluetoothPanelRoot.softFill
                            border.color: bluetoothPanelRoot.borderCol
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 8

                                Text {
                                    text: modelData.icon || "󰂱"
                                    color: bluetoothPanelRoot.fgColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: modelData.name || "Undiscovered"
                                    color: bluetoothPanelRoot.fgColor
                                    font.family: bluetoothPanelRoot.fontFamily
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Unpair Knop (Hokje)
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 1
                                    color: unpairMa.containsMouse ? "#40ff5555" : "transparent"
                                    border.color: bluetoothPanelRoot.borderCol
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "" // Prullenbak icoon
                                        color: "#99fff7e5"
                                        font.family: bluetoothPanelRoot.fontFamily
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: unpairMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: bluetoothPanelRoot.sendCommand("unpair " + modelData.mac)
                                    }
                                }

                                // Connect Knop (Hokje)
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 1
                                    color: connectMa.containsMouse ? "#20ffffff" : "transparent"
                                    border.color: bluetoothPanelRoot.borderCol
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰂱" // Connect icoon
                                        color: bluetoothPanelRoot.fgColor
                                        font.family: bluetoothPanelRoot.fontFamily
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: connectMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: bluetoothPanelRoot.sendCommand("connect " + modelData.mac)
                                    }
                                }
                            }
                        }
                    }
                }

                // Melding als er geen apparaten zijn
                Text {
                    visible: bluetoothPanelRoot.devices.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    text: "NO DEVICES FOUND"
                    color: bluetoothPanelRoot.dimColor
                    font.family: bluetoothPanelRoot.fontFamily
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
