// quickshell/modules/components/MorphShape.qml
import QtQuick 2.15
import QtQuick.Shapes 1.15

Shape {
    id: root

    property real sidebarWidth: 38
    property real cornerRadius: 6
    property real panelGap: 8
    property real panelRadius: 16

    property real morphW: 0
    property real openFrac: 0
    property real panelTopY: 120
    property real panelH: 260

    property color barBg: "#60090c13"
    property color borderCol: "#33ffffff"

    readonly property real panelX: root.sidebarWidth + root.panelGap
    readonly property real panelW: Math.max(0, root.morphW - root.panelGap)
    readonly property real panelDrawH: root.panelH * root.openFrac

    anchors.fill: parent

    // --- Zijbalk: vaste, losstaande pil, nooit vervormd door het paneel ---
    ShapePath {
        fillColor: root.barBg
        strokeColor: root.borderCol
        strokeWidth: 2
        joinStyle: ShapePath.RoundJoin

        startX: root.cornerRadius
        startY: 0

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
        PathLine {
            x: root.sidebarWidth
            y: root.height - root.cornerRadius
        }
        PathArc {
            x: root.sidebarWidth - root.cornerRadius
            y: root.height
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
        }
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

    // --- Popout paneel: volledig losstaand van de balk, eigen afgeronde rechthoek ---
    ShapePath {
        fillColor: root.barBg
        strokeColor: root.borderCol
        strokeWidth: 2
        joinStyle: ShapePath.RoundJoin
        fillRule: ShapePath.WindingFill

        startX: root.panelX + root.panelRadius
        startY: root.panelTopY

        PathLine {
            x: root.panelX + root.panelW - root.panelRadius
            y: root.panelTopY
        }
        PathArc {
            x: root.panelX + root.panelW
            y: root.panelTopY + root.panelRadius
            radiusX: root.panelRadius
            radiusY: root.panelRadius
        }
        PathLine {
            x: root.panelX + root.panelW
            y: root.panelTopY + root.panelDrawH - root.panelRadius
        }
        PathArc {
            x: root.panelX + root.panelW - root.panelRadius
            y: root.panelTopY + root.panelDrawH
            radiusX: root.panelRadius
            radiusY: root.panelRadius
        }
        PathLine {
            x: root.panelX + root.panelRadius
            y: root.panelTopY + root.panelDrawH
        }
        PathArc {
            x: root.panelX
            y: root.panelTopY + root.panelDrawH - root.panelRadius
            radiusX: root.panelRadius
            radiusY: root.panelRadius
        }
        PathLine {
            x: root.panelX
            y: root.panelTopY + root.panelRadius
        }
        PathArc {
            x: root.panelX + root.panelRadius
            y: root.panelTopY
            radiusX: root.panelRadius
            radiusY: root.panelRadius
        }
    }
}
