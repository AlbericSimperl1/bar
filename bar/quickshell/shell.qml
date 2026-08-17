// quickshell/shell.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import "./modules"
import "./modules/components"
import "./modules/bar"
import "./modules/panels"
import "./modules/services"

ShellRoot {
    id: root

    readonly property color barBg: '#50000207'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color borderCol: "#2cffffff"
    readonly property string fontFamily: "Mononoki Nerd Font Mono"

    readonly property int sidebarWidth: 28
    readonly property int marginSize: 0
    readonly property int barRadius: 8

    readonly property int panelMaxWidth: 480
    readonly property int panelMaxHeight: 420
    readonly property int panelMinHeight: 140
    readonly property int panelGap: 8
    readonly property int panelRadius: 12

    readonly property var activePlayer: {
        const players = Mpris.players.values;
        if (!players || players.length === 0)
            return null;
        for (let p of players) {
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        }
        return players[0];
    }

    Variants {
        model: Quickshell.screens

        OSD {
            screen: modelData
        }

        NotificationToast {
            screen: modelData
        }

        PanelWindow {
            id: sidebarPanel

            required property var modelData

            property bool popoutOpen: false
            property string activePanel: "none"
            property bool hovered: false

            readonly property real openP: popoutOpen ? 1 : 0
            property real panelTopY: 120

            // Hoogteberekening uitgebreid met wifi
            readonly property real contentNeededHeight: activePanel === "media" ? mediaPanel.implicitHeight : activePanel === "bluetooth" ? bluetoothPanel.neededHeight : activePanel === "notifications" ? notificationPanel.neededHeight : activePanel === "wifi" ? wifiPanel.neededHeight : 0
            readonly property real panelH: Math.min(root.panelMaxHeight, Math.max(root.panelMinHeight, contentNeededHeight + 16))

            onPanelHChanged: {
                if (popoutOpen) {
                    const inset = root.barRadius + root.panelRadius + 2;
                    const maxTop = sidebarBg.height - inset - panelH;
                    panelTopY = Math.max(inset, Math.min(panelTopY, maxTop));
                }
            }

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            margins.top: 3
            margins.bottom: 3
            margins.left: 2

            exclusiveZone: root.sidebarWidth + 4
            implicitWidth: root.sidebarWidth + root.panelGap + root.panelMaxWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            mask: Region {
                Region {
                    x: 0
                    y: 0
                    width: root.sidebarWidth
                    height: sidebarBg.height
                }

                Region {
                    x: sidebarPanel.popoutOpen ? (root.sidebarWidth + root.panelGap) : 0
                    y: sidebarPanel.popoutOpen ? sidebarPanel.panelTopY : 0
                    width: sidebarPanel.popoutOpen ? root.panelMaxWidth : 0
                    height: sidebarPanel.popoutOpen ? sidebarPanel.panelH : 0
                }
            }

            Timer {
                id: closeTimer
                interval: 200
                onTriggered: {
                    if (!sidebarPanel.hovered) {
                        sidebarPanel.popoutOpen = false;
                        sidebarPanel.activePanel = "none";
                    }
                }
            }

            onHoveredChanged: {
                if (hovered)
                    closeTimer.stop();
                else if (popoutOpen)
                    closeTimer.start();
            }

            function togglePanel(type, clickY) {
                if (popoutOpen && activePanel === type) {
                    popoutOpen = false;
                    activePanel = "none";
                    return;
                }

                activePanel = type;

                const inset = root.barRadius + root.panelRadius + 2;
                const maxTop = sidebarBg.height - inset - panelH;
                panelTopY = Math.max(inset, Math.min(clickY - panelH / 2, maxTop));
                popoutOpen = true;
            }

            Item {
                id: rootItem
                anchors.fill: parent

                HoverHandler {
                    id: sidebarHover
                    onHoveredChanged: sidebarPanel.hovered = hovered
                }

                Item {
                    id: sidebarBg
                    width: root.sidebarWidth + root.panelGap + root.panelMaxWidth + 4
                    height: parent.height

                    Rectangle {
                        x: 0
                        y: 0
                        width: root.sidebarWidth
                        height: parent.height
                        color: root.barBg
                        radius: root.barRadius
                        border.color: root.borderCol
                        border.width: 1
                    }

                    SidebarContent {
                        id: sidebar
                        activePlayer: root.activePlayer
                        fontFamily: root.fontFamily
                        fgColor: root.fg
                        isMediaOpen: sidebarPanel.popoutOpen && sidebarPanel.activePanel === "media"

                        onMediaClicked: clickY => sidebarPanel.togglePanel("media", clickY)
                        onBluetoothClicked: clickY => sidebarPanel.togglePanel("bluetooth", clickY)
                        onWifiClicked: clickY => sidebarPanel.togglePanel("wifi", clickY)
                        onNotificationsClicked: clickY => sidebarPanel.togglePanel("notifications", clickY)
                    }

                    Rectangle {
                        x: root.sidebarWidth + root.panelGap
                        y: sidebarPanel.panelTopY
                        width: root.panelMaxWidth
                        height: sidebarPanel.panelH
                        color: root.barBg
                        radius: root.panelRadius
                        border.color: root.borderCol
                        border.width: 1
                        visible: sidebarPanel.popoutOpen

                        Item {
                            anchors.fill: parent
                            anchors.margins: 8

                            MediaPanel {
                                id: mediaPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "media"
                                player: root.activePlayer
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            BluetoothPanel {
                                id: bluetoothPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "bluetooth"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            WifiPanel {
                                id: wifiPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "wifi"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            NotificationPanel {
                                id: notificationPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "notifications"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }
                        }
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                Region {
                    x: 0
                    y: 0
                    width: root.sidebarWidth
                    height: sidebarBg.height
                }

                Region {
                    x: sidebarPanel.popoutOpen ? (root.sidebarWidth + root.panelGap) : 0
                    y: sidebarPanel.popoutOpen ? sidebarPanel.panelTopY : 0
                    width: sidebarPanel.popoutOpen ? root.panelMaxWidth : 0
                    height: sidebarPanel.popoutOpen ? sidebarPanel.panelH : 0
                }
            }
        }
    }
}
