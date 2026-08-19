import QtQuick
import qs.Commons

// Theme-colored pixel penguin, 16×16 cells scaled to the painted box.
// Legend: K body, W belly/eye white, A glasses, O beak and feet, P pupil.
// Frames: idle, blink (self-timed), talk (mouth flap while `talking`),
// sleep (while `muted`). Colors follow the active theme, so he recolors
// himself the moment the theme changes.
Item {
  id: root

  property bool muted: false
  property bool talking: false

  property color bodyColor: Color.foreground
  property color bellyColor: Qt.rgba(
    Color.foreground.r * 0.25 + Color.background.r * 0.75,
    Color.foreground.g * 0.25 + Color.background.g * 0.75,
    Color.foreground.b * 0.25 + Color.background.b * 0.75, 1)
  property color glassColor: Color.accent
  property color beakColor: Color.urgent
  property color pupilColor: Color.foreground

  property bool blinking: false
  property bool mouthOpen: false

  readonly property string frame: muted
    ? "sleep"
    : (talking && mouthOpen ? "talk" : (blinking ? "blink" : "idle"))

  readonly property var idleRows: [
    "................",
    ".....KKKKKK.....",
    "....KKKKKKKK....",
    "...KKKKKKKKKK...",
    "...KWWWKKWWWK...",
    "..AAWPWAAWPWAA..",
    "...KWWWKKWWWK...",
    "...KKKOOOOKKK...",
    "...KWWWWWWWWK...",
    "..KKWWWWWWWWKK..",
    "..KKWWWWWWWWKK..",
    "..KKWWWWWWWWKK..",
    "...KWWWWWWWWK...",
    "...KKKKKKKKKK...",
    "....OO....OO....",
    "................"
  ]

  function rowsFor(name) {
    var rows = idleRows.slice()
    if (name === "blink") {
      rows[5] = "..AAWWWAAWWWAA.."
    } else if (name === "sleep") {
      rows[4] = "...KKKKKKKKKK..."
      rows[5] = "..AAWWWAAWWWAA.."
      rows[6] = "...KKKKKKKKKK..."
    } else if (name === "talk") {
      rows[8] = "...KWWOOOOWWK..."
    }
    return rows
  }

  function cssColor(c) {
    if (!c) return "#000000"
    return "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")"
  }

  onFrameChanged: canvas.requestPaint()
  onBodyColorChanged: canvas.requestPaint()
  onBellyColorChanged: canvas.requestPaint()
  onGlassColorChanged: canvas.requestPaint()
  onBeakColorChanged: canvas.requestPaint()
  onPupilColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
  Component.onCompleted: canvas.requestPaint()

  // Occasional blink, re-jittered every cycle so he never metronomes.
  Timer {
    id: blinkTimer
    running: root.visible && !root.muted
    repeat: true
    interval: 2800 + Math.round(Math.random() * 3200)
    onTriggered: {
      root.blinking = true
      blinkOffTimer.restart()
      interval = 2800 + Math.round(Math.random() * 3200)
    }
  }

  Timer {
    id: blinkOffTimer
    interval: 140
    onTriggered: root.blinking = false
  }

  // Beak flap while a line is on screen.
  Timer {
    id: mouthTimer
    running: root.talking && !root.muted
    repeat: true
    interval: 170
    triggeredOnStart: true
    onTriggered: root.mouthOpen = !root.mouthOpen
    onRunningChanged: if (!running) root.mouthOpen = false
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: false
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var rows = root.rowsFor(root.frame)
      var cols = 16
      var px = Math.max(1, Math.floor(Math.min(width / cols, height / rows.length)))
      var ox = Math.floor((width - px * cols) / 2)
      var oy = Math.floor((height - px * rows.length) / 2)
      var colors = {
        "K": root.cssColor(root.bodyColor),
        "W": root.cssColor(root.bellyColor),
        "A": root.cssColor(root.glassColor),
        "O": root.cssColor(root.beakColor),
        "P": root.cssColor(root.pupilColor)
      }

      for (var y = 0; y < rows.length; y++) {
        var row = rows[y]
        for (var x = 0; x < cols; x++) {
          var ch = row.charAt(x)
          var fill = colors[ch]
          if (!fill) continue
          ctx.fillStyle = fill
          ctx.fillRect(ox + x * px, oy + y * px, px, px)
        }
      }
    }
  }
}
