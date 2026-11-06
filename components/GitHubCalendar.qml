import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// GitHub contribution grid for the last ~6 months (26 weeks, Sunday-aligned
// like github.com). Data comes from the signed-in `gh` CLI's GraphQL API as
// the viewer, so private-repo contributions are included alongside public
// ones. Nothing user-controlled is interpolated into the command.
Rectangle {
  id: root

  property var bar: null
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"
  property color emptyCell: "#242B37"

  readonly property int weekCount: 26
  readonly property int cellGap: Style.space(3)
  readonly property real cellSize: Math.floor((gridArea.width - (root.weekCount - 1) * root.cellGap) / root.weekCount)

  property bool loading: false
  property bool failed: false
  property bool hasData: false
  property var weeks: []          // [[{date, count, level}, ...7], ...]
  property int total: 0
  property int streak: 0
  property int bestDay: 0
  property string today: ""

  implicitHeight: calendarColumn.implicitHeight + Style.space(28)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function levelColor(level) {
    if (level <= 0) return root.emptyCell
    var alpha = [0, 0.45, 0.65, 0.85, 1.0][Math.min(level, 4)]
    return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, alpha)
  }

  function levelFor(name) {
    switch (name) {
    case "FIRST_QUARTILE": return 1
    case "SECOND_QUARTILE": return 2
    case "THIRD_QUARTILE": return 3
    case "FOURTH_QUARTILE": return 4
    default: return 0
    }
  }

  function refresh() {
    if (calendarProcess.running) return
    root.loading = true
    calendarProcess.running = true
  }

  function applyData(raw) {
    var lines = String(raw || "").trim().split("\n")
    var dateRe = /^\d{4}-\d{2}-\d{2}$/
    var days = []
    var sum = 0
    var best = 0

    // Bounded: at most 26 weeks × 7 days plus slack.
    for (var i = 0; i < lines.length && days.length < 7 * (root.weekCount + 1); i++) {
      var parts = lines[i].split(" ")
      if (parts.length !== 3 || !dateRe.test(parts[0])) continue
      var count = parseInt(parts[1], 10)
      if (isNaN(count) || count < 0 || count > 100000) continue
      days.push({ date: parts[0], count: count, level: root.levelFor(parts[2]) })
      sum += count
      if (count > best) best = count
    }

    if (!days.length) {
      root.failed = true
      return
    }

    var grouped = []
    for (var d = 0; d < days.length; d += 7) grouped.push(days.slice(d, d + 7))
    grouped = grouped.slice(-root.weekCount)

    // Current streak: consecutive days with activity, ending today — or
    // yesterday, so a streak isn't shown as broken before you've committed.
    var run = 0
    var j = days.length - 1
    if (j >= 0 && days[j].count === 0) j--
    for (; j >= 0 && days[j].count > 0; j--) run++

    root.weeks = grouped
    root.total = sum
    root.bestDay = best
    root.streak = run
    root.today = days[days.length - 1].date
    root.hasData = true
    root.failed = false
  }

  function monthLabel(weekIndex) {
    var week = root.weeks[weekIndex]
    if (!week || !week.length) return ""
    var month = week[0].date.substring(5, 7)
    if (weekIndex > 0) {
      var prev = root.weeks[weekIndex - 1]
      if (prev && prev.length && prev[0].date.substring(5, 7) === month) return ""
    } else if (parseInt(week[0].date.substring(8, 10), 10) > 7) {
      // A partial month at the left edge would crowd the next label.
      return ""
    }
    var names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return names[parseInt(month, 10) - 1] || ""
  }

  Process {
    id: calendarProcess
    command: [
      "bash",
      "-lc",
      "set -o pipefail; dow=$(date +%w); from=$(date -u -d \"-$((dow + 175)) days\" +%Y-%m-%dT00:00:00Z); to=$(date -u +%Y-%m-%dT%H:%M:%SZ); " +
      "timeout 20 gh api graphql -f from=\"$from\" -f to=\"$to\" " +
      "-f query='query($from:DateTime!,$to:DateTime!){viewer{contributionsCollection(from:$from,to:$to){contributionCalendar{weeks{contributionDays{date contributionCount contributionLevel}}}}}}' " +
      "--jq '.data.viewer.contributionsCollection.contributionCalendar.weeks[].contributionDays[] | \"\\(.date) \\(.contributionCount) \\(.contributionLevel)\"'"
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyData(text)
    }

    onExited: function(exitCode) {
      root.loading = false
      if (exitCode !== 0 && !root.hasData) root.failed = true
    }
  }

  Timer {
    interval: 30 * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Column {
    id: calendarColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(14)
    spacing: Style.space(8)

    Row {
      width: parent.width

      Text {
        width: parent.width * 0.62
        text: "GITHUB · LAST 6 MONTHS"
        textFormat: Text.PlainText
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        width: parent.width * 0.38
        text: root.loading && !root.hasData ? "UPDATING" : (root.hasData ? "LIVE" : "OFFLINE")
        textFormat: Text.PlainText
        color: root.hasData ? root.accentSoft : root.muted
        horizontalAlignment: Text.AlignRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Row {
      width: parent.width
      visible: root.hasData
      spacing: Style.space(18)

      Repeater {
        model: [
          { value: root.total, label: "contributions" },
          { value: root.streak, label: "day streak" },
          { value: root.bestDay, label: "best day" }
        ]

        delegate: Row {
          required property var modelData
          spacing: Style.space(5)

          Text {
            anchors.baseline: statLabel.baseline
            text: String(modelData.value)
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            id: statLabel
            text: modelData.label
            textFormat: Text.PlainText
            color: root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: !root.hasData
      text: root.failed
        ? "Couldn't load contributions. Check `gh auth status` in a terminal."
        : "Loading contributions…"
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: root.muted
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
    }

    Item {
      id: gridArea
      width: parent.width
      visible: root.hasData
      height: monthRow.height + Style.space(4) + 7 * root.cellSize + 6 * root.cellGap

      Item {
        id: monthRow
        width: parent.width
        height: Style.font.caption + Style.space(2)

        Repeater {
          model: root.weeks.length

          delegate: Text {
            required property int index
            x: index * (root.cellSize + root.cellGap)
            text: root.monthLabel(index)
            textFormat: Text.PlainText
            color: root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Row {
        anchors.top: monthRow.bottom
        anchors.topMargin: Style.space(4)
        spacing: root.cellGap

        Repeater {
          model: root.weeks

          delegate: Column {
            required property var modelData
            spacing: root.cellGap

            Repeater {
              model: modelData

              delegate: Rectangle {
                required property var modelData
                width: root.cellSize
                height: root.cellSize
                radius: Math.max(2, root.cellSize / 4)
                color: root.levelColor(modelData.level)
                border.width: modelData.date === root.today ? 1 : 0
                border.color: root.foreground
              }
            }
          }
        }
      }
    }

    Row {
      visible: root.hasData
      anchors.right: parent.right
      spacing: Style.space(4)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Less"
        textFormat: Text.PlainText
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: 5

        delegate: Rectangle {
          required property int index
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(10)
          height: width
          radius: 2
          color: root.levelColor(index)
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "More"
        textFormat: Text.PlainText
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }
}
