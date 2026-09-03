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
  property var dockOrder: ["browser", "terminal", "editor", "spotify", "docker"]
  property var dockHidden: []
  readonly property var visibleDockItems: orderedDockItems()

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

  function appDefinition(itemId) {
    var definitions = {
      browser: {
        id: "browser", label: "", tooltip: "Browser",
        command: "omarchy-launch-or-focus 'brave|chromium|firefox|google-chrome' 'omarchy-launch-browser'",
        patterns: ["brave", "chromium", "firefox", "google-chrome"]
      },
      terminal: {
        id: "terminal", label: "", tooltip: "Terminal",
        command: "omarchy-launch-or-focus 'kitty|alacritty|foot|ghostty' 'uwsm-app -- $TERMINAL'",
        patterns: ["kitty", "alacritty", "foot", "ghostty"]
      },
      editor: {
        id: "editor", label: "", tooltip: "Editor",
        command: "omarchy-launch-or-focus 'code|codium|cursor|zed' 'omarchy-launch-editor'",
        patterns: ["code", "codium", "cursor", "zed"]
      },
      spotify: {
        id: "spotify", label: "", tooltip: "Spotify",
        command: "omarchy-launch-or-focus spotify",
        patterns: ["spotify"]
      },
      docker: {
        id: "docker", label: "", tooltip: "Docker / Lazydocker",
        command: "omarchy-launch-or-focus-tui lazydocker",
        patterns: ["org.omarchy.lazydocker", "lazydocker"]
      }
    }
    return definitions[itemId] || null
  }

  function orderedDockItems() {
    var defaults = ["browser", "terminal", "editor", "spotify", "docker"]
    var source = root.dockOrder instanceof Array ? root.dockOrder : defaults
    var hidden = root.dockHidden instanceof Array ? root.dockHidden : []
    var result = []
    for (var i = 0; i < source.length; i++) {
      var item = root.appDefinition(source[i])
      if (item && hidden.indexOf(item.id) === -1) result.push(item)
    }
    for (var j = 0; j < defaults.length; j++) {
      var fallback = root.appDefinition(defaults[j])
      if (source.indexOf(defaults[j]) === -1 && hidden.indexOf(defaults[j]) === -1)
        result.push(fallback)
    }
    return result
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
      visible: root.visibleDockItems.length > 0
      color: root.surfaceBorder
      anchors.verticalCenter: parent.verticalCenter
    }

    Repeater {
      model: root.visibleDockItems

      delegate: DockButton {
        required property var modelData
        required property int index
        bar: root.bar
        label: modelData.label
        tooltip: modelData.tooltip
        command: modelData.command
        running: root.appRunning(modelData.patterns)
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        neighborHighlighted: root.neighborOf(index + 1)
        onHoveredChanged: root.setHover(index + 1, hovered)
      }
    }
  }
}
