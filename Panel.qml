import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "dev.thabopal.nexushub-dashboard"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  property int cpuUsage: -1
  property int ramUsage: -1
  property int diskUsage: -1
  property string uptimeText: "--"
  property bool systemSampleReady: false

  readonly property color surface: "#11151D"
  readonly property color surfaceAlt: "#171C26"
  readonly property color accent: "#D86F55"
  readonly property color accentSoft: "#E5A66E"
  readonly property color textPrimary: "#F4EEE7"
  readonly property color textMuted: "#8E8791"
  readonly property int cardRadius: 16

  function open() { root.controller.show() }
  function close() { root.controller.hide() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function percentText(value) {
    return value >= 0 ? value + "%" : "--"
  }

  function refreshSystemStats() {
    if (!systemStats.running) systemStats.running = true
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Process {
    id: systemStats
    command: [
      "bash",
      "-lc",
      "read -r _ u1 n1 s1 i1 io1 irq1 sirq1 st1 _ < /proc/stat; t1=$((u1+n1+s1+i1+io1+irq1+sirq1+st1)); idle1=$((i1+io1)); sleep 0.18; read -r _ u2 n2 s2 i2 io2 irq2 sirq2 st2 _ < /proc/stat; t2=$((u2+n2+s2+i2+io2+irq2+sirq2+st2)); idle2=$((i2+io2)); dt=$((t2-t1)); di=$((idle2-idle1)); if (( dt > 0 )); then cpu=$((100*(dt-di)/dt)); else cpu=0; fi; mt=$(awk '/MemTotal:/ {print $2}' /proc/meminfo); ma=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo); if (( mt > 0 )); then ram=$((100*(mt-ma)/mt)); else ram=0; fi; disk=$(df -P / | awk 'NR==2 {gsub(/%/,\"\",$5); print $5}'); up=$(cut -d. -f1 /proc/uptime); days=$((up/86400)); hours=$(((up%86400)/3600)); mins=$(((up%3600)/60)); if (( days > 0 )); then uptime=\"${days}d ${hours}h\"; elif (( hours > 0 )); then uptime=\"${hours}h ${mins}m\"; else uptime=\"${mins}m\"; fi; printf '%s|%s|%s|%s\\n' \"$cpu\" \"$ram\" \"$disk\" \"$uptime\""
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var line = String(text || "").trim()
        var parts = line.split("|")
        if (parts.length !== 4) return

        var cpu = parseInt(parts[0])
        var ram = parseInt(parts[1])
        var disk = parseInt(parts[2])
        if (isNaN(cpu) || isNaN(ram) || isNaN(disk)) return

        root.cpuUsage = Math.max(0, Math.min(100, cpu))
        root.ramUsage = Math.max(0, Math.min(100, ram))
        root.diskUsage = Math.max(0, Math.min(100, disk))
        root.uptimeText = parts[3] || "--"
        root.systemSampleReady = true
      }
    }
  }

  Timer {
    interval: 4000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshSystemStats()
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
              height: Style.space(108)
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
              height: Style.space(108)
              radius: root.cardRadius
              color: root.surfaceAlt

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(12)
                spacing: Style.space(5)

                Row {
                  width: parent.width
                  Text { text: "SYSTEM"; color: root.textMuted; font.pixelSize: Style.font.caption; font.bold: true }
                  Text {
                    width: parent.width - implicitWidth
                    text: root.systemSampleReady ? "LIVE" : "SAMPLING"
                    color: root.systemSampleReady ? root.accentSoft : root.textMuted
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }

                Text {
                  text: "CPU  " + root.percentText(root.cpuUsage) + "   RAM  " + root.percentText(root.ramUsage)
                  color: root.textPrimary
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Text {
                  text: "Disk  " + root.percentText(root.diskUsage) + "   Up  " + root.uptimeText
                  color: root.textMuted
                  font.pixelSize: Style.font.caption
                }
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
              Text { text: "Control Center online · desktop dock mounted"; color: root.accentSoft; font.pixelSize: Style.font.caption }
            }
          }

          Text {
            width: parent.width
            text: "NexusHub Control Center · system telemetry live"
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
