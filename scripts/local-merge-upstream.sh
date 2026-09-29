#!/bin/bash
# Merge upstream's plugin release into this customized checkout.
#
# This checkout carries local work (window-picker stack, own icon index,
# hover label, CLI/terminal matching). Never rebase it and never force-push:
# Omarchy's `omarchy plugin update` only fast-forwards, so history has to stay
# append-only.
#
# Usage:
#   scripts/local-merge-upstream.sh            # fetch + merge + run the tests
#   scripts/local-merge-upstream.sh --dry-run  # show what would come in only
#
# Exit codes: 0 current or merged cleanly / 1 conflicts or failing tests / 2 unsafe state

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

DRY_RUN=0
[[ ${1-} == "--dry-run" ]] && DRY_RUN=1

say() { printf '%s\n' "$*"; }

if [[ -n $(git status --porcelain) ]]; then
  say "Refusing to merge: the working tree has uncommitted changes."
  say "Commit or stash them first — the dock runs straight from this directory."
  say ""
  git status --short
  exit 2
fi

remote=""
if git remote | grep -qx upstream; then
  remote=upstream
elif git remote | grep -qx origin; then
  remote=origin
else
  say "No 'upstream' or 'origin' remote configured."
  exit 2
fi

git symbolic-ref --short -q HEAD >/dev/null || { say "Detached HEAD; check out a branch first."; exit 2; }

say "Fetching $remote ..."
git fetch --quiet "$remote" || { say "fetch failed."; exit 2; }

target=""
for ref in "$remote/main" "$remote/master" FETCH_HEAD; do
  if git rev-parse --verify --quiet "$ref" >/dev/null; then
    target="$ref"
    break
  fi
done
[[ -n $target ]] || { say "Nothing to merge from $remote."; exit 2; }

incoming=$(git log --oneline "HEAD..$target" | head -20)
if [[ -z $incoming ]]; then
  say "Already up to date with $target."
  exit 0
fi

say ""
say "Incoming from $remote ($target):"
say "$incoming"
say ""

if (( DRY_RUN )); then
  say "--dry-run: nothing merged."
  exit 0
fi

if git merge --no-edit "$target"; then
  say ""
  say "Merged cleanly."
else
  say ""
  say "CONFLICT — resolve, then finish the merge:"
  git diff --name-only --diff-filter=U | sed 's/^/  /'
  say ""
  say "  git add <files> && git commit    # finish"
  say "  git merge --abort                # give up"
  exit 1
fi

rc=0
if [[ -x /usr/lib/qt6/bin/qmltestrunner ]]; then
  say ""
  say "$ qmltestrunner -input tests"
  /usr/lib/qt6/bin/qmltestrunner -input tests 2>&1 | tail -3 || rc=1
fi

say ""
say "$ python3 -m unittest discover -s tests"
python3 -m unittest discover -s tests -q 2>&1 | tail -3 || rc=1

say ""
if (( rc == 0 )); then
  say "Done. Reload the dock with: omarchy-shell shell rescanPlugins"
else
  say "Tests failed — fix before shipping this merge."
fi
exit $rc
