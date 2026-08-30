.pragma library

function clamp(value, minimum, maximum) {
  return Math.max(minimum, Math.min(maximum, value))
}

function booleanValue(value, fallback) {
  if (value === true || value === "true") return true
  if (value === false || value === "false") return false
  return fallback
}

function normalize(raw) {
  var source = raw && typeof raw === "object" ? raw : {}
  var opacity = Number(source.dimOpacity)
  if (!isFinite(opacity)) opacity = 0.48
  var blankSeconds = Number(source.screenBlankSeconds)
  if (!isFinite(blankSeconds)) blankSeconds = 300
  blankSeconds = Math.round(blankSeconds)

  return {
    backgroundMode: source.backgroundMode === "solid" ? "solid" : "wallpaper",
    dimOpacity: clamp(opacity, 0, 0.85),
    screenBlankSeconds: clamp(blankSeconds, 5, 3600),
    hourFormat: String(source.hourFormat || "24") === "12" ? "12" : "24",
    showSecondsRing: booleanValue(source.showSecondsRing, true),
    showPowerActions: booleanValue(source.showPowerActions, true),
    identityLabel: String(source.identityLabel || "").trim()
  }
}
