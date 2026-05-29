#!/bin/bash
set -euo pipefail

echo "Installing missing asdf plugins"
while read -r plugin_name _; do
  asdf plugin add "$plugin_name" 2>/dev/null || true
done <~/.dotfiles/asdf/.tool-versions
asdf install

echo "Updating asdf and all plugins"
asdf plugin update --all

echo "Installing missing brew packages"
brew bundle --file=~/.dotfiles/Brewfile

echo "Upgrading brew packages"
brew update
brew upgrade

echo "Setting up fzf shell integration"
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc

echo "Installing and upgrading pip packages"
"$(brew --prefix python3)/bin/pip3" install -r ~/.dotfiles/python/requirements.txt

echo "Installing and updating npm packages"
xargs "$(brew --prefix node)/bin/npm" install -g <~/.dotfiles/node/global-npm-packages

echo "Installing/updating cargo packages"
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  cargo install "$pkg"
done <~/.dotfiles/rust/cargo-packages.txt

echo "Installing/updating go packages"
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  GOPATH="$HOME/go" go install "$pkg"
done <~/.dotfiles/go/go-packages.txt

echo "Installing/updating GitHub release tools"
install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"
while read -r repo binary; do
  [[ -z "$repo" || "$repo" == \#* ]] && continue
  gh release download --repo "$repo" --pattern "*darwin*amd64*" \
    --output "$install_dir/$binary" --clobber
  chmod +x "$install_dir/$binary"
done <~/.dotfiles/github-releases.txt

echo "Building from source: groovy-language-server"
gls_dir="$HOME/.local/share/groovy-language-server"
if [[ -d "$gls_dir" ]]; then
  git -C "$gls_dir" pull
else
  git clone https://github.com/GroovyLanguageServer/groovy-language-server "$gls_dir"
fi
(cd "$gls_dir" && ./gradlew build)
