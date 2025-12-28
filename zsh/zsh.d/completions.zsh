load_completion_from_cmd() {
  local cmd=$1
  local args=("${@:2}")
  local completion_file="${ZSH_CACHE_DIR}/completions/_${cmd}"

  [[ -n $commands[$cmd] ]] || return

  # Regenerate if missing or older than 30 days
  if [[ ! -f $completion_file ]] || [[ $(find "$completion_file" -mtime +30 2>/dev/null) ]]; then
    eval "$cmd ${args[*]}" >| $completion_file &|
  fi
}

# Constants at the top
GENCOMPL_FPATH="${HOME}/.zsh/complete"

# Let belak/zsh-utils (compstyle_prez_setup) handle most zstyles
# Only keep plugin-specific configuration here
zstyle :plugin:zsh-completion-generator programs ggrep kubedebug docker_copy_between_regions ab

# Initialize completion system
autoload -U +X bashcompinit && bashcompinit

# Group related paths together
fpath+=(
  "${ZSH_CACHE_DIR}/completions"
  "$HOME/.docker/completions"
  "/opt/homebrew/share/zsh/site-functions"
  "${GENCOMPL_FPATH}"
)

# Group related completions together
# Infrastructure tools (loaded eagerly as they're used frequently)
complete -o nospace -C terraform terraform
complete -o nospace -C terragrunt terragrunt
complete -o nospace -C 'aws_completer' aws

# Lazy load completions - only generate on first use for faster startup
# Development tools
kubectl() {
  unfunction kubectl
  load_completion_from_cmd kubectl completion zsh
  kubectl "$@"
}

helm() {
  unfunction helm
  load_completion_from_cmd helm completion zsh
  helm "$@"
}

asdf() {
  unfunction asdf
  load_completion_from_cmd asdf completion zsh
  asdf "$@"
}

# CLI tools
gh() {
  unfunction gh
  load_completion_from_cmd gh completion --shell zsh
  gh "$@"
}

argocd() {
  unfunction argocd
  load_completion_from_cmd argocd completion zsh
  argocd "$@"
}

wezterm() {
  unfunction wezterm
  load_completion_from_cmd wezterm shell-completion --shell zsh
  wezterm "$@"
}

op() {
  unfunction op
  load_completion_from_cmd op completion zsh
  op "$@"
}

gitleaks() {
  unfunction gitleaks
  load_completion_from_cmd gitleaks completion zsh
  gitleaks "$@"
}
