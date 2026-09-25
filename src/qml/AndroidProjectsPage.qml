import QtQuick
import QtQuick.Controls.Basic
import Drift
import "components"

// The project library: every project EditorState knows about (the same recentProjects
// list Home's strip and the desktop's recents popup already use — there is no separate
// on-disk project index to draw a bigger list from), searchable and sortable client-side.
//
// This used to be the home screen's own landing content (the create tiles + a two-column
// grid of recents). That content now lives in AndroidHomePage; this page is the "see
// everything" destination Home's "See all" link points at, matching the CapCut-style shell
// where Home is for starting something and Projects is the full library.
Item {
    id: root

    signal newProjectRequested()
    signal openProjectRequested()
    signal openRecentRequested(string path)

    property string searchText: ""
    property bool searchActive: false
    // "recent": EditorState's own order (most recently used first).
    // "name": alphabetical — the only two orderings the data supports, since recentProjects
    // carries no timestamp or size, only path/name/exists.
    property string sortMode: "recent"

    readonly property var filteredProjects: {
        const all = EditorState.recentProjects
        const needle = root.searchText.trim().toLowerCase()
        const filtered = needle.length === 0
            ? all
            : all.filter(p => (p.name || "").toLowerCase().includes(needle))
        if (root.sortMode !== "name")
            return filtered
        const copy = filtered.slice()
        copy.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
        return copy
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: root.SafeArea.margins.top
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        contentWidth: width
        contentHeight: pageColumn.implicitHeight + Theme.spacing2xl + fab.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: pageColumn
            width: parent.width
            spacing: Theme.spacingLg
            topPadding: Theme.spacingLg
            leftPadding: Theme.androidPagePadding
            rightPadding: Theme.androidPagePadding

            readonly property real contentWidth: width - leftPadding - rightPadding

            // --- Header ---------------------------------------------------
            Item {
                width: pageColumn.contentWidth
                height: Math.max(titleLabel.implicitHeight, headerActions.height)

                ThemedLabel {
                    id: titleLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Projects")
                    size: "lg"
                }

                Row {
                    id: headerActions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingSm

                    IconButton {
                        buttonSize: Theme.iconButtonSize
                        iconSize: Theme.iconSizeMd
                        glyph: root.searchActive ? Theme.icons.x : Theme.icons.search
                        variant: "text"
                        tooltip: qsTr("Search projects")
                        onClicked: {
                            root.searchActive = !root.searchActive
                            if (!root.searchActive)
                                root.searchText = ""
                        }
                    }

                    IconButton {
                        buttonSize: Theme.iconButtonSize
                        iconSize: Theme.iconSizeMd
                        glyph: root.sortMode === "recent" ? Theme.icons.clock : Theme.icons.sortByName
                        variant: "text"
                        tooltip: root.sortMode === "recent" ? qsTr("Sorted by recent") : qsTr("Sorted by name")
                        onClicked: root.sortMode = (root.sortMode === "recent" ? "name" : "recent")
                    }

                    IconButton {
                        buttonSize: Theme.iconButtonSize
                        iconSize: Theme.iconSizeMd
                        glyph: Theme.icons.folderInput
                        variant: "text"
                        tooltip: qsTr("Open a project from this device")
                        onClicked: {
                            Haptics.select()
                            root.openProjectRequested()
                        }
                    }
                }
            }

            ThemedTextField {
                width: pageColumn.contentWidth
                visible: root.searchActive
                placeholderText: qsTr("Search projects")
                text: root.searchText
                onTextChanged: root.searchText = text
                focus: root.searchActive
            }

            ThemedLabel {
                text: qsTr("%n project(s)", "", root.filteredProjects.length)
                tone: "muted"
                size: "sm"
            }

            // --- Empty states ---------------------------------------------
            ThemedLabel {
                width: pageColumn.contentWidth
                visible: EditorState.recentProjects.length === 0
                wrapMode: Text.WordWrap
                text: qsTr("Nothing here yet — projects you save will show up in this list.")
            }

            ThemedLabel {
                width: pageColumn.contentWidth
                visible: EditorState.recentProjects.length > 0 && root.filteredProjects.length === 0
                wrapMode: Text.WordWrap
                text: qsTr("No projects match “%1”.").arg(root.searchText)
            }

            // --- The library, as full-width rows ---------------------------
            Column {
                width: pageColumn.contentWidth
                spacing: Theme.spacingSm

                Repeater {
                    model: root.filteredProjects

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        width: pageColumn.contentWidth
                        height: 72
                        radius: Theme.radiusMd
                        color: Theme.panelBackground
                        border.width: Theme.borderWidth
                        border.color: Theme.panelBorder
                        opacity: modelData.exists === false ? 0.55 : 1

                        Accessible.role: Accessible.Button
                        Accessible.name: row.projectLabel

                        readonly property string projectLabel: {
                            const n = row.modelData.name || ""
                            return n.replace(/\.drift$/i, "") || qsTr("Untitled")
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.right: rowMenu.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingMd
                            anchors.rightMargin: Theme.spacingSm
                            spacing: Theme.spacingMd

                            Rectangle {
                                width: 52
                                height: 52
                                anchors.verticalCenter: parent.verticalCenter
                                radius: Theme.radiusSm
                                color: Theme.panelAccent

                                IconGlyph {
                                    anchors.centerIn: parent
                                    glyph: Theme.icons.film
                                    iconSize: Theme.iconSizeMd
                                    iconColor: Theme.mutedForeground
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 4
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: row.modelData.exists === false
                                           ? Theme.mutedForeground : Theme.constructive
                                }
                            }

                            Column {
                                width: parent.width - 52 - Theme.spacingMd
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: row.projectLabel
                                    color: Theme.panelForeground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeBase
                                    font.weight: Font.Medium
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    width: parent.width
                                    text: row.modelData.path
                                    color: Theme.mutedForeground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    elide: Text.ElideLeft
                                }
                            }
                        }

                        IconButton {
                            id: rowMenu
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: Theme.spacingXs
                            buttonSize: Theme.iconButtonSize
                            iconSize: Theme.iconSizeMd
                            glyph: Theme.icons.ellipsis
                            variant: "text"
                            tooltip: qsTr("Project actions")
                            onClicked: rowContextMenu.popup()
                        }

                        ThemedContextMenu {
                            id: rowContextMenu

                            ThemedMenuItem {
                                text: qsTr("Remove from recents")
                                icon.name: Theme.icons.trash
                                onTriggered: EditorState.removeRecentProject(row.modelData.path)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            pressAndHoldInterval: 450
                            property bool heldMenu: false
                            onPressed: heldMenu = false
                            onPressAndHold: {
                                heldMenu = true
                                Haptics.pickUp()
                                rowContextMenu.popup()
                            }
                            onClicked: {
                                if (heldMenu)
                                    return
                                if (row.modelData.exists === false) {
                                    Toasts.warning(qsTr("That project file is missing."))
                                    return
                                }
                                Haptics.select()
                                root.openRecentRequested(row.modelData.path)
                            }
                        }
                    }
                }
            }
        }
    }

    // Floating "Create" action, the way the reference library screen keeps project
    // creation reachable without scrolling back up to Home.
    AbstractButton {
        id: fab
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing2xl
        anchors.bottomMargin: Theme.spacing2xl + root.SafeArea.margins.bottom
        width: implicitWidth
        height: 48
        hoverEnabled: true

        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Create")

        scale: fab.down ? Theme.pressScale : 1.0
        Behavior on scale {
            NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
        }

        onClicked: {
            Haptics.select()
            root.newProjectRequested()
        }

        background: Rectangle {
            radius: height / 2
            color: fab.down ? Qt.darker(Theme.primary, 1.15) : Theme.primary
        }

        contentItem: Row {
            spacing: Theme.spacingSm
            leftPadding: Theme.spacingLg
            rightPadding: Theme.spacingXl

            IconGlyph {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Theme.icons.plus
                iconSize: Theme.iconSizeMd
                iconColor: Theme.primaryForeground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Create")
                color: Theme.primaryForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                font.weight: Font.Medium
            }
        }
    }
}
