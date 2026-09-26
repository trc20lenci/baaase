import QtQuick
import QtQuick.Controls.Basic
import Drift
import "components"

// The home shell's default destination: a CapCut-style landing page. Unlike the old
// Projects-as-landing-page, this is not meant to hold the full project library — that is
// what the Projects tab is for. This page's job is "start something" and "show what the
// app can do", so its tools grid links out to real, already-shipped engine features
// (transitions, cutout/chroma key, masks, auto captions, effects, keyframes) rather than
// placeholder entries; there is nothing here that the editor cannot already do.
//
// The reference this was built against opens on a full-bleed photo/video promo banner.
// There is no real content to put there — no AI template gallery, no editorial picks —
// so faking one would be exactly the kind of invented feature this page otherwise avoids.
// What it keeps from that reference is the *shape*: a full-width coloured band at the top
// carrying the brand mark and the privileges ticker, the same weight the photo banner had,
// just filled with something true instead of a stock image.
Item {
    id: root

    signal newProjectRequested()
    signal quickEditRequested()
    signal openProjectRequested()
    signal openRecentRequested(string path)
    signal viewAllProjectsRequested()
    signal searchProjectsRequested()

    readonly property var createTiles: [
        { id: "new", label: qsTr("New video"), icon: Theme.icons.plus },
        { id: "quick", label: qsTr("Quick edit"), icon: Theme.icons.sparkles }
    ]

    // Every entry here is a feature that already exists in the C++/QML editor. Tapping one
    // starts an edit rather than deep-linking into a specific panel: there is no routing API
    // from the home shell into the editor's internal tabs, and building one just for this
    // grid would be new surface area rather than surfacing what already ships.
    readonly property var tools: [
        { id: "transitions", label: qsTr("Transitions"), icon: Theme.icons.shuffle },
        { id: "cutout", label: qsTr("Object cutout"), icon: Theme.icons.scissors },
        { id: "chroma", label: qsTr("Chroma key"), icon: Theme.icons.blend },
        { id: "masks", label: qsTr("Masks"), icon: Theme.icons.mask },
        { id: "captions", label: qsTr("Auto captions"), icon: Theme.icons.captions },
        { id: "effects", label: qsTr("Effects"), icon: Theme.icons.wand },
        { id: "keyframes", label: qsTr("Keyframes"), icon: Theme.icons.diamondPlus }
    ]

    readonly property var privileges: [
        qsTr("4K export"),
        qsTr("Transitions"),
        qsTr("Object cutout & chroma key"),
        qsTr("Masks"),
        qsTr("Auto captions"),
        qsTr("Keyframe animation"),
        qsTr("Effects library")
    ]

    function triggerCreateTile(tileId) {
        if (tileId === "quick")
            root.quickEditRequested()
        else if (tileId === "new")
            root.newProjectRequested()
    }

    // Pale tint of the brand colour, for surfaces that sit on white rather than on the
    // hero band itself (the create tiles, below).
    function tintedPrimary(alpha) {
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, alpha)
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        contentWidth: width
        contentHeight: pageColumn.implicitHeight + Theme.spacing2xl
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: pageColumn
            width: parent.width
            spacing: Theme.spacingLg

            // --- Hero band -------------------------------------------------
            // Full-bleed, the way the reference's promo photo runs edge to edge. Carries
            // the brand mark, a real search entry point (into the Projects library, the
            // only searchable surface this app has), and the privileges ticker.
            Rectangle {
                id: hero
                width: parent.width
                height: heroContent.implicitHeight + heroContent.anchors.topMargin + Theme.spacingXl

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.exportGradientTop }
                    GradientStop { position: 1.0; color: Theme.exportGradientBottom }
                }

                Column {
                    id: heroContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: root.SafeArea.margins.top + Theme.spacingMd
                    anchors.leftMargin: Theme.androidPagePadding
                    anchors.rightMargin: Theme.androidPagePadding
                    spacing: Theme.spacingLg

                    Item {
                        width: parent.width
                        height: Math.max(mark.height, searchButton.height)

                        Rectangle {
                            id: mark
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: Qt.rgba(1, 1, 1, 0.22)

                            Text {
                                anchors.centerIn: parent
                                text: "B"
                                color: "white"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }
                        }

                        AbstractButton {
                            id: searchButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.iconButtonSize
                            height: Theme.iconButtonSize
                            hoverEnabled: true

                            Accessible.role: Accessible.Button
                            Accessible.name: qsTr("Search projects")

                            background: Rectangle {
                                radius: width / 2
                                color: searchButton.down ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                            }

                            contentItem: IconGlyph {
                                anchors.centerIn: parent
                                glyph: Theme.icons.search
                                iconSize: Theme.iconSizeMd
                                iconColor: "white"
                            }

                            onClicked: {
                                Haptics.select()
                                root.searchProjectsRequested()
                            }
                        }
                    }

                    Image {
                        source: "qrc:/qt/qml/Drift/resources/base_wordmark_light.png"
                        height: 20
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        width: implicitWidth * (height / Math.max(implicitHeight, 1))
                    }

                    MarqueeBanner {
                        width: parent.width
                        items: root.privileges
                        showBackground: false
                        textColor: "white"
                    }
                }
            }

            // --- The rest of the page, inset with the usual page padding -------
            Column {
                width: parent.width
                spacing: Theme.spacingLg
                leftPadding: Theme.androidPagePadding
                rightPadding: Theme.androidPagePadding
                topPadding: Theme.spacingLg

                readonly property real contentWidth: width - leftPadding - rightPadding

                // --- Start something, side by side ------------------------
                Row {
                    width: parent.contentWidth
                    spacing: Theme.spacingMd

                    Repeater {
                        model: root.createTiles

                        delegate: AbstractButton {
                            id: tile
                            required property var modelData

                            width: (parent.width - parent.spacing) / 2
                            height: Theme.androidHomeTileHeight * 1.3
                            hoverEnabled: true

                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.label

                            scale: tile.down ? Theme.pressScale : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
                            }

                            onClicked: {
                                Haptics.select()
                                root.triggerCreateTile(modelData.id)
                            }

                            background: Rectangle {
                                radius: Theme.radiusLg
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: root.tintedPrimary(tile.down ? 0.22 : 0.16) }
                                    GradientStop { position: 1.0; color: root.tintedPrimary(tile.down ? 0.10 : 0.05) }
                                }
                            }

                            contentItem: Item {
                                implicitWidth: tileContent.implicitWidth
                                implicitHeight: tileContent.implicitHeight

                                Column {
                                    id: tileContent
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingMd

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 44
                                        height: 44
                                        radius: Theme.radiusMd
                                        color: Theme.panelForeground

                                        IconGlyph {
                                            anchors.centerIn: parent
                                            glyph: tile.modelData.icon
                                            iconSize: Theme.iconSizeMd
                                            iconColor: Theme.panelBackground
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.label
                                        color: Theme.panelForeground
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeBase
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Recent projects, a scrolling strip ---------------------
                ListView {
                    width: parent.width
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Theme.androidHomeRecentCardHeight
                    orientation: ListView.Horizontal
                    spacing: Theme.spacingSm
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    visible: EditorState.recentProjects.length > 0
                    model: EditorState.recentProjects

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        width: Theme.androidHomeRecentCardHeight * 0.72
                        height: Theme.androidHomeRecentCardHeight
                        radius: Theme.radiusMd
                        color: Theme.panelAccent
                        opacity: modelData.exists === false ? 0.55 : 1

                        Accessible.role: Accessible.Button
                        Accessible.name: card.projectLabel

                        readonly property string projectLabel: {
                            const n = card.modelData.name || ""
                            return n.replace(/\.drift$/i, "") || qsTr("Untitled")
                        }

                        IconGlyph {
                            anchors.centerIn: parent
                            glyph: Theme.icons.film
                            iconSize: Theme.iconSizeLg
                            iconColor: Theme.mutedForeground
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: Theme.spacingXs
                            radius: Theme.radiusSm
                            color: Qt.rgba(0, 0, 0, 0.55)
                            width: badgeRow.implicitWidth + Theme.spacingSm
                            height: badgeRow.implicitHeight + 4

                            Row {
                                id: badgeRow
                                anchors.centerIn: parent
                                spacing: 3

                                IconGlyph {
                                    anchors.verticalCenter: parent.verticalCenter
                                    glyph: Theme.icons.scissors
                                    iconSize: 12
                                    iconColor: "white"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: card.projectLabel
                                    color: "white"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth, 64)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (card.modelData.exists === false) {
                                    Toasts.warning(qsTr("That project file is missing."))
                                    return
                                }
                                Haptics.select()
                                root.openRecentRequested(card.modelData.path)
                            }
                        }
                    }

                    footer: AbstractButton {
                        width: Theme.androidHomeRecentCardHeight * 0.4
                        height: Theme.androidHomeRecentCardHeight
                        hoverEnabled: true

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("See all projects")

                        onClicked: {
                            Haptics.select()
                            root.viewAllProjectsRequested()
                        }

                        background: Rectangle {
                            radius: Theme.radiusMd
                            color: Theme.panelMuted
                        }

                        contentItem: IconGlyph {
                            anchors.centerIn: parent
                            glyph: Theme.icons.chevronRight
                            iconSize: Theme.iconSizeMd
                            iconColor: Theme.mutedForeground
                        }
                    }
                }

                // --- Tools, a plain icon grid -------------------------------
                Grid {
                    width: parent.contentWidth
                    columns: 3
                    columnSpacing: Theme.spacingMd
                    rowSpacing: Theme.spacingXl

                    readonly property real cellWidth: (width - columnSpacing * (columns - 1)) / columns

                    Repeater {
                        model: root.tools

                        delegate: AbstractButton {
                            id: toolTile
                            required property var modelData

                            width: parent.cellWidth
                            height: 68
                            hoverEnabled: true

                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.label

                            scale: toolTile.down ? Theme.pressScale : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
                            }

                            onClicked: {
                                Haptics.select()
                                root.quickEditRequested()
                            }

                            background: null

                            contentItem: Item {
                                implicitWidth: toolContent.implicitWidth
                                implicitHeight: toolContent.implicitHeight

                                Column {
                                    id: toolContent
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingSm

                                    IconGlyph {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        glyph: toolTile.modelData.icon
                                        iconSize: Theme.iconSizeLg
                                        iconColor: Theme.panelForeground
                                    }

                                    Text {
                                        width: toolTile.width
                                        text: toolTile.modelData.label
                                        color: Theme.panelForeground
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
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
