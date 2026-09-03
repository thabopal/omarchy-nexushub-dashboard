import QtQuick
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accentSoft: "#E5A66E"

  height: Style.space(92)
  radius: Style.space(16)
  color: root.surface

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(12)
    spacing: Style.space(7)

    Text {
      text: "PROJECT PULSE"
      color: root.muted
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Text {
      text: "NexusHub Dashboard"
      color: root.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.subtitle
      font.bold: true
    }

    Text {
      text: "Control Center online · weather, GitHub + telemetry live"
      color: root.accentSoft
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
