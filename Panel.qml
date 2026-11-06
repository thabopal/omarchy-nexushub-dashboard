import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "components" as Components

Panel {
  id: root
  moduleName: "dev.thabopal.nexushub-dashboard"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var settings: ({})

  readonly property bool dockEnabled: settingEnabled("dockEnabled")
  readonly property bool widgetsEnabled: settingEnabled("widgetsEnabled")
  readonly property bool systemMonitorEnabled: settingEnabled("systemMonitorEnabled")
  readonly property bool weatherEnabled: settingEnabled("weatherEnabled")
  readonly property bool githubActivityEnabled: settingEnabled("githubActivityEnabled")
  readonly property bool projectPulseEnabled: settingEnabled("projectPulseEnabled")
  readonly property bool footballEnabled: settingEnabled("footballEnabled")
  readonly property bool newsEnabled: settingEnabled("newsEnabled")
  readonly property string activeProfile: settings && settings.activeProfile
    ? String(settings.activeProfile)
    : "custom"
  readonly property var dockOrder: normalizedDockOrder()
  readonly property var dockHidden: settings && settings.dockHidden instanceof Array
    ? settings.dockHidden
    : []

  readonly property color surface: "#11151D"
  readonly property color surfaceAlt: "#171C26"
  readonly property color accent: "#D86F55"
  readonly property color accentSoft: "#E5A66E"
  readonly property color textPrimary: "#F4EEE7"
  readonly property color textMuted: "#8E8791"
  readonly property int cardRadius: 16

  function open() { root.controller.show() }
  function close() { root.controller.hide() }

  function settingEnabled(key) {
    return !root.settings || root.settings[key] !== false
  }

  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings)
      if (existing !== "id") entry[existing] = root.settings[existing]
    for (var key in values) entry[key] = values[key]

    root.settings = entry
    if (root.hostWidget && "settings" in root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setWidgetEnabled(key, enabled) {
    // Master switches are independent of the widget profile.
    if (key === "widgetsEnabled" || key === "dockEnabled") {
      var master = {}
      master[key] = enabled
      persistSettings(master)
      return
    }
    var values = { activeProfile: "custom" }
    values[key] = enabled
    persistSettings(values)
  }

  function normalizedDockOrder() {
    var defaults = ["browser", "files", "mail", "terminal", "editor", "spotify", "docker"]
    var configured = root.settings && root.settings.dockOrder instanceof Array
      ? root.settings.dockOrder
      : []
    var result = []
    for (var i = 0; i < configured.length; i++)
      if (defaults.indexOf(configured[i]) !== -1 && result.indexOf(configured[i]) === -1)
        result.push(configured[i])
    for (var j = 0; j < defaults.length; j++)
      if (result.indexOf(defaults[j]) === -1) result.push(defaults[j])
    return result
  }

  function setDockItemEnabled(itemId, enabled) {
    var hidden = root.dockHidden.slice()
    var index = hidden.indexOf(itemId)
    if (enabled && index !== -1) hidden.splice(index, 1)
    else if (!enabled && index === -1) hidden.push(itemId)
    persistSettings({ dockHidden: hidden, dockOrder: root.dockOrder })
  }

  function moveDockItem(itemId, delta) {
    var order = root.dockOrder.slice()
    var index = order.indexOf(itemId)
    var target = index + delta
    if (index < 0 || target < 0 || target >= order.length) return
    var moved = order[index]
    order.splice(index, 1)
    order.splice(target, 0, moved)
    persistSettings({ dockOrder: order })
  }

  function applyProfile(profile) {
    if (profile === "development") {
      persistSettings({
        activeProfile: profile,
        systemMonitorEnabled: true,
        weatherEnabled: false,
        githubActivityEnabled: true,
        projectPulseEnabled: true,
        footballEnabled: false,
        newsEnabled: false
      })
    } else if (profile === "focus") {
      persistSettings({
        activeProfile: profile,
        systemMonitorEnabled: true,
        weatherEnabled: false,
        githubActivityEnabled: false,
        projectPulseEnabled: false,
        footballEnabled: false,
        newsEnabled: false
      })
    } else {
      persistSettings({
        activeProfile: "daily",
        systemMonitorEnabled: true,
        weatherEnabled: true,
        githubActivityEnabled: false,
        projectPulseEnabled: true,
        footballEnabled: true,
        newsEnabled: true
      })
    }
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(content.implicitHeight + Style.space(32), Style.space(650))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Rectangle {
        anchors.fill: parent
        color: root.surface
        radius: root.cardRadius

        Flickable {
          anchors.fill: parent
          anchors.margins: Style.space(16)
          contentWidth: width
          contentHeight: content.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height

          Column {
            id: content
            width: parent.width
            spacing: Style.space(12)

          Row {
            width: parent.width
            spacing: Style.space(12)

            Column {
              width: parent.width - statusPill.width - Style.space(12)
              spacing: Style.space(2)

              Text {
                text: "NEXUSHUB"
                color: root.accent
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                font.letterSpacing: 2
              }

              Text {
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                color: root.textMuted
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }

            Rectangle {
              id: statusPill
              width: statusText.implicitWidth + Style.space(18)
              height: Style.space(28)
              radius: height / 2
              color: "#202632"

              Text {
                id: statusText
                anchors.centerIn: parent
                text: "OMARCHY"
                color: root.textMuted
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }
          }

          Rectangle {
            width: parent.width
            height: Style.space(104)
            radius: root.cardRadius
            color: root.surfaceAlt

            Column {
              anchors.centerIn: parent
              spacing: Style.space(3)

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: root.textPrimary
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.displayLarge
                font.bold: true
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Build. Secure. Connect."
                color: root.accentSoft
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }

          Components.GitHubActivity {
            width: parent.width
            visible: root.githubActivityEnabled
            bar: root.bar
            username: "thabopal"
            surface: root.surfaceAlt
            foreground: root.textPrimary
            muted: root.textMuted
            accent: root.accent
            accentSoft: root.accentSoft
          }

          Components.ProjectPulse {
            width: parent.width
            visible: root.projectPulseEnabled
            bar: root.bar
            surface: root.surfaceAlt
            foreground: root.textPrimary
            muted: root.textMuted
            accentSoft: root.accentSoft
          }

          Components.WidgetControls {
            width: parent.width
            bar: root.bar
            surface: root.surfaceAlt
            foreground: root.textPrimary
            muted: root.textMuted
            accent: root.accent
            activeProfile: root.activeProfile
            widgetsEnabled: root.widgetsEnabled
            systemMonitorEnabled: root.systemMonitorEnabled
            weatherEnabled: root.weatherEnabled
            githubActivityEnabled: root.githubActivityEnabled
            projectPulseEnabled: root.projectPulseEnabled
            footballEnabled: root.footballEnabled
            newsEnabled: root.newsEnabled
            onProfileRequested: function(profile) { root.applyProfile(profile) }
            onWidgetRequested: function(key, enabled) { root.setWidgetEnabled(key, enabled) }
          }

          Components.DockControls {
            width: parent.width
            bar: root.bar
            surface: root.surfaceAlt
            foreground: root.textPrimary
            muted: root.textMuted
            accent: root.accent
            dockOrder: root.dockOrder
            dockHidden: root.dockHidden
            dockEnabled: root.dockEnabled
            onDockToggled: function(enabled) { root.setWidgetEnabled("dockEnabled", enabled) }
            onItemToggled: function(itemId, enabled) { root.setDockItemEnabled(itemId, enabled) }
            onMoveRequested: function(itemId, delta) { root.moveDockItem(itemId, delta) }
          }

          Text {
            width: parent.width
            text: "NexusHub Control Center · desktop widgets, GitHub and projects"
            color: root.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          }
        }
      }
    }
  }
}
