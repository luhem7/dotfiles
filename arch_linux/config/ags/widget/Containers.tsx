import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import GLib from "gi://GLib"

const POLL_MS = 5000
const CONTAINER_GLYPH = "󰡨" // nf-md-docker; podman is docker-compatible

// Thin space (not a regular space) so the glyph and count hug as one token
// rather than reading like a number trailing the icon row.
const badge = (n: number) => `[${n}]`

// Tab-separated columns: name, state, status, image, created-at, command, ports.
const PS_FORMAT = [
  "{{.Names}}",
  "{{.State}}",
  "{{.Status}}",
  "{{.Image}}",
  "{{.CreatedAt}}",
  "{{.Command}}",
  "{{.Ports}}",
].join("\t")
const PS_ARGS = ["podman", "ps", "--format", PS_FORMAT]

type Row = {
  name: string
  state: string
  status: string
  image: string
  created: string
  command: string
  ports: string
}

// Health/run state -> dot glyph + CSS state class (colors live in style.scss).
function dotFor(row: Row): { glyph: string; cls: string } {
  const s = row.status.toLowerCase()
  if (row.state === "paused" || s.includes("(paused)")) return { glyph: "⏸", cls: "paused" }
  if (s.includes("(unhealthy)")) return { glyph: "●", cls: "unhealthy" }
  if (s.includes("(starting)")) return { glyph: "●", cls: "starting" }
  if (row.state === "running") return { glyph: "●", cls: "running" }
  return { glyph: "●", cls: "other" }
}

// Drop the trailing health/pause parenthetical; the dot already conveys it.
function cleanStatus(status: string): string {
  return status.replace(/\s*\((healthy|unhealthy|starting|paused)\)\s*$/i, "").trim()
}

// "2026-06-06 07:44:18.78... -0400 EDT" -> "2026-06-06 07:44"
function startedAt(createdAt: string): string {
  return createdAt.slice(0, 16)
}

// Build the hover table: [dot] Container | Status | Image | Started | Command | Ports.
function buildTable(rows: Row[]): Gtk.Widget {
  const grid = new Gtk.Grid()
  grid.add_css_class("container-tooltip")
  grid.set_row_spacing(4)
  grid.set_column_spacing(12)

  // Header row (column 0 holds the state dot and has no header label).
  const headers = ["Container", "Status", "Image", "Started", "Command", "Ports"]
  headers.forEach((text, c) => {
    const lbl = new Gtk.Label({ label: text })
    lbl.add_css_class("c-header")
    lbl.set_xalign(0)
    grid.attach(lbl, c + 1, 0, 1, 1)
  })

  const cell = (text: string, cls: string, col: number, row: number) => {
    const lbl = new Gtk.Label({ label: text })
    lbl.add_css_class(cls)
    lbl.set_xalign(0)
    grid.attach(lbl, col, row, 1, 1)
  }

  rows.forEach((row, i) => {
    const r = i + 1 // row 0 is the header
    const { glyph, cls } = dotFor(row)

    const dot = new Gtk.Label({ label: glyph })
    dot.add_css_class("state-dot")
    dot.add_css_class(`state-${cls}`)
    grid.attach(dot, 0, r, 1, 1)

    cell(row.name, "c-name", 1, r)
    cell(cleanStatus(row.status), "c-meta", 2, r)
    cell(row.image, "c-meta", 3, r)
    cell(startedAt(row.created), "c-meta", 4, r)
    cell(row.command || "—", "c-meta", 5, r)
    cell(row.ports.trim() || "—", "c-meta", 6, r)
  })

  return grid
}

function initContainers(button: Gtk.Button) {
  const label = new Gtk.Label({ label: badge(0) })
  button.set_child(label)

  let latest: Row[] = []

  const refresh = () => {
    execAsync(PS_ARGS)
      .then(out => {
        latest = out
          .split("\n")
          .map(l => l.trim())
          .filter(Boolean)
          .map(l => {
            const f = l.split("\t")
            return {
              name: f[0] ?? "",
              state: f[1] ?? "",
              status: f[2] ?? "",
              image: f[3] ?? "",
              created: f[4] ?? "",
              command: f[5] ?? "",
              ports: f[6] ?? "",
            }
          })
        label.set_label(badge(latest.length))
      })
      .catch(err => {
        console.error("podman ps failed:", err)
        latest = []
        label.set_label(badge(0))
      })
  }

  // Rich hover table, built on demand from the latest poll snapshot.
  button.set_has_tooltip(true)
  button.connect("query-tooltip", (_w, _x, _y, _kbd, tooltip) => {
    if (latest.length === 0) {
      tooltip.set_text("No running containers")
      return true
    }
    tooltip.set_custom(buildTable(latest))
    return true
  })

  refresh()

  // Repeating poll for the bar's lifetime (no teardown needed, like Media.tsx).
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, POLL_MS, () => {
    refresh()
    return GLib.SOURCE_CONTINUE
  })

  // Click forces an immediate re-poll instead of waiting for the next tick.
  button.connect("clicked", refresh)
}

export function Containers() {
  return <button class="volume-button containers" onRealize={initContainers} />
}
