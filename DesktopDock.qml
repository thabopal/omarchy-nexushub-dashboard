import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "components" as Components

Item {
  id: root

  property var bar: null
  property var targetScreen: null
  property bool dockVisible: true
  property int bottomMargin: Style.space(18)

  signal nexusRequested()

  PanelWindow {
    id: dockWindow
    screen: root.targetScreen
    visible: root.dockVisible
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.namespace: "nexushub-dock"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Keep the fullscreen layer surface click-through everywhere except the
    // actual dock. This lets normal desktop/app clicks pass straight through.
    mask: Region {
      x: dock.x
      y: dock.y
      width: dock.width
      height: dock.height
    }

    Components.NexusDock {
      id: dock
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: root.bottomMargin
      bar: root.bar
      surface: "#E6151A23"
      surfaceBorder: "#7A3A4352"
      foreground: "#F4EEE7"
      muted: "#A8A0AA"
      accent: "#D86F55"
      onNexusRequested: root.nexusRequested()
    }
  }
}
