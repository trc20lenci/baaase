import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window
import Drift

// The home shell: a bottom-nav host over three destinations.
//
// This used to be one scrolling page whose middle band was the layout picker, so the first
// thing on screen was a question about aspect ratios rather than the user's own work. Then
// Projects became the landing page itself. Now Home is a proper CapCut-style landing page
// of its own (AndroidHomePage: start something, see what the app can do) and Projects is
// the full library you land in from "See all" or the nav bar.
//
// Market lost its nav tab (nobody asked for an addon marketplace), but it is not deleted:
// shared links still land there via startLinkImport below, so it stays in the internal
// destination list without a button pointing at it. Deleting the market backend outright
// would touch MarketClient/MarketEndpoint/MarketIdentity and the MCP dispatcher that other,
// unrelated features (in-editor stock asset import) depend on — out of scope for a nav
// change, and not something to gut without being able to rebuild and test it.
Item {
    id: root

    signal enterEditor()
    signal openProjectRequested()
    signal openRecentRequested(string path)
    signal newProjectRequested()
    signal quickEditRequested()

    readonly property string startDestination: "home"
    property string current: "home"

    readonly property bool needsAttention: {
        const win = root.Window.window
        return (win ? win.addonAttentionNeeded : false) || Updates.updateAvailable
    }

    function showDestination(destinationId) {
        if (destinationId === "market")
            marketLoader.active = true
        root.current = destinationId
    }

    // A shared link. Switches to Market and hands the url to it — parked first, because the
    // loader is asynchronous and on a cold start from a share the page does not exist yet.
    property string _pendingLinkUrl: ""

    function startLinkImport(url) {
        root._pendingLinkUrl = url
        root.showDestination("market")
        root._flushPendingLink()
    }

    function _flushPendingLink() {
        if (root._pendingLinkUrl === "" || !marketLoader.item)
            return
        const url = root._pendingLinkUrl
        root._pendingLinkUrl = ""
        marketLoader.item.startLinkImport(url)
    }

    // Android's convention: Back from a secondary destination returns to the start
    // destination rather than leaving the app. Market's own drill-down unwinds first, so a
    // Back mid-import does not skip past it straight to Home.
    function handleBack() {
        const market = marketLoader.item
        if (market && market.handleBack !== undefined && market.handleBack())
            return true
        if (root.current !== root.startDestination) {
            root.current = root.startDestination
            return true
        }
        return false
    }

    readonly property var destinationIds: ["home", "projects", "market", "me"]

    StackLayout {
        id: pages
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: nav.top
        // StackLayout keeps every destination alive, so each one holds its own scroll
        // position across a switch instead of snapping back to the top.
        currentIndex: Math.max(0, root.destinationIds.indexOf(root.current))

        AndroidHomePage {
            onNewProjectRequested: root.newProjectRequested()
            onQuickEditRequested: root.quickEditRequested()
            onOpenProjectRequested: root.openProjectRequested()
            onOpenRecentRequested: (path) => root.openRecentRequested(path)
            onViewAllProjectsRequested: root.showDestination("projects")
            onSearchProjectsRequested: {
                root.showDestination("projects")
                projectsPage.searchActive = true
            }
        }

        AndroidProjectsPage {
            id: projectsPage
            onNewProjectRequested: root.newProjectRequested()
            onOpenProjectRequested: root.openProjectRequested()
            onOpenRecentRequested: (path) => root.openRecentRequested(path)
        }

        // Lazy, because the store is a network surface nobody has asked for until a shared
        // link needs somewhere to land — but latched, not unloaded on the way out. Binding
        // `active` straight to the current destination destroyed the page on every switch
        // away, which threw out results and re-fetched the catalog; kept alive here to match.
        Loader {
            id: marketLoader
            active: false
            asynchronous: true

            sourceComponent: AndroidMarket { }

            onLoaded: root._flushPendingLink()
        }

        AndroidMePage { }
    }

    AndroidHomeNav {
        id: nav
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        current: root.current
        attention: root.needsAttention
        onSelected: (destinationId) => root.showDestination(destinationId)
    }
}
