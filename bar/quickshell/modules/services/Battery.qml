pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real percentage: dev ? dev.percentage : 1.0
    readonly property bool isCharging: dev ? dev.state === UPowerDeviceState.Charging : false

    signal thresholdReached(int percent, string message)

    property int _lastThreshold: -1

    onPercentageChanged: {
        let p = Math.round(percentage * 100);
        if (!isCharging) {
            if (p <= 10 && _lastThreshold !== 10) {
                _lastThreshold = 10;
                thresholdReached(10, "Accu kritiek laag!");
            } else if (p <= 20 && _lastThreshold !== 20 && p > 10) {
                _lastThreshold = 20;
                thresholdReached(20, "Accu bijna leeg");
            }
        } else {
            _lastThreshold = -1;
        }
    }
}
