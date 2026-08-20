import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root
    property color fgColor
    property color accentColor
    property string fontFamily

    // Noodzakelijk voor je berekening op regel 52 in shell.qml
    property real neededHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notificaties"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "󰩹"
                color: clearMouse.containsMouse ? "#ff6666" : root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 16

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        const notifs = NotificationServer.notifications;
                        for (let i = notifs.length - 1; i >= 0; i--) {
                            notifs[i].close();
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#2cffffff"
        }

        // Lege status
        Text {
            visible: NotificationServer.notifications.length === 0
            text: "De Herald rust, geen notificaties"
            color: Qt.darker(root.fgColor, 1.5)
            font.family: root.fontFamily
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 60
            verticalAlignment: Text.AlignVCenter
        }

        // Dynamische notificatielijst
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            Layout.maximumHeight: root.height - 40
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: NotificationServer.notifications
            visible: NotificationServer.notifications.length > 0

            delegate: NotificationItem {
                width: listView.width
                notification: modelData
                fgColor: root.fgColor
                accentColor: root.accentColor
                fontFamily: root.fontFamily
            }
        }
    }
}
