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
    readonly property string fontFamily: "mononoki"

    readonly property int sidebarWidth: 28
    readonly property int marginSize: 0
    readonly property int cornerRadius: 6

    readonly property int panelMaxWidth: 480
    readonly property int panelMaxHeight: 820
    readonly property int filletRadius: 16
    readonly property int panelRadius: 12

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
            property real openP: popoutOpen ? 1 : 0
            Behavior on openP {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }

            property real panelTopY: 120
            property real panelH: 585

            readonly property real morphW: root.panelMaxWidth * openP
            readonly property real morphF: root.filletRadius * openP
            readonly property real morphR: root.panelRadius * openP

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            margins.top: 5
            margins.bottom: 5
            margins.left: 4

            // Vaste exclusiveZone: enkel de balkbreedte wordt gereserveerd
            exclusiveZone: root.sidebarWidth + 6

            implicitWidth: root.sidebarWidth + root.panelMaxWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            mask: Region {
                x: 0
                y: 0
                width: root.sidebarWidth
                height: sidebarBg.height

                Region {
                    x: root.sidebarWidth
                    y: sidebarPanel.panelTopY
                    width: sidebarPanel.morphW
                    height: sidebarBg.height - sidebarPanel.panelTopY
                }

                Region {
                    x: root.sidebarWidth
                    y: sidebarPanel.panelTopY - sidebarPanel.morphF
                    width: sidebarPanel.morphF
                    height: sidebarPanel.morphF
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

            // Generieke toggle-functie voor alle panelen
            function togglePanel(type, clickY) {
                if (popoutOpen && activePanel === type) {
                    popoutOpen = false;
                    activePanel = "none";
                    return;
                }

                const inset = root.cornerRadius + root.filletRadius + 2;
                const targetH = sidebarBg.height - inset - Math.max(inset, Math.min(clickY - 130, sidebarBg.height - 520 - inset));

                panelH = Math.min(root.panelMaxHeight, targetH);
                panelTopY = Math.max(inset, Math.min(clickY - 130, sidebarBg.height - panelH - inset));
                activePanel = type;
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
                    width: root.sidebarWidth + root.panelMaxWidth + 4
                    height: parent.height

                    // 1. De Vorm / Achtergrond
                    MorphShape {
                        id: morphShape
                        sidebarWidth: root.sidebarWidth
                        cornerRadius: root.cornerRadius
                        morphW: sidebarPanel.morphW
                        morphF: sidebarPanel.morphF
                        morphR: sidebarPanel.morphR
                        panelTopY: sidebarPanel.panelTopY
                        panelH: sidebarPanel.panelH
                        barBg: root.barBg
                        borderCol: root.borderCol
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

                    // 3. Uitgeklapt Inhoudspaneel
                    Item {
                        x: root.sidebarWidth + 8
                        y: sidebarPanel.panelTopY + 8
                        width: root.panelMaxWidth - 16
                        height: sidebarPanel.panelH - 16

                        readonly property real contentP: Math.max(0, Math.min(1, (sidebarPanel.openP - 0.5) * 2))

                        visible: contentP > 0
                        opacity: contentP

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

            // BLUR-REGIO: balk + paneel + bovenjunction
            BackgroundEffect.blurRegion: Region {
                x: 0
                y: 0
                width: root.sidebarWidth
                height: sidebarBg.height

                Region {
                    x: root.sidebarWidth
                    y: sidebarPanel.panelTopY
                    width: sidebarPanel.morphW
                    height: sidebarBg.height - sidebarPanel.panelTopY
                }

                Region {
                    x: root.sidebarWidth
                    y: sidebarPanel.panelTopY - sidebarPanel.morphF
                    width: sidebarPanel.morphF
                    height: sidebarPanel.morphF
                }
            }
        }
    }
}
