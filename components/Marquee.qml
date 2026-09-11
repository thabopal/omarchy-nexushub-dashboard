import QtQuick
import qs.Commons

Item {
  id: root

  property string text: ""
  property color textColor: "#F4EEE7"
  property string fontFamily: Style.font.family
  property int fontPixelSize: Style.font.caption
  property real pixelsPerSecond: 36
  property real gap: Style.space(48)

  height: Style.space(18)
  clip: true

  readonly property bool overflowing: measure.implicitWidth > root.width

  Text {
    id: measure
    visible: false
    text: root.text
    font.family: root.fontFamily
    font.pixelSize: root.fontPixelSize
  }

  Text {
    visible: !root.overflowing
    anchors.verticalCenter: parent.verticalCenter
    text: root.text
    color: root.textColor
    font.family: root.fontFamily
    font.pixelSize: root.fontPixelSize
    elide: Text.ElideRight
    width: root.width
  }

  Row {
    id: track
    visible: root.overflowing
    height: parent.height
    spacing: root.gap

    Text {
      id: copyA
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontPixelSize
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontPixelSize
    }

    NumberAnimation on x {
      running: root.overflowing
      loops: Animation.Infinite
      from: 0
      to: -(copyA.implicitWidth + track.spacing)
      duration: Math.max(1, (copyA.implicitWidth + track.spacing) / root.pixelsPerSecond * 1000)
    }
  }
}
