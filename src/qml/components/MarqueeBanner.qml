import QtQuick
import Drift

// A continuously scrolling strip of short feature/privilege callouts ("Export in 4K",
// "Auto captions", ...), used at the top of the Home destination the way CapCut-style
// editors show what the app can do before the user has opened anything.
//
// Built from two identical copies of the same row placed back to back and driven by a
// single 0..1 phase: x = -phase * (one copy's width). At phase 1 the strip has scrolled
// exactly one copy's width, so the loop restarting at phase 0 is visually seamless —
// there is no snap because the pixels at x=-width and x=0 are identical.
Item {
    id: root

    property var items: []
    property real pxPerSecond: 36

    implicitHeight: Theme.androidTouchGap * 2 + Theme.iconSizeMd

    clip: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.primary
        opacity: Theme.darkMode ? 0.16 : 0.12
    }

    property real _phase: 0

    NumberAnimation on _phase {
        from: 0
        to: 1
        duration: Math.max(4000, (track.singleWidth / root.pxPerSecond) * 1000)
        loops: Animation.Infinite
        running: track.singleWidth > 0
    }

    Row {
        id: track
        height: parent.height
        x: -root._phase * track.singleWidth
        spacing: 0

        readonly property real singleWidth: copyA.width

        Row {
            id: copyA
            height: track.height
            spacing: Theme.spacing2xl
            rightPadding: Theme.spacing2xl

            Repeater {
                model: root.items
                delegate: MarqueeChip { text: modelData }
            }
        }

        Row {
            height: track.height
            spacing: Theme.spacing2xl
            rightPadding: Theme.spacing2xl

            Repeater {
                model: root.items
                delegate: MarqueeChip { text: modelData }
            }
        }
    }

    component MarqueeChip: Row {
        id: chip
        property alias text: chipLabel.text
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        spacing: Theme.spacingSm

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.icons.sparkles
            iconSize: Theme.iconSizeMd
            iconColor: Theme.accentOnPanel
        }

        Text {
            id: chipLabel
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accentOnPanel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
        }
    }
}
