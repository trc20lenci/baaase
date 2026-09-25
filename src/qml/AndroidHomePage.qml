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
Item {
    id: root

    signal newProjectRequested()
    signal quickEditRequested()
    signal openProjectRequested()
    signal openRecentRequested(string path)
    signal viewAllProjectsRequested()

    readonly property var createTiles: [
        { id: "new", label: qsTr("New video"), detail: qsTr("Choose a canvas, start empty"),
          icon: Theme.icons.plus, primary: true },
        { id: "quick", label: qsTr("Quick edit"), detail: qsTr("Pick a clip, start now"),
          icon: Theme.icons.sparkles, primary: false }
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

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: root.SafeArea.margins.top
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
            spacing: Theme.spacing2xl
            topPadding: Theme.spacingLg
            leftPadding: Theme.androidPagePadding
            rightPadding: Theme.androidPagePadding

            readonly property real contentWidth: width - leftPadding - rightPadding

            // --- Privileges ticker ----------------------------------------
            MarqueeBanner {
                width: pageColumn.contentWidth
                items: root.privileges
            }

            // --- Wordmark -----------------------------------------------------
            Column {
                width: pageColumn.contentWidth
                spacing: 2

                Image {
                    source: Theme.darkMode
                            ? "qrc:/qt/qml/Drift/resources/base_wordmark_light.png"
                            : "qrc:/qt/qml/Drift/resources/base_wordmark_dark.png"
                    height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    width: implicitWidth * (height / Math.max(implicitHeight, 1))
                }

                Text {
                    text: qsTr("Create polished videos fast")
                    color: Theme.mutedForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                }
            }

            // --- Start something, side by side --------------------------------
            Row {
                width: pageColumn.contentWidth
                spacing: Theme.androidTouchGap

                Repeater {
                    model: root.createTiles

                    delegate: AbstractButton {
                        id: tile
                        required property var modelData

                        width: (pageColumn.contentWidth - Theme.androidTouchGap) / 2
                        height: Theme.androidHomeTileHeight * 1.3
                        hoverEnabled: true

                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label
                        Accessible.description: modelData.detail

                        scale: tile.down ? Theme.pressScale : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
                        }

                        onClicked: {
                            Haptics.select()
                            root.triggerCreateTile(modelData.id)
                        }

                        background: Rectangle {
                            radius: Theme.radiusMd
                            color: tile.modelData.primary
                                   ? (tile.down ? Qt.darker(Theme.primary, 1.15) : Theme.primary)
                                   : (tile.down ? Theme.panelMuted : Theme.panelBackground)
                            border.width: tile.modelData.primary ? 0 : Theme.borderWidth
                            border.color: Theme.panelBorder
                        }

                        contentItem: Column {
                            spacing: Theme.spacingSm
                            topPadding: Theme.spacingXl

                            IconGlyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                glyph: tile.modelData.icon
                                iconSize: Theme.iconSizeLg
                                iconColor: tile.modelData.primary
                                           ? Theme.primaryForeground : Theme.panelForeground
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.label
                                color: tile.modelData.primary
                                       ? Theme.primaryForeground : Theme.panelForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBase
                                font.weight: Font.Medium
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.detail
                                color: tile.modelData.primary
                                       ? Theme.primaryForeground : Theme.mutedForeground
                                opacity: tile.modelData.primary ? 0.85 : 1
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }

            // --- Recent projects, a scrolling strip ----------------------------
            Column {
                width: pageColumn.contentWidth
                spacing: Theme.spacingMd
                visible: EditorState.recentProjects.length > 0

                Item {
                    width: parent.width
                    height: recentsLabel.implicitHeight

                    ThemedLabel {
                        id: recentsLabel
                        anchors.left: parent.left
                        text: qsTr("Recent projects")
                        tone: "default"
                        size: "sm"
                    }

                    Text {
                        anchors.right: parent.right
                        text: qsTr("See all")
                        color: Theme.accentOnPanel
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Medium

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -Theme.spacingSm
                            onClicked: root.viewAllProjectsRequested()
                        }
                    }
                }

                ListView {
                    width: parent.width
                    height: Theme.androidHomeRecentCardHeight + 28
                    orientation: ListView.Horizontal
                    spacing: Theme.spacingMd
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: EditorState.recentProjects

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        width: Theme.androidHomeRecentCardHeight
                        height: Theme.androidHomeRecentCardHeight + 24
                        radius: Theme.radiusMd
                        color: Theme.panelBackground
                        border.width: Theme.borderWidth
                        border.color: Theme.panelBorder
                        opacity: modelData.exists === false ? 0.55 : 1

                        Accessible.role: Accessible.Button
                        Accessible.name: card.projectLabel

                        readonly property string projectLabel: {
                            const n = card.modelData.name || ""
                            return n.replace(/\.drift$/i, "") || qsTr("Untitled")
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSm
                            spacing: Theme.spacingSm

                            Rectangle {
                                width: parent.width
                                height: width
                                radius: Theme.radiusSm
                                color: Theme.panelAccent

                                IconGlyph {
                                    anchors.centerIn: parent
                                    glyph: Theme.icons.film
                                    iconSize: Theme.iconSizeLg
                                    iconColor: Theme.mutedForeground
                                }
                            }

                            Text {
                                width: parent.width
                                text: card.projectLabel
                                color: Theme.panelForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
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
                }
            }

            // --- Tools, a plain icon grid --------------------------------------
            Column {
                width: pageColumn.contentWidth
                spacing: Theme.spacingLg

                ThemedLabel {
                    text: qsTr("Tools")
                    tone: "default"
                    size: "sm"
                }

                Grid {
                    width: parent.width
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
                            height: 72
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

                            contentItem: Column {
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
