import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui
import "Lines.js" as Lines

// Bar penguin plus the host for the speech-bubble panel.
// Left click summons a line; right click mutes wander/reactions;
// middle click snoozes for the configured interval.
BarWidget {
  id: root
  moduleName: "io.github.bvisagie.kernel-spirit"

  property var currentLine: null
  property int lineEpoch: 0
  property var recentLines: []
  property double snoozeUntil: 0
  property real coreCount: 1
  property real loadOne: -1
  property int batteryPercent: -1
  property int uptimeSeconds: -1
  property int highLoadStreak: 0
  property int lastUptimeMilestone: 0
  property bool uptimePrimed: false
  property bool batteryLowLatched: false
  property string lastNightKey: ""
  property double lastReactionAt: 0

  readonly property bool muted: Lines.isTruthy(setting("muted", false))
  readonly property bool snoozed: snoozeUntil > 0
  readonly property int wanderMinutes: Math.max(15, Lines.numberSetting(setting("wanderIntervalMin", 60), 60))
  readonly property int cooldownMs: Math.max(10, Lines.numberSetting(setting("cooldownMin", 45), 45)) * 60000
  readonly property int snoozeMinutes: Math.max(15, Lines.numberSetting(setting("snoozeMin", 60), 60))
  readonly property real loadThreshold: Math.max(0.1, Lines.numberSetting(setting("loadThreshold", 0.75), 0.75))
  readonly property int batteryThreshold: Math.max(5, Lines.numberSetting(setting("batteryThreshold", 20), 20))
  readonly property int lateNightStartHour: Lines.numberSetting(setting("lateNightStartHour", 0), 0)
  readonly property int lateNightEndHour: Lines.numberSetting(setting("lateNightEndHour", 5), 5)
  readonly property bool loadTrigger: Lines.isTruthy(setting("loadTrigger", true))
  readonly property bool batteryTrigger: Lines.isTruthy(setting("batteryTrigger", true))
  readonly property bool lateNightTrigger: Lines.isTruthy(setting("lateNightTrigger", true))
  readonly property bool uptimeTrigger: Lines.isTruthy(setting("uptimeTrigger", true))
  readonly property bool themeTrigger: Lines.isTruthy(setting("themeTrigger", true))

  // Theme reactions stay quiet during startup while the theme first loads.
  property bool themeArmed: false

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property real openPanelIndicatorWidth: button.glyphPaintedWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  // Built fresh per line so the wall clock is never stale.
  function makeContext() {
    return {
      load: loadOne >= 0 ? loadOne.toFixed(2) : "?",
      battery: batteryPercent >= 0 ? batteryPercent : "?",
      days: Lines.uptimeDays(uptimeSeconds),
      hour: Lines.formatHour(new Date())
    }
  }

  function isPrimary() {
    var items = bar && typeof bar.moduleWidgets === "function" ? bar.moduleWidgets(moduleName) : [root]
    return !items || items.length === 0 || items[0] === root
  }

  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (var key in values) entry[key] = values[key]
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function toggleMute() {
    persistSettings({ muted: !root.muted })
  }

  function snooze() {
    root.snoozeUntil = Date.now() + root.snoozeMinutes * 60000
    snoozeTimer.interval = root.snoozeMinutes * 60000
    snoozeTimer.restart()
  }

  function clearSnooze() {
    snoozeTimer.stop()
    root.snoozeUntil = 0
  }

  function reactionsAllowed() {
    return !root.muted && !root.snoozed
  }

  function cooldownReady() {
    return Date.now() - root.lastReactionAt >= root.cooldownMs
  }

  function speak(kind) {
    var line = Lines.speak(kind, root.recentLines, makeContext())
    if (!line) return false
    root.currentLine = line
    var recent = root.recentLines.slice(-2)
    recent.push(line.raw)
    root.recentLines = recent
    root.lineEpoch = root.lineEpoch + 1
    if (kind !== "click") root.lastReactionAt = Date.now()
    return true
  }

  function openPanel() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function open() {
    if (speak("click")) openPanel()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    togglePanel()
  }

  function togglePanel() {
    if (root.opened) root.close()
    else if (speak("click")) openPanel()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function maybeSpeak(kind, skipCooldown) {
    if (!reactionsAllowed()) return false
    if (!isPrimary()) return false
    if (!skipCooldown && !cooldownReady()) return false
    if (!speak(kind)) return false
    openPanel()
    return true
  }

  function checkSignals() {
    var now = new Date()
    var perCore = root.coreCount > 0 && root.loadOne >= 0 ? root.loadOne / root.coreCount : -1

    if (root.loadTrigger && perCore >= 0) {
      if (perCore >= root.loadThreshold) root.highLoadStreak += 1
      else root.highLoadStreak = 0
      if (root.highLoadStreak >= 2 && maybeSpeak("load"))
        root.highLoadStreak = 0
    }

    if (root.batteryTrigger) {
      var device = UPower.displayDevice
      var present = !!(device && device.isPresent)
      var percent = present ? Math.round(Number(device.percentage || 0) * 100) : -1
      root.batteryPercent = percent
      var discharging = present && UPower.onBattery && percent >= 0
      var low = discharging && percent <= root.batteryThreshold
      if (low && !root.batteryLowLatched) {
        if (maybeSpeak("battery")) root.batteryLowLatched = true
      } else if (!low) {
        root.batteryLowLatched = false
      }
    }

    if (root.lateNightTrigger && Lines.inLateNight(now, root.lateNightStartHour, root.lateNightEndHour)) {
      var key = Lines.nightKey(now)
      if (key !== root.lastNightKey && maybeSpeak("lateNight"))
        root.lastNightKey = key
    }

    if (root.uptimeTrigger && root.uptimeSeconds >= 0) {
      var days = Lines.uptimeDays(root.uptimeSeconds)
      if (!root.uptimePrimed) {
        root.uptimePrimed = true
        root.lastUptimeMilestone = days
      } else {
        var milestone = Lines.nextMilestone(days, root.lastUptimeMilestone)
        if (milestone > 0 && maybeSpeak("uptime"))
          root.lastUptimeMilestone = milestone
      }
    }
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("SpeechPanel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  FileView {
    id: loadFile
    path: "/proc/loadavg"
    watchChanges: false
    printErrors: false
    onLoaded: root.loadOne = Lines.parseLoadavg(text())
  }

  FileView {
    id: uptimeFile
    path: "/proc/uptime"
    watchChanges: false
    printErrors: false
    onLoaded: root.uptimeSeconds = Math.round(Lines.parseUptimeSeconds(text()))
  }

  Process {
    id: coreProc
    command: ["nproc"]
    running: true
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) return
      var n = Number(String(stdout.text || "").trim())
      if (isFinite(n) && n > 0) root.coreCount = n
    }
  }

  Timer {
    id: pollTimer
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      loadFile.reload()
      uptimeFile.reload()
      root.checkSignals()
    }
  }

  Timer {
    id: wanderTimer
    interval: Lines.wanderIntervalMs(root.wanderMinutes)
    running: root.reactionsAllowed()
    repeat: true
    onTriggered: {
      interval = Lines.wanderIntervalMs(root.wanderMinutes)
      if (!root.reactionsAllowed()) return
      if (!root.isPrimary()) return
      if (root.speak("wander")) root.openPanel()
    }
  }

  Timer {
    id: snoozeTimer
    repeat: false
    onTriggered: root.snoozeUntil = 0
  }

  // Theme switches: the Color singleton updates in-process when the theme
  // changes, so no file watching or polling is needed. Armed a few seconds
  // after startup so the initial theme load stays silent; debounced because
  // several color properties change per switch. Skips the reaction cooldown —
  // this is a direct user action, and the penguin recolors to match.
  Timer {
    id: themeArmTimer
    interval: 5000
    running: true
    onTriggered: root.themeArmed = true
  }

  Timer {
    id: themeDebounce
    interval: 700
    onTriggered: root.maybeSpeak("themeChange", true)
  }

  Connections {
    target: Color
    function onAccentChanged() {
      if (root.themeArmed && root.themeTrigger) themeDebounce.restart()
    }
    function onBackgroundChanged() {
      if (root.themeArmed && root.themeTrigger) themeDebounce.restart()
    }
  }

  IpcHandler {
    target: "io.github.bvisagie.kernel-spirit"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function mute(): void { root.toggleMute() }
    function snooze(): void { root.broadcast("snooze") }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    hasVisualContent: true
    dimmed: root.muted || root.snoozed
    slotSize: Style.bar.iconSlot
    tooltipText: root.muted
      ? "Kernel Spirit (muted)"
      : (root.snoozed ? "Kernel Spirit (snoozed)" : "Kernel Spirit")
    iconComponent: Component {
      Item {
        transform: Translate { id: hopShift }

        SequentialAnimation {
          id: hop
          NumberAnimation { target: hopShift; property: "y"; to: -3; duration: 90; easing.type: Easing.OutQuad }
          NumberAnimation { target: hopShift; property: "y"; to: 0; duration: 160; easing.type: Easing.OutBounce }
        }

        Connections {
          target: root
          function onLineEpochChanged() { hop.restart() }
        }

        Loader {
          id: penguinLoader
          anchors.fill: parent
          source: Qt.resolvedUrl("PenguinIcon.qml")
        }
        Binding {
          when: penguinLoader.item !== null
          target: penguinLoader.item
          property: "muted"
          value: root.muted || root.snoozed
        }
        Binding {
          when: penguinLoader.item !== null
          target: penguinLoader.item
          property: "talking"
          value: root.opened
        }
      }
    }

    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleMute()
      else if (b === Qt.MiddleButton) {
        if (root.snoozed) root.clearSnooze()
        else root.snooze()
      } else {
        root.togglePanel()
      }
    }
  }
}
