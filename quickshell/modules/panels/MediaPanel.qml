import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Item {
    id: root

    implicitWidth: 420
    implicitHeight: 380

    property color fgColor: "#fff7e5"
    property color mutedColor: Qt.rgba(1, 0.95, 0.82, 0.78)
    property color accentColor: "#ebd9b9"
    property color cavaColor: "#bbbbbb"
    property string fontFamily: "mononoki"
    property var player
    property var cavaBars: []

    // -------------------------------------------------------------
    // MPRIS LOGICA
    // -------------------------------------------------------------
    readonly property var ignoredPlayers: ["zen-browser", "firefox", "youtube"]

    readonly property var activePlayer: {
        const players = Mpris.players.values || [];
        let fallback = null;
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (!p)
                continue;
            const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase();
            if (ignoredPlayers.some(name => id.includes(name)))
                continue;
            if (p.isPlaying)
                return p;
            if (!fallback && p.playbackState !== MprisPlaybackState.Stopped)
                fallback = p;
        }
        return fallback;
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property string trackTitle: hasPlayer && activePlayer.trackTitle ? activePlayer.trackTitle : "Geen nummer"
    readonly property string trackArtist: hasPlayer && activePlayer.trackArtist ? activePlayer.trackArtist : "Onbekende artiest"
    readonly property string artUrl: hasPlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
    readonly property real trackLength: hasPlayer && activePlayer.lengthSupported ? Math.max(0, activePlayer.length) : 0
    readonly property bool canSeek: hasPlayer && activePlayer.canSeek && trackLength > 0
    property real trackPosition: 0

    // -------------------------------------------------------------
    // BAR ICON COMPONENT (Noctalia-style Album Art voor in je statusbar)
    // -------------------------------------------------------------
    property Component barItem: Component {
        Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 6
            color: "transparent"
            clip: true

            Image {
                id: barArt
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready && root.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: !barArt.visible
                text: "\uf001"
                color: root.fgColor
                font.family: root.fontFamily
                font.pixelSize: 14
            }
        }
    }

    function syncPosition() {
        if (!activePlayer || !activePlayer.positionSupported) {
            trackPosition = 0;
            return;
        }
        trackPosition = Math.max(0, activePlayer.position);
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            if (root.isPlaying && root.trackLength > 0)
                root.trackPosition = Math.min(root.trackLength, root.trackPosition + 0.5);
            else
                root.syncPosition();
        }
    }

    Connections {
        target: root.activePlayer
        enabled: root.activePlayer !== null
        function onPositionChanged() {
            root.syncPosition();
        }
        function onTrackTitleChanged() {
            root.syncPosition();
        }
    }

    // -------------------------------------------------------------
    // CAVA PROCESS INTEGRATIE
    // -------------------------------------------------------------
    Process {
        id: cavaProc
        running: root.isPlaying
        command: ["bash", "-lc", "cfg=$(mktemp); " + "printf '%s\\n' '[general]' 'bars = 52' 'framerate = 60' 'sensitivity = 160' " + "'[input]' 'method = pipewire' '[output]' 'method = raw' 'raw_target = /dev/stdout' " + "'data_format = ascii' 'ascii_max_range = 12' 'bar_delimiter = 59' 'frame_delimiter = 10' 'channels = mono' " + "'[smoothing]' 'integral = 70' 'monstercat = 1' > \"$cfg\"; " + "cava -p \"$cfg\"; code=$?; rm -f \"$cfg\"; exit $code"]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(";");
                const vals = [];
                for (let i = 0; i < parts.length; i++) {
                    const v = parseInt(parts[i]);
                    vals.push(isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 12)));
                }
                root.cavaBars = vals;
            }
        }
    }

    // -------------------------------------------------------------
    // HOOFDINDELING (Sleek layout zonder achtergrondkaarten)
    // -------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 16

        // LINKER KOLOM: Media Bediening & Artwork
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Album Art (met afgeronde hoeken via OpacityMask)
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 235
                Layout.preferredHeight: 235

                // 1. Bron-afbeelding (verborgen, dient als input)
                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                // 2. Het masker dat de ronding van de hoeken bepaalt
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 22 // Pas hier de hoeveelheid afronding aan
                    visible: false
                }

                // 3. De afgeronde afbeelding
                OpacityMask {
                    anchors.fill: parent
                    source: albumArt
                    maskSource: maskRect
                    visible: albumArt.status === Image.Ready && root.artUrl !== ""
                }

                // 4. Fallback wanneer er geen hoesje is
                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: "#1a1b26"
                    visible: albumArt.status !== Image.Ready || root.artUrl === ""

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: root.mutedColor
                        font.pixelSize: 32
                    }
                }
            }

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.trackTitle
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.trackArtist
                    color: root.mutedColor
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Progress Bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: "#22ffffff"

                Rectangle {
                    height: parent.height
                    width: root.trackLength > 0 ? parent.width * (root.trackPosition / root.trackLength) : 0
                    radius: 2
                    color: root.accentColor
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.canSeek
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (root.activePlayer && root.canSeek) {
                            root.activePlayer.position = (mouse.x / width) * root.trackLength;
                            root.syncPosition();
                        }
                    }
                }
            }

            // Knoppenbalk (Apple-style: grote, strakke iconen zonder achtergrond)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 46

                // Vorige nummer
                Text {
                    text: "\uf048"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 54
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer)
                            root.activePlayer.previous()
                    }
                }

                // Play / Pause (Centraal & Extra groot)
                Text {
                    text: root.isPlaying ? "\uf04c" : "\uf04b"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 56
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer)
                            root.activePlayer.togglePlaying()
                    }
                }

                // Volgende nummer
                Text {
                    text: "\uf051"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 54
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer)
                            root.activePlayer.next()
                    }
                }
            }
        }

        // RECHTER KOLOM: CAVA Visualizer (Volledige Hoogte - 52 Bars)
        Item {
            Layout.preferredWidth: 85
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: 52

                    delegate: Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter

                        property real distFromCenter: Math.abs(index - 25.5)
                        property int mappedIdx: Math.min(51, Math.floor(distFromCenter * 2))

                        property real val: (root.cavaBars && root.cavaBars.length > mappedIdx) ? root.cavaBars[mappedIdx] : 0

                        width: Math.max(8, val * 85)
                        height: 3
                        radius: 1.5
                        color: root.cavaColor
                        opacity: 0.25 + (val * 0.75)

                        // Behavior on width {
                        //     NumberAnimation {
                        //         duration: 40
                        //     }
                        // }
                        // Behavior on opacity {
                        //     NumberAnimation {
                        //         duration: 40
                        //     }
                        // }
                    }
                }
            }
        }
    }
}
