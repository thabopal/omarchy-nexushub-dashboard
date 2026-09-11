import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "dev.thabopal.nexushub-dashboard"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false
  readonly property bool dockEnabled: !root.settings || root.settings.dockEnabled !== false
  readonly property bool systemMonitorEnabled: !root.settings || root.settings.systemMonitorEnabled !== false
  readonly property bool weatherEnabled: !root.settings || root.settings.weatherEnabled !== false
  readonly property bool eplEnabled: !root.settings || root.settings.eplEnabled !== false
  readonly property bool uclEnabled: !root.settings || root.settings.uclEnabled !== false
  readonly property bool newsEnabled: !root.settings || root.settings.newsEnabled !== false
  readonly property string footballApiKey: root.settings && root.settings.footballApiKey
    ? String(root.settings.footballApiKey)
    : ""
  readonly property var dockOrder: root.settings && root.settings.dockOrder instanceof Array
    ? root.settings.dockOrder
    : ["browser", "files", "mail", "terminal", "editor", "spotify", "docker"]
  readonly property var dockHidden: root.settings && root.settings.dockHidden instanceof Array
    ? root.settings.dockHidden
    : []

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.settings = root.settings
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  function dockScreen() {
    try {
      return button.QsWindow.window ? button.QsWindow.window.screen : null
    } catch (e) {
      return null
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  DesktopDock {
    id: desktopDock
    bar: root.bar
    targetScreen: root.dockScreen()
    dockVisible: root.dockEnabled
    dockOrder: root.dockOrder
    dockHidden: root.dockHidden
    onNexusRequested: root.toggle()
  }

  DesktopWidgets {
    bar: root.bar
    targetScreen: root.dockScreen()
    systemMonitorVisible: root.systemMonitorEnabled
    weatherVisible: root.weatherEnabled
    eplVisible: root.eplEnabled
    uclVisible: root.uclEnabled
    newsVisible: root.newsEnabled
    footballApiKey: root.footballApiKey
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "NX"
    tooltipText: "Open NexusHub Control Center"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
