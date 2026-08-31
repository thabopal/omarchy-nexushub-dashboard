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

  readonly property color surface: "#11151D"
  readonly property color surfaceAlt: "#171C26"
  readonly property color accent: "#D86F55"
  readonly property color accentSoft: "#E5A66E"
  readonly property color textPrimary: "#F4EEE7"
  readonly property color textMuted: "#8E8791"
  readonly property int cardRadius: 16
  readonly property bool dockEnabled: !root.hostWidget || !root.hostWidget.settings || root.hostWidget.settings.dockEnabled !== false

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
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
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Rectangle {
        anchors.fill: parent
        color: root.surface
        radius: root.cardRadius

        Column {
          id: content
          anchors.fill: parent
          anchors.margins: Style.space(16)
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

          Row {
            width: parent.width
            spacing: Style.space(10)

            Rectangle {
              width: (parent.width - Style.space(10)) / 2
              height: Style.space(92)
              radius: root.cardRadius
              color: root.surfaceAlt

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(12)
                spacing: Style.space(6)
                Text { text: "WEATHER"; color: root.textMuted; font.pixelSize: Style.font.caption; font.bold: true }
                Text { text: "18°"; color: root.textPrimary; font.pixelSize: Style.font.displayMedium; font.bold: true }
                Text { text: "Bloemfontein · preview"; color: root.accentSoft; font.pixelSize: Style.font.caption }
              }
            }

            Rectangle {
              width: (parent.width - Style.space(10)) / 2
              height: Style.space(92)
              radius: root.cardRadius
              color: root.surfaceAlt

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(12)
                spacing: Style.space(6)
                Text { text: "SYSTEM"; color: root.textMuted; font.pixelSize: Style.font.caption; font.bold: true }
                Text { text: "CPU  24%"; color: root.textPrimary; font.pixelSize: Style.font.subtitle; font.bold: true }
                Text { text: "RAM  41%"; color: root.textMuted; font.pixelSize: Style.font.caption }
              }
            }
          }

          Rectangle {
            width: parent.width
            height: Style.space(92)
            radius: root.cardRadius
            color: root.surfaceAlt

            Column {
              anchors.fill: parent
              anchors.margins: Style.space(12)
              spacing: Style.space(7)
              Text { text: "PROJECT PULSE"; color: root.textMuted; font.pixelSize: Style.font.caption; font.bold: true }
              Text { text: "NexusHub Dashboard"; color: root.textPrimary; font.pixelSize: Style.font.subtitle; font.bold: true }
              Text { text: "Theme core ready · dock alpha ready"; color: root.accentSoft; font.pixelSize: Style.font.caption }
            }
          }

          Components.NexusDock {
            visible: root.dockEnabled
            anchors.horizontalCenter: parent.horizontalCenter
            bar: root.bar
            surface: "#151A23"
            surfaceBorder: "#2A3140"
            foreground: root.textPrimary
            muted: root.textMuted
            accent: root.accent
          }

          Text {
            width: parent.width
            text: root.dockEnabled
              ? "Dock alpha · hover and click the app buttons"
              : "Dock disabled in NexusHub widget settings"
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
