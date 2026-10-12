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

  implicitHeight: mainColumn.implicitHeight + Style.space(28)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function formatKickoff(iso) {
    if (!iso) return ""
    var date = new Date(iso)
    if (isNaN(date.getTime())) return ""
    return Qt.formatDateTime(date, "ddd d MMM, HH:mm")
  }

  function nextTicker() {
    if (!root.active || !root.active.next.length) return "No upcoming fixtures in range"
    return root.active.next.map(function(m) {
      return m.h + " vs " + m.a + "  ·  " + root.formatKickoff(m.d)
    }).join("      •      ")
  }

  function lastTicker() {
    if (!root.active || !root.active.last.length) return "No results in range"
    return root.active.last.map(function(m) {
      return m.h + "  " + m.hs + " - " + m.as + "  " + m.a
    }).join("      •      ")
  }

  function refresh() {
    if (root.needsKey) return
    if (footballProcess.running) return

    root.loading = true
    root.failed = false
    footballProcess.command = [
      "bash",
      "-lc",
      // Look back as far as ahead: UCL matchdays can be ~4 weeks apart.
      "set -o pipefail; from=$(date -u -d '-45 days' +%F); to=$(date -u -d '+45 days' +%F); "
      + "for code in PL CL; do "
      + "curl -fsS --max-time 8 -H \"X-Auth-Token: " + root.apiKey + "\" "
      + "\"https://api.football-data.org/v4/competitions/$code/matches?dateFrom=$from&dateTo=$to\" "
      + "| jq -c --arg code \"$code\" '(.matches // []) as $m "
      + "| ($m | map(select(.status==\"SCHEDULED\" or .status==\"TIMED\"))) as $upcoming "
      + "| ($m | map(select(.status==\"FINISHED\"))) as $finished "
      // Next gameweek = earliest one that is still mostly unplayed, so a single
      // postponed fixture doesn't hide the real next round. Stragglers from
      // earlier gameweeks are kept in the list, sorted by kickoff.
      + "| ($upcoming | map(.matchday // 0) | unique | map(. as $d | select(($upcoming | map(select((.matchday // 0) == $d)) | length) >= ($finished | map(select((.matchday // 0) == $d)) | length)))) as $openMDs "
      + "| (if ($openMDs | length) > 0 then ($openMDs | min) else null end) as $nextMD "
      + "| (if $nextMD != null then ($upcoming | map(select((.matchday // 0) <= $nextMD)) | sort_by(.utcDate)) else [] end) as $nextGames "
      + "| (if ($finished | length) > 0 then ($finished | map(.matchday // 0) | max) else null end) as $lastMD "
      + "| (if $lastMD != null then ($finished | map(select((.matchday // 0) == $lastMD)) | sort_by(.utcDate)) else [] end) as $lastGames "
      + "| {code: $code, "
      + "next: ($nextGames | map({h: (.homeTeam.tla // .homeTeam.shortName // \"?\"), a: (.awayTeam.tla // .awayTeam.shortName // \"?\"), d: .utcDate})), "
      + "last: ($lastGames | map({h: (.homeTeam.tla // .homeTeam.shortName // \"?\"), a: (.awayTeam.tla // .awayTeam.shortName // \"?\"), hs: (.score.fullTime.home // 0), as: (.score.fullTime.away // 0)}))}' "
      + "|| printf '{\"code\":\"%s\",\"next\":[],\"last\":[]}' \"$code\"; "
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
          if (!lines[i].length) continue
          try {
            var obj = JSON.parse(lines[i])
            if (!obj || !obj.code) continue
            var nextGames = Array.isArray(obj.next) ? obj.next : []
            var lastGames = Array.isArray(obj.last) ? obj.last : []
            if (nextGames.length || lastGames.length) any = true
            next[obj.code] = { next: nextGames, last: lastGames }
          } catch (e) {
            continue
          }
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
    id: mainColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
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
      spacing: 3

      Text {
        width: parent.width
        text: "NEXT GAMEWEEK"
        color: root.accentSoft
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Marquee {
        width: parent.width
        text: root.nextTicker()
        textColor: root.active && root.active.next.length ? root.foreground : root.muted
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        fontPixelSize: Style.font.caption
      }
    }

    Rectangle { visible: !root.needsKey; width: parent.width; height: 1; color: "#242B37" }

    Column {
      visible: !root.needsKey
      width: parent.width
      spacing: 3

      Text {
        width: parent.width
        text: "PREVIOUS GAMEWEEK"
        color: root.accentSoft
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Marquee {
        width: parent.width
        text: root.lastTicker()
        textColor: root.active && root.active.last.length ? root.foreground : root.muted
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        fontPixelSize: Style.font.caption
      }
    }
  }
}
