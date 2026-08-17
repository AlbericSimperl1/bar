// quickshell/modules/panels/Model.js

function parseNetworkStatus(raw) {
  var parts = String(raw || "disconnected\t\t\t")
    .replace(/\r?\n+$/, "")
    .split("\t");
  return {
    kind: parts[0] || "disconnected",
    label: parts[1] || "",
    signalStrength: parts[2] ? parseInt(parts[2], 10) : -1,
    frequency: parts[3] || "",
  };
}

function wifiIconFor(strength) {
  var icons = ["󰤟", "󰤢", "󰤥", "󰤨"];
  var index = Math.max(0, Math.min(3, Math.ceil(strength / 25) - 1));
  return icons[index];
}

function connectionIcon(kind, signalStrength) {
  if (kind === "wifi") return wifiIconFor(signalStrength);
  if (kind === "ethernet") return "󰈀";
  return "󰤭";
}

function formatHeaderSpeed(mbps) {
  var v = parseInt(mbps, 10);
  if (!v || v < 0) return "";
  if (v >= 1000) return (v / 1000).toFixed(v % 1000 === 0 ? 0 : 1) + "gbit";
  return v + "mbit";
}

function formatHeaderFreq(mhz) {
  var v = parseFloat(mhz);
  if (!v) return "";

  if (v >= 2400 && v < 2500) return "2.4ghz";
  if (v >= 4900 && v < 5925) return "5ghz";
  if (v >= 5925 && v < 7125) return "6ghz";
  if (v >= 57000 && v < 71000) return "60ghz";

  var ghz = v / 1000;
  return ghz.toFixed(ghz % 1 === 0 ? 0 : 1) + "ghz";
}

function headerDetail(info) {
  var value = info || {};
  if (value.type === "ethernet") return formatHeaderSpeed(value.speed || "");
  return "";
}

function bandLabel(band) {
  if (band === "auto") return "Auto";
  if (!band) return "";
  return band + "ghz";
}

function bandSectionTitle(selected, current) {
  if (selected !== "auto") return "WI-FI BAND";
  var label = bandLabel(current);
  if (label === "") return "WI-FI BAND";
  return "WI-FI BAND: " + label.toUpperCase();
}

function bandTooltip(band) {
  if (band === "auto") return "Let Wi-Fi pick the band";
  if (!band) return "";
  return "Stay on " + bandLabel(band);
}

function parseBandStatus(raw) {
  var next = parseKeyValue(raw);
  var tokens = String(next.available || "").split(" ");
  var available = [];

  for (var i = 0; i < tokens.length; i++) {
    if (tokens[i] !== "") available.push(tokens[i]);
  }

  return {
    band: next.band || "",
    selected: next.selected || "auto",
    available: available,
  };
}

function decodeIwSsid(value) {
  var raw = String(value || "");
  try {
    var encoded = "";
    for (var i = 0; i < raw.length; i++) {
      if (
        raw[i] === "\\" &&
        raw[i + 1] === "x" &&
        /^[0-9a-f]{2}$/i.test(raw.substring(i + 2, i + 4))
      ) {
        var hex = raw.substring(i + 2, i + 4);
        var byte = parseInt(hex, 16);
        encoded +=
          byte < 32 || byte === 127
            ? encodeURIComponent(raw.substring(i, i + 4))
            : "%" + hex;
        i += 3;
      } else {
        encoded += encodeURIComponent(raw[i]);
      }
    }
    return decodeURIComponent(encoded);
  } catch (error) {
    return raw;
  }
}

function parseKeyValue(raw) {
  var next = {};
  var lines = String(raw || "").split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (!line) continue;
    var idx = line.indexOf("\t");
    if (idx === -1) continue;
    var key = line.substring(0, idx);
    var value = line.substring(idx + 1);
    next[key] = key === "ssid" ? decodeIwSsid(value) : value.trim();
  }
  return next;
}

function throughputState(previous, next, now) {
  var prev = previous || {};
  var sample = next || {};
  var iface = sample.iface || "";
  var rx = parseFloat(sample.rx_bytes || "0");
  var tx = parseFloat(sample.tx_bytes || "0");
  var previousTime = Number(prev.prevSampleTime || 0);

  if (iface !== (prev.prevIface || "") || previousTime === 0) {
    return {
      prevIface: iface,
      prevRxBytes: rx,
      prevTxBytes: tx,
      prevSampleTime: now,
      downloadRate: 0,
      uploadRate: 0,
    };
  }

  var downloadRate = Number(prev.downloadRate || 0);
  var uploadRate = Number(prev.uploadRate || 0);
  var dt = now - previousTime;
  if (dt > 0) {
    downloadRate = Math.max(0, (rx - Number(prev.prevRxBytes || 0)) / dt);
    uploadRate = Math.max(0, (tx - Number(prev.prevTxBytes || 0)) / dt);
  }

  return {
    prevIface: iface,
    prevRxBytes: rx,
    prevTxBytes: tx,
    prevSampleTime: now,
    downloadRate: downloadRate,
    uploadRate: uploadRate,
  };
}

function formatBytes(bytes) {
  var n = Number(bytes);
  if (!isFinite(n) || n < 0) n = 0;
  if (n < 1024) return Math.round(n) + " B";
  if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB";
  if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB";
  return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB";
}

function formatRate(bytesPerSec) {
  return formatBytes(bytesPerSec) + "/s";
}

function wifiRow(network) {
  if (!network) return null;
  return {
    connected: !!network.connected,
    known: !!network.known,
    ssid: network.name || "",
    signal: Math.round((network.signalStrength || 0) * 100),
    security: network.security,
  };
}

function sortWifiRows(rows) {
  var nets = Array.isArray(rows) ? rows.slice() : [];
  nets.sort(function (a, b) {
    if (a.connected !== b.connected) return a.connected ? -1 : 1;
    if (a.known !== b.known) return a.known ? -1 : 1;
    return b.signal - a.signal;
  });
  return nets;
}

function wifiSectionTitle(wifiNetworks, index) {
  var networks = Array.isArray(wifiNetworks) ? wifiNetworks : [];
  if (index < 0 || index >= networks.length) return "";

  var net = networks[index];
  if (!net) return "";

  if (net.known && index === 0) return "BEKENDE NETWERKEN";
  if (
    !net.known &&
    (index === 0 || (networks[index - 1] && networks[index - 1].known))
  )
    return "OVERIGE NETWERKEN";
  return "";
}

function requiresCredentials(security, openSecurity, oweSecurity) {
  return security !== openSecurity && security !== oweSecurity;
}

function canForgetNetwork(network) {
  return !!(network && network.known && !network.connected);
}

var enterpriseConnectScript =
  "u=$(uuidgen); IFS= read -r pw;" +
  ' nmcli connection add type wifi con-name "$1" ssid "$1" connection.uuid "$u"' +
  " wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2" +
  ' 802-1x.identity "$2" 802-1x.auth-timeout 8 >/dev/null' +
  ' && printf \'set 802-1x.password %s\\nsave\\nquit\\n\' "$pw" | nmcli connection edit uuid "$u" >/dev/null' +
  ' && nmcli connection up uuid "$u"' +
  ' || { nmcli connection delete uuid "$u" >/dev/null 2>&1; false; }';

function networkFailureReason(reason, needsCredentials, reasons) {
  var r = reasons || {};
  if (needsCredentials && reason === r.NoSecrets) return "Wachtwoord vereist";
  if (needsCredentials && reason === r.WifiAuthTimeout)
    return "Fout wachtwoord";
  if (reason === r.WifiNetworkLost) return "Netwerk verloren";
  if (reason === r.WifiClientDisconnected) return "Verbinding verbroken";
  if (reason === r.WifiClientFailed) return "Verbinding mislukt";
  return "Kan niet verbinden";
}

function shouldRepromptPassphrase(reason, needsCredentials, reasons) {
  var r = reasons || {};
  if (!needsCredentials) return false;
  return reason === r.NoSecrets || reason === r.WifiAuthTimeout;
}
