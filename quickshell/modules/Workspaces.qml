import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

ColumnLayout {
    id: wsColumn
    spacing: 4
    Layout.alignment: Qt.AlignHCenter

    property int persistentCount: 6

    Repeater {
        model: persistentCount
        delegate: Rectangle {
            id: pill
            required property int index
            property int wsId: index + 1
            property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            property bool isEmpty: {
                for (const ws of Hyprland.workspaces.values) {
                    if (ws.id === wsId)
                        return false;
                }
                return true;
            }
            property bool hovered: false

            // Verticaal: vaste breedte (6px), dynamische hoogte op basis van status
            Layout.preferredWidth: 9
            Layout.preferredHeight: isActive ? 65 : (isEmpty ? 20 : 40)
            Layout.alignment: Qt.AlignHCenter
            radius: 100
            color: isActive ? "#fff7e5" : (hovered ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.25))

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

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
                onClicked: Hyprland.dispatch("workspace " + pill.wsId)
            }
        }
    }
}
