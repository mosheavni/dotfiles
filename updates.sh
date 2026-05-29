#!/bin/bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

# ── helpers ──────────────────────────────────────────────────────────────────

log() {
  echo ""
  echo "▶ $*"
}

each_line() {
  # Usage: each_line <file> <callback>
  # Calls callback for each non-empty, non-comment line in file.
  local file="$1" callback="$2"
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    "$callback" "$line"
  done <"$file"
}

# ── sections ─────────────────────────────────────────────────────────────────

update_asdf() {
  log "asdf — install plugins and runtimes"
  while read -r plugin _; do
    asdf plugin add "$plugin" 2>/dev/null || true
  done <"$DOTFILES/asdf/.tool-versions"
  asdf install
  asdf plugin update --all
}

update_brew() {
  log "brew — bundle, update, upgrade"
  brew bundle --file="$DOTFILES/Brewfile"
  brew update
  brew upgrade
  log "fzf — shell integration"
  "$(brew --prefix)/opt/fzf/install" --all --no-update-rc
}

update_pip() {
  log "pip — sync venv at ~/.local/share/dotfiles-python"
  uv venv --python "$(brew --prefix python3)/bin/python3" --allow-existing \
    "$HOME/.local/share/dotfiles-python"
  uv pip install --python "$HOME/.local/share/dotfiles-python" \
    -r "$DOTFILES/python/requirements.txt"
}

update_npm() {
  log "npm — global packages"
  xargs "$(brew --prefix node)/bin/npm" install -g --force \
    <"$DOTFILES/node/global-npm-packages"
}

_cargo_install() { cargo install "$1"; }
update_cargo() {
  log "cargo — global packages"
  each_line "$DOTFILES/rust/cargo-packages.txt" _cargo_install
}

_go_install() { GOPATH="$HOME/go" go install "$1"; }
update_go() {
  log "go — global packages"
  each_line "$DOTFILES/go/go-packages.txt" _go_install
}

update_build_tools() {
  log "build — groovy-language-server"
  local dir="$HOME/.local/share/groovy-language-server"
  if [[ -d "$dir" ]]; then
    git -C "$dir" pull
  else
    git clone https://github.com/GroovyLanguageServer/groovy-language-server "$dir"
  fi
  (cd "$dir" && ./gradlew build)
}

# ── main ─────────────────────────────────────────────────────────────────────

update_asdf
update_brew
update_pip
update_npm
update_cargo
update_go
update_build_tools

echo ""
echo "✓ All done."
