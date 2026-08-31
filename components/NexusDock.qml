import QtQuick

Rectangle {
  id: root

  property var bar: null
  property color surface: "#151A23"
  property color surfaceBorder: "#2A3140"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"

  implicitWidth: dockRow.implicitWidth + 28
  implicitHeight: 62
  radius: 20
  color: root.surface
  border.width: 1
  border.color: root.surfaceBorder

  Row {
    id: dockRow
    anchors.centerIn: parent
    spacing: 5

    DockButton {
      bar: root.bar
      label: "NX"
      tooltip: "Omarchy"
      command: "omarchy-menu"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }

    Rectangle {
      width: 1
      height: 30
      color: root.surfaceBorder
      anchors.verticalCenter: parent.verticalCenter
    }

    DockButton {
      bar: root.bar
      label: "WEB"
      tooltip: "Browser"
      command: "omarchy-launch-browser"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }

    DockButton {
      bar: root.bar
      label: ">_"
      tooltip: "Terminal"
      command: "uwsm-app -- $TERMINAL"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }

    DockButton {
      bar: root.bar
      label: "DEV"
      tooltip: "Editor"
      command: "omarchy-launch-editor"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }

    DockButton {
      bar: root.bar
      label: "SP"
      tooltip: "Spotify"
      command: "omarchy-launch-or-focus spotify"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }

    DockButton {
      bar: root.bar
      label: "DK"
      tooltip: "Docker"
      command: "omarchy-launch-tui lazydocker"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }
  }
}
