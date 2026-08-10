// modules/components/ClockV.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: clockRoot

    // ---- HIER DIT TOEVOEGEN ALS HET ER NIET STAAT ----
    property color fgColor: "#fff7e5"
    property color mutedColor: Qt.rgba(1, 0.95, 0.82, 0.78)
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    spacing: 0

    readonly property string timeStr: Qt.formatDateTime(clockTimer.currentDate, "HHmm")

    Repeater {
        model: 4

        Text {
            text: clockRoot.timeStr.charAt(index)
            color: index < 2 ? clockRoot.fgColor : clockRoot.mutedColor
            font.family: clockRoot.fontFamily
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: index === 1 ? 8 : 0
        }
    }

    Timer {
        id: clockTimer
        property date currentDate: new Date()
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }
}
