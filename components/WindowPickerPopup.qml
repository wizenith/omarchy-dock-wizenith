import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

PopupWindow {
    id: root
    property var anchorWindow: null
    property rect anchorRect: Qt.rect(0, 0, 1, 1)
    property var appItem: null
    property var windows: []
    property string iconSource: ""
    property string barPosition: "bottom"
    property bool open: false
    property string errorText: ""
    property var selectedWindows: []
    property bool selecting: false
    property bool busy: false
    property string originWorkspace: ""
    property string layoutMode: "classic"
    readonly property bool dense: root.layoutMode !== "classic"
    readonly property bool listMode: root.layoutMode === "list"
    signal editingRequested()
    signal toggleRequested(var toplevel)
    signal selectAllRequested()
    signal moveRequested(string mode, bool follow)
    readonly property int bridge: 8
    readonly property int rowHeight: root.listMode ? 40 : (root.dense ? 50 : 68)
    readonly property int visibleRows: Math.max(1, Math.min(root.listMode ? 9 : (root.dense ? 7 : 6), root.windows.length,
        Math.floor(((root.anchorWindow && root.anchorWindow.screen ? root.anchorWindow.screen.height : 1080) - (root.dense ? 230 : 300)) / (root.rowHeight + 4))))
    readonly property real listOffsetY: card.y + column.y + windowList.y
    readonly property real listContentY: windowList.contentY

    signal hoverChanged(bool hovered)
    signal previewRequested(var toplevel)
    signal previewCanceled(var toplevel)
    signal selectionRequested(var toplevel)
    signal dismissRequested()

    implicitWidth: Math.min(440, (root.anchorWindow && root.anchorWindow.screen ? root.anchorWindow.screen.width : 1920) - 24)
    implicitHeight: card.implicitHeight + ((root.barPosition === "top" || root.barPosition === "bottom") ? root.bridge : 0)
    visible: root.open && root.windows.length > 0 && !!root.anchorWindow
    color: "transparent"
    grabFocus: false

    function windowTitle(top, index) {
        return top && top.title ? String(top.title).trim() : ("Window " + (index + 1))
    }

    function workspaceLabel(top) {
        var tops = Hyprland.toplevels ? Hyprland.toplevels.values : []
        for (var i = 0; i < tops.length; ++i) {
            if (tops[i] && (tops[i] === top || tops[i].wayland === top)) {
                var workspace = tops[i].workspace
                var name = workspace ? String(workspace.name || workspace.id || "") : ""
                return name.indexOf("special:") === 0 ? "已最小化" : (name ? "工作區 " + name : "")
            }
        }
        return ""
    }

    onVisibleChanged: {
        if (!visible) root.hoverChanged(false)
        else windowList.contentY = 0
    }

    anchor {
        id: popupAnchor
        window: root.anchorWindow
        adjustment: PopupAdjustment.Slide
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        rect.width: 1
        rect.height: 1
        onAnchoring: {
            var r = root.anchorRect
            var x = r.x + r.width / 2 - root.width / 2
            var y = r.y + r.height - 1
            if (root.barPosition === "top") y = r.y - root.height + 1
            else if (root.barPosition === "left") {
                x = r.x - root.width + 1
                y = r.y + r.height / 2 - root.height / 2
            } else if (root.barPosition === "right") {
                x = r.x + r.width - 1
                y = r.y + r.height / 2 - root.height / 2
            }
            popupAnchor.rect.x = Math.round(x)
            popupAnchor.rect.y = Math.round(y)
        }
    }

    // The transparent bridge is part of this input surface, so moving from the
    // icon into the card never crosses an untracked gap.
    Item {
        anchors.fill: parent
        HoverHandler { onHoveredChanged: root.hoverChanged(hovered) }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.dismissRequested()
        }

        BorderSurface {
            id: card
            anchors.fill: parent
            anchors.bottomMargin: root.barPosition === "top" ? root.bridge : 0
            anchors.topMargin: root.barPosition === "bottom" ? root.bridge : 0
            anchors.rightMargin: root.barPosition === "left" ? root.bridge : 0
            anchors.leftMargin: root.barPosition === "right" ? root.bridge : 0
            implicitHeight: column.implicitHeight + contentTopInset + contentBottomInset
            color: Color.popups.background
            borderSpec: Border.localOrSurfaceSpec("popups", "border", Color.accent, Color.popups.border, Math.max(1, Style.space(2)))
            padding: root.dense ? 8 : 12
            radius: Style.cornerRadius >= 0 ? Style.cornerRadius : 12

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.leftMargin: card.contentLeftInset
                anchors.rightMargin: card.contentRightInset
                anchors.topMargin: card.contentTopInset
                anchors.bottomMargin: card.contentBottomInset
                spacing: root.dense ? 4 : 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: root.appItem ? String(root.appItem.name || root.appItem.appId || "Windows") : "Windows"
                        textFormat: Text.PlainText
                        font.family: Style.font.family
                        font.pixelSize: 13
                        font.bold: true
                        color: Color.popups.text
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.windows.length + " 個視窗"
                        font.family: Style.font.family
                        font.pixelSize: 11
                        color: Color.accent
                    }
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 6
                        color: closeMouse.containsMouse ? Style.hoverFillFor(Color.popups.text, Color.accent) : "transparent"
                        Text { anchors.centerIn: parent; text: "×"; color: Color.popups.text; font.pixelSize: 20 }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dismissRequested()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Controls.Button {
                        text: root.busy ? "移動中…" : "集中到這裡"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.dense ? 30 : implicitHeight
                        font.pixelSize: root.dense ? 11 : Style.font.body
                        enabled: !root.busy && root.selectedWindows.length > 0 && root.originWorkspace !== ""
                        onHoveredChanged: if (hovered) root.editingRequested()
                        onClicked: root.moveRequested("here", false)
                        Controls.ToolTip.visible: hovered
                        Controls.ToolTip.text: "移至工作區 " + root.originWorkspace + "，沿用現有排列"
                    }
                    Controls.Button {
                        text: "移至新工作區"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.dense ? 30 : implicitHeight
                        font.pixelSize: root.dense ? 11 : Style.font.body
                        enabled: !root.busy && root.selectedWindows.length > 0 && root.originWorkspace !== ""
                        onHoveredChanged: if (hovered) root.editingRequested()
                        onClicked: root.moveRequested("new", followCheck.checked)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Controls.CheckBox {
                        text: "全選（" + root.selectedWindows.length + "/" + root.windows.length + "）"
                        Layout.preferredHeight: root.dense ? 28 : implicitHeight
                        font.pixelSize: root.dense ? 11 : Style.font.body
                        checked: root.windows.length > 0 && root.selectedWindows.length === root.windows.length
                        enabled: !root.busy
                        onHoveredChanged: if (hovered) root.editingRequested()
                        onClicked: root.selectAllRequested()
                    }
                    Item { Layout.fillWidth: true }
                    Controls.CheckBox {
                        id: followCheck
                        text: "移動後切換過去"
                        Layout.preferredHeight: root.dense ? 28 : implicitHeight
                        font.pixelSize: root.dense ? 11 : Style.font.body
                        checked: true
                        enabled: !root.busy
                        onHoveredChanged: if (hovered) root.editingRequested()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: !root.dense
                    text: root.selecting ? "勾選要搬移的視窗 · 點擊標題仍可切換" : "滑過標題預覽 · 勾選後暫停預覽"
                    font.family: Style.font.family
                    font.pixelSize: 11
                    color: Color.muted
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.errorText !== ""
                    text: root.errorText
                    textFormat: Text.PlainText
                    font.family: Style.font.family
                    font.pixelSize: 10
                    color: Color.accent
                    elide: Text.ElideRight
                }
                ListView {
                    id: windowList
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.visibleRows * root.rowHeight + Math.max(0, root.visibleRows - 1) * 4
                    // A count model keeps hovered delegates alive on focus/title
                    // updates; their toplevel objects carry the live properties.
                    model: root.windows.length
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: root.windows.length > root.visibleRows
                    delegate: Rectangle {
                        id: row
                        required property int index
                        readonly property var toplevel: root.windows[index] || null
                        readonly property bool isActive: !!(row.toplevel && row.toplevel.activated)
                        width: windowList.width
                        height: root.rowHeight
                        radius: Math.max(5, Style.cornerRadius - 3)
                        color: rowMouse.containsMouse ? Style.hoverFillFor(Color.popups.text, Color.accent)
                            : (row.isActive ? Color.composed("accent", "accent-alpha", Color.accent, 0.1) : "transparent")
                        border.width: row.isActive ? 1 : 0
                        border.color: Color.composed("accent", "accent-alpha", Color.accent, 0.45)
                        Behavior on color { ColorAnimation { duration: 90 } }
                        RowLayout {
                            anchors.fill: parent
                            id: rowContents
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            spacing: 10
                            Controls.CheckBox {
                                id: windowCheck
                                Layout.preferredHeight: root.dense ? 26 : implicitHeight
                                checked: root.selectedWindows.indexOf(row.toplevel) >= 0
                                enabled: !root.busy
                                onHoveredChanged: if (hovered) root.editingRequested()
                                onClicked: root.toggleRequested(row.toplevel)
                            }
                            Image {
                                visible: !root.listMode
                                Layout.preferredWidth: root.dense ? 24 : 32
                                Layout.preferredHeight: root.dense ? 24 : 32
                                source: root.iconSource
                                sourceSize: Qt.size(64, 64)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    Layout.fillWidth: true
                                    text: root.windowTitle(row.toplevel, row.index)
                                    textFormat: Text.PlainText
                                    font.family: Style.font.family
                                    font.pixelSize: 12
                                    font.bold: row.isActive
                                    color: Color.popups.text
                                    wrapMode: Text.Wrap
                                    maximumLineCount: root.dense ? 1 : 2
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: !root.listMode
                                    text: root.workspaceLabel(row.toplevel) + (row.isActive ? " · 使用中" : "")
                                    textFormat: Text.PlainText
                                    font.family: Style.font.family
                                    font.pixelSize: 10
                                    color: row.isActive ? Color.accent : Color.muted
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                visible: root.listMode
                                text: root.workspaceLabel(row.toplevel) + (row.isActive ? " · 使用中" : "")
                                textFormat: Text.PlainText
                                font.family: Style.font.family
                                font.pixelSize: 10
                                color: row.isActive ? Color.accent : Color.muted
                            }
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            anchors.leftMargin: 8 + windowCheck.width + rowContents.spacing
                            enabled: !root.busy
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onEntered: if (!windowList.moving) root.previewRequested(row.toplevel)
                            onExited: root.previewCanceled(row.toplevel)
                            onClicked: root.selectionRequested(row.toplevel)
                        }
                    }
                }
            }
        }
    }
}
