import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io  // <-- VOEG DIT TOE

ColumnLayout {
    id: wsColumn
    spacing: 4
    Layout.alignment: Qt.AlignHCenter

    property int persistentCount: 9

    Repeater {
        model: persistentCount
        delegate: Rectangle {
            id: pill
            required property int index
            property int wsId: index + 1

            // 1. Is dit de actieve/gefocuste workspace?
            property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId

            // 2. Staan er geopende vensters op dit werkblad?
            property bool hasWindows: {
                if (!Hyprland.toplevels)
                    return false;
                return Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === wsId);
            }

            property bool hovered: false

            // Drie dynamische hoogtes:
            // - Actieve workspace: 65px
            // - Niet-actief maar WEL met open venster(s): 40px
            // - Niet-actief en HELEMAAL leeg: 20px
            property real targetHeight: isActive ? 65 : (hasWindows ? 40 : 20)

            Behavior on targetHeight {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Layout.preferredWidth: 9
            Layout.preferredHeight: targetHeight
            Layout.alignment: Qt.AlignHCenter
            radius: 100
            color: isActive ? "#99ffffff" : (hovered ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.25))

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: pill.hovered = true
                onExited: pill.hovered = false

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    // Hyprland >= 0.55 gebruikt Lua-dispatchers (hl.dsp.*) i.p.v. de oude
                    // platte "workspace 2" / "movetoworkspace 2" strings. Daarom via hyprctl
                    // met een Lua-expressie als argument i.p.v. Hyprland.dispatch().
                    if (mouse.button === Qt.LeftButton) {
                        dispatchProcess.command = ["hyprctl", "dispatch", "hl.dsp.focus({workspace = " + pill.wsId.toString() + "})"];
                        dispatchProcess.running = true;
                    } else if (mouse.button === Qt.RightButton) {
                        dispatchProcess.command = ["hyprctl", "dispatch", "hl.dsp.window.move({workspace = " + pill.wsId.toString() + "})"];
                        dispatchProcess.running = true;
                    }
                }
            }

            Process {
                id: dispatchProcess
            }
        }
    }
}
