# Local maintenance of this checkout

This is a **customized copy** of `rosakodu/omarchy-dock`, installed for Omarchy at
`~/.config/omarchy/plugins/rosakodu.dock`. It carries local work upstream does not have:

- the window-picker stack (`components/WindowPickerController.qml`,
  `components/WindowPickerPopup.qml`, `scripts/dock-window-focus.py`,
  `scripts/dock-window-move.py`) plus its timing controls
- the dock's own icon index plus `~/.config/omarchy/dock-icons.json` overrides
- the hover label (`components/DockTooltip.qml`) and `cliAppIcons`
- terminal / CLI matching fixes (GUI app names in window titles, `/proc` scan scoping,
  reverse-domain app ids, terminal-owned window classes)

## How updates work here

The git remote layout is deliberate:

```
upstream  https://github.com/rosakodu/omarchy-dock.git   ← the author's repo
origin    (absent on purpose)
```

`omarchy plugin update` fetches `origin`, so with no `origin` it **cannot touch this
checkout** — it fails harmlessly with "fetch failed". Updating is done by
`~/dock-update.sh`, which fetches `upstream`, tags a backup, and hands the merge to an
OMP agent. To adopt the author's history on another machine, install from your own fork
and point `origin` at it (see below).

## Updating

```bash
~/dock-update.sh              # interactive OMP session; it may ask you about conflicts
~/dock-update.sh --print      # unattended: it stops and reports instead of deciding
~/dock-update.sh --dry-run    # fetch only, list what came in
omarchy-shell shell rescanPlugins
```

No-agent fallback (plain git, no decisions made for you):

```bash
scripts/local-merge-upstream.sh [--dry-run]
```

## Rules that keep updates possible

1. **Never rebase, never force-push, never `git reset --hard` over unsaved work.**
   `omarchy plugin update` only fast-forwards, so history stays append-only.
2. **Commit before updating.** Both the script and the fallback refuse to run on a dirty
   tree. This matters more than usual here: other agent sessions edit these same files, so
   check `git status` and commit their work before starting a merge.
3. **Never use `omarchy plugin remove` to fix state**: for a git checkout it is a plain
   `rm -rf` with no backup.
4. Merge upstream **into** this branch. Do not replay local work as patches on a fresh
   checkout: upstream churns the same files and the patches rot.
5. When two sessions are editing the plugin at once, stop one of them first. A merge
   started while another session writes these files can silently mix both changes.

## Optional: own fork (for reinstalls and other machines)

```bash
git remote rename upstream upstream            # already the case
git remote add origin git@github.com:<you>/omarchy-dock.git
git push -u origin main                        # your fork becomes the update source
```

After that `~/dock-update.sh` still merges from `upstream`, and `omarchy plugin update`
fast-forwards to your fork. The plugin id in `manifest.json` can stay `rosakodu.dock`;
renaming it is cosmetic and touches `shell.json`, the Hyprland binding, the plugin's IPC
target and its widget registry, so only do it deliberately.

## Rollback

```bash
git tag backup-$(date +%Y%m%d)   # before merging (dock-update.sh tags automatically)
git merge --abort                # abandon a conflicted merge
git reflog                       # locate the pre-merge commit
```
