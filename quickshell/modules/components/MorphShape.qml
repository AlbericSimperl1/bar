import QtQuick 2.15
import QtQuick.Shapes 1.15

Shape {
    id: root

    property real sidebarWidth: 38
    property real cornerRadius: 12
    property real morphW: 0
    property real morphF: 0
    property real morphR: 0
    property real panelTopY: 120
    property real panelH: 260
    property color barBg: "#60090c13"
    property color borderCol: "#33ffffff"

    anchors.fill: parent

    ShapePath {
        fillColor: root.barBg
        strokeColor: root.borderCol
        strokeWidth: 2
        joinStyle: ShapePath.RoundJoin

        startX: root.cornerRadius
        startY: 0

        // 1. Bovenrand zijbalk + bolle hoek rechtsboven
        PathLine {
            x: root.sidebarWidth - root.cornerRadius
            y: 0
        }
        PathArc {
            x: root.sidebarWidth
            y: root.cornerRadius
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
        }

        // 2. Rechterrand zijbalk omlaag tot bovenste junction
        PathLine {
            x: root.sidebarWidth
            y: root.panelTopY - root.morphF
        }

        // 3. HOLLE BINNENBOOG (balk → paneelbovenrand)
        PathAngleArc {
            centerX: root.sidebarWidth + root.morphF
            centerY: root.panelTopY - root.morphF
            radiusX: root.morphF
            radiusY: root.morphF
            startAngle: 180
            sweepAngle: -90
            moveToStart: false
        }

        // 4. Paneelbovenrand + bolle hoek
        PathLine {
            x: root.sidebarWidth + root.morphW - root.morphR
            y: root.panelTopY
        }
        PathArc {
            x: root.sidebarWidth + root.morphW
            y: root.panelTopY + root.morphR
            radiusX: root.morphR
            radiusY: root.morphR
        }

        // 5. Paneelrechterrand omlaag; ONDERSTE RECHTERHOEK is één hoek met
        // constante straal r die meeglijdt met pw (balk- én paneelhoek)
        PathLine {
            x: root.sidebarWidth + root.morphW
            y: root.height - root.cornerRadius
        }
        PathArc {
            x: root.sidebarWidth + root.morphW - root.cornerRadius
            y: root.height
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
        }

        // 6. GEDEELDE onderlijn: paneelonderkant = balkonderkant
        PathLine {
            x: root.cornerRadius
            y: root.height
        }
        PathArc {
            x: 0
            y: root.height - root.cornerRadius
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
        }

        // 7. Linkerrand + sluiten
        PathLine {
            x: 0
            y: root.cornerRadius
        }
        PathArc {
            x: root.cornerRadius
            y: 0
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
        }
    }
}
