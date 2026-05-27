-- Hyprland configuration (Lua form)
-- Translated from hyprland.conf. See https://wiki.hypr.land/Configuring/Start/
-- Reference sample: /usr/share/hypr/hyprland.lua

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- NVIDIA hardware video acceleration
hl.env("LIBVA_DRIVER_NAME",        "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Cursor sizes
hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Required for xdg-desktop-portal to work correctly. GDK_BACKEND ensures
-- GTK apps (including xdg-desktop-portal-gtk) use Wayland instead of X11.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND",         "wayland,x11,*")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output            = "DP-1",
    mode              = "3440x1440@164.9",
    position          = "0x0",
    scale             = 1,
    bitdepth          = 10, -- Colors registered in Hyprland (e.g. the border color) do not
                            -- support 10 bit. Some applications do not support screen capture
                            -- with 10 bit enabled.
    supports_hdr        = 1, -- 0=auto, 1=force on
    supports_wide_color = 1, -- 0=auto, 1=force on
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "dolphin"
local menu        = "rofi -show combi -modes combi -combi-modes \"window,drun,run\""
local lockmgr     = "hyprlock"
local webBrowser  = "firefox"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    -- Pass environment variables to systemd/dbus so xdg-desktop-portal services
    -- know they're in a Wayland session. Without this, the GTK portal times out
    -- trying to connect to X11, causing ~50 second delays on keybind app launches.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP GDK_BACKEND")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    hl.exec_cmd("ags run")
end)


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 5,

        border_size = 2,

        -- Gruvbox Material colors (dark material palette)
        col = {
            active_border   = { colors = { "rgba(e78a4eee)", "rgba(d8a657ee)" }, angle = 45 },
            inactive_border = "rgba(504945aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a, -- AARRGGBB; equivalent to rgba(1a1a1aee)
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

for _, a in ipairs({
    -- leaf,           speed, bezier,           style (optional)
    { "global",        10,    "default" },
    { "border",        5.39,  "easeOutQuint" },
    { "windows",       4.79,  "easeOutQuint" },
    { "windowsIn",     4.1,   "easeOutQuint",   "popin 87%" },
    { "windowsOut",    1.49,  "linear",         "popin 87%" },
    { "fadeIn",        1.73,  "almostLinear" },
    { "fadeOut",       1.46,  "almostLinear" },
    { "fade",          3.03,  "quick" },
    { "layers",        3.81,  "easeOutQuint" },
    { "layersIn",      4,     "easeOutQuint",   "fade" },
    { "layersOut",     1.5,   "linear",         "fade" },
    { "fadeLayersIn",  1.79,  "almostLinear" },
    { "fadeLayersOut", 1.39,  "almostLinear" },
    { "workspaces",    1.94,  "almostLinear",   "fade" },
    { "workspacesIn",  1.21,  "almostLinear",   "fade" },
    { "workspacesOut", 1.94,  "almostLinear",   "fade" },
    { "zoomFactor",    7,     "quick" },
}) do
    hl.animation({ leaf = a[1], enabled = true, speed = a[2], bezier = a[3], style = a[4] })
end

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name        = "no-gaps-wtv1",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})
hl.window_rule({
    name        = "no-gaps-f1",
    match       = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Basics/Gestures/
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Example per-device config
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

local function bind(keys, action, opts)  hl.bind(mainMod .. " + " .. keys, action, opts) end
local function sbind(keys, action, opts) hl.bind(mainMod .. " + SHIFT + " .. keys, action, opts) end

-- Top level / System level commands
bind ("Escape",   hl.dsp.exec_cmd(lockmgr))
sbind("Escape",   hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
sbind("S",        hl.dsp.window.move({ workspace = 10 }))
bind ("T",        hl.dsp.exec_cmd(terminal))
bind ("Q",        hl.dsp.window.close())
sbind("Q",        hl.dsp.exec_cmd("hyprctl kill"))
bind ("M",        hl.dsp.exit())
bind ("F",        hl.dsp.exec_cmd(fileManager))
bind ("W",        hl.dsp.exec_cmd(webBrowser))
bind ("V",        hl.dsp.window.float({ action = "toggle" }))
bind ("Space",    hl.dsp.exec_cmd(menu))
bind ("P",        hl.dsp.window.pseudo())        -- dwindle
bind ("J",        hl.dsp.layout("togglesplit"))  -- dwindle
bind ("Print",    hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
sbind("Print",    hl.dsp.exec_cmd("bash -c 'hyprshot -m output -o ~ -f screenshot_$(date +%Y-%m-%dT%H-%M-%S).jpg'"))

-- Move focus with mainMod + arrow keys
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind(dir, hl.dsp.focus({ direction = dir }))
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 maps to key 0
    bind (key, hl.dsp.focus({ workspace = i }))
    sbind(key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
bind ("grave", hl.dsp.workspace.toggle_special("magic"))
sbind("grave", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind("mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
local repeat_locked = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),            repeat_locked)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),                 repeat_locked)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/audio-mute-toggle.sh"),     repeat_locked)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),              repeat_locked)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                             repeat_locked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                             repeat_locked)

-- Requires playerctl
local locked = { locked = true }
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   locked)


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name           = "ignore-maximize-requests",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drag",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Remove borders and rounding for fullscreen windows
hl.window_rule({
    name        = "fullscreen-no-borders",
    match       = { fullscreen = true },
    rounding    = 0,
    border_size = 0,
})

-- Remove borders and rounding for Steam games (borderless windowed)
hl.window_rule({
    name        = "steam-games-no-borders",
    match       = { class = "^(steam_app_.*)$" },
    rounding    = 0,
    border_size = 0,
})

-- Window rules for steam
hl.window_rule({
    name  = "steam-float",
    match = { class = "^(steam)$" },
    float = true,
})
