import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

// Hover label for a single dock icon: names the app and, for an app with exactly
// one window, names that window too. Apps with several windows list their titles
// in the window picker instead, so this label stays out of its way.
PopupWindow {
    id: root

    property var anchorWindow: null
    property rect anchorRect: Qt.rect(0, 0, 1, 1)
    property bool open: false
    property string title: ""
    property string subtitle: ""
    property string barPosition: "bottom"
    property bool rendered: false

    readonly property int gap: 6
    readonly property int maxTextWidth: 360
    readonly property real measuredWidth: Math.max(titleText.implicitWidth, subtitleText.implicitWidth) + 24
    readonly property real screenWidth: (root.anchorWindow && root.anchorWindow.screen) ? root.anchorWindow.screen.width : 1920

    implicitWidth: Math.max(140, Math.min(root.screenWidth - 24, root.measuredWidth))
    implicitHeight: card.implicitHeight
    visible: root.rendered && !!root.anchorWindow && (root.title.length > 0 || root.subtitle.length > 0)
    color: "transparent"
    grabFocus: false
    // Pure information: never take pointer input, so it can never swallow a hover
    // or a click meant for an icon it happens to sit next to.
    mask: Region {}

    onOpenChanged: {
        if (root.open) {
            hideTimer.stop()
            root.rendered = true
        } else {
            hideTimer.restart()
        }
    }

    Component.onCompleted: root.rendered = root.open

    Timer {
        id: hideTimer
        interval: 190
        repeat: false
        onTriggered: if (!root.open) root.rendered = false
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
            // Same convention as the window picker: barPosition is the *bar's* position,
            // so a bar at the top means the dock sits at the bottom and the label goes above.
            // The label always clears the icon row, so it can never sit under the pointer
            // on the way to a neighbouring icon.
            var r = root.anchorRect
            var x = Math.round(r.x + r.width / 2 - root.width / 2)
            var y = 0
            if (root.barPosition === "bottom") {
                y = Math.round(r.y + r.height + root.gap)
            } else if (root.barPosition === "left") {
                x = Math.round(r.x - root.width - root.gap)
                y = Math.round(r.y + r.height / 2 - root.height / 2)
            } else if (root.barPosition === "right") {
                x = Math.round(r.x + r.width + root.gap)
                y = Math.round(r.y + r.height / 2 - root.height / 2)
            } else {
                y = Math.round(r.y - root.height - root.gap)
            }
            popupAnchor.rect.x = x
            popupAnchor.rect.y = y
        }
    }

    Item {
        anchors.fill: parent

        BorderSurface {
            id: card
            anchors.fill: parent
            opacity: root.open ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            color: Color.popups.background
            borderSpec: Border.localOrSurfaceSpec("popups", "border", Color.accent, Color.popups.border, Math.max(1, Style.space(2)))
            padding: 10
            radius: Style.cornerRadius >= 0 ? Style.cornerRadius : 12
            implicitHeight: column.implicitHeight + contentTopInset + contentBottomInset

            Column {
                id: column
                anchors.fill: parent
                anchors.leftMargin: card.contentLeftInset
                anchors.rightMargin: card.contentRightInset
                anchors.topMargin: card.contentTopInset
                anchors.bottomMargin: card.contentBottomInset
                spacing: 1

                Text {
                    id: titleText
                    width: Math.min(implicitWidth, root.maxTextWidth)
                    text: root.title
                    textFormat: Text.PlainText
                    font.family: Style.font.family
                    font.pixelSize: 13
                    font.bold: true
                    color: Color.popups.text
                    elide: Text.ElideRight
                }

                Text {
                    id: subtitleText
                    width: Math.min(implicitWidth, root.maxTextWidth)
                    visible: root.subtitle.length > 0
                    text: root.subtitle
                    textFormat: Text.PlainText
                    font.family: Style.font.family
                    font.pixelSize: 11
                    color: Color.composed("popups.text", "popups.text-alpha", Color.text, 0.6)
                    elide: Text.ElideRight
                }
            }
        }
    }
}
