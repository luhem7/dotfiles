// Sunrise/Sunset calculator using standard solar position algorithm
// Coordinates for Richmond, VA area
const LATITUDE = 37.6313917
const LONGITUDE = -77.3490173

const toRad = (deg: number) => (deg * Math.PI) / 180
const toDeg = (rad: number) => (rad * 180) / Math.PI

export function getSunTimes(date: Date = new Date()): { sunrise: number; sunset: number } {
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const day = date.getDate()

  const n1 = Math.floor((275 * month) / 9)
  const n2 = Math.floor((month + 9) / 12)
  const n3 = 1 + Math.floor((year - 4 * Math.floor(year / 4) + 2) / 3)
  const dayOfYear = n1 - n2 * n3 + day - 30

  const zenith = 90.833
  const localOffset = -date.getTimezoneOffset() / 60
  const lngHour = LONGITUDE / 15

  const tRise = dayOfYear + (6 - lngHour) / 24
  const tSet = dayOfYear + (18 - lngHour) / 24

  const mRise = 0.9856 * tRise - 3.289
  const mSet = 0.9856 * tSet - 3.289

  const calcTrueLong = (m: number) => {
    let l = m + 1.916 * Math.sin(toRad(m)) + 0.02 * Math.sin(toRad(2 * m)) + 282.634
    if (l > 360) l -= 360
    if (l < 0) l += 360
    return l
  }

  const lRise = calcTrueLong(mRise)
  const lSet = calcTrueLong(mSet)

  const calcRA = (l: number) => {
    let ra = toDeg(Math.atan(0.91764 * Math.tan(toRad(l))))
    if (ra > 360) ra -= 360
    if (ra < 0) ra += 360
    const lQuad = Math.floor(l / 90) * 90
    const raQuad = Math.floor(ra / 90) * 90
    ra += lQuad - raQuad
    return ra / 15
  }

  const raRise = calcRA(lRise)
  const raSet = calcRA(lSet)

  const calcHourAngle = (l: number, rising: boolean) => {
    const sinDec = 0.39782 * Math.sin(toRad(l))
    const cosDec = Math.cos(Math.asin(sinDec))
    const cosH =
      (Math.cos(toRad(zenith)) - sinDec * Math.sin(toRad(LATITUDE))) /
      (cosDec * Math.cos(toRad(LATITUDE)))
    const clampedCosH = Math.max(-1, Math.min(1, cosH))
    let h = toDeg(Math.acos(clampedCosH))
    if (rising) h = 360 - h
    return h / 15
  }

  const hRise = calcHourAngle(lRise, true)
  const hSet = calcHourAngle(lSet, false)

  const tLocalRise = hRise + raRise - 0.06571 * tRise - 6.622
  const tLocalSet = hSet + raSet - 0.06571 * tSet - 6.622

  const toLocalTime = (t: number) => {
    let local = t - lngHour + localOffset
    if (local < 0) local += 24
    if (local > 24) local -= 24
    return local
  }

  return {
    sunrise: toLocalTime(tLocalRise),
    sunset: toLocalTime(tLocalSet),
  }
}

/**
 * Calculate brightness (0-1) for a given hour based on sun position.
 * Uses a cosine curve peaking at solar noon.
 */
export function getHourBrightness(hour: number, sunTimes?: { sunrise: number; sunset: number }): number {
  const { sunrise, sunset } = sunTimes ?? getSunTimes()

  const solarNoon = (sunrise + sunset) / 2

  let hoursSinceNoon = hour - solarNoon
  if (hoursSinceNoon > 12) hoursSinceNoon -= 24
  if (hoursSinceNoon < -12) hoursSinceNoon += 24

  const angle = (hoursSinceNoon / 12) * Math.PI
  return (Math.cos(angle) + 1) / 2
}

function parseHex(hex: string): [number, number, number] {
  return [
    parseInt(hex.slice(1, 3), 16),
    parseInt(hex.slice(3, 5), 16),
    parseInt(hex.slice(5, 7), 16),
  ]
}

function toHex(r: number, g: number, b: number): string {
  const clamp = (n: number) => Math.min(255, Math.max(0, Math.round(n)))
  return `#${clamp(r).toString(16).padStart(2, "0")}${clamp(g).toString(16).padStart(2, "0")}${clamp(b).toString(16).padStart(2, "0")}`
}

/**
 * Convert brightness (0-1) to a hex color, with optional tint blending.
 */
export function brightnessToColor(
  brightness: number,
  baseColor = "#433F3C",
  maxLighten = 20,
  tintColor?: string,
  tintAmount = 0.3
): string {
  const [r, g, b] = parseHex(baseColor)

  const lightenAmount = brightness * maxLighten * 2.55
  let newR = r + lightenAmount
  let newG = g + lightenAmount
  let newB = b + lightenAmount

  if (tintColor) {
    const [tR, tG, tB] = parseHex(tintColor)
    const t = tintAmount * brightness
    newR = newR * (1 - t) + tR * t
    newG = newG * (1 - t) + tG * t
    newB = newB * (1 - t) + tB * t
  }

  return toHex(newR, newG, newB)
}
