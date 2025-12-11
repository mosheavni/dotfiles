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
# Infrastructure tools
complete -o nospace -C terraform terraform
complete -o nospace -C terragrunt terragrunt
complete -o nospace -C 'aws_completer' aws

# Development tools
load_completion_from_cmd kubectl completion zsh
load_completion_from_cmd helm completion zsh
load_completion_from_cmd asdf completion zsh

# CLI tools
load_completion_from_cmd gh completion --shell zsh
load_completion_from_cmd argocd completion zsh
load_completion_from_cmd wezterm shell-completion --shell zsh
load_completion_from_cmd op completion zsh
