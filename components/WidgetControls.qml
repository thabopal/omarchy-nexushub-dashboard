import QtQuick
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property string activeProfile: "custom"
  property bool widgetsEnabled: true
  property bool systemMonitorEnabled: true
  property bool weatherEnabled: true
  property bool githubActivityEnabled: true
  property bool githubCalendarEnabled: true
  property bool projectPulseEnabled: true
  property bool footballEnabled: true
  property bool newsEnabled: true

  signal profileRequested(string profile)
  signal widgetRequested(string key, bool enabled)

  height: controls.implicitHeight + Style.space(24)
  radius: Style.space(16)
  color: root.surface

  Column {
    id: controls
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(12)
    spacing: Style.space(10)

    Row {
      width: parent.width
      spacing: Style.space(8)

      Text {
        width: parent.width - profileState.implicitWidth - Style.space(8)
        text: "WIDGET CONTROLS"
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        id: profileState
        text: root.activeProfile.toUpperCase()
        color: root.activeProfile === "custom" ? root.muted : root.accent
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(7)

      Repeater {
        model: [
          { key: "development", label: "Development" },
          { key: "daily", label: "Daily" },
          { key: "focus", label: "Focus" }
        ]

        delegate: Rectangle {
          required property var modelData
          width: (controls.width - Style.space(14)) / 3
          height: Style.space(30)
          radius: height / 2
          color: root.activeProfile === modelData.key ? root.accent : "#242B37"

          Text {
            anchors.centerIn: parent
            text: modelData.label
            color: root.activeProfile === modelData.key ? root.foreground : root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.profileRequested(modelData.key)
          }
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(6)

      Repeater {
        model: [
          { key: "widgetsEnabled", label: "All Desktop Widgets", enabled: root.widgetsEnabled },
          { key: "systemMonitorEnabled", label: "System Monitor · Desktop", enabled: root.systemMonitorEnabled },
          { key: "weatherEnabled", label: "Weather · Desktop", enabled: root.weatherEnabled },
          { key: "githubCalendarEnabled", label: "GitHub Contributions · Desktop", enabled: root.githubCalendarEnabled },
          { key: "footballEnabled", label: "Football Fixtures · Desktop", enabled: root.footballEnabled },
          { key: "newsEnabled", label: "Top News · Desktop", enabled: root.newsEnabled },
          { key: "githubActivityEnabled", label: "GitHub Activity", enabled: root.githubActivityEnabled },
          { key: "projectPulseEnabled", label: "Project Pulse", enabled: root.projectPulseEnabled }
        ]

        delegate: Item {
          required property var modelData
          width: controls.width
          height: Style.space(26)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            color: root.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(38)
            height: Style.space(21)
            radius: height / 2
            color: modelData.enabled ? root.accent : "#303744"

            Rectangle {
              width: Style.space(15)
              height: width
              radius: width / 2
              anchors.verticalCenter: parent.verticalCenter
              x: modelData.enabled ? parent.width - width - Style.space(3) : Style.space(3)
              color: root.foreground

              Behavior on x { NumberAnimation { duration: 120 } }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.widgetRequested(modelData.key, !modelData.enabled)
          }
        }
      }
    }
  }
}
