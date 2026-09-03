import QtQuick
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property var dockOrder: ["browser", "terminal", "editor", "spotify", "docker"]
  property var dockHidden: []

  signal itemToggled(string itemId, bool enabled)
  signal moveRequested(string itemId, int delta)

  readonly property var labels: ({
    browser: "Browser",
    terminal: "Terminal",
    editor: "Editor",
    spotify: "Spotify",
    docker: "Docker / Lazydocker"
  })

  height: controls.implicitHeight + Style.space(24)
  radius: Style.space(16)
  color: root.surface

  function itemEnabled(itemId) {
    return !(root.dockHidden instanceof Array) || root.dockHidden.indexOf(itemId) === -1
  }

  Column {
    id: controls
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(12)
    spacing: Style.space(8)

    Text {
      text: "DOCK CONTROLS"
      color: root.muted
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Repeater {
      model: root.dockOrder

      delegate: Item {
        required property string modelData
        required property int index
        width: controls.width
        height: Style.space(28)
        readonly property bool enabledInDock: root.itemEnabled(modelData)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(122)
          text: root.labels[modelData] || modelData
          color: parent.enabledInDock ? root.foreground : root.muted
          elide: Text.ElideRight
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        Rectangle {
          id: moveLeft
          anchors.right: moveRight.left
          anchors.rightMargin: Style.space(5)
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(25)
          height: Style.space(23)
          radius: Style.space(7)
          color: index > 0 ? "#242B37" : "transparent"

          Text { anchors.centerIn: parent; text: "‹"; color: index > 0 ? root.foreground : root.muted; font.pixelSize: Style.font.subtitle }
          MouseArea { anchors.fill: parent; enabled: index > 0; cursorShape: Qt.PointingHandCursor; onClicked: root.moveRequested(modelData, -1) }
        }

        Rectangle {
          id: moveRight
          anchors.right: toggle.left
          anchors.rightMargin: Style.space(9)
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(25)
          height: Style.space(23)
          radius: Style.space(7)
          color: index < root.dockOrder.length - 1 ? "#242B37" : "transparent"

          Text { anchors.centerIn: parent; text: "›"; color: index < root.dockOrder.length - 1 ? root.foreground : root.muted; font.pixelSize: Style.font.subtitle }
          MouseArea { anchors.fill: parent; enabled: index < root.dockOrder.length - 1; cursorShape: Qt.PointingHandCursor; onClicked: root.moveRequested(modelData, 1) }
        }

        Rectangle {
          id: toggle
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(38)
          height: Style.space(21)
          radius: height / 2
          color: parent.enabledInDock ? root.accent : "#303744"

          Rectangle {
            width: Style.space(15)
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: parent.parent.enabledInDock ? parent.width - width - Style.space(3) : Style.space(3)
            color: root.foreground
            Behavior on x { NumberAnimation { duration: 120 } }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.itemToggled(modelData, !parent.parent.enabledInDock)
          }
        }
      }
    }

    Text {
      width: parent.width
      text: "NexusHub stays fixed at the start of the dock."
      color: root.muted
      wrapMode: Text.WordWrap
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
