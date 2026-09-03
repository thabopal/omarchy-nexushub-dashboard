import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Rectangle {
  id: root

  property var bar: null
  property string locationName: "Bloemfontein"
  property real latitude: -29.0852
  property real longitude: 26.1596
  property color surface: "#171C26"
  property color foreground: "#F4EEE7"
  property color muted: "#8E8791"
  property color accent: "#D86F55"
  property color accentSoft: "#E5A66E"

  property real temperature: NaN
  property real feelsLike: NaN
  property int humidity: -1
  property int weatherCode: -1
  property bool isDay: true
  property string sunrise: "--:--"
  property string sunset: "--:--"
  property bool loading: false
  property bool hasData: false
  property bool failed: false

  implicitHeight: Style.space(126)
  radius: Style.space(16)
  color: root.surface
  clip: true

  function formatTemp(value) {
    return isNaN(value) ? "--" : Math.round(value) + "°"
  }

  function timePart(value) {
    var text = String(value || "")
    var t = text.indexOf("T")
    if (t >= 0 && text.length >= t + 6) return text.slice(t + 1, t + 6)
    return "--:--"
  }

  function conditionForCode(code) {
    if (code === 0) return "Clear"
    if (code === 1) return "Mostly clear"
    if (code === 2) return "Partly cloudy"
    if (code === 3) return "Overcast"
    if (code === 45 || code === 48) return "Fog"
    if (code === 51 || code === 53 || code === 55) return "Drizzle"
    if (code === 56 || code === 57) return "Freezing drizzle"
    if (code === 61 || code === 63 || code === 65) return "Rain"
    if (code === 66 || code === 67) return "Freezing rain"
    if (code === 71 || code === 73 || code === 75 || code === 77) return "Snow"
    if (code === 80 || code === 81 || code === 82) return "Rain showers"
    if (code === 85 || code === 86) return "Snow showers"
    if (code === 95 || code === 96 || code === 99) return "Thunderstorm"
    return root.hasData ? "Current conditions" : "Waiting for weather"
  }

  function iconForCode(code) {
    if (code === 0) return root.isDay ? "☀" : "☾"
    if (code === 1 || code === 2) return root.isDay ? "⛅" : "☁"
    if (code === 3) return "☁"
    if (code === 45 || code === 48) return "≋"
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "☂"
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "❄"
    if (code >= 95) return "ϟ"
    return "◌"
  }

  function refresh() {
    if (weatherProcess.running) return

    root.loading = true
    root.failed = false
    var url = "https://api.open-meteo.com/v1/forecast"
      + "?latitude=" + encodeURIComponent(String(root.latitude))
      + "&longitude=" + encodeURIComponent(String(root.longitude))
      + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day"
      + "&daily=sunrise,sunset"
      + "&forecast_days=1"
      + "&timezone=auto"

    weatherProcess.command = ["curl", "-fsS", "--max-time", "8", url]
    weatherProcess.running = true
  }

  Process {
    id: weatherProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        var raw = String(text || "").trim()
        if (!raw) {
          root.failed = true
          return
        }

        try {
          var data = JSON.parse(raw)
          var current = data.current || null
          var daily = data.daily || null
          if (!current) {
            root.failed = true
            return
          }

          root.temperature = Number(current.temperature_2m)
          root.feelsLike = Number(current.apparent_temperature)
          root.humidity = parseInt(current.relative_humidity_2m)
          root.weatherCode = parseInt(current.weather_code)
          root.isDay = parseInt(current.is_day) !== 0
          root.sunrise = daily && daily.sunrise && daily.sunrise.length ? root.timePart(daily.sunrise[0]) : "--:--"
          root.sunset = daily && daily.sunset && daily.sunset.length ? root.timePart(daily.sunset[0]) : "--:--"
          root.hasData = true
          root.failed = false
        } catch (e) {
          root.failed = true
        }
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

  Row {
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(14)

    Column {
      width: parent.width * 0.38
      height: parent.height
      spacing: Style.space(4)

      Text {
        text: "WEATHER"
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Row {
        spacing: Style.space(8)

        Text {
          text: root.iconForCode(root.weatherCode)
          color: root.accentSoft
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.displayMedium
        }

        Text {
          text: root.formatTemp(root.temperature)
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.displayMedium
          font.bold: true
        }
      }

      Text {
        width: parent.width
        text: root.failed && !root.hasData ? "Weather unavailable" : root.conditionForCode(root.weatherCode)
        color: root.failed ? root.muted : root.accentSoft
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    Column {
      width: parent.width * 0.57
      height: parent.height
      spacing: Style.space(5)

      Row {
        width: parent.width
        Text {
          width: parent.width * 0.68
          text: root.locationName.toUpperCase()
          color: root.accentSoft
          elide: Text.ElideRight
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        Text {
          width: parent.width * 0.32
          text: root.loading ? "UPDATING" : (root.hasData ? "LIVE" : "OFFLINE")
          color: root.hasData ? root.accentSoft : root.muted
          horizontalAlignment: Text.AlignRight
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      Text {
        width: parent.width
        text: "Feels like  " + root.formatTemp(root.feelsLike) + "   ·   Humidity  " + (root.humidity >= 0 ? root.humidity + "%" : "--")
        color: root.foreground
        elide: Text.ElideRight
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        width: parent.width
        height: 1
        color: "#242B37"
      }

      Row {
        width: parent.width
        Text {
          width: parent.width / 2
          text: "Sunrise  " + root.sunrise
          color: root.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          width: parent.width / 2
          text: "Sunset  " + root.sunset
          color: root.muted
          horizontalAlignment: Text.AlignRight
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
