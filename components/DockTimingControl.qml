import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
    id: root

    required property string label
    required property string description
    required property int value
    property int minimum: 0
    property int maximum: 1000
    property int step: 50
    signal valueEdited(int value)

    implicitHeight: 48

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.label
                textFormat: Text.PlainText
                font.family: Style.font.family
                font.pixelSize: 12
                font.bold: true
                color: Color.popups.text
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.description
                textFormat: Text.PlainText
                font.family: Style.font.family
                font.pixelSize: 10
                color: Color.muted
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: minusMouse.containsMouse ? Style.hoverFillFor(Color.popups.text, Color.accent) : "transparent"
            opacity: root.value <= root.minimum ? 0.4 : 1.0

            Text {
                anchors.centerIn: parent
                text: "−"
                font.family: Style.font.family
                font.pixelSize: 17
                color: Color.popups.text
            }

            MouseArea {
                id: minusMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.value > root.minimum
                cursorShape: Qt.PointingHandCursor
                onClicked: root.valueEdited(Math.max(root.minimum, root.value - root.step))
            }
        }

        Text {
            Layout.preferredWidth: 58
            horizontalAlignment: Text.AlignHCenter
            text: (root.value / 1000).toFixed(2) + " s"
            textFormat: Text.PlainText
            font.family: Style.font.family
            font.pixelSize: 11
            color: Color.accent
        }

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: plusMouse.containsMouse ? Style.hoverFillFor(Color.popups.text, Color.accent) : "transparent"
            opacity: root.value >= root.maximum ? 0.4 : 1.0

            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: Style.font.family
                font.pixelSize: 16
                color: Color.popups.text
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.value < root.maximum
                cursorShape: Qt.PointingHandCursor
                onClicked: root.valueEdited(Math.min(root.maximum, root.value + root.step))
            }
        }
    }
}
