# Hyprland Integration with Astal/AGS

This document covers how to integrate Hyprland window manager data into AGS widgets using the AstalHyprland library.

## Overview

Astal provides a dedicated library called **AstalHyprland** that communicates with Hyprland via its IPC (Inter-Process Communication) socket. This enables **event-driven updates** rather than polling, meaning your widgets react instantly to changes.

## What is an IPC Socket?

An IPC socket is a communication channel between processes. Hyprland exposes two sockets:

1. **Command Socket** - Send commands and receive responses (like `hyprctl`)
2. **Event Socket** - Streams real-time events (workspace changes, window focus, etc.)

Socket location: `$XDG_RUNTIME_DIR/hyprland/$HYPRLAND_INSTANCE_SIGNATURE/`

AstalHyprland monitors the event socket in the background and emits GObject signals when state changes occur.

## Setup

### 1. Install the AstalHyprland Library

The Hyprland bindings are provided by a separate library that must be installed first.

**Arch Linux (AUR):**
```bash
paru -S libastal-hyprland-git
```

This installs the GObject introspection bindings that AGS needs to communicate with Hyprland.

### 2. Generate Type Definitions

After installing the library, regenerate types:

```bash
ags types
```

This generates types to `~/.config/ags/@girs/` by default.

**Important**: The project's `@girs/` directory should be a symlink to `~/.config/ags/@girs/` so that newly generated types are automatically available:

```bash
# If @girs is a regular directory, replace it with a symlink:
rm -rf @girs
ln -s ~/.config/ags/@girs @girs
```

After this, `astalhyprland-0.1.d.ts` (and any future type definitions) will be available in the project.

### 3. Import the Library

```typescript
import Hyprland from "gi://AstalHyprland"

const hyprland = Hyprland.get_default()
```

## Available Properties

### Active/Focused State

| Property | Type | Description |
|----------|------|-------------|
| `hyprland.focused_workspace` | `Workspace` | Currently active workspace |
| `hyprland.focused_monitor` | `Monitor` | Currently focused monitor |
| `hyprland.focused_client` | `Client` | Currently focused window |

### Collections

| Property | Type | Description |
|----------|------|-------------|
| `hyprland.workspaces` | `Workspace[]` | All workspaces |
| `hyprland.clients` | `Client[]` | All open windows |
| `hyprland.monitors` | `Monitor[]` | All connected monitors |

### Workspace Object Properties

```typescript
workspace.id        // Workspace ID (number)
workspace.name      // Workspace name (string)
workspace.monitor   // Monitor this workspace is on
```

### Client (Window) Object Properties

```typescript
client.address      // Window address (hex string)
client.title        // Window title
client.class        // Window class (app name)
client.workspace    // Workspace the window is on
client.monitor      // Monitor the window is on
client.floating     // Is window floating?
client.fullscreen   // Is window fullscreen?
client.focused      // Is window focused?
```

### Monitor Object Properties

```typescript
monitor.id          // Monitor ID
monitor.name        // Monitor name (e.g., "DP-1")
monitor.width       // Resolution width
monitor.height      // Resolution height
monitor.x           // X position
monitor.y           // Y position
monitor.scale       // Scale factor
monitor.active_workspace  // Current workspace on this monitor
```

## Event Signals

AstalHyprland emits signals when Hyprland state changes. Connect to these for event-driven updates:

| Signal | Description |
|--------|-------------|
| `notify::focused-workspace` | Active workspace changed |
| `notify::focused-client` | Focused window changed |
| `notify::focused-monitor` | Focused monitor changed |
| `workspace-added` | New workspace created |
| `workspace-removed` | Workspace deleted |
| `client-added` | Window opened |
| `client-removed` | Window closed |
| `urgent-window` | Window requests attention |
| `submap` | Keybind submap activated |
| `keyboard-layout` | Keyboard layout changed |

## Usage Patterns

### Basic Signal Connection

```typescript
import Hyprland from "gi://AstalHyprland"

const hyprland = Hyprland.get_default()

// React to workspace changes
hyprland.connect("notify::focused-workspace", () => {
    const ws = hyprland.focused_workspace
    console.log(`Workspace changed to: ${ws.name}`)
})

// React to window focus changes
hyprland.connect("notify::focused-client", () => {
    const client = hyprland.focused_client
    if (client) {
        console.log(`Focused: ${client.title}`)
    }
})
```

### Reactive Binding in JSX

Using Astal's `bind()` function for reactive UI updates:

```typescript
import { bind } from "ags/binding"
import Hyprland from "gi://AstalHyprland"

const hyprland = Hyprland.get_default()

function WorkspaceIndicator() {
    return (
        <label
            label={bind(hyprland, "focused_workspace").as(ws => ws?.name || "")}
        />
    )
}

function ActiveWindowTitle() {
    return (
        <label
            label={bind(hyprland, "focused_client").as(client =>
                client?.title || "Desktop"
            )}
        />
    )
}
```

### Workspace List Widget

```typescript
import { bind } from "ags/binding"
import Hyprland from "gi://AstalHyprland"

const hyprland = Hyprland.get_default()

function Workspaces() {
    return (
        <box>
            {bind(hyprland, "workspaces").as(workspaces =>
                workspaces
                    .sort((a, b) => a.id - b.id)
                    .map(ws => (
                        <button
                            class={bind(hyprland, "focused_workspace").as(fw =>
                                fw?.id === ws.id ? "focused" : ""
                            )}
                            onClicked={() => ws.focus()}
                        >
                            <label label={String(ws.id)} />
                        </button>
                    ))
            )}
        </box>
    )
}
```

### Sending Commands to Hyprland

```typescript
const hyprland = Hyprland.get_default()

// Dispatch commands (async)
hyprland.message_async("dispatch workspace 1", null)

// Or use the message method
hyprland.message("dispatch togglefloating")
```

## Common Recipes

### Show Active Workspace ID

```typescript
<label label={bind(hyprland, "focused_workspace").as(ws => `WS: ${ws?.id}`)} />
```

### Show Window Count

```typescript
<label label={bind(hyprland, "clients").as(clients => `Windows: ${clients.length}`)} />
```

### Show Current Monitor Name

```typescript
<label label={bind(hyprland, "focused_monitor").as(m => m?.name || "")} />
```

### Workspace Dots Indicator

```typescript
function WorkspaceDots() {
    return (
        <box class="workspace-dots">
            {bind(hyprland, "workspaces").as(workspaces =>
                workspaces
                    .filter(ws => ws.id > 0)  // Filter out special workspaces
                    .sort((a, b) => a.id - b.id)
                    .map(ws => (
                        <box
                            class={bind(hyprland, "focused_workspace").as(fw =>
                                `dot ${fw?.id === ws.id ? "active" : ""}`
                            )}
                        />
                    ))
            )}
        </box>
    )
}
```

## References

- [Astal Hyprland Documentation](https://aylur.github.io/astal/guide/libraries/hyprland)
- [AGS Hyprland Service Docs](https://aylur.github.io/ags-docs/services/hyprland/)
- [Hyprland Wiki - IPC](https://wiki.hyprland.org/IPC/)

## Example Projects Using Hyprland + AGS

- [HyprPanel](https://github.com/Jas-SinghFSU/HyprPanel) - Feature-rich panel for Hyprland
- [Matshell](https://github.com/Neurarian/matshell) - Material Design shell
- [n7n-AGS-Shell](https://github.com/nine7nine/n7n-AGS-Shell) - Wayland desktop shell
