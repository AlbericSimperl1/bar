// quickshell/modules/panels/WifiPanel.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

Item {
    id: wifiPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "Mononoki Nerd Font Mono"

    readonly property real neededHeight: Math.min(420, Math.max(140, (layoutRoot.anchors.margins * 2) + headerRow.implicitHeight + layoutRoot.spacing + mainColumn.implicitHeight))

    // Filtert verborgen SSIDs en pakt per unieke SSID het sterkste signaal
    function getCleanedList(rawList) {
        if (!rawList)
            return [];
        let uniqueMap = {};

        for (let i = 0; i < rawList.length; i++) {
            let item = rawList[i];
            let ssid = (item.ssid ?? "").trim();

            // Negeer lege of verborgen netwerken
            if (!ssid || ssid === "--")
                continue;

            let signal = item.signal ?? 0;

            // Onthoud alleen als SSID nieuw is of het signaal beter is
            if (!uniqueMap[ssid] || signal > (uniqueMap[ssid].signal ?? 0)) {
                uniqueMap[ssid] = item;
            }
        }

        // Zet om naar array en sorteer op signaalsterkte (hoog naar laag)
        let result = Object.keys(uniqueMap).map(key => uniqueMap[key]);
        result.sort((a, b) => (b.signal ?? 0) - (a.signal ?? 0));
        return result;
    }

    ColumnLayout {
        id: layoutRoot
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Wi-Fi"
                color: wifiPanelRoot.fgColor
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 19
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: Wifi.radioOn ? "󰤨 Wi-Fi Aan" : "󰤭 Wi-Fi Uit"
                color: radioMa.containsMouse ? wifiPanelRoot.fgColor : (Wifi.radioOn ? wifiPanelRoot.accentColor : wifiPanelRoot.dimColor)
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 13

                MouseArea {
                    id: radioMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Wifi.toggleRadio()
                }
            }

            Text {
                text: "•"
                color: wifiPanelRoot.dimColor
                font.pixelSize: 11
            }

            Text {
                text: Wifi.liveMode ? "󰑐 Live Scan" : "󰋚 Opgeslagen"
                color: modeMa.containsMouse ? wifiPanelRoot.fgColor : wifiPanelRoot.dimColor
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 13

                MouseArea {
                    id: modeMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Wifi.toggleLiveMode()
                }
            }
        }

        // Statusbalk voor actieve verbinding
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: Wifi.connected ? statusText.implicitHeight + 4 : 0
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                id: statusText
                text: "Verbonden met: " + Wifi.ssid
                color: wifiPanelRoot.accentColor
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 11
                width: parent.width
            }
        }

        // Scrollbaar gebied
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

                // Gebruikt nu getCleanedList() om dubbelen en '--' te verwijderen
                Repeater {
                    model: wifiPanelRoot.getCleanedList(Wifi.liveMode ? Wifi.scanList : Wifi.history)

                    delegate: ColumnLayout {
                        required property var modelData

                        readonly property string itemSsid: modelData.ssid ?? ""
                        readonly property var itemSignal: modelData.signal ?? null
                        readonly property bool isConnected: Wifi.ssid === itemSsid
                        readonly property bool isSecured: modelData.security && modelData.security !== "Open" && modelData.security !== "none"

                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            Layout.bottomMargin: 12
                            spacing: 10

                            Text {
                                text: isConnected ? "󰤨" : (itemSignal ? (itemSignal > 65 ? "󰤨" : itemSignal > 35 ? "󰤥" : "󰤢") : "󰤨")
                                color: isConnected ? wifiPanelRoot.accentColor : wifiPanelRoot.fgColor
                                font.family: wifiPanelRoot.fontFamily
                                font.pixelSize: 18
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: itemSsid
                                        color: wifiPanelRoot.fgColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 14
                                        font.bold: isConnected
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: itemSignal !== null
                                        text: itemSignal + "%"
                                        color: wifiPanelRoot.dimColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        visible: isSecured
                                        text: "󰌾"
                                        color: wifiPanelRoot.dimColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            Text {
                                text: isConnected ? "Ontkoppelen" : "Verbinden"
                                color: actionMa.containsMouse ? wifiPanelRoot.accentColor : wifiPanelRoot.dimColor
                                font.family: wifiPanelRoot.fontFamily
                                font.pixelSize: 12

                                MouseArea {
                                    id: actionMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (isConnected) {
                                            Wifi.disconnect(itemSsid);
                                        } else {
                                            Wifi.connectTo(itemSsid);
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: !Wifi.liveMode
                                text: "✕"
                                color: forgetMa.containsMouse ? "#ff5555" : wifiPanelRoot.dimColor
                                font.family: wifiPanelRoot.fontFamily
                                font.pixelSize: 13

                                MouseArea {
                                    id: forgetMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: Wifi.forget(itemSsid)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: wifiPanelRoot.lineColor
                        }
                    }
                }

                Text {
                    visible: wifiPanelRoot.getCleanedList(Wifi.liveMode ? Wifi.scanList : Wifi.history).length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: Wifi.liveMode ? "Scannen naar netwerken..." : "Geen opgeslagen netwerken"
                    color: wifiPanelRoot.dimColor
                    font.family: wifiPanelRoot.fontFamily
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
