import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../DockModel.js" as DockModel

// Owned by DockPanel, not by its replaceable application delegates.
Item {
    id: root
    required property var dock
    readonly property string revision: "hover-picker-6"
    readonly property double loadedAt: Date.now()
    property bool opened: false
    property bool popupHovered: false
    property string iconHoveredId: ""
    property string appId: ""
    property var appItem: null
    property var windows: []
    property var anchorWindow: null
    property rect anchorRect: Qt.rect(0, 0, 1, 1)
    property string iconSource: ""
    property var pendingOpen: null
    property var pendingTop: null
    property var queuedAction: null
    property string lastError: ""
    property var lastResult: null
    property string originWorkspace: ""
    property var selectedWindows: []
    property bool selecting: false
    readonly property bool busy: !!(root.queuedAction && root.queuedAction.move) || (focusProcess.running && !!(focusProcess.action && focusProcess.action.move))

    function beginSelection() {
        root.selecting = true
        previewTimer.stop()
        root.pendingTop = null
        if (root.queuedAction && root.queuedAction.preview) root.queuedAction = null
    }

    function toggleSelection(top) {
        if (root.busy) return
        root.beginSelection()
        var next = root.selectedWindows.slice()
        var index = next.indexOf(top)
        if (index < 0) next.push(top)
        else next.splice(index, 1)
        root.selectedWindows = next
    }

    function selectAll() {
        if (root.busy) return
        root.beginSelection()
        root.selectedWindows = root.selectedWindows.length === root.windows.length ? [] : root.windows.slice()
    }

    function moveSelected(mode, follow) {
        if (root.busy || !root.selectedWindows.length || !root.originWorkspace) return
        root.beginSelection()
        var addresses = root.selectedWindows.map(function(top) { return root.addressFor(top) })
        if (addresses.some(function(address) { return !address })) {
            root.lastError = "部分視窗已關閉，請重新選取"
            root.refresh()
            return
        }
        root.lastError = ""
        root.queuedAction = { move: true, mode: mode, follow: follow, origin: root.originWorkspace, addresses: addresses }
        root.pump()
    }

    function itemId(item) {
        return item ? String(item.appId || item.id || "") : ""
    }

    function findItem(key) {
        var items = root.dock.dockItems || []
        for (var i = 0; i < items.length; ++i) {
            if (root.itemId(items[i]) === key && !items[i].isStack) return items[i]
        }
        return null
    }

    function enter(item, source) {
        if (root.busy || !item || item.isStack || root.dock.isEditMode || root.dock.dockDragActiveIndex >= 0) return
        var key = root.itemId(item)
        root.iconHoveredId = key
        if (root.opened && root.appId === key) {
            closeTimer.stop()
            return
        }
        if (!item.toplevels || item.toplevels.length < (root.dock.showSingleWindowPicker ? 1 : 2)) return
        var win = source.QsWindow.window
        if (!win) return
        var point = win.contentItem.mapFromItem(source, 0, 0)
        root.pendingOpen = {
            appId: key, window: win,
            rect: Qt.rect(point.x, point.y, source.width, source.height),
            icon: source.resolveIcon(item)
        }
        closeTimer.stop()
        // Titles/focus can change while the pointer is still over this icon.
        if (!openTimer.running) openTimer.start()
    }

    function leave(item) {
        var key = root.itemId(item)
        if (root.iconHoveredId === key) root.iconHoveredId = ""
        if (root.pendingOpen && root.pendingOpen.appId === key) {
            openTimer.stop()
            root.pendingOpen = null
        }
        root.scheduleClose()
    }

    function refresh() {
        if (!root.opened) return
        var item = root.findItem(root.appId)
        var next = item && item.toplevels ? item.toplevels.filter(function(top) { return !!top }) : []
        if (next.length < (root.dock.showSingleWindowPicker ? 1 : 2)) {
            root.close()
            return
        }
        root.appItem = item
        var unchanged = next.length === root.windows.length
        for (var i = 0; unchanged && i < next.length; ++i) unchanged = next[i] === root.windows[i]
        // Preserve row objects/hover/scroll position on focus and title updates.
        if (!unchanged) {
            root.windows = next
            root.selectedWindows = root.selectedWindows.filter(function(top) { return next.indexOf(top) >= 0 })
        }
    }

    function scheduleClose() {
        if (root.opened && !root.popupHovered && root.iconHoveredId !== root.appId) closeTimer.restart()
    }

    function close() {
        openTimer.stop()
        closeTimer.stop()
        previewTimer.stop()
        root.pendingOpen = null
        root.pendingTop = null
        if (root.queuedAction && root.queuedAction.preview) root.queuedAction = null
        root.opened = false
        root.popupHovered = false
        root.iconHoveredId = ""
    }

    function addressFor(top) {
        var tops = Hyprland.toplevels ? Hyprland.toplevels.values : []
        return DockModel.hyprAddressFor(top, tops)
    }

    function preview(top) {
        if (!root.opened || root.selecting || root.busy || root.windows.indexOf(top) < 0) return
        root.pendingTop = top
        previewTimer.restart()
    }

    function cancelPreview(top) {
        if (root.pendingTop !== top) return
        previewTimer.stop()
        root.pendingTop = null
        if (root.queuedAction && root.queuedAction.preview) root.queuedAction = null
    }

    function select(top) {
        if (root.busy || root.windows.indexOf(top) < 0) return
        var address = root.addressFor(top)
        if (!address) {
            root.lastError = "The selected window has closed"
            root.refresh()
            return
        }
        root.close()
        root.queuedAction = { address: address, preview: false }
        root.pump()
    }

    function pump() {
        if (focusProcess.running || !root.queuedAction) return
        var action = root.queuedAction
        root.queuedAction = null
        if (action.preview && !root.opened) return
        focusProcess.action = action
        var script = action.move ? "dock-window-move.py" : "dock-window-focus.py"
        var path = Qt.resolvedUrl("../scripts/" + script).toString().replace(/^file:\/\//, "")
        focusProcess.command = action.move
            ? ["python3", "-B", path, action.mode, action.origin].concat(action.addresses).concat(action.follow ? ["--follow"] : [])
            : ["python3", "-B", path, action.address].concat(action.preview ? ["--preview"] : [])
        focusProcess.running = true
    }

    function debugState() {
        var rows = root.windows.map(function(top, index) {
            return { index: index, address: root.addressFor(top), title: top ? top.title : "", active: !!(top && top.activated) }
        })
        var icons = []
        var win = root.dock.dockWindow
        var repeater = win ? win.appItems : null
        for (var i = 0; repeater && i < repeater.count; ++i) {
            var item = repeater.itemAt(i)
            if (!item) continue
            var p = win.contentItem.mapFromItem(item, 0, 0)
            icons.push({ appId: root.itemId(item.itemData), count: item.itemData && item.itemData.toplevels ? item.itemData.toplevels.length : 0,
                x: p.x + item.width / 2, y: p.y + item.height / 2 })
        }
        return JSON.stringify({ revision: root.revision, loadedAt: root.loadedAt, opened: root.opened,
            originWorkspace: root.originWorkspace, selectedCount: root.selectedWindows.length, selecting: root.selecting, hovered: root.popupHovered, appId: root.appId, rows: rows, icons: icons,
            tooltip: { requested: !!root.dock.tooltipRequested, open: !!root.dock.tooltipOpen,
                appId: String(root.dock.tooltipAppId || ""), title: String(root.dock.tooltipTitle || "") },
            timing: { openDelayMs: root.dock.windowPickerOpenDelayMs, previewDelayMs: root.dock.windowPickerPreviewDelayMs,
                closeDelayMs: root.dock.windowPickerCloseDelayMs, fadeDurationMs: root.dock.windowPickerFadeDurationMs },
            error: root.lastError, lastResult: root.lastResult, busy: focusProcess.running,
            coordinateSpace: "dock-local", screen: win && win.screen ? win.screen.name : "",
            popup: { visible: popup.visible, x: popup.anchor.rect.x, y: popup.anchor.rect.y, width: popup.width, height: popup.height,
                listY: popup.listOffsetY, rowHeight: popup.rowHeight, contentY: popup.listContentY } })
    }

    Timer {
        id: openTimer
        interval: root.dock.windowPickerOpenDelayMs
        onTriggered: {
            var pending = root.pendingOpen
            if (!pending || root.iconHoveredId !== pending.appId) return
            var item = root.findItem(pending.appId)
            if (!item || !item.toplevels || item.toplevels.length < (root.dock.showSingleWindowPicker ? 1 : 2)) return
            root.appId = pending.appId
            root.anchorWindow = pending.window
            root.anchorRect = pending.rect
            root.iconSource = pending.icon
            root.lastError = ""
            root.pendingTop = null
            root.dock.activeStackItem = null
            root.dock.activeMenuItem = null
            var monitor = Hyprland.monitorFor(root.anchorWindow.screen)
            var workspace = monitor ? monitor.activeWorkspace : Hyprland.focusedWorkspace
            root.originWorkspace = workspace ? String(workspace.name || workspace.id) : ""
            root.selecting = false
            root.opened = true
            root.refresh()
            root.selectedWindows = root.windows.slice()
        }
    }

    Timer {
        id: closeTimer
        interval: root.dock.windowPickerCloseDelayMs
        onTriggered: {
            if (!root.popupHovered && root.iconHoveredId !== root.appId) root.close()
        }
    }

    Timer {
        id: previewTimer
        interval: root.dock.windowPickerPreviewDelayMs
        onTriggered: {
            var top = root.pendingTop
            if (!root.opened || root.selecting || root.busy || !root.popupHovered || !top || root.windows.indexOf(top) < 0 || top.activated) return
            var address = root.addressFor(top)
            if (!address) return
            root.queuedAction = { address: address, preview: true }
            root.pump()
        }
    }

    Process {
        id: focusProcess
        property var action: null
        stdout: StdioCollector { id: focusOutput }
        stderr: StdioCollector { id: focusErrors }
        onExited: function(exitCode, exitStatus) {
            try {
                root.lastResult = JSON.parse(focusOutput.text)
                root.lastError = root.lastResult.ok ? "" : String(root.lastResult.error || "Window focus failed")
            } catch (error) {
                root.lastError = focusErrors.text || "Window focus helper did not respond"
            }
            if (focusProcess.action && focusProcess.action.move && !root.lastError) root.close()
            if (root.lastError) console.warn("Dock window picker:", root.lastError)
            Qt.callLater(root.pump)
        }
    }

    onOpenedChanged: root.dock.evaluateHoverState()

    Connections {
        target: root.dock
        function onDockItemsChanged() { root.refresh() }
        function onShowSingleWindowPickerChanged() { root.refresh() }
        function onDockRevealedChanged() { if (!root.dock.dockRevealed) root.close() }
        function onIsEditModeChanged() { if (root.dock.isEditMode) root.close() }
        function onDockDragActiveIndexChanged() { if (root.dock.dockDragActiveIndex >= 0) root.close() }
        function onIsStackOpenChanged() { if (root.dock.isStackOpen) root.close() }
        function onIsMenuOpenChanged() { if (root.dock.isMenuOpen) root.close() }
    }

    WindowPickerPopup {
        id: popup
        anchorWindow: root.anchorWindow
        anchorRect: root.anchorRect
        appItem: root.appItem
        windows: root.windows
        iconSource: root.iconSource
        barPosition: root.dock.barPosition
        layoutMode: root.dock.windowPickerLayout
        fadeDurationMs: root.dock.windowPickerFadeDurationMs
        open: root.opened
        errorText: root.lastError
        selectedWindows: root.selectedWindows
        selecting: root.selecting
        busy: root.busy
        originWorkspace: root.originWorkspace
        onEditingRequested: root.beginSelection()
        onToggleRequested: function(top) { root.toggleSelection(top) }
        onSelectAllRequested: root.selectAll()
        onMoveRequested: function(mode, follow) { root.moveSelected(mode, follow) }
        onHoverChanged: function(hovered) {
            root.popupHovered = hovered
            if (hovered) closeTimer.stop()
            else root.scheduleClose()
        }
        onPreviewRequested: function(top) { root.preview(top) }
        onPreviewCanceled: function(top) { root.cancelPreview(top) }
        onSelectionRequested: function(top) { root.select(top) }
        onDismissRequested: root.close()
    }
}
