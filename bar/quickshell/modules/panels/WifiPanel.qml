// quickshell/modules/panels/WifiPanel.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "./Model.js" as Model

Item {
    id: wifiPanelRoot

    property color fgColor: "#fff7e5"
    property color accentColor: "#ebd9b9"
    property color dimColor: "#66fff7e5"
    property color lineColor: "#20ffffff"
    property string fontFamily: "Mononoki Nerd Font Mono"

    // Dynamische hoogteberekening voor shell.qml
    readonly property real neededHeight: Math.min(420, Math.max(160, (layoutRoot.anchors.margins * 2) + headerRow.implicitHeight + layoutRoot.spacing + mainColumn.implicitHeight))

    // State & Networking
    readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
    readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: findDevice(DeviceType.Wifi)
    readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var connectedWifiNetwork: findConnectedWifiNetwork()
    readonly property var wiredDevice: findDevice(DeviceType.Wired)

    property var wifiNetworks: []
    property bool scanning: false
    property bool wifiStationAvailable: false

    property string dnsProvider: "DHCP"
    property string actionSsid: ""
    property string actionKind: ""
    property string failureSsid: ""
    property string failureReason: ""
    property string passwordSsid: ""
    property string passwordText: ""
    property string identityText: ""

    readonly property bool busy: actionKind !== ""

    readonly property string kind: {
        if (wiredDevice && wiredDevice.connected)
            return "ethernet";
        if (connectedWifiNetwork)
            return "wifi";
        return "disconnected";
    }

    readonly property int signalStrength: connectedWifiNetwork ? Math.round((connectedWifiNetwork.signalStrength || 0) * 100) : -1

    readonly property string icon: Model.connectionIcon(kind, signalStrength)

    property int connectionPhraseIndex: 0
    readonly property var connectionPhrases: ["Wiring bits", "Handling packets", "Sorting frames", "Hauling bytes", "Routing crumbs"]
    readonly property string connectionPhrase: connectionPhrases[connectionPhraseIndex % connectionPhrases.length]

    // Functies
    function cancelPasswordPrompt() {
        passwordSsid = "";
        passwordText = "";
        identityText = "";
    }

    function toggleNetwork() {
        if (!networkManagerAvailable)
            return;
        Networking.wifiEnabled = !Networking.wifiEnabled;
        Qt.callLater(function () {
            wifiPanelRoot.refresh(true);
        });
    }

    function findDevice(type) {
        var devices = networkDevices || [];
        var fallback = null;
        for (var i = 0; i < devices.length; i++) {
            var device = devices[i];
            if (!device || device.type !== type)
                continue;
            if (device.connected)
                return device;
            if (!fallback)
                fallback = device;
        }
        return fallback;
    }

    function findConnectedWifiNetwork() {
        var networks = wifiNetworkObjects || [];
        for (var i = 0; i < networks.length; i++) {
            if (networks[i] && networks[i].connected)
                return networks[i];
        }
        return null;
    }

    function syncWifiNetworks() {
        var nets = [];
        var networks = wifiNetworkObjects || [];

        for (var i = 0; i < networks.length; i++) {
            var network = networks[i];
            if (!network)
                continue;
            checkActionCompletion(network);
            var row = Model.wifiRow(network);
            if (row)
                nets.push(row);
        }
        wifiNetworks = Model.sortWifiRows(nets);
        wifiStationAvailable = !!wifiDevice;
        scanning = false;
    }

    function refresh(scanWifi) {
        if (scanWifi === undefined)
            scanWifi = false;
        if (wifiDevice) {
            if (scanWifi) {
                scanning = true;
                setScannerEnabled(false);
                scanRestart.start();
            } else {
                setScannerEnabled(true);
            }
        }
        syncWifiNetworks();
    }

    property var scannerDevice: null
    function setScannerEnabled(enabled) {
        var nextDevice = wifiDevice;
        if (scannerDevice && scannerDevice !== nextDevice)
            scannerDevice.scannerEnabled = false;
        scannerDevice = nextDevice;
        if (scannerDevice)
            scannerDevice.scannerEnabled = enabled;
    }

    Component.onCompleted: refresh(true)
    Component.onDestruction: {
        if (scannerDevice)
            scannerDevice.scannerEnabled = false;
    }

    onWifiDeviceChanged: {
        setScannerEnabled(true);
        syncWifiNetworks();
    }
    onWifiNetworkObjectsChanged: syncWifiNetworks()

    function requiresCredentials(security) {
        return Model.requiresCredentials(security, WifiSecurityType.Open, WifiSecurityType.Owe);
    }

    function openPasswordPrompt(ssid) {
        if (passwordSsid !== ssid) {
            passwordText = "";
            identityText = "";
        }
        passwordSsid = ssid;
    }

    function networkForSsid(ssid) {
        var networks = wifiNetworkObjects || [];
        for (var i = 0; i < networks.length; i++) {
            if (networks[i] && networks[i].name === ssid)
                return networks[i];
        }
        return null;
    }

    function runNetworkAction(kind, network, callback) {
        if (actionKind !== "" || !network)
            return;
        var ssid = network.name || "";
        actionSsid = ssid;
        actionKind = kind;
        failureSsid = "";
        failureReason = "";
        callback(network);
        actionTimeout.restart();
    }

    function clearNetworkAction() {
        actionTimeout.stop();
        if (actionKind === "connect")
            passwordSsid = "";
        failureSsid = "";
        failureReason = "";
        actionSsid = "";
        actionKind = "";
        refresh();
    }

    function checkActionCompletion(network) {
        if (!network || actionKind === "" || actionSsid !== (network.name || ""))
            return;
        if (actionKind === "connect" && network.connected)
            clearNetworkAction();
        else if (actionKind === "disconnect" && !network.connected && !network.stateChanging)
            clearNetworkAction();
        else if (actionKind === "forget" && !network.known && !network.stateChanging)
            clearNetworkAction();
    }

    function connectDirectly(ssid) {
        runNetworkAction("connect", networkForSsid(ssid), function (network) {
            network.connect();
        });
    }

    function connectWithPassphrase(ssid, passphrase) {
        runNetworkAction("connect", networkForSsid(ssid), function (network) {
            network.connectWithPsk(passphrase);
        });
    }

    function connectEnterprise(ssid, identity, passphrase) {
        runNetworkAction("connect", networkForSsid(ssid), function (network) {
            enterpriseConnect.secret = passphrase;
            enterpriseConnect.command = ["bash", "-c", Model.enterpriseConnectScript, "nmcli-eap", ssid, identity];
            enterpriseConnect.running = true;
        });
    }

    Process {
        id: enterpriseConnect
        property string secret: ""
        stdinEnabled: true
        onStarted: {
            write(secret + "\n");
            secret = "";
        }
    }

    function disconnectRow(ssid) {
        var network = networkForSsid(ssid);
        if (network)
            runNetworkAction("disconnect", network, function (net) {
                net.disconnect();
            });
    }

    function forget(net) {
        var network = net ? networkForSsid(net.ssid) : null;
        if (network)
            runNetworkAction("forget", network, function (n) {
                n.forget();
            });
    }

    Timer {
        id: scanRestart
        interval: 100
        repeat: false
        onTriggered: {
            if (wifiPanelRoot.wifiDevice) {
                wifiPanelRoot.setScannerEnabled(true);
                scanDone.start();
            }
        }
    }

    Timer {
        id: scanDone
        interval: 1500
        repeat: false
        onTriggered: wifiPanelRoot.syncWifiNetworks()
    }

    Timer {
        id: connectionPhraseTimer
        interval: 2800
        running: wifiPanelRoot.kind !== "disconnected"
        repeat: true
        onTriggered: connectionPhraseIndex = (connectionPhraseIndex + 1) % connectionPhrases.length
    }

    Timer {
        id: actionTimeout
        interval: 30000
        repeat: false
        onTriggered: {
            if (!wifiPanelRoot.actionKind)
                return;
            wifiPanelRoot.failureSsid = wifiPanelRoot.actionSsid;
            wifiPanelRoot.failureReason = "Timing out";
            wifiPanelRoot.actionSsid = "";
            wifiPanelRoot.actionKind = "";
            wifiPanelRoot.refresh();
        }
    }

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
                text: "Netwerk"
                color: wifiPanelRoot.fgColor
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 19
                font.bold: true
                Layout.fillWidth: true
            }

            // Vernieuw knop
            Text {
                text: "󰑐"
                color: refreshMa.containsMouse ? wifiPanelRoot.fgColor : wifiPanelRoot.dimColor
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 16

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: wifiPanelRoot.refresh(true)
                }
            }

            // Wifi In/Uitschakelen
            Text {
                text: Networking.wifiEnabled ? "󰤨 Aan" : "󰤭 Uit"
                color: toggleMa.containsMouse ? wifiPanelRoot.fgColor : (Networking.wifiEnabled ? wifiPanelRoot.accentColor : wifiPanelRoot.dimColor)
                font.family: wifiPanelRoot.fontFamily
                font.pixelSize: 13

                MouseArea {
                    id: toggleMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: wifiPanelRoot.toggleNetwork()
                }
            }
        }

        // Main content
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: mainColumn.implicitHeight
            interactive: true

            ColumnLayout {
                id: mainColumn
                width: parent.width
                spacing: 16

                // Status kaartje actieve verbinding
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 50
                    color: wifiPanelRoot.lineColor
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Text {
                            text: wifiPanelRoot.icon
                            color: wifiPanelRoot.accentColor
                            font.family: wifiPanelRoot.fontFamily
                            font.pixelSize: 22
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: {
                                    if (wifiPanelRoot.kind === "wifi")
                                        return wifiPanelRoot.connectedWifiNetwork ? wifiPanelRoot.connectedWifiNetwork.name : "Wi-Fi";
                                    if (wifiPanelRoot.kind === "ethernet")
                                        return "Ethernet";
                                    return "Niet verbonden";
                                }
                                color: wifiPanelRoot.fgColor
                                font.family: wifiPanelRoot.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: wifiPanelRoot.kind !== "disconnected"
                                text: wifiPanelRoot.connectionPhrase.toUpperCase()
                                color: wifiPanelRoot.dimColor
                                font.family: wifiPanelRoot.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.1
                            }
                        }
                    }
                }

                // DNS Provider Selector
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "DNS PROVIDER"
                        color: wifiPanelRoot.dimColor
                        font.family: wifiPanelRoot.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: ["DHCP", "Cloudflare", "Google", "Custom"]

                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 6
                                color: wifiPanelRoot.dnsProvider === modelData ? wifiPanelRoot.accentColor : wifiPanelRoot.lineColor

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: wifiPanelRoot.dnsProvider === parent.modelData ? "#11111b" : wifiPanelRoot.fgColor
                                    font.family: wifiPanelRoot.fontFamily
                                    font.pixelSize: 11
                                    font.bold: wifiPanelRoot.dnsProvider === parent.modelData
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiPanelRoot.dnsProvider = parent.modelData
                                }
                            }
                        }
                    }
                }

                // Scheidingslijn
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: wifiPanelRoot.lineColor
                }

                // Netwerken lijst
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: wifiPanelRoot.scanning ? "SCANNING WI-FI…" : "WI-FI NETWERKEN"
                        color: wifiPanelRoot.dimColor
                        font.family: wifiPanelRoot.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    Repeater {
                        model: wifiPanelRoot.wifiStationAvailable ? wifiPanelRoot.wifiNetworks : []

                        delegate: ColumnLayout {
                            required property var modelData
                            required property int index

                            readonly property string sectionTitle: Model.wifiSectionTitle(wifiPanelRoot.wifiNetworks, index)
                            readonly property bool isConnected: modelData && modelData.connected
                            readonly property bool isKnown: modelData && modelData.known
                            readonly property bool requiresCredentials: modelData ? wifiPanelRoot.requiresCredentials(modelData.security) : false
                            readonly property bool isEnterprise: modelData ? (modelData.security === WifiSecurityType.Wpa2Eap || modelData.security === WifiSecurityType.WpaEap) : false
                            readonly property bool isPasswordOpen: wifiPanelRoot.passwordSsid !== "" && wifiPanelRoot.passwordSsid === (modelData ? modelData.ssid : "")

                            Layout.fillWidth: true
                            spacing: 4

                            // Sectie titel (Bekende / Overige)
                            Text {
                                visible: sectionTitle !== ""
                                text: sectionTitle
                                color: wifiPanelRoot.accentColor
                                font.family: wifiPanelRoot.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                Layout.topMargin: 6
                            }

                            // Netwerk Rij
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: 6
                                color: rowMa.containsMouse ? wifiPanelRoot.lineColor : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    Text {
                                        text: Model.wifiIconFor(modelData.signal)
                                        color: isConnected ? wifiPanelRoot.accentColor : wifiPanelRoot.fgColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 16
                                    }

                                    Text {
                                        text: modelData.ssid || "Verborgen netwerk"
                                        color: wifiPanelRoot.fgColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 13
                                        font.bold: isConnected
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Status tekst
                                    Text {
                                        visible: isConnected || (wifiPanelRoot.actionSsid === modelData.ssid)
                                        text: isConnected ? "Verbonden" : (wifiPanelRoot.actionSsid === modelData.ssid ? "Bezig..." : "")
                                        color: isConnected ? wifiPanelRoot.accentColor : wifiPanelRoot.dimColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 11
                                    }

                                    // Vergrendeld / Vergeten icoon
                                    Text {
                                        visible: requiresCredentials || (isKnown && !isConnected)
                                        text: (isKnown && !isConnected) ? "󰅙" : "󰌾"
                                        color: (isKnown && !isConnected && forgetMa.containsMouse) ? "#ff5555" : wifiPanelRoot.dimColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 14

                                        MouseArea {
                                            id: forgetMa
                                            anchors.fill: parent
                                            enabled: isKnown && !isConnected
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: wifiPanelRoot.forget(modelData)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: -1
                                    onClicked: {
                                        if (isConnected) {
                                            wifiPanelRoot.disconnectRow(modelData.ssid);
                                            return;
                                        }
                                        if (requiresCredentials && !isKnown) {
                                            wifiPanelRoot.openPasswordPrompt(modelData.ssid);
                                            return;
                                        }
                                        wifiPanelRoot.connectDirectly(modelData.ssid);
                                    }
                                }
                            }

                            // Inklapbaar Wachtwoord Invoerveld
                            ColumnLayout {
                                visible: isPasswordOpen
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                spacing: 6

                                TextField {
                                    visible: isEnterprise
                                    Layout.fillWidth: true
                                    placeholderText: "Identiteit (gebruiker@domein)"
                                    color: wifiPanelRoot.fgColor
                                    font.family: wifiPanelRoot.fontFamily
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        color: wifiPanelRoot.lineColor
                                        radius: 4
                                    }
                                    onTextChanged: wifiPanelRoot.identityText = text
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    TextField {
                                        id: pwInput
                                        Layout.fillWidth: true
                                        echoMode: TextInput.Password
                                        placeholderText: "Wachtwoord"
                                        color: wifiPanelRoot.fgColor
                                        font.family: wifiPanelRoot.fontFamily
                                        font.pixelSize: 12
                                        background: Rectangle {
                                            color: wifiPanelRoot.lineColor
                                            radius: 4
                                        }
                                        onTextChanged: wifiPanelRoot.passwordText = text
                                        onAccepted: submitBtn.click()
                                    }

                                    Rectangle {
                                        id: submitBtn
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        radius: 4
                                        color: wifiPanelRoot.accentColor

                                        function click() {
                                            if (pwInput.text.length === 0)
                                                return;
                                            if (!isEnterprise) {
                                                wifiPanelRoot.connectWithPassphrase(modelData.ssid, pwInput.text);
                                            } else if (wifiPanelRoot.identityText.length > 0) {
                                                wifiPanelRoot.connectEnterprise(modelData.ssid, wifiPanelRoot.identityText, pwInput.text);
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬"
                                            color: "#11111b"
                                            font.family: wifiPanelRoot.fontFamily
                                            font.pixelSize: 14
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: parent.click()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
