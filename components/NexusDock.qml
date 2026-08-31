import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
  id: root

  property var bar: null
  property color surface: "#151A23"
  property color surfaceBorder: "#2A3140"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property var clients: []
  property int hoveredIndex: -1
  property bool refreshPending: false

  signal nexusRequested()

  implicitWidth: dockRow.implicitWidth + 30
  implicitHeight: 68
  radius: 23
  color: root.surface
  border.width: 1
  border.color: root.surfaceBorder

  function normalize(value) {
    return String(value || "").toLowerCase()
  }

  function appRunning(patterns) {
    if (!Array.isArray(root.clients)) return false
    for (var i = 0; i < root.clients.length; i++) {
      var c = root.clients[i] || {}
      var haystack = [c.class, c.title, c.initialClass, c.initialTitle]
        .map(root.normalize)
        .join(" ")
      for (var p = 0; p < patterns.length; p++) {
        if (haystack.indexOf(root.normalize(patterns[p])) !== -1) return true
      }
    }
    return false
  }

  function refreshClients() {
    if (clientsProc.running) {
      root.refreshPending = true
      return
    }
    root.refreshPending = false
    clientsProc.running = true
  }

  function setHover(index, active) {
    if (active) root.hoveredIndex = index
    else if (root.hoveredIndex === index) root.hoveredIndex = -1
  }

  function neighborOf(index) {
    return root.hoveredIndex >= 0 && Math.abs(root.hoveredIndex - index) === 1
  }

  Component.onCompleted: refreshClients()

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return
      var name = String(event.name)
      if (name.indexOf("openwindow") !== -1 ||
          name.indexOf("closewindow") !== -1 ||
          name.indexOf("activewindow") !== -1 ||
          name.indexOf("movewindow") !== -1) {
        refreshDelay.restart()
      }
    }
  }

  Timer {
    id: refreshDelay
    interval: 180
    onTriggered: root.refreshClients()
  }

  Timer {
    interval: 3000
    repeat: true
    running: true
    onTriggered: root.refreshClients()
  }

  Process {
    id: clientsProc
    command: ["hyprctl", "-j", "clients"]
    onRunningChanged: {
      if (!running && root.refreshPending) root.refreshClients()
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text || "[]")
          if (Array.isArray(parsed)) root.clients = parsed
        } catch (e) {
          root.clients = []
        }
      }
    }
  }

  Row {
    id: dockRow
    anchors.centerIn: parent
    spacing: 5

    DockButton {
      bar: root.bar
      label: "◆"
      tooltip: "NexusHub Control Center"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      neighborHighlighted: root.neighborOf(0)
      onHoveredChanged: root.setHover(0, hovered)
      onActivated: root.nexusRequested()
    }

    Rectangle {
      width: 1
      height: 32
      color: root.surfaceBorder
      anchors.verticalCenter: parent.verticalCenter
    }

    DockButton {
      bar: root.bar
      label: ""
      tooltip: "Browser"
      command: "omarchy-launch-or-focus 'brave|chromium|firefox|google-chrome' 'omarchy-launch-browser'"
      running: root.appRunning(["brave", "chromium", "firefox", "google-chrome"])
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      neighborHighlighted: root.neighborOf(1)
      onHoveredChanged: root.setHover(1, hovered)
    }

    DockButton {
      bar: root.bar
      label: ""
      tooltip: "Terminal"
      command: "omarchy-launch-or-focus 'kitty|alacritty|foot|ghostty' 'uwsm-app -- $TERMINAL'"
      running: root.appRunning(["kitty", "alacritty", "foot", "ghostty"])
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      neighborHighlighted: root.neighborOf(2)
      onHoveredChanged: root.setHover(2, hovered)
    }

    DockButton {
      bar: root.bar
      label: ""
      tooltip: "Editor"
      command: "omarchy-launch-or-focus 'code|codium|cursor|zed' 'omarchy-launch-editor'"
      running: root.appRunning(["code", "codium", "cursor", "zed"])
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      neighborHighlighted: root.neighborOf(3)
      onHoveredChanged: root.setHover(3, hovered)
    }

    DockButton {
      bar: root.bar
      label: ""
      tooltip: "Spotify"
      command: "omarchy-launch-or-focus spotify"
      running: root.appRunning(["spotify"])
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      neighborHighlighted: root.neighborOf(4)
      onHoveredChanged: root.setHover(4, hovered)
    }

    DockButton {
      bar: root.bar
      label: ""
      tooltip: "Docker / Lazydocker"
      command: "omarchy-launch-or-focus-tui lazydocker"
      running: root.appRunning(["org.omarchy.lazydocker", "lazydocker"])
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      neighborHighlighted: root.neighborOf(5)
      onHoveredChanged: root.setHover(5, hovered)
    }
  }
}
