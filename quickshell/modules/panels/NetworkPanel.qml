import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: networkPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color softFill: "#10ffffff"
    property color borderCol: "#20ffffff"
    property string fontFamily: "mononoki"

    property var networks: []
    property string connectedSsid: ""
    property bool wifiEnabled: false

    Process {
        id: netProcess
        // Zorg dat dit pad klopt!
        command: ["/home/alberic/.config/bar/rust/target/debug/bar-backend"]

    

        stdout: SplitParser {
            onRead: line => {
                try {
                    let payload = JSON.parse(line);
                    // Let op de === "network" check hieronder!
                    if (payload.type === "network" && payload.data) {
                        networkPanelRoot.wifiEnabled = payload.data.wifi_enabled || false;
                        networkPanelRoot.connectedSsid = payload.data.connected_ssid || "";
                        networkPanelRoot.networks = payload.data.networks || [];
                    }
                } catch (e) {
                    console.log("Net JSON Parse error:", e);
                }
            }
        }

        stderr: SplitParser {
            onRead: line => {
                console.log("[Rust Net Error]: " + line);
            }
        }
    }

    Component.onCompleted: {
        netProcess.running = true;
    }

    function sendCommand(cmd) {
        netProcess.write(cmd + "\n");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Wi-Fi"
                color: networkPanelRoot.fgColor
                font.family: networkPanelRoot.fontFamily
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            // Scan Knop
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 1
                color: scanMouseArea.containsMouse ? "#20ffffff" : networkPanelRoot.softFill
                border.color: networkPanelRoot.borderCol
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰑐" // Scan icoon
                    color: networkPanelRoot.accentColor
                    font.family: networkPanelRoot.fontFamily
                    font.pixelSize: 16
                }

                MouseArea {
                    id: scanMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: networkPanelRoot.sendCommand("wifi_scan")
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: networkPanelRoot.borderCol
        }

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

                Repeater {
                    model: networkPanelRoot.networks

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 1

                        // Accent als het de actieve verbinding is
                        color: modelData.active ? Qt.rgba(networkPanelRoot.accentColor.r, networkPanelRoot.accentColor.g, networkPanelRoot.accentColor.b, 0.25) : networkPanelRoot.softFill
                        border.color: modelData.active ? networkPanelRoot.accentColor : networkPanelRoot.borderCol
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 8

                            // Signaal icoon (gebaseerd op sterkte)
                            Text {
                                text: {
                                    if (modelData.signal > 75)
                                        return "󰤨";
                                    if (modelData.signal > 50)
                                        return "󰤥";
                                    if (modelData.signal > 25)
                                        return "󰤤";
                                    return "󰤟";
                                }
                                color: modelData.active ? networkPanelRoot.accentColor : networkPanelRoot.fgColor
                                font.family: networkPanelRoot.fontFamily
                                font.pixelSize: 16
                            }

                            Text {
                                text: modelData.ssid
                                color: networkPanelRoot.fgColor
                                font.family: networkPanelRoot.fontFamily
                                font.pixelSize: 14
                                font.bold: modelData.active
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Slot icoon als beveiligd
                            Text {
                                visible: modelData.secured
                                text: "󰌾"
                                color: networkPanelRoot.dimColor
                                font.family: networkPanelRoot.fontFamily
                                font.pixelSize: 14
                            }

                            // Connect/Disconnect Knop
                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 1
                                color: connectMa.containsMouse ? "#20ffffff" : "transparent"
                                border.color: networkPanelRoot.borderCol
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.active ? "󰂲" : "󰂱"
                                    color: networkPanelRoot.fgColor
                                    font.family: networkPanelRoot.fontFamily
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: connectMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (!modelData.active) {
                                            networkPanelRoot.sendCommand("wifi_connect " + modelData.ssid);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: networkPanelRoot.networks.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    text: "Geen netwerken gevonden"
                    color: networkPanelRoot.dimColor
                    font.family: networkPanelRoot.fontFamily
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
