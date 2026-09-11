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
  property bool footballVisible: true
  property bool newsVisible: true
  property string footballApiKey: ""

  readonly property bool hasVisibleWidgets: root.systemMonitorVisible || root.weatherVisible
    || root.footballVisible || root.newsVisible

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

    // Most widgets here are purely informational: leave that part of the
    // surface click-through so desktop and application input continues to
    // behave normally. Football (competition switch) and News (headline
    // links) have real controls, so their own bounds accept input — same
    // approach as the dock's mask matching just its own strip.
    mask: Region {
      Region { item: footballLoader }
      Region { item: newsLoader }
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

      Loader {
        id: footballLoader
        width: parent.width
        active: root.footballVisible
        visible: active
        height: item ? item.implicitHeight : 0

        sourceComponent: Components.FootballCard {
          width: parent ? parent.width : 0
          bar: root.bar
          apiKey: root.footballApiKey
          surface: "#E6171C26"
          foreground: "#F4EEE7"
          muted: "#A8A0AA"
          accent: "#D86F55"
          accentSoft: "#E5A66E"
        }
      }

      Loader {
        id: newsLoader
        width: parent.width
        active: root.newsVisible
        visible: active
        height: item ? item.implicitHeight : 0

        sourceComponent: Components.NewsCard {
          width: parent ? parent.width : 0
          bar: root.bar
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
