import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accentSoft: "#E5A66E"
  property var projects: []
  property bool loading: false
  property bool failed: false

  implicitHeight: Style.space(48) + Math.max(1, root.projects.length) * Style.space(58)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function refresh() {
    if (projectProcess.running) return
    root.loading = true
    root.failed = false
    projectProcess.running = true
  }

  function ageText(epoch) {
    var seconds = Math.max(0, Math.floor(Date.now() / 1000) - Number(epoch || 0))
    if (seconds < 60) return "now"
    if (seconds < 3600) return Math.floor(seconds / 60) + "m ago"
    if (seconds < 86400) return Math.floor(seconds / 3600) + "h ago"
    if (seconds < 604800) return Math.floor(seconds / 86400) + "d ago"
    if (seconds < 2592000) return Math.floor(seconds / 604800) + "w ago"
    return Math.floor(seconds / 2592000) + "mo ago"
  }

  function syncText(project) {
    var parts = []
    if (project.ahead > 0) parts.push("↑" + project.ahead)
    if (project.behind > 0) parts.push("↓" + project.behind)
    return parts.length ? parts.join(" ") : "synced"
  }

  Process {
    id: projectProcess
    command: [
      "bash",
      "-lc",
      "find \"$HOME\" -maxdepth 4 \\( -path \"$HOME/.*\" -o -path \"*/node_modules\" -o -path \"*/.cache\" \\) -prune -o -type d -name .git -print0 | while IFS= read -r -d '' dot; do repo=${dot%/.git}; epoch=$(git -C \"$repo\" log -1 --format=%ct 2>/dev/null) || continue; [[ \"$epoch\" =~ ^[0-9]+$ ]] || continue; name=$(basename \"$repo\"); branch=$(git -C \"$repo\" symbolic-ref --quiet --short HEAD 2>/dev/null || git -C \"$repo\" rev-parse --short HEAD 2>/dev/null || printf detached); if [[ -n $(git -C \"$repo\" status --porcelain 2>/dev/null | head -n 1) ]]; then state=dirty; else state=clean; fi; ahead=0; behind=0; if git -C \"$repo\" rev-parse --verify --quiet '@{upstream}' >/dev/null; then read -r ahead behind <<< \"$(git -C \"$repo\" rev-list --left-right --count HEAD...'@{upstream}' 2>/dev/null)\"; fi; subject=$(git -C \"$repo\" log -1 --format=%s 2>/dev/null | tr '\\t\\n' '  '); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$epoch\" \"$name\" \"$branch\" \"$state\" \"${ahead:-0}\" \"${behind:-0}\" \"$subject\" \"$repo\"; done | sort -t $'\\t' -k1,1nr | head -n 3"
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var rows = String(text || "").trim().split("\n")
        var next = []
        for (var i = 0; i < rows.length; i++) {
          if (!rows[i]) continue
          var fields = rows[i].split("\t")
          if (fields.length < 8) continue
          next.push({
            epoch: Number(fields[0]),
            name: fields[1],
            branch: fields[2],
            dirty: fields[3] === "dirty",
            ahead: Number(fields[4]) || 0,
            behind: Number(fields[5]) || 0,
            subject: fields[6],
            path: fields[7]
          })
        }
        root.projects = next
        root.loading = false
        root.failed = next.length === 0
      }
    }
  }

  Timer {
    interval: 2 * 60 * 1000
    repeat: true
    running: root.visible
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(12)
    spacing: Style.space(7)

    Item {
      width: parent.width
      height: Style.space(20)

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "PROJECT PULSE"
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.loading ? "UPDATING" : (root.failed ? "NO REPOS" : "LIVE")
        color: root.failed ? root.muted : root.accentSoft
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Text {
      visible: root.projects.length === 0
      width: parent.width
      text: root.loading ? "Scanning local projects…" : "No recent Git repositories found"
      color: root.muted
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
    }

    Repeater {
      model: root.projects

      delegate: Item {
        required property var modelData
        required property int index
        width: parent ? parent.width : 0
        height: Style.space(51)

        Text {
          id: projectName
          anchors.left: parent.left
          anchors.top: parent.top
          width: parent.width - repoState.implicitWidth - Style.space(12)
          text: modelData.name + "  ·  " + modelData.branch
          color: root.foreground
          elide: Text.ElideRight
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Text {
          id: repoState
          anchors.right: parent.right
          anchors.top: parent.top
          text: modelData.dirty ? "DIRTY" : "CLEAN"
          color: modelData.dirty ? root.accentSoft : root.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Text {
          anchors.left: parent.left
          anchors.right: syncState.left
          anchors.rightMargin: Style.space(10)
          anchors.bottom: parent.bottom
          text: modelData.subject
          color: root.muted
          elide: Text.ElideRight
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          id: syncState
          anchors.right: age.left
          anchors.rightMargin: Style.space(10)
          anchors.bottom: parent.bottom
          text: root.syncText(modelData)
          color: modelData.ahead > 0 || modelData.behind > 0 ? root.accentSoft : root.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          id: age
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          text: root.ageText(modelData.epoch)
          color: root.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.bottomMargin: -Style.space(6)
          height: 1
          color: "#242B37"
          visible: index < root.projects.length - 1
        }
      }
    }
  }
}
