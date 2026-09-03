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
  property var dockOrder: []
  property var dockHidden: []
  property int bottomMargin: Style.space(18)

  signal nexusRequested()

  PanelWindow {
    id: dockWindow
    screen: root.targetScreen
    visible: root.dockVisible
    color: "transparent"

    // Reserve only the dock strip at the bottom of the screen. Normal tiled
    // and maximized windows now stop above it instead of rendering behind it.
    exclusionMode: root.dockVisible ? ExclusionMode.Auto : ExclusionMode.Ignore
    implicitHeight: dock.implicitHeight + root.bottomMargin

    anchors {
      bottom: true
      left: true
      right: true
    }

    // Keep the dock below normal application windows. Hyprland still honours
    // the exclusive zone for tiled/maximized clients, while real fullscreen
    // windows can cover the dock naturally.
    WlrLayershell.namespace: "nexushub-dock"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // The surface spans the screen width so it can reserve bottom space, but
    // only the actual dock accepts pointer input.
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
      dockOrder: root.dockOrder
      dockHidden: root.dockHidden
      onNexusRequested: root.nexusRequested()
    }
  }
}
