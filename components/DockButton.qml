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

  signal activated()

  implicitWidth: 48
  implicitHeight: 48
  scale: mouse.containsMouse ? 1.08 : 1.0

  Behavior on scale {
    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
  }

  function launch() {
    root.activated()
    if (!root.command.length) return
    if (root.bar && typeof root.bar.run === "function") root.bar.run(root.command)
  }

  Rectangle {
    anchors.fill: parent
    radius: 14
    color: mouse.containsMouse ? root.surfaceHover : "transparent"

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: root.running ? -2 : 0
      text: root.label
      color: mouse.containsMouse ? root.foreground : root.muted
      font.pixelSize: root.label.length <= 2 ? 14 : 10
      font.bold: true
      font.letterSpacing: root.label.length <= 2 ? 0.5 : 0

      Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
      width: mouse.containsMouse ? 18 : 6
      height: 3
      radius: 2
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 3
      color: root.accent
      opacity: root.running ? 1 : (mouse.containsMouse ? 0.9 : 0)

      Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 120 } }
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
