# Local maintenance of this checkout

This is a **customized copy** of `rosakodu/omarchy-dock`, installed for Omarchy at
`~/.config/omarchy/plugins/rosakodu.dock`. It carries local work upstream does not have:

- the window-picker stack (`components/WindowPickerController.qml`,
  `components/WindowPickerPopup.qml`, `scripts/dock-window-focus.py`,
  `scripts/dock-window-move.py`)
- the dock's own icon index plus `~/.config/omarchy/dock-icons.json` overrides
- the hover label (`components/DockTooltip.qml`) and `cliAppIcons`
- terminal / CLI matching fixes (GUI app names in window titles, `/proc` scan scoping,
  reverse-domain app ids, terminal-owned window classes)

## Rules that keep updates possible

1. **Never rebase, never force-push, never `git reset --hard` over unsaved work.**
   `omarchy plugin update` only does `git fetch origin` + `git merge --ff-only`, so
   history must stay append-only.
2. **Keep the working tree clean.** The dock runs straight out of this directory.
   A dirty tree both risks losing edits and blocks the updater.
3. **Never use `omarchy plugin remove` to fix state**: for a git checkout it is a plain
   `rm -rf` with no backup.
4. Merge upstream **into** this branch. Do not replay local work as patches on top of a
   fresh checkout: upstream churns the same files (DockMatcher.js, DockPanel.qml,
   DockItem.qml, scripts/dock-minimize.py, tests) and the patches rot.

## Bringing in an upstream release

```bash
cd ~/.config/omarchy/plugins/rosakodu.dock
scripts/local-merge-upstream.sh            # fetch + merge + both test suites
# conflicts? resolve them, then: git add <files> && git commit
omarchy-shell shell rescanPlugins
```

`--dry-run` lists what would come in without merging. The script refuses to run on a
dirty tree, never pushes, and never resolves conflicts by itself.

## Two ways this checkout can be wired

| | local only (current) | own fork (optional later) |
| --- | --- | --- |
| remotes | `origin` = author's repo | `origin` = your fork, `upstream` = author's repo |
| upstream news arrives via | `scripts/local-merge-upstream.sh` | same, then `git push origin main` |
| `omarchy plugin update` | refuses (`--ff-only` cannot apply) — harmless | fast-forwards to your fork |
| survives reinstall / second machine | no | yes |

Switching to fork mode:

```bash
git remote rename origin upstream
git remote add origin git@github.com:<you>/omarchy-dock.git
git push -u origin main
```

## Handing this to an AI agent

> In `~/.config/omarchy/plugins/rosakodu.dock`, bring in the latest upstream release:
> run `scripts/local-merge-upstream.sh`. If it reports conflicts, show me the conflicting
> hunks and ask me how to resolve each one before committing. After a clean merge run both
> test suites, reload the dock (`omarchy-shell shell rescanPlugins`) and check it still
> renders (`omarchy-shell rosakodu.dock windowPickerState`). Do not rebase, do not
> force-push, do not run `git reset --hard`.

## Rollback

```bash
git tag backup-$(date +%Y%m%d)   # before merging
git merge --abort                # abandon a conflicted merge
git reflog                       # locate the pre-merge commit
```
