# Deferred export of GITHUB_TOKEN from gh (see zsh-defer call in .zshrc).

_zsh_defer_export_github_token() {
  (( ${+GITHUB_TOKEN} && ${#GITHUB_TOKEN} )) && return 0
  [[ -n $commands[gh] ]] || return 0

  local token
  token=$(gh auth token 2>/dev/null) || return 0
  [[ -n $token ]] && export GITHUB_TOKEN=$token
}
