// quickshell/modules/panels/NotificationPanel.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

Item {
    id: rootPanel

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property string fontFamily: "Mononoki Nerd Font Mono"

    readonly property real neededHeight: Math.min(380, mainCol.implicitHeight + 16)

    implicitWidth: parent ? parent.width : 300
    implicitHeight: neededHeight

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 6
                color: Notifications.dndEnabled ? rootPanel.accentColor : "#20ffffff"

                Text {
                    anchors.centerIn: parent
                    text: "󰂛"
                    color: Notifications.dndEnabled ? "#000000" : rootPanel.fgColor
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.toggleDnd()
                }
            }

            Text {
                text: "Notificaties"
                color: rootPanel.fgColor
                font.family: rootPanel.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 70
                implicitHeight: 26
                radius: 6
                color: "#20ffffff"

                Text {
                    anchors.centerIn: parent
                    text: "Wis alles"
                    color: rootPanel.fgColor
                    font.family: rootPanel.fontFamily
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearAll()
                }
            }
        }

        // DND Melding
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: Notifications.dndEnabled ? dndText.implicitHeight + 4 : 0
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                id: dndText
                text: "Niet storen is ingeschakeld"
                color: rootPanel.accentColor
                font.family: rootPanel.fontFamily
                font.pixelSize: 11
                width: parent.width
            }
        }

        // Notificaties Lijst
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 6

                Repeater {
                    model: Notifications.list

                    delegate: Rectangle {
                        required property string title
                        required property string body
                        required property string hash
                        readonly property bool isEmpty: hash === ""

                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + 12
                        radius: 8
                        color: isEmpty ? "transparent" : "#20ffffff"
                        border.width: isEmpty ? 0 : 1
                        border.color: "#1affffff"

                        ColumnLayout {
                            id: cardCol
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            Text {
                                text: title
                                color: rootPanel.fgColor
                                font.family: rootPanel.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: body !== ""
                                text: body
                                color: rootPanel.fgColor
                                opacity: 0.7
                                font.family: rootPanel.fontFamily
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!isEmpty)
                                    Notifications.close(hash);
                            }
                        }
                    }
                }
            }
        }
    }
}
