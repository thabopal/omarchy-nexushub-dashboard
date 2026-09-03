import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property color surface: "#171C26"
  property color track: "#242B37"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"

  property int cpuUsage: -1
  property int ramUsage: -1
  property int diskUsage: -1
  property int batteryLevel: -1
  property string batteryStatus: "--"
  property int temperature: -1
  property string uptimeText: "--"
  property real rxRate: -1
  property real txRate: -1
  property double previousRx: -1
  property double previousTx: -1
  property double previousNetworkTime: 0
  property bool sampleReady: false

  implicitHeight: Style.space(208)
  radius: Style.space(16)
  color: root.surface

  function clampPercent(value) {
    return Math.max(0, Math.min(100, value))
  }

  function percentText(value) {
    return value >= 0 ? value + "%" : "--"
  }

  function tempText() {
    return root.temperature >= 0 ? root.temperature + "°C" : "--"
  }

  function batteryText() {
    if (root.batteryLevel < 0) return "No battery"
    var state = root.batteryStatus && root.batteryStatus !== "--" ? " · " + root.batteryStatus : ""
    return root.batteryLevel + "%" + state
  }

  function formatRate(bytesPerSecond) {
    if (bytesPerSecond < 0) return "--"
    if (bytesPerSecond >= 1024 * 1024) return (bytesPerSecond / (1024 * 1024)).toFixed(1) + " MB/s"
    if (bytesPerSecond >= 1024) return (bytesPerSecond / 1024).toFixed(1) + " KB/s"
    return Math.round(bytesPerSecond) + " B/s"
  }

  function refresh() {
    if (!statsProcess.running) statsProcess.running = true
  }

  Process {
    id: statsProcess
    command: [
      "bash",
      "-lc",
      "read -r _ u1 n1 s1 i1 io1 irq1 sirq1 st1 _ < /proc/stat; t1=$((u1+n1+s1+i1+io1+irq1+sirq1+st1)); idle1=$((i1+io1)); sleep 0.18; read -r _ u2 n2 s2 i2 io2 irq2 sirq2 st2 _ < /proc/stat; t2=$((u2+n2+s2+i2+io2+irq2+sirq2+st2)); idle2=$((i2+io2)); dt=$((t2-t1)); di=$((idle2-idle1)); if (( dt > 0 )); then cpu=$((100*(dt-di)/dt)); else cpu=0; fi; mt=$(awk '/MemTotal:/ {print $2}' /proc/meminfo); ma=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo); if (( mt > 0 )); then ram=$((100*(mt-ma)/mt)); else ram=0; fi; disk=$(df -P / | awk 'NR==2 {gsub(/%/,\"\",$5); print $5}'); up=$(cut -d. -f1 /proc/uptime); days=$((up/86400)); hours=$(((up%86400)/3600)); mins=$(((up%3600)/60)); if (( days > 0 )); then uptime=\"${days}d ${hours}h\"; elif (( hours > 0 )); then uptime=\"${hours}h ${mins}m\"; else uptime=\"${mins}m\"; fi; bat=-1; batstate=-- ; for d in /sys/class/power_supply/BAT*; do if [[ -r \"$d/capacity\" ]]; then bat=$(cat \"$d/capacity\" 2>/dev/null); batstate=$(cat \"$d/status\" 2>/dev/null | tr ' ' '_'); break; fi; done; temp=-1; for f in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do [[ -r \"$f\" ]] || continue; v=$(cat \"$f\" 2>/dev/null); [[ \"$v\" =~ ^[0-9]+$ ]] || continue; if (( v > 1000 )); then v=$((v/1000)); fi; if (( v >= 10 && v <= 120 && v > temp )); then temp=$v; fi; done; read rx tx < <(awk -F'[: ]+' 'NR>2 && $1 !~ /lo/ {rx+=$3; tx+=$11} END {printf \"%.0f %.0f\\n\", rx, tx}' /proc/net/dev); printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\\n' \"$cpu\" \"$ram\" \"$disk\" \"$uptime\" \"$bat\" \"$batstate\" \"$temp\" \"$rx\" \"$tx\""
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parts = String(text || "").trim().split("|")
        if (parts.length !== 9) return

        var cpu = parseInt(parts[0])
        var ram = parseInt(parts[1])
        var disk = parseInt(parts[2])
        var battery = parseInt(parts[4])
        var temp = parseInt(parts[6])
        var rx = parseFloat(parts[7])
        var tx = parseFloat(parts[8])
        if (isNaN(cpu) || isNaN(ram) || isNaN(disk) || isNaN(rx) || isNaN(tx)) return

        root.cpuUsage = root.clampPercent(cpu)
        root.ramUsage = root.clampPercent(ram)
        root.diskUsage = root.clampPercent(disk)
        root.uptimeText = parts[3] || "--"
        root.batteryLevel = isNaN(battery) ? -1 : root.clampPercent(battery)
        root.batteryStatus = (parts[5] || "--").replace(/_/g, " ")
        root.temperature = isNaN(temp) || temp < 0 ? -1 : temp

        var now = Date.now()
        if (root.previousNetworkTime > 0 && now > root.previousNetworkTime) {
          var seconds = (now - root.previousNetworkTime) / 1000.0
          root.rxRate = Math.max(0, (rx - root.previousRx) / seconds)
          root.txRate = Math.max(0, (tx - root.previousTx) / seconds)
        }
        root.previousRx = rx
        root.previousTx = tx
        root.previousNetworkTime = now
        root.sampleReady = true
      }
    }
  }

  Timer {
    interval: 3000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  component MeterRow: Column {
    required property string title
    required property int value
    width: parent ? parent.width : 0
    spacing: Style.space(3)

    Row {
      width: parent.width
      Text {
        text: parent.parent.title
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        width: parent.width - implicitWidth
        text: root.percentText(parent.parent.value)
        color: root.foreground
        horizontalAlignment: Text.AlignRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Rectangle {
      width: parent.width
      height: 5
      radius: 3
      color: root.track

      Rectangle {
        width: parent.width * (Math.max(0, parent.parent.value) / 100)
        height: parent.height
        radius: parent.radius
        color: root.accent
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
      }
    }
  }

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(9)

    Row {
      width: parent.width
      Text {
        text: "SYSTEM MONITOR"
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
      Text {
        width: parent.width - implicitWidth
        text: root.sampleReady ? "LIVE" : "SAMPLING"
        color: root.sampleReady ? root.accentSoft : root.muted
        horizontalAlignment: Text.AlignRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    MeterRow { title: "CPU"; value: root.cpuUsage }
    MeterRow { title: "Memory"; value: root.ramUsage }
    MeterRow { title: "Disk /"; value: root.diskUsage }

    Rectangle { width: parent.width; height: 1; color: root.track }

    Row {
      width: parent.width
      spacing: Style.space(8)

      Column {
        width: (parent.width - Style.space(8)) / 2
        spacing: Style.space(3)
        Text { text: "BATTERY"; color: root.muted; font.pixelSize: Style.font.caption; font.bold: true }
        Text { text: root.batteryText(); color: root.foreground; font.pixelSize: Style.font.caption }
        Text { text: "TEMP  " + root.tempText(); color: root.accentSoft; font.pixelSize: Style.font.caption }
      }

      Column {
        width: (parent.width - Style.space(8)) / 2
        spacing: Style.space(3)
        Text { text: "NETWORK"; color: root.muted; font.pixelSize: Style.font.caption; font.bold: true }
        Text { text: "↓  " + root.formatRate(root.rxRate); color: root.foreground; font.pixelSize: Style.font.caption }
        Text { text: "↑  " + root.formatRate(root.txRate); color: root.accentSoft; font.pixelSize: Style.font.caption }
      }
    }

    Text {
      width: parent.width
      text: "Uptime  " + root.uptimeText
      color: root.muted
      horizontalAlignment: Text.AlignRight
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
