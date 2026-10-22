#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.dotfiles/.scripts/lib.sh"
# shellcheck disable=SC1091
source "$HOME/.dotfiles/.scripts/tools.sh"

# ── sections ─────────────────────────────────────────────────────────────────

update_asdf() {
  log "asdf — install plugins and runtimes"
  while read -r plugin _; do
    asdf plugin add "$plugin" 2>/dev/null || true
  done <"$DOTFILES/asdf/.tool-versions"
  asdf install
  asdf plugin update --all &
}

update_brew() {
  log "brew — bundle, update, upgrade"
  trust_brewfile_taps
  local file
  while IFS= read -r file; do
    brew bundle --file="$file"
  done < <(brew_bundle_files)
  brew update
  brew upgrade
  log "fzf — shell integration"
  "$(brew --prefix)/opt/fzf/install" --all --no-update-rc
}

update_figlet_fonts() {
  log "figlet — download missing fonts"
  if ! command -v figlet >/dev/null; then
    echo "figlet not installed, skipping" >&2
    return 0
  fi
  local font_dir repo_url="https://raw.githubusercontent.com/xero/figlet-fonts/master"
  font_dir=$(figlet -I2)

  local font ext found
  while IFS= read -r font; do
    [[ -z "$font" ]] && continue
    found=false
    for ext in flf flc tlf; do
      [[ -f "$font_dir/$font.$ext" ]] && found=true && break
    done
    "$found" && continue

    for ext in flf flc tlf; do
      if curl -fsSL -o "$font_dir/$font.$ext" "$repo_url/${font// /%20}.$ext" 2>/dev/null; then
        echo "Downloaded figlet font: $font"
        found=true
        break
      fi
      rm -f "$font_dir/$font.$ext"
    done
    "$found" || echo "Could not download figlet font: $font" >&2
  done < <(
    # Font list lives in the nvim figlet module; extract the quoted names.
    sed -n "/^local fonts = {/,/^}/s/^  '\(.*\)',$/\1/p" \
      "$DOTFILES/nvim/.config/nvim/lua/user/figlet.lua"
  )
}

update_pip() {
  log "pip — sync venv at ~/.local/share/dotfiles-python"
  uv venv --python "$(brew --prefix python3)/bin/python3" --allow-existing \
    "$HOME/.local/share/dotfiles-python"
  # requirements.txt lists top-level tools only; `uv pip sync` expects a fully
  # resolved lockfile, so compile the transitive closure first.
  local compiled
  compiled=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm -f $(printf '%q' "$compiled")" RETURN
  uv pip compile --quiet -o "$compiled" "$DOTFILES/python/requirements.txt"
  uv pip sync --python "$HOME/.local/share/dotfiles-python/bin/python" "$compiled"
}

update_npm() {
  log "npm — global packages"
  xargs "$(brew --prefix node)/bin/npm" install -g --force \
    <"$DOTFILES/node/global-npm-packages"
}

update_gh_releases() {
  log "gh — GitHub release tools"
  local install_dir="$HOME/.local/bin"
  mkdir -p "$install_dir"

  local arch
  case "$(uname -m)" in
  arm64 | aarch64) arch=arm64 ;;
  x86_64 | amd64) arch=amd64 ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    return 1
    ;;
  esac

  while read -r repo binary arm64_pattern amd64_pattern; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    local pattern
    if [[ "$arch" == arm64 ]]; then
      pattern="$arm64_pattern"
    else
      pattern="$amd64_pattern"
    fi

    local tmpdir asset assets=()
    tmpdir=$(mktemp -d)
    gh release download --repo "$repo" --pattern "$pattern" --dir "$tmpdir" --clobber
    while IFS= read -r -d '' f; do
      assets+=("$f")
    done < <(find "$tmpdir" -maxdepth 1 -type f -print0)
    if ((${#assets[@]} != 1)); then
      echo "Expected 1 release asset for $repo (pattern: $pattern), found ${#assets[@]}" >&2
      rm -rf "$tmpdir"
      return 1
    fi
    asset="${assets[0]}"

    case "$asset" in
    *.tar.gz | *.tgz | *.tar.xz | *.tar.bz2 | *.tar)
      tar -xf "$asset" -C "$tmpdir"
      rm -f "$asset"
      asset=$(find "$tmpdir" -name "${binary}*" -type f | head -1)
      if [[ -z "$asset" ]]; then
        echo "Could not find $binary inside archive for $repo" >&2
        rm -rf "$tmpdir"
        return 1
      fi
      ;;
    *.zip)
      unzip -oq "$asset" -d "$tmpdir"
      rm -f "$asset"
      asset=$(find "$tmpdir" -name "${binary}*" -type f | head -1)
      if [[ -z "$asset" ]]; then
        echo "Could not find $binary inside archive for $repo" >&2
        rm -rf "$tmpdir"
        return 1
      fi
      ;;
    esac
    mv "$asset" "$install_dir/$binary"
    rm -rf "$tmpdir"
    chmod +x "$install_dir/$binary"
  done <"$DOTFILES/github-releases.txt"
}

# ── main ─────────────────────────────────────────────────────────────────────

UPDATE_SECTIONS=(asdf brew figlet pip npm gh tools)

run_section() {
  case "$1" in
  asdf) update_asdf ;;
  brew) update_brew ;;
  figlet) update_figlet_fonts ;;
  pip) update_pip ;;
  npm) update_npm ;;
  gh) update_gh_releases ;;
  tools) update_tools ;;
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
      --header "Select sections to sync (space toggle, enter confirm)" \
      "${UPDATE_SECTIONS[@]}"
  ); then
    echo "Cancelled."
    exit 0
  fi

  if [[ -z "$selected" ]]; then
    echo "No sections selected."
    exit 0
  fi

  local section
  while IFS= read -r section; do
    [[ -z "$section" ]] && continue
    run_section "$section"
  done <<<"$selected"
}

INTERACTIVE=false
while getopts "i" opt; do
  case "$opt" in
  i) INTERACTIVE=true ;;
  *)
    echo "Usage: $0 [-i]" >&2
    exit 1
    ;;
  esac
done

if $INTERACTIVE; then
  interactive_select
else
  for section in "${UPDATE_SECTIONS[@]}"; do
    run_section "$section"
  done
fi

echo ""
echo "✓ All done."
