import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property string apiKey: ""
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"

  property bool loading: false
  property bool failed: false
  property bool hasData: false
  readonly property bool needsKey: apiKey.length === 0

  property string activeCode: "PL"
  property var byCode: ({})

  readonly property var competitions: [
    { code: "PL", label: "EPL" },
    { code: "CL", label: "UCL" }
  ]

  readonly property var active: root.byCode[root.activeCode] || null

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
      + "for code in PL CL; do "
      + "curl -fsS --max-time 8 -H \"X-Auth-Token: " + root.apiKey + "\" "
      + "\"https://api.football-data.org/v4/competitions/$code/matches?dateFrom=$from&dateTo=$to\" "
      + "| jq -r --arg code \"$code\" '(.matches // []) as $m "
      + "| ($m | map(select(.status==\"SCHEDULED\" or .status==\"TIMED\")) | sort_by(.utcDate) | first) as $next "
      + "| ($m | map(select(.status==\"FINISHED\")) | sort_by(.utcDate) | last) as $last "
      + "| [$code, ($next.homeTeam.tla // $next.homeTeam.shortName // \"\"), "
      + "($next.awayTeam.tla // $next.awayTeam.shortName // \"\"), "
      + "($next.utcDate // \"\"), "
      + "($last.homeTeam.tla // $last.homeTeam.shortName // \"\"), "
      + "($last.awayTeam.tla // $last.awayTeam.shortName // \"\"), "
      + "(($last.score.fullTime.home // \"\") | tostring), "
      + "(($last.score.fullTime.away // \"\") | tostring)] | join(\"|\")' "
      + "|| echo \"$code|||||||\"; "
      + "done"
    ]
    footballProcess.running = true
  }

  Process {
    id: footballProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        var lines = String(text || "").trim().split("\n")
        if (!lines.length || !lines[0].length) {
          root.failed = true
          return
        }

        var next = {}
        var any = false
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("|")
          if (parts.length !== 8) continue
          var code = parts[0]
          var entry = {
            nextHome: parts[1] || "--",
            nextAway: parts[2] || "--",
            nextKickoff: parts[3] || "",
            lastHome: parts[4] || "--",
            lastAway: parts[5] || "--",
            lastHomeScore: parts[6] || "",
            lastAwayScore: parts[7] || ""
          }
          if (entry.nextKickoff.length || entry.lastHomeScore.length) any = true
          next[code] = entry
        }

        root.byCode = next
        root.hasData = any
        root.failed = !any
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

    Item {
      width: parent.width
      height: Style.space(20)

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)

        Repeater {
          model: root.competitions

          delegate: Rectangle {
            required property var modelData
            width: Style.space(42)
            height: Style.space(20)
            radius: height / 2
            color: root.activeCode === modelData.code ? root.accent : "#242B37"

            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: root.activeCode === modelData.code ? root.foreground : root.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeCode = modelData.code
            }
          }
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.needsKey ? "NO KEY" : (root.loading ? "UPDATING" : (root.hasData ? "LIVE" : "OFFLINE"))
        color: root.hasData && !root.needsKey ? root.accentSoft : root.muted
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
        text: "NEXT  ·  " + (root.active ? root.active.nextHome + " vs " + root.active.nextAway : "--")
        color: root.foreground
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        width: parent.width
        text: root.active && root.active.nextKickoff.length ? root.formatKickoff(root.active.nextKickoff) : "No upcoming fixture in range"
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
        text: "LAST  ·  " + (root.active && root.active.lastHomeScore.length
          ? root.active.lastHome + " " + root.active.lastHomeScore + " - " + root.active.lastAwayScore + " " + root.active.lastAway
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
