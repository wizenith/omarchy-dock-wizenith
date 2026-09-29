# Omarchy Dock

![Omarchy Dock](./preview.png)

A modern, highly polished, and fully native application dock plugin for **Omarchy Quattro** (Hyprland + Quickshell), featuring app stacks (folders), iOS-style edit wiggle animations, multi-window management, dynamic orientation, and seamless theme integration.

---

## ✨ Features

- 🧩 **Integrated Dock Widgets** — Move native system widgets (Weather, Volume & Audio, Bluetooth, Network, Power/Battery, Display, Clock/Calendar, Tailscale VPN) directly into the dock. Choose widget placement (Left or Right) via the dedicated widget configuration popup. When clicked, all widget panels appear centered on screen with clean system spacing.
- 📁 **App Stacks (Folders)** — Organize apps into folders with multi-column grids. Create folders by simply dragging one icon onto another. Customize folder icons with built-in Nerd Font glyphs, edit titles inline, and enjoy marquee text scrolling for long names. Folders seamlessly remain open when launching or switching applications.
- ✨ **iOS-Style Edit Mode (Wiggle)** — Long-press (450ms) any icon to enter edit mode with smooth physical wobbling ($\pm 3.8^\circ$, 105ms). Quickly toggle favorite pins (`•`), dissolve folders (`-`), remove dock widgets (`-`), or reorder apps.
- 🔀 **Fluid 1D & 2D Drag & Drop** — Smooth rail displacement physics when dragging apps across the dock or within folder grids. Effortlessly extract apps from folders back to the main dock.
- 🔄 **Multi-Instance Sliding Viewport (Infinite Wheel Scrolling)** — Hover over any running app with duplicate windows and scroll the mouse wheel to cycle through instances. The status capsule uses a smooth 3-slot sliding viewport: the original app is always a distinct wide dash (`━`), while duplicates are round dots (`•`). As you scroll deeper into duplicates, the original dash smoothly scrolls out of view and reappears when looping back.
- 🪟 **Window Picker** — Hover over an app with multiple windows to open a list with the app icon and each window title. Hover a row briefly to preview that window while the pointer stays in place; click to confirm and close the picker. The list includes live titles and workspace labels, and stays open across focus/title updates.
- 🎯 **Real-Time Hyprland IPC Focus Sync** — Moving the mouse cursor over any window tile on the desktop (`follow_mouse = 1`) or switching focus instantly syncs and highlights the corresponding slot on the dock in real time without lag.
- ⚡ **Dedicated Controls (LMB, RMB & Middle-Click)** — Left-click opens closed apps or focuses/restores running windows. Right-click minimizes active/visible windows to a special minimized state. Middle-click (pressing the mouse wheel) instantly spawns a new duplicate instance anytime.
- 👁️ **Smart Cursor Hiding** — The mouse cursor is automatically hidden (`Qt.BlankCursor`) during mouse wheel scrolling and folder title hover to ensure an unobstructed view of the status capsule and animations.
- 🌐 **Full Web Apps (PWA) Support** — Automatic domain matching for Chrome/Chromium web apps (Google Maps, Google Contacts, WhatsApp, YouTube, Discord, etc.) with native GTK theme icons.
- ⚡ **Zero-Flicker Boot & Tile Lift** — Two-phase initialization instantly reserves Hyprland exclusive space to lift tiled windows smoothly, followed by a monolithic fade-in once all vector theme icons are loaded.
- 🧭 **Dynamic Auto-Positioning** — Automatically adapts its position opposite to the Omarchy status bar (top $\leftrightarrow$ bottom, left $\leftrightarrow$ right) and draws a dock on every connected monitor.
- ⏱️ **Flexible Visibility** — Keep the dock visible, reveal it from the screen edge, or toggle it through a Hyprland keybinding. On multi-monitor setups with an autohide mode, a reveal only slides the dock in on the monitor that triggered it; the others stay hidden with their edge triggers still armed.
- 🪟 **Native Overlay Mode** — Float the dock above full-screen/tiling windows without shifting Hyprland window arrangements (macOS / Dash to Dock behavior).
- 🔔 **Real-Time Notification Badges** — Dynamic unread badges on app icons aggregated from D-Bus notifications, Hyprland dwell timers, and window titles.
- 🎛️ **Status Bar Settings Widget (`BarWidget`)** — Native top bar menu for dock visibility, workspace targeting, Overlay Mode, folder titles, notification badges, and dock widgets; the settings card opens directly beneath the widget wherever it's placed in the bar (left, center, or right).
- 🎨 **100% Native Theme Sync** — Clean borderless status capsules that automatically react to Omarchy colors (`Color.accent`, `Color.bar.background`), system fonts, and window corner radius tokens.
- 🔤 **Subpixel Vector Glyphs (`DockGlyph`)** — GPU-accelerated vector curve rendering without font hinting distortion or pixel jitter during animations.

---

## 🎮 Controls & Shortcuts

| Action | Control | Description |
| :--- | :--- | :--- |
| **Open / Restore / Focus Window** | `Left-Click` | Opens the application if closed, restores if minimized, or focuses its active window. |
| **Minimize Window** | `Right-Click` *(on App)* | Minimizes visible application windows to special minimized workspace. |
| **Launch Duplicate** | `Middle-Click` / `Tab` | Instantly spawns a new duplicate instance of the application with immediate focus. |
| **Choose an App Window** | `Hover` an app with multiple windows | Opens a list with app icons and window titles; hovering a row previews it without moving the pointer, and clicking confirms and closes the list. |
| **Preview Duplicate Windows** | `Mouse Wheel` / `←` `→` Arrow Keys | Cycles through the 3-slot status capsule; click the app or press `Enter` to activate the previewed window. |
| **Open Widget Panel** | `Left-Click` *(on Widget)* | Opens the hosted system widget panel (Audio, Wi-Fi, BT, Power, Monitor, etc.) centered on screen. |
| **Enter Edit Mode** | `Long-Press` *(450ms)* | Activates iOS-style physical wobble mode to reorder apps, toggle pins, remove widgets, or dissolve folders. |
| **Reorder & Folders** | `Drag & Drop` | Drag along the rail to reorder. Drag one icon onto another to create a folder (App Stack). |
| **Folder Icon Picker** | `Right-Click` *(on Folder)* | Opens the Nerd Font glyph picker to customize the folder's icon. |
| **Exit Edit Mode / Close Menus** | `Right-Click` / `Escape` | Instantly exits edit mode and dismisses open menus. |
| **Toggle Pin State** | `Click • Badge` *(in Edit Mode)* | Pins or unpins the application to/from favorites. |
| **Dissolve Folder / Remove Widget**| `Click - Badge` *(in Edit Mode)* | Dissolves folder back to dock, or returns widget back to system status bar tray. |

---

## 📦 Installation

Install and enable the dock with a single command:

```bash
omarchy plugin add https://github.com/rosakodu/omarchy-dock.git --enable
```

---

## ⚙️ Configuration

The dock works out of the box with zero configuration required. With `visibleWorkspace` set to `all` (the default), a dock is created on every Hyprland monitor — the same per-output pattern as the Omarchy status bar. Pinning the dock to a specific workspace still shows it only on the monitor that currently displays that workspace.

You can customize options directly via the `···` status bar widget or in `~/.config/omarchy/dock-settings.json`:

```json
{
  "dockEnabled": true,
  "visibilityMode": "always",
  "overlayMode": false,
  "visibleWorkspace": "all",
  "showFolderTitles": true,
  "showBadges": true,
  "windowPickerOpenDelayMs": 150,
  "windowPickerPreviewDelayMs": 140,
  "windowPickerCloseDelayMs": 250,
  "windowPickerFadeDurationMs": 150,
  "widgetsEnabled": true,
  "widgetPosition": "left",
  "dockWidgets": [
    "omarchy.apps"
  ]
}
```

`visibilityMode` accepts `always`, `hover`, `keybind`, or `hybrid`. `overlayMode` uses the
native v1.5.0 implementation: `false` reserves screen space and `true` floats
the dock above tiled windows.
`visibleWorkspace` accepts `all`, a numeric workspace ID, or a Hyprland
workspace name. With `all`, a keyboard opening targets the workspace and
monitor containing the focused window and keeps that target until the dock is
closed. With an explicit selector, the dock always targets that workspace and
can open only while the workspace is active on a monitor.

### Keyboard toggle

Keyboard shortcuts belong to Hyprland, so the plugin never edits your Omarchy
bindings automatically. To use `SUPER + SHIFT + D`, add this to
`~/.config/hypr/bindings.lua`:

```lua
-- Omarchy assigns this shortcut to Docker by default, so replace it explicitly.
hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Dock", "omarchy-shell -q rosakodu.dock toggleReveal")
```

Choose any other key combination by changing the first argument to `o.bind`.
The shortcut works when `visibilityMode` is `always`, `keybind`, or `hybrid`; `hover`
accepts only the screen-edge trigger. In `hybrid` mode, both the screen-edge hover
trigger and keyboard shortcuts operate concurrently. If the dock is already visible, the first
press closes it without moving it and the next press opens it on the current
target. In `keybind` and `hybrid` modes, summoned docks automatically hide after
the same 1.5-second inactivity delay used by hover mode. Keeping the pointer or
a dock popup active pauses the dismissal timer. With `visibleWorkspace` set to
`all` on a multi-monitor setup, the keyboard shortcut reveals the dock only on
the currently focused monitor, and hovering a screen edge reveals only that
screen's dock — the other monitors' docks stay slid out until their own edge
is hovered or the shortcut is used while they are focused.

Pinned items and folder layouts are automatically saved to `~/.config/omarchy/dock-pinned.json`.

---

## 🎨 Icon overrides, hover labels and CLI icons

**Icon / name overrides** — `~/.config/omarchy/dock-icons.json` (optional, reloads on save):

```json
{
  "corehub": "file:///home/me/.local/share/icons/hicolor/1024x1024/apps/corehub.png",
  "org.wails.corehub": { "icon": "/home/me/corehub/build/appicon.png", "name": "Core Hub" },
  "dev.zed.Zed": "accessories-text-editor"
}
```

Keys are matched case-insensitively against the window class, the app id and the desktop
entry id (a `.desktop` suffix is optional). A value is an icon name from the icon theme,
an absolute path, a `file://` URL, or an object with `icon` and/or `name`. An override wins
over every heuristic; an icon that cannot be resolved falls through to the normal chain.

**Automatic icons** — the dock resolves icons itself instead of relying on Qt's themed
lookup alone: icons installed anywhere in the XDG icon directories are found by name even
when they sit in a size the icon theme does not list (a 1024x1024 icon in
`~/.local/share/icons`, for example), which is the usual reason an app shows the Omarchy
fallback icon. Newly installed icons are picked up by the next rescan.

**Hover label** — hovering an app icon names the app and, when it has exactly one window,
names that window too ("name — window title"). Apps with several windows open the window
picker (which lists every title) instead; the label never covers the icon row and takes no
pointer input, so it cannot block hovering or clicking another icon.

**CLI app icons** — with `cliAppIcons` enabled (default) a terminal window wears the icon of
the CLI app running inside it; turn it off in the status-bar dock settings ("CLI app icons")
or with `omarchy-shell rosakodu.dock setCliAppIcons false` to keep every terminal under its
terminal emulator and read the running app from the hover label / window picker.

**Windows with a custom class** — a window that a terminal drives through a custom class
(`kitty --class org.omarchy.agent`) is grouped with that terminal instead of appearing as an
unknown app wearing the fallback icon; the class-to-program mapping is scanned from `/proc`.

---

## 🗑️ Uninstallation

```bash
omarchy plugin remove rosakodu.dock
```

---

## 📄 License

[MIT](./LICENSE) © 2026 rosakodu

## Local Window Picker

Dock Settings has timing controls for the picker; changing them takes effect immediately without restarting the shell. The same values can be set in `dock-settings.json`, in milliseconds:

| Setting | Default | Range | Effect |
| --- | ---: | ---: | --- |
| `windowPickerOpenDelayMs` | 150 ms | 0–1000 ms | Wait over an app before opening the menu |
| `windowPickerPreviewDelayMs` | 140 ms | 0–800 ms | Wait over a row before previewing that window |
| `windowPickerCloseDelayMs` | 250 ms | 0–2000 ms | Wait after leaving both the icon and menu before closing |
| `windowPickerFadeDurationMs` | 150 ms | 0–600 ms | Fade the menu in and out |

The Dock Settings controls display seconds and adjust in small steps. Apps with multiple windows show the picker by default; Dock Settings can enable it for a single window too. Click a row to confirm; click × or right-click the list to dismiss. The transparent bridge between the icon and card keeps hover continuous. Longer lists scroll with the mouse wheel.

Previewing a minimized window restores it to the current workspace. Leaving the picker keeps the last previewed window focused. Window identity and ordering remain stable when focus or titles update; a closed target never launches a replacement app or selects a different window by index.

After changing QML, reload reliably with `omarchy restart shell`. `omarchy-shell shell rescanPlugins` rescans plugins but may retain cached QML components. Confirm the loaded implementation and inspect the picker with `omarchy-shell rosakodu.dock windowPickerState`; this version reports `hover-picker-6`.

The preview helper uses one Hyprland Lua evaluation to temporarily suppress cursor warps, focus the target, and restore the previous options even on a dispatch error. Preview requests are serialized, and click confirmation takes precedence over queued hovers. If preview protection is unavailable, the list stays usable for click selection.


### Local window picker actions and layouts (hover-picker-6)

The hover picker supports one or more windows when enabled for single-window apps
in Dock Settings. Its default remains two or more windows. All windows are selected when
opening it. Use the row checkboxes or Select All to choose windows; interacting
with selection/action controls pauses hover preview until the picker is reopened.
Clicking a title still focuses that window.

Dock Settings offers three layouts. **Original** preserves the full-height rows,
buttons and instructions. **Compact** uses smaller controls and one-line titles,
keeps each app icon and workspace line, and removes the instructions. **Single-line
list** removes repeated icons, puts the title and workspace on one line, and also
removes the instructions. The default is Original. These choices affect the hover
picker only; they do not change workspace tiling.

- **集中到這裡** moves the selected windows to the dock monitor's workspace captured
  when the popup opened, preserving the workspace's existing layout.
- **移至新工作區** chooses one free numeric workspace after the captured workspace
  (starting at 1 for named workspaces). Occupied, visible, and persistent workspaces
  on all monitors are skipped. Every selected window uses that same destination.
- **移動後切換過去** controls whether the new-workspace action follows the windows.
  Otherwise it returns to the captured origin, including after hover previews.

Moves are serialized with focus previews, validated by window address, and checked
against compositor state afterward. Closed selections, pinned windows, and partial
Hyprland tab groups report an error instead of moving unintended windows. Floating
windows retain their floating state; gathering does not force a different layout.
