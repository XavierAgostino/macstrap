#!/usr/bin/env bash
#
# macstrap uninstall. Conservative back-out of chezmoi-managed dotfiles.
#
#   uninstall.sh                 dry-run (default): show what would be removed
#   uninstall.sh --apply         remove managed dotfiles from $HOME (with backups)
#
# It NEVER removes Homebrew packages, 1Password, your data, mise runtimes, or the
# repo. Removed files are backed up to ~/.macstrap-backup first.
#
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"

APPLY=0
for a in "$@"; do
  case "$a" in
    --apply)   APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    *) echo "usage: uninstall.sh [--dry-run|--apply]" >&2; exit 2 ;;
  esac
done

echo "== macstrap uninstall ($([[ $APPLY -eq 1 ]] && echo apply || echo dry-run)) =="
echo "Removes chezmoi-managed dotfiles from \$HOME. Homebrew packages, 1Password,"
echo "runtimes, your data, and the repo are left intact."
echo

command -v chezmoi >/dev/null 2>&1 || { echo "chezmoi not installed; nothing to do."; exit 0; }

backup="$HOME/.macstrap-backup/$(date +%Y%m%d-%H%M%S)"
count=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  target="$HOME/$f"
  [[ -e "$target" ]] || continue
  count=$((count + 1))
  if [[ $APPLY -eq 1 ]]; then
    mkdir -p "$backup/$(dirname "$f")"
    cp -a "$target" "$backup/$f" 2>/dev/null || true
    rm -f "$target"
    echo "  removed (backed up): ~/$f"
  else
    echo "  would remove: ~/$f"
  fi
done < <(chezmoi managed --include=files 2>/dev/null)

echo
if [[ $APPLY -eq 1 ]]; then
  echo "Removed $count file(s). Backups in $backup"
  echo "To also remove Homebrew packages: review 'brew leaves' and uninstall manually."
else
  echo "Dry run only ($count file(s) would be removed). Re-run with --apply to perform."
fi
