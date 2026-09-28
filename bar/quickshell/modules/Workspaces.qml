// import QtQuick
// import QtQuick.Layouts
// import Quickshell
// import Quickshell.Hyprland
// import Quickshell.Io  // <-- VOEG DIT TOE
//
// ColumnLayout {
//     id: wsColumn
//     spacing: 4
//     Layout.alignment: Qt.AlignHCenter
//
//     property int persistentCount: 5
//
//     Repeater {
//         model: persistentCount
//         delegate: Rectangle {
//             id: pill
//             required property int index
//             property int wsId: index + 1
//
//             // 1. Is dit de actieve/gefocuste workspace?
//             property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
//
//             // 2. Staan er geopende vensters op dit werkblad?
//             property bool hasWindows: {
//                 if (!Hyprland.toplevels)
//                     return false;
//                 return Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === wsId);
//             }
//
//             property bool hovered: false
//
//             property real targetHeight: isActive ? 50 : (hasWindows ? 30 : 15)
//
//             Behavior on targetHeight {
//                 NumberAnimation {
//                     duration: 100
//                     easing.type: Easing.OutCubic
//                 }
//             }
//
//             Layout.preferredWidth: 6
//             Layout.preferredHeight: targetHeight
//             Layout.alignment: Qt.AlignHCenter
//             radius: 100
//             color: isActive ? "#99ffffff" : (hovered ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.25))
//
//             Behavior on color {
//                 ColorAnimation {
//                     duration: 100
//                 }
//             }
//
//             MouseArea {
//                 anchors.fill: parent
//                 hoverEnabled: true
//                 onEntered: pill.hovered = true
//                 onExited: pill.hovered = false
//
//                 acceptedButtons: Qt.LeftButton | Qt.RightButton
//                 onClicked: mouse => {
//                     if (mouse.button === Qt.LeftButton) {
//                         dispatchProcess.command = ["hyprctl", "dispatch", "hl.dsp.focus({workspace = " + pill.wsId.toString() + "})"];
//                         dispatchProcess.running = true;
//                     } else if (mouse.button === Qt.RightButton) {
//                         dispatchProcess.command = ["hyprctl", "dispatch", "hl.dsp.window.move({workspace = " + pill.wsId.toString() + "})"];
//                         dispatchProcess.running = true;
//                     }
//                 }
//             }
//
//             Process {
//                 id: dispatchProcess
//             }
//         }
//     }
// }

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

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

            // Enkel tonen als de workspace actief is of vensters bevat
            visible: isActive || hasWindows

            property bool hovered: false

            property real targetHeight: isActive ? 90 : (hasWindows ? 60 : 30)

            // Behavior on targetHeight {
            //     NumberAnimation {
            //         duration: 100
            //         easing.type: Easing.OutCubic
            //     }
            // }

            Layout.preferredWidth: 7
            Layout.preferredHeight: targetHeight
            Layout.alignment: Qt.AlignHCenter
            radius: 100
            color: isActive ? "#99ffffff" : (hovered ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.25))

            // Behavior on color {
            //     ColorAnimation {
            //         duration: 100
            //     }
            // }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: pill.hovered = true
                onExited: pill.hovered = false

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
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
