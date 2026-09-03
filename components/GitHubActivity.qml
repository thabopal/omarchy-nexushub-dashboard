import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property string username: "thabopal"
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"

  property int publicRepos: -1
  property int followers: -1
  property int recentPushes: -1
  property string activeRepo: "--"
  property string latestAction: "--"
  property string latestWhen: "--"
  property bool hasData: false
  property bool refreshing: false

  implicitHeight: Style.space(132)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function eventLabel(type) {
    switch (type) {
    case "PushEvent": return "Pushed commits"
    case "CreateEvent": return "Created something"
    case "PullRequestEvent": return "Pull request activity"
    case "IssuesEvent": return "Issue activity"
    case "IssueCommentEvent": return "Commented"
    case "ForkEvent": return "Forked repository"
    case "WatchEvent": return "Starred repository"
    case "ReleaseEvent": return "Release activity"
    default: return type ? type.replace(/Event$/, "") : "Public activity"
    }
  }

  function timeAgo(iso) {
    if (!iso) return "--"
    var then = new Date(iso).getTime()
    if (isNaN(then)) return "--"
    var seconds = Math.max(0, Math.floor((Date.now() - then) / 1000))
    if (seconds < 60) return "just now"
    var minutes = Math.floor(seconds / 60)
    if (minutes < 60) return minutes + "m ago"
    var hours = Math.floor(minutes / 60)
    if (hours < 24) return hours + "h ago"
    var days = Math.floor(hours / 24)
    if (days < 30) return days + "d ago"
    return Qt.formatDate(new Date(then), "d MMM")
  }

  function refresh() {
    if (activityProcess.running) return
    root.refreshing = true
    activityProcess.running = true
  }

  Process {
    id: activityProcess
    command: [
      "bash",
      "-lc",
      "set -o pipefail; ua='NexusHub-Omarchy'; p=$(curl -fsS --max-time 6 -H \"User-Agent: $ua\" https://api.github.com/users/" + root.username + ") || exit 1; e=$(curl -fsS --max-time 6 -H \"User-Agent: $ua\" 'https://api.github.com/users/" + root.username + "/events/public?per_page=20') || exit 1; repos=$(printf '%s' \"$p\" | jq -r '.public_repos // -1'); followers=$(printf '%s' \"$p\" | jq -r '.followers // -1'); pushes=$(printf '%s' \"$e\" | jq '[.[] | select(.type == \"PushEvent\")] | length'); repo=$(printf '%s' \"$e\" | jq -r '.[0].repo.name // \"--\"'); type=$(printf '%s' \"$e\" | jq -r '.[0].type // \"\"'); when=$(printf '%s' \"$e\" | jq -r '.[0].created_at // \"\"'); printf '%s|%s|%s|%s|%s|%s\\n' \"$repos\" \"$followers\" \"$pushes\" \"$repo\" \"$type\" \"$when\""
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.refreshing = false
        var parts = String(text || "").trim().split("|")
        if (parts.length !== 6) return

        var repos = parseInt(parts[0])
        var followers = parseInt(parts[1])
        var pushes = parseInt(parts[2])
        if (isNaN(repos) || isNaN(followers) || isNaN(pushes)) return

        root.publicRepos = repos
        root.followers = followers
        root.recentPushes = pushes
        root.activeRepo = parts[3] || "--"
        root.latestAction = root.eventLabel(parts[4])
        root.latestWhen = root.timeAgo(parts[5])
        root.hasData = true
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
        text: "GITHUB  @" + root.username
        color: root.muted
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        width: parent.width * 0.38
        text: root.refreshing ? "UPDATING" : (root.hasData ? "LIVE" : "OFFLINE")
        color: root.hasData ? root.accentSoft : root.muted
        horizontalAlignment: Text.AlignRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(10)

      Column {
        width: (parent.width - Style.space(20)) / 3
        spacing: 1
        Text { text: root.publicRepos >= 0 ? String(root.publicRepos) : "--"; color: root.foreground; font.pixelSize: Style.font.subtitle; font.bold: true }
        Text { text: "REPOS"; color: root.muted; font.pixelSize: Style.font.caption }
      }

      Column {
        width: (parent.width - Style.space(20)) / 3
        spacing: 1
        Text { text: root.followers >= 0 ? String(root.followers) : "--"; color: root.foreground; font.pixelSize: Style.font.subtitle; font.bold: true }
        Text { text: "FOLLOWERS"; color: root.muted; font.pixelSize: Style.font.caption }
      }

      Column {
        width: (parent.width - Style.space(20)) / 3
        spacing: 1
        Text { text: root.recentPushes >= 0 ? String(root.recentPushes) : "--"; color: root.foreground; font.pixelSize: Style.font.subtitle; font.bold: true }
        Text { text: "RECENT PUSHES"; color: root.muted; font.pixelSize: Style.font.caption }
      }
    }

    Rectangle { width: parent.width; height: 1; color: "#242B37" }

    Row {
      width: parent.width
      spacing: Style.space(8)

      Column {
        width: parent.width * 0.68
        spacing: 2
        Text {
          width: parent.width
          text: root.activeRepo
          color: root.accentSoft
          elide: Text.ElideMiddle
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        Text {
          width: parent.width
          text: root.latestAction
          color: root.foreground
          elide: Text.ElideRight
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        width: parent.width * 0.28
        text: root.latestWhen
        color: root.muted
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Style.font.caption
      }
    }
  }
}
