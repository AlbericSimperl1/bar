import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: notificationsPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "mononoki"

    property var notifications: []
    property var tempNotifications: []
    property var currentNotif: null

    function fetchHistory() {
        tempNotifications = [];
        currentNotif = null;
        makoProc.running = false;
        makoProc.running = true;
    }

    // Leest de platte tekst van makoctl geschiedenis direct uit
    Process {
        id: makoProc
        command: ["makoctl", "history"]

        stdout: SplitParser {
            onRead: line => {
                let match = line.match(/^Notification (\d+): (.*)$/);
                if (match) {
                    if (notificationsPanelRoot.currentNotif) {
                        notificationsPanelRoot.tempNotifications.push(notificationsPanelRoot.currentNotif);
                    }
                    notificationsPanelRoot.currentNotif = {
                        id: match[1],
                        summary: match[2],
                        appName: "",
                        body: ""
                    };
                    return;
                }

                if (!notificationsPanelRoot.currentNotif)
                    return;

                let trimmed = line.trim();
                if (trimmed.startsWith("App name:")) {
                    notificationsPanelRoot.currentNotif.appName = trimmed.substring(9).trim();
                } else if (trimmed.startsWith("Body:")) {
                    notificationsPanelRoot.currentNotif.body = trimmed.substring(5).trim();
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (notificationsPanelRoot.currentNotif) {
                notificationsPanelRoot.tempNotifications.push(notificationsPanelRoot.currentNotif);
                notificationsPanelRoot.currentNotif = null;
            }
            notificationsPanelRoot.notifications = notificationsPanelRoot.tempNotifications;
        }
    }

    // Ververs automatisch zodra het paneel zichtbaar is
    Timer {
        interval: 1500
        running: notificationsPanelRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: notificationsPanelRoot.fetchHistory()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Notifications"
                color: notificationsPanelRoot.fgColor
                font.family: notificationsPanelRoot.fontFamily
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Clear all"
                color: clearMa.containsMouse ? notificationsPanelRoot.fgColor : notificationsPanelRoot.dimColor
                font.family: notificationsPanelRoot.fontFamily
                font.pixelSize: 13
                visible: notificationsPanelRoot.notifications.length > 0

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(["makoctl", "dismiss", "-a"]);
                        notificationsPanelRoot.notifications = [];
                    }
                }
            }
        }

        // Lijst van notificaties
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: notificationsPanelRoot.notifications

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                implicitHeight: cardCol.implicitHeight + 18
                color: "#12ffffff"
                radius: 8

                ColumnLayout {
                    id: cardCol
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 10
                    }
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: modelData.appName !== "" ? modelData.appName : "Notificatie"
                            color: notificationsPanelRoot.accentColor
                            font.family: notificationsPanelRoot.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "✕"
                            color: dismissItemMa.containsMouse ? "#ff5555" : notificationsPanelRoot.dimColor
                            font.pixelSize: 12

                            MouseArea {
                                id: dismissItemMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.id) {
                                        Quickshell.execDetached(["makoctl", "dismiss", "-i", modelData.id.toString()]);
                                        notificationsPanelRoot.fetchHistory();
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: modelData.summary || ""
                        color: notificationsPanelRoot.fgColor
                        font.family: notificationsPanelRoot.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        visible: text !== ""
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.body || ""
                        color: notificationsPanelRoot.fgColor
                        font.family: notificationsPanelRoot.fontFamily
                        font.pixelSize: 12
                        opacity: 0.85
                        wrapMode: Text.Wrap
                        visible: text !== ""
                        Layout.fillWidth: true
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: notificationsPanelRoot.notifications.length === 0
                text: "No notifications"
                color: notificationsPanelRoot.dimColor
                font.family: notificationsPanelRoot.fontFamily
                font.pixelSize: 14
            }
        }
    }
}
