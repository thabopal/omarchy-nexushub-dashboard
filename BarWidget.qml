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
    onNexusRequested: root.toggle()
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
