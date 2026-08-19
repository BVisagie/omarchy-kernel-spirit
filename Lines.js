// Quote bank and small pure helpers for Kernel Spirit.
// Fabricated lines belong to the penguin. Quoted entries are real public
// remarks, marked in the UI and sourced in the README.

var UPTIME_MILESTONES = [1, 7, 14, 30]

var WANDER = [
  { text: "If it compiles, ship it. If it doesn't, that's also information." },
  { text: "Your init is fine. Stop poking it." },
  { text: "A desktop is just a kernel that got dressed up." },
  { text: "I don't care what DE you run. I care that you still have a rootfs." },
  { text: "Reboot is not a debugging strategy. It is a surrender." },
  { text: "Patches welcome. Keep the opinions shorter than the diff." },
  { text: "You have a terminal. Use it." },
  { text: "Nice rice. Does it boot." },
  { text: "Userspace can be pretty. The kernel still has to be right." },
  { text: "Most bugs are in your code. The rest are also in your code." },
  { text: "Read the log. Then read it again. Then fix the thing." },
  { text: "We don't break userspace. You, on the other hand…" },
  { text: "A config you cannot explain is a bug you have not met yet." },
  { text: "The best code is the code you finally deleted." },
  { text: "Warnings are errors that haven't grown up yet." },
  { text: "It worked on your machine? This is your machine." },
  { text: "This desktop is production. Act accordingly." },
  { text: "I have seen your shell history. Bold choices." },
  { text: "Everything is a file. Even your problems." },
  { text: "Naming things is hard. That's why you have a folder called tmp." },
  { text: "Your dotfiles are showing. Good. Own them." },
  { text: "Somewhere a process is leaking memory. It can wait. Probably." },
  { text: "Talk is cheap. Show me the code.", quoted: true, source: "Linus Torvalds, linux-kernel mailing list, 25 Aug 2000" },
  { text: "Only wimps use tape backup: real men just upload their important stuff on ftp, and let the rest of the world mirror it ;)", quoted: true, source: "Linus Torvalds, linux-kernel mailing list, 20 Jul 1996" },
  { text: "Given enough eyeballs, all bugs are shallow.", quoted: true, source: "“Linus's Law”, coined by Eric S. Raymond in The Cathedral and the Bazaar" }
]

var CLICK = [
  { text: "You rang." },
  { text: "What." },
  { text: "Yes?" },
  { text: "Make it short." },
  { text: "I'm here. The code still isn't going to write itself." },
  { text: "Go on. I haven't got all cycle." },
  { text: "If this is about systemd, I already know." },
  { text: "Speak. I bill by the jiffy." },
  { text: "This had better be about something segfaulting." },
  { text: "One line. That's the format." }
]

var LOAD = [
  { text: "Something is pegging your cores. I hope it's a compile and not a browser." },
  { text: "Load's at {load}. That's not a suggestion." },
  { text: "Your CPUs are busy. Mine too. Difference is I don't complain. Much." },
  { text: "If this is a compile, good. If this is JavaScript, we need to talk." },
  { text: "Scheduler's doing its job. Whatever you started had better be worth it." },
  { text: "{load} load average. The fans believe in you. I remain neutral." },
  { text: "All cores accounted for and screaming. Carry on." }
]

var BATTERY = [
  { text: "{battery}%. Save your work. Filesystems forgive; unwritten buffers don't." },
  { text: "Battery's leaving. Follow its example and plug in." },
  { text: "You're discharging like it's a feature. It isn't." },
  { text: "{battery}% and falling. Sync, save, then panic if you must." },
  { text: "The kernel can power-manage. It cannot generate power. {battery}%." },
  { text: "Electrons are a finite resource today. {battery}%." }
]

var LATE_NIGHT = [
  { text: "The kernel never sleeps. You, however, should." },
  { text: "It's {hour}. This is how bugs are born." },
  { text: "Nothing good is committed after midnight. I have the logs." },
  { text: "Go to bed. The machine will still be wrong in the morning." },
  { text: "{hour}. Caffeine is not a scheduler." },
  { text: "Past midnight the only thing you should ship is yourself, to bed." },
  { text: "It's {hour}. Whatever you're debugging, it's winning." }
]

var UPTIME = [
  { text: "{days} days without a reboot. Either you're careful or lucky. Don't ask which." },
  { text: "Uptime: {days} days. The kernel is not impressed. I am slightly less annoyed." },
  { text: "Still up after {days} days. Don't jinx it." },
  { text: "{days} days. Fine. You may feel a little smug. Quietly." },
  { text: "{days} days of uptime and nothing on fire. Statistically suspicious." }
]

var THEME = [
  { text: "New coat of paint. Same bugs underneath." },
  { text: "A theme change. Bold move for someone with uncommitted work." },
  { text: "I liked the old colors. I'll adapt. I always adapt." },
  { text: "Fresh palette. The kernel doesn't care. I almost do." },
  { text: "You rice more than you compile. Respect." },
  { text: "Noted. I match the furniture now." }
]

function bankFor(kind) {
  if (kind === "load") return LOAD
  if (kind === "battery") return BATTERY
  if (kind === "lateNight") return LATE_NIGHT
  if (kind === "uptime") return UPTIME
  if (kind === "themeChange") return THEME
  if (kind === "click") return CLICK.concat(WANDER)
  return WANDER
}

// Pick a line the penguin hasn't said recently. `recent` is an array of the
// last few spoken texts; short banks fall back to the full list rather than
// going silent.
function pickLine(list, recent) {
  if (!list || list.length === 0) return null
  var avoid = recent || []
  var choices = []
  for (var i = 0; i < list.length; i++) {
    if (avoid.indexOf(list[i].text) === -1) choices.push(list[i])
  }
  if (choices.length === 0) choices = list
  return choices[Math.floor(Math.random() * choices.length)]
}

function pad2(value) {
  var n = Number(value)
  return (n < 10 ? "0" : "") + n
}

function formatHour(date) {
  return pad2(date.getHours()) + ":" + pad2(date.getMinutes())
}

function render(entry, ctx) {
  if (!entry) return null
  var text = String(entry.text || "")
  if (ctx) {
    if (ctx.load !== undefined) text = text.replace(/\{load\}/g, String(ctx.load))
    if (ctx.battery !== undefined) text = text.replace(/\{battery\}/g, String(ctx.battery))
    if (ctx.days !== undefined) text = text.replace(/\{days\}/g, String(ctx.days))
    if (ctx.hour !== undefined) text = text.replace(/\{hour\}/g, String(ctx.hour))
  }
  return {
    text: text,
    raw: String(entry.text || ""),
    quoted: !!entry.quoted,
    source: entry.source ? String(entry.source) : ""
  }
}

function speak(kind, recent, ctx) {
  return render(pickLine(bankFor(kind), recent), ctx)
}

function isTruthy(value) {
  return value === true || value === 1 || value === "true" || value === "1"
}

function numberSetting(value, fallback) {
  var n = Number(value)
  return isFinite(n) ? n : fallback
}

function parseLoadavg(text) {
  var parts = String(text || "").replace(/^\s+|\s+$/g, "").split(/\s+/)
  var one = Number(parts[0])
  return isFinite(one) ? one : -1
}

function parseUptimeSeconds(text) {
  var parts = String(text || "").replace(/^\s+|\s+$/g, "").split(/\s+/)
  var seconds = Number(parts[0])
  return isFinite(seconds) && seconds >= 0 ? seconds : -1
}

function uptimeDays(seconds) {
  if (!(seconds >= 0)) return 0
  return Math.floor(seconds / 86400)
}

function nextMilestone(days, lastSpoken) {
  var spoken = Number(lastSpoken)
  if (!isFinite(spoken)) spoken = 0
  var found = 0
  for (var i = 0; i < UPTIME_MILESTONES.length; i++) {
    if (days >= UPTIME_MILESTONES[i] && UPTIME_MILESTONES[i] > spoken)
      found = UPTIME_MILESTONES[i]
  }
  return found
}

function wanderIntervalMs(minutes) {
  var base = Math.max(15, Number(minutes) || 60) * 60000
  var jitter = 0.3
  var factor = 1 - jitter + Math.random() * jitter * 2
  return Math.round(base * factor)
}

function nightKey(date) {
  // A "night" belongs to the morning it ends on, so 23:00 and 02:00
  // of the next calendar day share a cooldown.
  var year = date.getFullYear()
  var month = date.getMonth()
  var day = date.getDate()
  if (date.getHours() >= 12) {
    var next = new Date(year, month, day + 1)
    year = next.getFullYear()
    month = next.getMonth()
    day = next.getDate()
  }
  return year + "-" + pad2(month + 1) + "-" + pad2(day)
}

function inLateNight(date, startHour, endHour) {
  var hour = date.getHours()
  var start = ((Number(startHour) % 24) + 24) % 24
  var end = ((Number(endHour) % 24) + 24) % 24
  if (start === end) return false
  if (start < end) return hour >= start && hour < end
  return hour >= start || hour < end
}

if (typeof module !== "undefined") {
  module.exports = {
    bankFor: bankFor,
    pickLine: pickLine,
    render: render,
    speak: speak,
    isTruthy: isTruthy,
    numberSetting: numberSetting,
    parseLoadavg: parseLoadavg,
    parseUptimeSeconds: parseUptimeSeconds,
    uptimeDays: uptimeDays,
    nextMilestone: nextMilestone,
    wanderIntervalMs: wanderIntervalMs,
    nightKey: nightKey,
    inLateNight: inLateNight,
    formatHour: formatHour,
    UPTIME_MILESTONES: UPTIME_MILESTONES
  }
}
