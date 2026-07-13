#!/bin/bash
# Install build-from-source and scripted tools — source from sync.sh or run directly.

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

git_sync_repo() {
  local url="$1" dir="$2"
  if [[ -d "$dir" ]]; then
    git -C "$dir" pull
  else
    git clone "$url" "$dir"
  fi
}

install_groovy_language_server() {
  log "build — groovy-language-server"
  local dir="$HOME/.local/share/groovy-language-server"
  git_sync_repo https://github.com/GroovyLanguageServer/groovy-language-server "$dir"
  (cd "$dir" && ./gradlew build)
}

update_tldr() {
  log "tldr — database"
  tldr --update
}

install_pre_commit_hooks() {
  log "pre-commit — hooks"
  pre-commit install
}

update_tools() {
  install_groovy_language_server
  update_tldr
  install_pre_commit_hooks
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  update_tools
fi
