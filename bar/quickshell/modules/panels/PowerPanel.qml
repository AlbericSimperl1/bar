// quickshell/modules/panels/PowerPanel.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Io

Item {
    id: powerPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    readonly property real neededHeight: 220
    property string currentProfile: "balanced"

    // Haalt de initiële status op (als noctalia onder water powerprofilesctl gebruikt)
    Process {
        id: profileProcess
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() !== "")
                    powerPanelRoot.currentProfile = line.trim();
            }
        }
    }

    function setProfile(profile) {
        Quickshell.execDetached(["noctalia", "msg", "power-set", profile]);
        currentProfile = profile;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text {
            text: "Power Management"
            color: powerPanelRoot.fgColor
            font.family: powerPanelRoot.fontFamily
            font.pixelSize: 18
            font.bold: true
            Layout.fillWidth: true
        }

        // --- POWER MODES ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    {
                        name: "Saver",
                        cmd: "power-saver",
                        icon: "󰌪"
                    },
                    {
                        name: "Balanced",
                        cmd: "balanced",
                        icon: "󰾆"
                    },
                    {
                        name: "Perf",
                        cmd: "performance",
                        icon: "󰓅"
                    }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 0
                    color: powerPanelRoot.currentProfile === modelData.cmd ? "#33ffffff" : "transparent"
                    border.color: powerPanelRoot.currentProfile === modelData.cmd ? powerPanelRoot.accentColor : powerPanelRoot.lineColor
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: modelData.icon
                            color: powerPanelRoot.currentProfile === modelData.cmd ? powerPanelRoot.accentColor : powerPanelRoot.fgColor
                            font.family: powerPanelRoot.fontFamily
                            font.pixelSize: 20
                        }

                        Text {
                            text: modelData.name
                            color: powerPanelRoot.currentProfile === modelData.cmd ? powerPanelRoot.accentColor : powerPanelRoot.fgColor
                            font.family: powerPanelRoot.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerPanelRoot.setProfile(modelData.cmd)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: powerPanelRoot.lineColor
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }

        // --- POWER ACTIONS ---
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            Repeater {
                model: [
                    {
                        name: "Lock",
                        icon: "",
                        cmd: ["noctalia", "msg", "session", "lock"]
                    },
                    {
                        name: "Logout",
                        icon: "󰍃",
                        cmd: ["hyprctl", "dispatch", "exit"]
                    },
                    {
                        name: "Suspend",
                        icon: "󰒲",
                        cmd: ["systemctl", "suspend"]
                    },
                    {
                        name: "Reboot",
                        icon: "󰜉",
                        cmd: ["systemctl", "reboot"]
                    },
                    {
                        name: "Shutdown",
                        icon: "⏻",
                        cmd: ["systemctl", "poweroff"],
                        hoverColor: "#ff5555"
                    }
                ]

                delegate: Item {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44

                    Rectangle {
                        anchors.fill: parent
                        radius: 0
                        color: maAction.containsMouse ? "#22ffffff" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: maAction.containsMouse && modelData.hoverColor ? modelData.hoverColor : (maAction.containsMouse ? powerPanelRoot.accentColor : powerPanelRoot.fgColor)
                            font.family: powerPanelRoot.fontFamily
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: maAction
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(modelData.cmd)
                        }
                    }
                }
            }
        }
    }
}
