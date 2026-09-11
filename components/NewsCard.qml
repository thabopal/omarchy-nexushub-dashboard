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
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"

  property bool loading: false
  property bool failed: false
  property bool hasData: false
  property var headlines: ({})

  readonly property var categories: [
    { key: "AI", label: "AI" },
    { key: "ECONOMY", label: "ECONOMY" },
    { key: "POLITICS", label: "POLITICS" },
    { key: "TECH", label: "TECH" }
  ]

  implicitHeight: newsColumn.implicitHeight + Style.space(28)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function headlineFor(key) {
    return root.headlines[key] || null
  }

  function refresh() {
    if (newsProcess.running) return
    root.loading = true
    root.failed = false
    newsProcess.running = true
  }

  Process {
    id: newsProcess
    command: [
      "bash",
      "-lc",
      "timeout 25 python3 <<'PYEOF'\n" +
      "import urllib.request, xml.etree.ElementTree as ET\n" +
      "feeds = [\n" +
      "  ('AI', 'https://news.google.com/rss/search?q=artificial+intelligence+OR+%22machine+learning%22+OR+LLM&hl=en-ZA&gl=ZA&ceid=ZA:en'),\n" +
      "  ('ECONOMY', 'https://news.google.com/rss/search?q=%22South+Africa%22+%28economy+OR+inflation+OR+rand+OR+%22fuel+price%22%29&hl=en-ZA&gl=ZA&ceid=ZA:en'),\n" +
      "  ('POLITICS', 'https://news.google.com/rss/search?q=%28election+OR+government+OR+parliament+OR+president%29+%28%22South+Africa%22+OR+Europe+OR+%22United+States%22%29&hl=en-ZA&gl=ZA&ceid=ZA:en'),\n" +
      "  ('TECH', 'https://news.google.com/rss/search?q=%28smartphone+OR+hardware+OR+software+OR+Arduino+OR+%22Raspberry+Pi%22%29&hl=en-ZA&gl=ZA&ceid=ZA:en'),\n" +
      "]\n" +
      "for label, url in feeds:\n" +
      "  try:\n" +
      "    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})\n" +
      "    with urllib.request.urlopen(req, timeout=8) as resp:\n" +
      "      data = resp.read()\n" +
      "    root = ET.fromstring(data)\n" +
      "    item = root.find('./channel/item')\n" +
      "    title = (item.findtext('title') or '') if item is not None else ''\n" +
      "    link = (item.findtext('link') or '') if item is not None else ''\n" +
      "    if ' - ' in title:\n" +
      "      headline, source = title.rsplit(' - ', 1)\n" +
      "    else:\n" +
      "      headline, source = title, ''\n" +
      "    print(label + '\\t' + headline.strip() + '\\t' + source.strip() + '\\t' + link.strip())\n" +
      "  except Exception:\n" +
      "    print(label + '\\t\\t\\t')\n" +
      "PYEOF"
    ]

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
          var parts = lines[i].split("\t")
          if (parts.length !== 4) continue
          var headline = parts[1]
          if (headline.length) any = true
          next[parts[0]] = { headline: headline, source: parts[2], link: parts[3] }
        }

        root.headlines = next
        root.hasData = any
        root.failed = !any
      }
    }
  }

  Timer {
    interval: 20 * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Column {
    id: newsColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(14)
    spacing: Style.space(8)

    Row {
      width: parent.width

      Text {
        width: parent.width * 0.62
        text: "TOP NEWS"
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        width: parent.width * 0.38
        text: root.loading ? "UPDATING" : (root.hasData ? "LIVE" : "OFFLINE")
        color: root.hasData ? root.accentSoft : root.muted
        horizontalAlignment: Text.AlignRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Repeater {
      model: root.categories

      delegate: Item {
        id: categoryRow
        required property var modelData
        readonly property var entry: root.headlineFor(modelData.key)
        readonly property bool hasLink: categoryRow.entry && categoryRow.entry.link.length > 0
        width: newsColumn.width
        height: rowContent.implicitHeight

        Column {
          id: rowContent
          width: parent.width
          spacing: 1

          Text {
            width: parent.width
            text: modelData.label
            color: root.accentSoft
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            id: headlineText
            width: parent.width
            text: categoryRow.entry && categoryRow.entry.headline.length ? categoryRow.entry.headline : "No headline available"
            color: linkArea.containsMouse ? root.accentSoft : root.foreground
            font.underline: categoryRow.hasLink && linkArea.containsMouse
            elide: Text.ElideRight
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body

            Behavior on color { ColorAnimation { duration: 120 } }
          }

          Text {
            width: parent.width
            visible: categoryRow.entry && categoryRow.entry.source.length > 0
            text: categoryRow.entry ? categoryRow.entry.source : ""
            color: root.muted
            elide: Text.ElideRight
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        MouseArea {
          id: linkArea
          anchors.fill: parent
          enabled: categoryRow.hasLink
          hoverEnabled: categoryRow.hasLink
          cursorShape: categoryRow.hasLink ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: Qt.openUrlExternally(categoryRow.entry.link)
        }
      }
    }
  }
}
