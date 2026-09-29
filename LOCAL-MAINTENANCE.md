# Local maintenance of this checkout

This is the **wizenith build** of `rosakodu/omarchy-dock` (see `README.md` for provenance).
It is installed for Omarchy at `~/.config/omarchy/plugins/wizenith.dock` and carries local
work upstream does not have:

- the window-picker stack (`components/WindowPickerController.qml`,
  `components/WindowPickerPopup.qml`, `components/DockTimingControl.qml`,
  `scripts/dock-window-focus.py`, `scripts/dock-window-move.py`) with timing controls
- the `~/.config/omarchy/dock-icons.json` icon/name override layer
- the hover label (`components/DockTooltip.qml`) and the `cliAppIcons` setting
- terminal / CLI matching fixes (GUI app names in window titles, `/proc` scan scoping,
  reverse-domain app ids, terminal-owned window classes)
- wider disk-icon coverage for sizes the icon theme does not list

## Remotes

```
origin    https://github.com/wizenith/omarchy-dock-wizenith.git   your fork
          (fetch over HTTPS — anonymous, works on any machine;
           push over git@github.com:wizenith/omarchy-dock-wizenith.git)
upstream  https://github.com/rosakodu/omarchy-dock.git            the author's repo
```

`omarchy plugin update wizenith.dock` fast-forwards this checkout to **origin** (your
fork). It cannot fetch upstream, and it never overwrites local commits — that is what the
merge below is for.

## Updating

```bash
~/dock-update.sh              # fetch upstream, tag a backup, merge with an OMP agent
~/dock-update.sh --dry-run    # fetch only, list what came in
~/dock-update.sh --help       # modes, work order, recovery
omarchy-shell shell rescanPlugins
```

`--here` runs the agent in the same terminal; the default opens it in a new window and
this script continues when that window closes.

No-agent fallback (plain git, decides nothing for you):

```bash
scripts/local-merge-upstream.sh [--dry-run]
```

## Rules that keep updates possible

1. **Never rebase, never force-push, never `git reset --hard` over unsaved work.**
   `omarchy plugin update` only fast-forwards, so history stays append-only.
2. **Commit before updating.** Both updaters refuse to run on a dirty tree. Other agent
   sessions edit these same files, so check `git status` first and commit their work.
3. **Never use `omarchy plugin remove` to fix state**: for a git checkout it is a plain
   `rm -rf` with no backup.
4. Merge upstream **into** this branch. Do not replay local work as patches on a fresh
   checkout: upstream churns the same files and the patches rot.
5. When two sessions are editing the plugin at once, stop one of them first — a merge
   started while another session writes these files can silently mix both changes.

## After a merge that took upstream's implementation

If upstream fixes something we had fixed locally, delete our version rather than keeping
two implementations (this already happened once: our own icon index was dropped in favour
of upstream's `scan-icons` + `getDiskIcon`). The rule: one mechanism, upstream's when it is
equivalent, ours only where it is genuinely better.

## Rollback

```bash
git tag backup-$(date +%Y%m%d)   # before merging (dock-update.sh tags automatically)
git merge --abort                # abandon a conflicted merge
git reflog                       # locate the pre-merge commit
```
