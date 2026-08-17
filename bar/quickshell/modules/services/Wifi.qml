// services/Wifi.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property string ssid: "Disconnected"
    property var history: []
    readonly property bool radioOn: ssid !== "WiFi-OFF"
    readonly property bool connected: radioOn && ssid !== "Disconnected"

    property bool liveMode: false
    function toggleLiveMode() {
        liveMode = !liveMode;
    }
    property var scanList: []

    property bool popupOpen: false

    property string authError: ""
    property string authErrorSsid: ""
    function dismissAuthError() {
        root.authError = "";
    }

    function _q(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function toggleRadio() {
        Quickshell.execDetached(["bash", "-c", "if nmcli -t -f WIFI g | grep -q enabled; then nmcli radio wifi off; else nmcli radio wifi on; fi"]);
    }

    function scriptPath(name) {
        return Quickshell.env("HOME") + "/.config/quickshell/scripts/" + name;
    }

    function connectTo(ssidName) {
        if (ssidName === root.ssid)
            return;
        const disconnectCmd = root.connected ? ("nmcli connection down " + root._q(root.ssid) + "; sleep 0.5; ") : "";
        Quickshell.execDetached(["bash", "-c", disconnectCmd + "bash " + scriptPath("wifi-history.sh") + " connect " + root._q(ssidName) + " && bash " + scriptPath("wifi-history.sh") + " update " + root._q(ssidName)]);
    }

    function disconnect(ssidName) {
        Quickshell.execDetached(["bash", "-c", "nmcli connection down " + root._q(ssidName)]);
    }

    function forceConnectTo(ssidName) {
        connectTo(ssidName);
    }

    function connectWithPassword(ssidName, password) {
        if (connectProc.running)
            return;
        if (ssidName === root.ssid)
            return;
        root.authError = "";
        connectProc.ssidName = ssidName;
        connectProc.pendingPassword = password;
        connectProc.running = true;
    }

    property Process connectProc: Process {
        property string ssidName: ""
        property string pendingPassword: ""
        running: false
        command: ["bash", "-c", (root.connected ? ("nmcli connection down " + root._q(root.ssid) + "; sleep 0.5; ") : "") + "nmcli device wifi connect " + root._q(ssidName) + " password " + root._q(pendingPassword)]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.authError = "";
                Quickshell.execDetached(["bash", root.scriptPath("wifi-history.sh"), "update", connectProc.ssidName]);
            } else {
                root.authError = "Authentication failed";
                root.authErrorSsid = connectProc.ssidName;
            }
        }
    }

    function forget(ssidName) {
        Quickshell.execDetached(["bash", scriptPath("wifi-history.sh"), "forget", ssidName]);
        root.history = root.history.filter(h => h.ssid !== ssidName);
    }

    property Process _proc: Process {
        command: ["bash", root.scriptPath("wifi-history.sh")]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim().length)
                    return;
                try {
                    const data = JSON.parse(line);
                    root.ssid = data.ssid ?? root.ssid;
                    root.history = data.history ?? root.history;
                } catch (e) {
                    console.warn("Wifi: bad JSON from wifi-history.sh:", line);
                }
            }
        }
        onExited: restartTimer.start()
    }

    property Timer restartTimer: Timer {
        interval: 1000
        onTriggered: root._proc.running = true
    }

    property Process _scanProc: Process {
        running: root.liveMode && root.popupOpen
        command: ["bash", root.scriptPath("wifi-scan-listener.sh")]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.trim().length)
                    return;
                try {
                    root.scanList = JSON.parse(line);
                } catch (e) {
                    console.warn("Wifi: bad JSON from wifi-scan-listener.sh:", line);
                }
            }
        }
        onExited: if (root.liveMode && root.popupOpen)
            scanRestartTimer.start()
    }

    property Timer scanRestartTimer: Timer {
        interval: 1000
        onTriggered: root._scanProc.running = true
    }
}
