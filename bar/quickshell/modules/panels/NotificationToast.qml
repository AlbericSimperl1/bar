// quickshell/modules/panels/NotificationToast.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: toastWindow
    visible: Notifications.activeToasts.count > 0
    implicitWidth: 300
    implicitHeight: 600
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.namespace: "quickshell:toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }
    margins {
        top: 16
        right: 16
    }

    ColumnLayout {
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifications.activeToasts

            delegate: Rectangle {
                required property string hash
                required property string title
                required property string body
                required property int timeout

                Layout.fillWidth: true
                implicitHeight: col.implicitHeight + 16
                radius: 10
                color: "#f0000207"
                border.color: "#ebd9b9"
                border.width: 1

                Column {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Text {
                        text: title
                        color: "#fff7e5"
                        font.family: "Mononoki Nerd Font Mono"
                        font.pixelSize: 13
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: body !== ""
                        text: body
                        color: "#a0fff7e5"
                        font.family: "Mononoki Nerd Font Mono"
                        font.pixelSize: 11
                        width: parent.width
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                Timer {
                    interval: timeout > 0 ? timeout : 4000
                    running: true
                    onTriggered: Notifications.dismissToast(hash)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifications.dismissToast(hash)
                }
            }
        }
    }
}
