import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property string apiKey: ""
  property string competitionCode: "PL"
  property string competitionShort: "EPL"
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"

  property bool loading: false
  property bool failed: false
  property bool hasData: false
  readonly property bool needsKey: apiKey.length === 0

  property string nextHome: "--"
  property string nextAway: "--"
  property string nextKickoff: ""
  property string lastHome: "--"
  property string lastAway: "--"
  property string lastHomeScore: ""
  property string lastAwayScore: ""

  implicitHeight: Style.space(126)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function formatKickoff(iso) {
    if (!iso) return ""
    var date = new Date(iso)
    if (isNaN(date.getTime())) return ""
    return Qt.formatDateTime(date, "ddd d MMM, HH:mm")
  }

  function refresh() {
    if (root.needsKey) return
    if (footballProcess.running) return

    root.loading = true
    root.failed = false
    footballProcess.command = [
      "bash",
      "-lc",
      "set -o pipefail; from=$(date -u -d '-10 days' +%F); to=$(date -u -d '+21 days' +%F); "
      + "curl -fsS --max-time 8 -H \"X-Auth-Token: " + root.apiKey + "\" "
      + "\"https://api.football-data.org/v4/competitions/" + root.competitionCode + "/matches?dateFrom=$from&dateTo=$to\" "
      + "| jq -r '(.matches // []) as $m "
      + "| ($m | map(select(.status==\"SCHEDULED\" or .status==\"TIMED\")) | sort_by(.utcDate) | first) as $next "
      + "| ($m | map(select(.status==\"FINISHED\")) | sort_by(.utcDate) | last) as $last "
      + "| [($next.homeTeam.tla // $next.homeTeam.shortName // \"\"), "
      + "($next.awayTeam.tla // $next.awayTeam.shortName // \"\"), "
      + "($next.utcDate // \"\"), "
      + "($last.homeTeam.tla // $last.homeTeam.shortName // \"\"), "
      + "($last.awayTeam.tla // $last.awayTeam.shortName // \"\"), "
      + "(($last.score.fullTime.home // \"\") | tostring), "
      + "(($last.score.fullTime.away // \"\") | tostring)] | join(\"|\")'"
    ]
    footballProcess.running = true
  }

  Process {
    id: footballProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        var parts = String(text || "").trim().split("|")
        if (parts.length !== 7) {
          root.failed = true
          return
        }

        root.nextHome = parts[0] || "--"
        root.nextAway = parts[1] || "--"
        root.nextKickoff = parts[2] || ""
        root.lastHome = parts[3] || "--"
        root.lastAway = parts[4] || "--"
        root.lastHomeScore = parts[5] || ""
        root.lastAwayScore = parts[6] || ""
        root.hasData = true
        root.failed = false
      }
    }
  }

  Timer {
    interval: 15 * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(8)

    Row {
      width: parent.width

      Text {
        width: parent.width * 0.62
        text: root.competitionShort.toUpperCase()
        color: root.muted
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        width: parent.width * 0.38
        text: root.needsKey ? "NO KEY" : (root.loading ? "UPDATING" : (root.hasData ? "LIVE" : "OFFLINE"))
        color: root.hasData && !root.needsKey ? root.accentSoft : root.muted
        horizontalAlignment: Text.AlignRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Text {
      visible: root.needsKey
      width: parent.width
      text: "Add a football-data.org API key in NexusHub settings"
      color: root.muted
      wrapMode: Text.WordWrap
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
    }

    Column {
      visible: !root.needsKey
      width: parent.width
      spacing: 2

      Text {
        width: parent.width
        text: "NEXT  ·  " + root.nextHome + " vs " + root.nextAway
        color: root.foreground
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        width: parent.width
        text: root.nextKickoff.length ? root.formatKickoff(root.nextKickoff) : "No upcoming fixture in range"
        color: root.muted
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    Rectangle { visible: !root.needsKey; width: parent.width; height: 1; color: "#242B37" }

    Column {
      visible: !root.needsKey
      width: parent.width
      spacing: 2

      Text {
        width: parent.width
        text: "LAST  ·  " + (root.lastHomeScore.length
          ? root.lastHome + " " + root.lastHomeScore + " - " + root.lastAwayScore + " " + root.lastAway
          : "No recent result in range")
        color: root.accentSoft
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }
}
