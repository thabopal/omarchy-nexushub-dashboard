import QtQuick

Rectangle {
  id: root

  property var bar: null
  property color surface: "#151A23"
  property color surfaceBorder: "#2A3140"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"

  signal nexusRequested()

  implicitWidth: dockRow.implicitWidth + 30
  implicitHeight: 66
  radius: 22
  color: root.surface
  border.width: 1
  border.color: root.surfaceBorder

  Row {
    id: dockRow
    anchors.centerIn: parent
    spacing: 6

    DockButton {
      bar: root.bar
      label: "NX"
      tooltip: "NexusHub Control Center"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      onActivated: root.nexusRequested()
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
      tooltip: "Docker / Lazydocker"
      command: "omarchy-launch-tui lazydocker"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
    }
  }
}
