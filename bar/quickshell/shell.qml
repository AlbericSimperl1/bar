// quickshell/shell.qml
//@ pragma IconTheme MacTahoe-dark
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import "./modules"
import "./modules/components"
import "./modules/bar"
import "./modules/panels"

ShellRoot {
    id: root

    // ---- Kleuren & Instellingen ----
    readonly property color barBg: '#30202227'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color borderCol: "#2cffffff"
    readonly property string fontFamily: "Mononoki Nerd Font Mono"

    readonly property int sidebarWidth: 28
    readonly property int marginSize: 0
    readonly property int barRadius: 8      // Radius voor de bar zelf

    readonly property int panelMaxWidth: 480
    readonly property int panelMaxHeight: 820
    readonly property int panelMinHeight: 140
    readonly property int panelGap: 8
    readonly property int panelRadius: 12   // Radius voor de popup panels

    // MPRIS Active Player
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

        PanelWindow {
            id: sidebarPanel

            required property var modelData

            property bool popoutOpen: false
            property string activePanel: "none" // "media", "bluetooth" of "none"
            property bool hovered: false

            // Direct open of dicht (geen animatie)
            readonly property real openP: popoutOpen ? 1 : 0

            property real panelTopY: 120

            readonly property real contentNeededHeight: activePanel === "media" ? mediaPanel.implicitHeight : activePanel === "bluetooth" ? bluetoothPanel.neededHeight : 0

            // Hoogte van het paneel (geen animatie op panelH)
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

            margins.top: 5
            margins.bottom: 5
            margins.left: 4

            exclusiveZone: root.sidebarWidth + 6

            implicitWidth: root.sidebarWidth + root.panelGap + root.panelMaxWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            // Strakke, niet-geanimeerde maskers voor muisklikken
            mask: Region {
                // Bar gebied
                Region {
                    x: 0
                    y: 0
                    width: root.sidebarWidth
                    height: sidebarBg.height
                }

                // Panel gebied (alleen als hij open is)
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

                    // 1. Normale Rectangle voor de Bar zelf
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

                    // 2. Inhoud van de Balk
                    SidebarContent {
                        id: sidebar
                        activePlayer: root.activePlayer
                        fontFamily: root.fontFamily
                        fgColor: root.fg
                        isMediaOpen: sidebarPanel.popoutOpen && sidebarPanel.activePanel === "media"

                        onMediaClicked: sidebarPanel.togglePanel("media", clickY)
                        onBluetoothClicked: sidebarPanel.togglePanel("bluetooth", clickY)
                    }

                    // 3. Normale Rectangle voor het uitgeklapte Paneel
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

                            // Mediapaneel
                            MediaPanel {
                                id: mediaPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "media"
                                player: root.activePlayer
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }

                            // Bluetoothpaneel
                            BluetoothPanel {
                                id: bluetoothPanel
                                anchors.fill: parent
                                visible: sidebarPanel.activePanel === "bluetooth"
                                fgColor: root.fg
                                accentColor: root.accent
                                fontFamily: root.fontFamily
                            }
                        }
                    }
                }
            }

            // Blur over de bar en eventueel geopende panel
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
