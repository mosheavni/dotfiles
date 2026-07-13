#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.dotfiles/.scripts/lib.sh"

# asdf shims need asdf in PATH (not sourced in non-login bash)
# shellcheck disable=SC1091
[[ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]] && . "$(brew --prefix asdf)/libexec/asdf.sh"

# ── helpers ──────────────────────────────────────────────────────────────────

DRY_RUN=false

dry_or_run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

combined_brewfile() {
  local tmp file
  tmp=$(mktemp)
  while IFS= read -r file; do
    cat "$file" >>"$tmp"
    echo >>"$tmp"
  done < <(brew_bundle_files)
  echo "$tmp"
}

# ── sections ─────────────────────────────────────────────────────────────────

cleanup_brew() {
  log "brew — trust all taps in Brewfile(s)"
  trust_brewfile_taps

  log "brew — uninstall formulae from stale taps (prevents untap block)"
  local wanted_taps installed_taps stale_taps
  wanted_taps=$(brewfile_taps | sort -u)
  installed_taps=$(brew tap | sort)
  stale_taps=$(comm -23 <(echo "$installed_taps") <(echo "$wanted_taps"))

  if [[ -n "$stale_taps" ]]; then
    local tap owner repo tap_dir formula_names installed_from_tap brew_repo
    brew_repo=$(brew --repository)
    while IFS= read -r tap; do
      [[ -z "$tap" ]] && continue
      owner="${tap%%/*}"
      repo="${tap##*/}"
      tap_dir="${brew_repo}/Library/Taps/${owner}/homebrew-${repo}"
      [[ ! -d "$tap_dir" ]] && tap_dir="${brew_repo}/Library/Taps/${owner}/${repo}"
      if [[ ! -d "$tap_dir" ]]; then
        echo "Tap dir not found for $tap, skipping"
        continue
      fi

      formula_names=$(
        { find "$tap_dir/Formula" -name "*.rb" 2>/dev/null
          find "$tap_dir/Casks" -name "*.rb" 2>/dev/null
          find "$tap_dir" -maxdepth 1 -name "*.rb" 2>/dev/null; } \
        | xargs -I{} basename {} .rb \
        | sort -u
      )
      [[ -z "$formula_names" ]] && continue

      installed_from_tap=$(comm -12 \
        <({ brew list --formula; brew list --cask; } 2>/dev/null | sort) \
        <(echo "$formula_names"))

      if [[ -n "$installed_from_tap" ]]; then
        echo "Removing from stale tap $tap: $(echo "$installed_from_tap" | tr '\n' ' ')"
        while IFS= read -r f; do
          dry_or_run brew uninstall --ignore-dependencies --force "$f"
        done <<< "$installed_from_tap"
      fi
    done <<< "$stale_taps"
  fi

  log "brew — remove formulae/casks not in Brewfile(s)"
  local bundle_file
  bundle_file=$(combined_brewfile)
  # Expand path now — RETURN trap runs after locals are unset (set -u would fail)
  # shellcheck disable=SC2064
  trap "rm -f $(printf '%q' "$bundle_file")" RETURN

  if $DRY_RUN; then
    # cleanup without --force exits 1 when it finds candidates; don't let
    # set -e kill the remaining dry-run sections
    brew bundle cleanup --file="$bundle_file" || true
    return
  fi

  brew bundle cleanup --file="$bundle_file" --force
}

cleanup_asdf() {
  log "asdf — remove plugins not in .tool-versions"
  local wanted installed stale
  wanted=$(awk '{print $1}' "$DOTFILES/asdf/.tool-versions" | sort)
  installed=$(asdf plugin list 2>/dev/null | sort)
  stale=$(comm -23 <(echo "$installed") <(echo "$wanted"))

  if [[ -z "$stale" ]]; then
    echo "No stale asdf plugins."
    return
  fi

  echo "Stale plugins: $stale"
  while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    dry_or_run asdf plugin remove "$plugin"
  done <<<"$stale"
}

cleanup_npm() {
  log "npm — remove global packages not in global-npm-packages"
  local npm_bin wanted installed stale
  npm_bin="$(brew --prefix node)/bin/npm"

  # Strip @version suffixes (e.g. mcp-hub@latest → mcp-hub) but keep @scope prefixes
  wanted=$(sed 's/@[^@/]*$//' "$DOTFILES/node/global-npm-packages" | sort)

  # Preserve scoped names (e.g. @fsouza/prettierd) — strip only the node_modules/ prefix
  installed=$(
    "$npm_bin" list -g --depth=0 --parseable 2>/dev/null \
      | tail -n+2 \
      | sed 's|.*/node_modules/||' \
      | grep -v '^npm$' \
      | sort
  )
  stale=$(comm -23 <(echo "$installed") <(echo "$wanted"))

  if [[ -z "$stale" ]]; then
    echo "No stale npm globals."
    return
  fi

  echo "Stale npm globals: $stale"
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    dry_or_run "$npm_bin" uninstall -g "$pkg"
  done <<<"$stale"
}

cleanup_pip() {
  log "pip — skipped (sync.sh uses uv pip sync, handles cleanup)"
}

cleanup_gh_releases() {
  log "gh — remove ~/.local/bin binaries not in github-releases.txt"
  local install_dir="$HOME/.local/bin"
  local wanted stale
  wanted=$(awk 'NF && !/^#/ {print $2}' "$DOTFILES/github-releases.txt" | sort)
  stale=$(comm -23 <(find "$install_dir" -maxdepth 1 -type f -exec basename {} \; | sort) <(echo "$wanted"))

  if [[ -z "$stale" ]]; then
    echo "No stale binaries in $install_dir."
    return
  fi

  echo "Stale binaries in $install_dir:"
  echo "$stale"
  while IFS= read -r bin; do
    [[ -z "$bin" ]] && continue
    dry_or_run rm -f "$install_dir/$bin"
  done <<<"$stale"
}

# ── main ─────────────────────────────────────────────────────────────────────

CLEANUP_SECTIONS=(brew asdf npm gh)

run_section() {
  case "$1" in
  brew) cleanup_brew ;;
  asdf) cleanup_asdf ;;
  npm) cleanup_npm ;;
  pip) cleanup_pip ;;
  gh) cleanup_gh_releases ;;
  *)
    echo "Unknown section: $1" >&2
    return 1
    ;;
  esac
}

interactive_select() {
  if ! command -v gum >/dev/null; then
    echo "gum is required for -i (brew install gum)" >&2
    exit 1
  fi

  local selected
  if ! selected=$(
    gum choose --no-limit --selected='*' \
      --header "Select cleanups to run (space toggle, enter confirm)" \
      "${CLEANUP_SECTIONS[@]}"
  ); then
    echo "Cancelled."
    exit 0
  fi

  if [[ -z "$selected" ]]; then
    echo "No cleanups selected."
    exit 0
  fi

  local section
  while IFS= read -r section; do
    [[ -z "$section" ]] && continue
    run_section "$section"
  done <<<"$selected"
}

usage() {
  echo "Usage: $0 [-d] [-i] [section...]"
  echo "  -d  dry run (show what would be removed)"
  echo "  -i  interactive section picker"
  echo "Sections: ${CLEANUP_SECTIONS[*]}"
}

INTERACTIVE=false
while getopts "dih" opt; do
  case "$opt" in
  d) DRY_RUN=true ;;
  i) INTERACTIVE=true ;;
  h) usage; exit 0 ;;
  *)
    usage >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if $INTERACTIVE; then
  interactive_select
elif [[ $# -gt 0 ]]; then
  for section in "$@"; do
    run_section "$section"
  done
else
  for section in "${CLEANUP_SECTIONS[@]}"; do
    run_section "$section"
  done
fi

echo ""
echo "✓ Cleanup done."
