#!/bin/bash
# Shared helpers for updates.sh and cleanup.sh — source, don't execute.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
CORP_BREWFILE="${CORP_BREWFILE:-$HOME/corp-Brewfile}"

log() {
  echo "============================================"
  echo "▶ $*"
}

brew_bundle_files() {
  printf '%s\n' "$DOTFILES/Brewfile"
  [[ -f "$CORP_BREWFILE" ]] && printf '%s\n' "$CORP_BREWFILE"
}

# All taps declared across the Brewfile(s), one per line
brewfile_taps() {
  local file
  while IFS= read -r file; do
    awk '/^tap /{gsub(/"/, "", $2); print $2}' "$file"
  done < <(brew_bundle_files)
}

trust_brewfile_taps() {
  brewfile_taps | xargs -I{} brew trust {}
}
