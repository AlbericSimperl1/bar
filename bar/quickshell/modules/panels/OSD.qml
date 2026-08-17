import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import "../services"

PanelWindow {
    id: osdWindow

    required property var screen
    property string icon: "󰕾"
    property string label: ""
    property real value: 0
    property bool showBar: true

    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: false

    anchors {
        bottom: true
    }
    margins.bottom: 70

    implicitWidth: 240
    implicitHeight: 56

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: osdWindow.visible = false
    }

    function pop(newIcon, newLabel, newValue = 0, hasBar = true) {
        icon = newIcon;
        label = newLabel;
        value = newValue;
        showBar = hasBar;
        osdWindow.visible = true;
        hideTimer.restart();
    }

    Rectangle {
        anchors.fill: parent
        color: "#f0000207"
        radius: 12
        border.color: "#2cffffff"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: osdWindow.icon
                color: "#fff7e5"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: osdWindow.label
                    color: "#fff7e5"
                    font.family: "Mononoki Nerd Font Mono"
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: osdWindow.showBar
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: "#20ffffff"

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, osdWindow.value))
                        height: parent.height
                        radius: 2
                        color: "#ebd9b9"
                    }
                }
            }
        }
    }

    // 1. Volume
    Connections {
        target: Pipewire.defaultAudioSink
        function onVolumeChanged() {
            let sink = Pipewire.defaultAudioSink;
            if (!sink)
                return;
            osdWindow.pop(sink.muted ? "󰝟" : (sink.volume > 0.5 ? "󰕾" : "󰖀"), sink.muted ? "Gedempt" : `Volume ${Math.round(sink.volume * 100)}%`, sink.volume);
        }
    }

    // 2. Brightness
    Connections {
        target: Brightness
        function onChanged(val) {
            osdWindow.pop("󰃠", `Helderheid ${Math.round(val * 100)}%`, val);
        }
    }

    // 3. Media (Afspelen / Pauzeren / Nummer)
    Connections {
        target: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
        function onPlaybackStateChanged() {
            let p = Mpris.players.values[0];
            if (!p)
                return;
            let playing = p.playbackState === MprisPlaybackState.Playing;
            osdWindow.pop(playing ? "󰏤" : "󰐊", playing ? (p.trackTitle || "Media") : "Gepauzeerd", 0, false);
        }
    }

    // 4. Batterij Thresholds
    Connections {
        target: Battery
        function onThresholdReached(percent, msg) {
            osdWindow.pop("󰂃", `${msg} (${percent}%)`, percent / 100.0, true);
        }
    }

    // 5. Bluetooth Apparaten
    Connections {
        target: Bluetooth
        function onDeviceConnected(device) {
            osdWindow.pop("󰂱", `Verbonden: ${device.name || "Apparaat"}`, 0, false);
        }
        function onDeviceDisconnected(device) {
            osdWindow.pop("󰂲", `Ontkoppeld: ${device.name || "Apparaat"}`, 0, false);
        }
    }
}
