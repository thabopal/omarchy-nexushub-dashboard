import QtQuick

Item {
  id: root

  property var bar: null
  property string label: "APP"
  property string tooltip: ""
  property string command: ""
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color surfaceHover: "#252C38"
  property bool running: false
  property bool neighborHighlighted: false
  readonly property bool hovered: mouse.containsMouse

  signal activated()

  implicitWidth: 50
  implicitHeight: 50
  transformOrigin: Item.Bottom
  scale: hovered ? 1.16 : (neighborHighlighted ? 1.06 : 1.0)

  Behavior on scale {
    NumberAnimation { duration: 155; easing.type: Easing.OutCubic }
  }

  function launch() {
    root.activated()
    if (!root.command.length) return
    if (root.bar && typeof root.bar.run === "function") root.bar.run(root.command)
  }

  Rectangle {
    anchors.fill: parent
    radius: 15
    color: root.hovered ? root.surfaceHover : "transparent"

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: root.running ? -2 : 0
      text: root.label
      color: root.hovered ? root.foreground : root.muted
      font.family: "monospace"
      font.pixelSize: root.label.length <= 2 ? 19 : 13
      font.bold: true

      Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
      width: root.running ? 16 : (root.hovered ? 12 : 0)
      height: 3
      radius: 2
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 3
      color: root.accent
      opacity: root.running ? 1 : (root.hovered ? 0.8 : 0)

      Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }
  }

  Rectangle {
    id: tooltipBubble
    visible: root.hovered && root.tooltip.length > 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.top
    anchors.bottomMargin: 10
    width: tooltipText.implicitWidth + 18
    height: 28
    radius: 9
    color: "#F21A202A"
    border.width: 1
    border.color: "#663A4352"
    z: 100

    Text {
      id: tooltipText
      anchors.centerIn: parent
      text: root.tooltip
      color: root.foreground
      font.family: "monospace"
      font.pixelSize: 11
      font.bold: true
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.launch()
  }
}
