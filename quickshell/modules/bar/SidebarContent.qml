import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

import ".."
import "../components"

Item {
    id: barRoot

    // --- RUST INTEGRATIE ---
    // Definieer de naam of het absolute pad van je Rust executable hier centraal.
    property string rustCmd: "noctalia"

    property var activePlayer: null
    property string fontFamily: "mononoki"
    property color fgColor: "#fff7e5"
    property bool isMediaOpen: false
    signal mediaClicked(real clickY)
    signal bluetoothClicked(real clickY)

    width: 38
    implicitWidth: 38
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.topMargin: 16
    anchors.bottomMargin: 16

    // 1. BOVENAAN: Workspaces
    Workspaces {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // 2. exact IN HET MIDDEN VAN DE BALK: Klok
    Clock {
        id: clock
        anchors.centerIn: parent
        fontFamily: barRoot.fontFamily
        fgColor: barRoot.fgColor
    }

    // 3. ONDERAAN: Snelkoppelingen & Icoontjes
    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: 20

        // Media Trigger Container
        Item {
            id: mediaWidget
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 24
            implicitHeight: 24

            readonly property string artUrl: barRoot.activePlayer && barRoot.activePlayer.trackArtUrl ? barRoot.activePlayer.trackArtUrl : ""

            Item {
                anchors.fill: parent
                opacity: barRoot.isMediaOpen ? 0 : 1

                Image {
                    id: mediaArt
                    anchors.fill: parent
                    source: mediaWidget.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 6
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: mediaArt
                    maskSource: maskRect
                    visible: mediaArt.status === Image.Ready && mediaWidget.artUrl !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: mediaArt.status !== Image.Ready || mediaWidget.artUrl === ""
                    text: "󰎈"
                    color: barRoot.fgColor
                    font.family: barRoot.fontFamily
                    font.pixelSize: 23
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = mediaWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.mediaClicked(mapped.y + mediaWidget.height / 2);
                }
            }
        }

        // Audio {}

        // Bluetooth
        Text {
            id: bluetoothWidget
            text: ""
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = bluetoothWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.bluetoothClicked(mapped.y + bluetoothWidget.height / 2);
                }
            }
        }

        // // Settings / System
        // Text {
        //     text: "⚙"
        //     color: barRoot.fgColor
        //     font.family: barRoot.fontFamily
        //     font.pixelSize: 23
        //     Layout.alignment: Qt.AlignHCenter
        //     MouseArea {
        //         anchors.fill: parent
        //         cursorShape: Qt.PointingHandCursor
        //         onClicked: Quickshell.execDetached([barRoot.rustCmd, "msg", "panel-toggle", "control-center"])
        //     }
        // }

        // Notifications
        Text {
            text: "󰂚"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached([barRoot.rustCmd, "msg", "panel-toggle", "tray-drawer"])
            }
        }

        // Session / Power
        Text {
            text: "⏻"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["wlogout", "-b", "5"])
            }
        }
    }
}
