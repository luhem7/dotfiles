# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a GTK4 desktop shell/widget configuration for Linux built with the Astal ecosystem:

- **Astal** - Core framework: a collection of Vala/C libraries for building desktop widgets and shells, with libraries for system integration (Battery, Bluetooth, Mpris, Network, Tray, etc.)
- **Gnim** - Library that brings JSX to GJS (GNOME JavaScript), enabling TypeScript/TSX development
- **AGS** - Scaffolding CLI tool for Astal + Gnim TypeScript projects (handles bundling, hot-reload, type generation)

## Commands

```bash
# Run the shell (hot-reloads on file changes)
ags run

# Run with a specific entry file
ags run app.ts

# Bundle for distribution
ags bundle app.ts output-name

# Regenerate TypeScript type definitions for GObject introspection
ags types

# Update types and sync tsconfig/ags package
ags types --update

# Inspect running widgets with GTK debug tool
ags inspect

# Quit running instance
ags quit
```

## Architecture

- **app.ts** - Entry point that initializes the application, loads CSS, and creates widgets for each monitor
- **widget/** - TSX components for UI widgets (Gnim JSX with `jsxImportSource: "ags/gtk4"`)
- **style.scss** - SCSS styling using GTK/Adwaita theme variables (e.g., `@theme_fg_color`, `@theme_bg_color`)
- **@girs/** - Auto-generated TypeScript definitions for GObject libraries (gitignored, regenerate with `ags types`)
- **env.d.ts** - Type declarations for special imports (inline:*, *.scss, *.blp, *.css)

## Key Patterns

- Widgets are TSX functions returning GTK elements (`<window>`, `<box>`, `<button>`, etc.)
- `createPoll()` from `ags/time` - reactive values that update on intervals
- `execAsync()` from `ags/process` - async shell command execution
- `Astal.WindowAnchor` flags (TOP, LEFT, RIGHT, BOTTOM) for window positioning
- `$type` prop assigns children to container slots (start, center, end for centerbox)

## Code Style

- No semicolons (configured in package.json prettier)
- 2-space indentation
