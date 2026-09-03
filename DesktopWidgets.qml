import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "components" as Components

Item {
  id: root

  property var bar: null
  property var targetScreen: null
  property bool systemMonitorVisible: true
  property bool weatherVisible: true

  readonly property bool hasVisibleWidgets: root.systemMonitorVisible || root.weatherVisible

  PanelWindow {
    id: desktopWindow
    screen: root.targetScreen
    visible: root.hasVisibleWidgets && root.targetScreen !== null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Style.space(430)
    implicitHeight: widgetColumn.implicitHeight

    anchors {
      top: true
      right: true
    }

    margins {
      top: Style.space(72)
      right: Style.space(24)
    }

    WlrLayershell.namespace: "nexushub-desktop-widgets"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // These widgets are informational: leave the entire surface click-through
    // so desktop and application input continues to behave normally.
    mask: Region {
      width: 0
      height: 0
    }

    Column {
      id: widgetColumn
      width: parent.width
      spacing: Style.space(12)

      Loader {
        width: parent.width
        active: root.systemMonitorVisible
        visible: active
        height: item ? item.implicitHeight : 0

        sourceComponent: Components.SystemMonitor {
          width: parent ? parent.width : 0
          bar: root.bar
          surface: "#E6171C26"
          track: "#CC242B37"
          foreground: "#F4EEE7"
          muted: "#A8A0AA"
          accent: "#D86F55"
          accentSoft: "#E5A66E"
        }
      }

      Loader {
        width: parent.width
        active: root.weatherVisible
        visible: active
        height: item ? item.implicitHeight : 0

        sourceComponent: Components.WeatherCard {
          width: parent ? parent.width : 0
          bar: root.bar
          locationName: "Bloemfontein"
          latitude: -29.0852
          longitude: 26.1596
          surface: "#E6171C26"
          foreground: "#F4EEE7"
          muted: "#A8A0AA"
          accent: "#D86F55"
          accentSoft: "#E5A66E"
        }
      }
    }
  }
}
