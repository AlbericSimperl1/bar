// quickshell/modules/panels/NotificationPanel.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

Item {
    id: notificationPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "Mononoki Nerd Font Mono"

    readonly property real neededHeight: Math.min(420, Math.max(140, (layoutRoot.anchors.margins * 2) + headerRow.implicitHeight + layoutRoot.spacing + mainColumn.implicitHeight))

    ColumnLayout {
        id: layoutRoot
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Notificaties"
                color: notificationPanelRoot.fgColor
                font.family: notificationPanelRoot.fontFamily
                font.pixelSize: 19
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: Notifications.dndEnabled ? "󰂛 DND Aan" : "󰂚 DND Uit"
                color: dndMa.containsMouse ? notificationPanelRoot.fgColor : (Notifications.dndEnabled ? notificationPanelRoot.accentColor : notificationPanelRoot.dimColor)
                font.family: notificationPanelRoot.fontFamily
                font.pixelSize: 13

                MouseArea {
                    id: dndMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Notifications.toggleDnd()
                }
            }

            Text {
                text: "•"
                color: notificationPanelRoot.dimColor
                font.pixelSize: 11
            }

            Text {
                text: "Wis alles"
                color: clearMa.containsMouse ? "#ff5555" : notificationPanelRoot.dimColor
                font.family: notificationPanelRoot.fontFamily
                font.pixelSize: 13

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
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
                color: notificationPanelRoot.accentColor
                font.family: notificationPanelRoot.fontFamily
                font.pixelSize: 11
                width: parent.width
            }
        }

        // Scrollbaar gebied
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: mainColumn.implicitHeight
            interactive: true

            ColumnLayout {
                id: mainColumn
                width: parent.width
                spacing: 12

                Repeater {
                    model: Notifications.list

                    delegate: ColumnLayout {
                        required property string title
                        required property string body
                        required property string hash

                        // Optionele velden (als de service deze meestuurt)
                        property string icon: ""
                        property string timeAgo: ""

                        readonly property bool isEmpty: hash === ""

                        Layout.fillWidth: true
                        spacing: 0
                        visible: !isEmpty

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            Layout.bottomMargin: 12
                            spacing: 10

                            // App Icoon
                            Text {
                                text: icon !== "" ? icon : "󰂚"
                                color: notificationPanelRoot.accentColor
                                font.family: notificationPanelRoot.fontFamily
                                font.pixelSize: 18
                            }

                            // Bericht inhoud
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: title
                                        color: notificationPanelRoot.fgColor
                                        font.family: notificationPanelRoot.fontFamily
                                        font.pixelSize: 14
                                        font.bold: true
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: timeAgo !== ""
                                        text: timeAgo
                                        color: notificationPanelRoot.dimColor
                                        font.family: notificationPanelRoot.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    visible: body !== ""
                                    text: body
                                    color: notificationPanelRoot.dimColor
                                    font.family: notificationPanelRoot.fontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                            }

                            // Sluit knop
                            Text {
                                text: "✕"
                                color: closeMa.containsMouse ? "#ff5555" : notificationPanelRoot.dimColor
                                font.family: notificationPanelRoot.fontFamily
                                font.pixelSize: 13

                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (!isEmpty)
                                            Notifications.close(hash);
                                    }
                                }
                            }
                        }

                        // Trace lijn onder elk item
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: notificationPanelRoot.lineColor
                        }
                    }
                }

                // Lege staat
                Text {
                    visible: Notifications.list.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: "Geen notificaties"
                    color: notificationPanelRoot.dimColor
                    font.family: notificationPanelRoot.fontFamily
                    font.pixelSize: 22
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
