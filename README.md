# Dock (wizenith build)

A customized build of **[rosakodu/omarchy-dock](https://github.com/rosakodu/omarchy-dock)** —
the native, animated application dock for **Omarchy Quattro** (Hyprland + Quickshell):
window tracking, app stacks/folders, notification badges, hosted bar widgets and drag &
drop, all in one dock per monitor.

> ### Provenance and credit
> The original plugin — its design, architecture and the large majority of this code — is
> the work of **[rosakodu](https://github.com/rosakodu)** and is released under the MIT
> license. This repository is a fork maintained by
> **[wizenith](https://github.com/wizenith)**: it follows upstream releases by merging
> them (never by rebasing), and adds the changes listed below.
>
> `LICENSE` keeps the original copyright notice and adds the modification notice.
> Problems caused by the additions below belong here, not with the original author — when
> in doubt, test against upstream first and report upstream only what reproduces there.
>
> For the complete upstream feature set see the
> [original project](https://github.com/rosakodu/omarchy-dock).

## What this build adds on top of upstream

**Icons**
- `~/.config/omarchy/dock-icons.json` — override an app's icon and display name: theme
  icon name, absolute path, `file://` URL, or `{ "icon": …, "name": … }`; keys match the
  window class, app id or desktop entry id (case-insensitive). Overrides win over every
  heuristic and fall through gracefully when the icon cannot be resolved.
- Disk icon coverage for sizes the icon theme does not list (for example a 1024×1024 icon
  in `~/.local/share/icons/hicolor`), which Qt's themed lookup cannot see — the usual
  reason an app used to show the generic Omarchy icon.

**Knowing what an icon is**
- Hover label: hovering an app icon shows the app name and, when it owns a single window,
  the window title. It sits clear of the icon row and takes no pointer input, so it can
  never block hovering or clicking another icon. Apps with several windows keep opening
  the window picker, which lists every title and workspace.

**Terminals and CLI apps**
- `cliAppIcons` (settings panel, or `omarchy-shell wizenith.dock setCliAppIcons false`)
  keeps every terminal grouped under its terminal emulator instead of wearing the icon of
  the CLI app whose title it reports.
- A GUI app's name appearing in a terminal window title no longer hijacks that app's dock
  item; `/proc`-scanned CLI apps stay with the window they were found in; reverse-domain
  app ids (`md.obsidian.Obsidian`) resolve to their desktop entry; and a window that a
  terminal drives through a custom class (`kitty --class org.omarchy.agent`) is grouped
  with that terminal instead of showing up as an unknown app.

**Window picker**
- Timing controls (open delay, window-preview delay, close delay, fade duration) in the
  dock settings panel, plus helpers to move the picked windows to the current or a new
  workspace with live preview focus.

## Install

```bash
omarchy plugin add https://github.com/wizenith/omarchy-dock.git --enable
```

## Update

```bash
omarchy plugin update wizenith.dock   # fast-forward to this fork
~/dock-update.sh                      # merge a new upstream release (see below)
```

This checkout has two remotes: `origin` = this fork (what `omarchy plugin update` pulls)
and `upstream` = the author's repository. Upstream is brought in by merging, never by
replaying patches; `LOCAL-MAINTENANCE.md` documents the rules, and `~/dock-update.sh`
automates them with an OMP agent (it fetches upstream, tags a backup, merges, runs both
test suites and reloads the dock).

## Settings and state

| Path | Purpose |
| --- | --- |
| `~/.config/omarchy/dock-settings.json` | visibility, workspace, badges, `cliAppIcons`, picker layout and timings |
| `~/.config/omarchy/dock-icons.json` | icon/name overrides (this build) |
| `~/.config/omarchy/dock-pinned.json` | pinned apps and folders |
| dock widget settings | the `···` dock widget in the status bar |

## Keybinding

```lua
o.bind("SUPER + SHIFT + D", "Dock", "omarchy-shell -q wizenith.dock toggleReveal")
```

## Uninstall

```bash
omarchy plugin remove wizenith.dock
```

## Tests

```bash
/usr/lib/qt6/bin/qmltestrunner -input tests
python3 -m unittest discover -s tests
```

## License

MIT — original work © 2026 [rosakodu](https://github.com/rosakodu);
modifications © 2026 [wizenith](https://github.com/wizenith). See [LICENSE](./LICENSE).
