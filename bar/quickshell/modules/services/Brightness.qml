pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real percentage: 0

    signal changed(real value)

    Process {
        id: getProc
        command: ["brightnessctl", "-m", "i"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let parts = data.split(",");
                if (parts.length >= 4) {
                    let p = parseInt(parts[3].replace("%", ""));
                    if (!isNaN(p)) {
                        let newVal = p / 100.0;
                        // Alleen een OSD-signaal sturen als de waarde daadwerkelijk verandert
                        if (Math.abs(root.percentage - newVal) > 0.01) {
                            root.percentage = newVal;
                            root.changed(root.percentage);
                        }
                    }
                }
            }
        }
    }

    // Controleer elke 150ms op wijzigingen
    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: {
            if (!getProc.running)
                getProc.running = true;
        }
    }

    Component.onCompleted: {
        if (!getProc.running)
            getProc.running = true;
    }
}
