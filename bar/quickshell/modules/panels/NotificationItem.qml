import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var notification
    property color fgColor
    property color accentColor
    property string fontFamily

    implicitHeight: rowLayout.implicitHeight + 16
    color: hover.containsMouse ? "#15ffffff" : "transparent"
    radius: 8
    border.color: hover.containsMouse ? accentColor : "transparent"
    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: 100
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                notification.close();
            } else {
                notification.invokeDefaultAction();
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        // Icoon / Afbeelding
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignTop

            Image {
                anchors.fill: parent
                source: root.notification.image || root.notification.icon || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: source.toString().length > 0
            }

            Text {
                anchors.centerIn: parent
                text: "󰂚"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 18
                visible: parent.children[0].status !== Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.notification.appName || "Systeem"
                    color: root.notification.urgency === 2 ? "#ff6666" : root.accentColor
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                text: root.notification.summary
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: root.notification.body
                color: Qt.darker(root.fgColor, 1.2)
                font.family: root.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }
        }
    }
}
