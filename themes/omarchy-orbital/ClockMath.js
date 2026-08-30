// Ported from dumidulkdev/omarchy-orbital-lock (MIT): https://github.com/dumidulkdev/omarchy-orbital-lock.git
// Unchanged from the Omarchy Orbital Lock screen.
.pragma library

function normalizeAngle(angle) {
  var value = Number(angle) % 360
  return value < 0 ? value + 360 : value
}

function angularDistance(a, b) {
  var distance = Math.abs(normalizeAngle(a) - normalizeAngle(b))
  return Math.min(distance, 360 - distance)
}

function secondAngle(date) {
  var value = date instanceof Date ? date : new Date(date)
  return -((value.getSeconds() + value.getMilliseconds() / 1000) * 6)
}

function minuteAngle(date) {
  var value = date instanceof Date ? date : new Date(date)
  return -((value.getMinutes() + value.getSeconds() / 60 + value.getMilliseconds() / 60000) * 6)
}

// The orbit center sits just beyond the left screen edge. Offset the usual
// 12-o'clock alignment so the current value crosses the visible right edge.
function visibleEdgeRotation(angle) {
  return Number(angle) + 90
}

function hourText(date, format) {
  var value = date instanceof Date ? date : new Date(date)
  var hour = value.getHours()
  if (String(format) === "12") {
    hour %= 12
    if (hour === 0) hour = 12
  }
  return String(hour).padStart(2, "0")
}
