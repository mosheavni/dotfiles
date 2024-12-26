load_completion_from_cmd() {
  local cmd=$1
  local args=("${@:2}")
  local completion_file="${ZSH_CACHE_DIR}/completions/_${cmd}"

  [[ -n $commands[$cmd] ]] || return

  if [[ ! -f $completion_file ]]; then
    typeset -g -A _comps
    autoload -Uz _$cmd
    _comps[$cmd]=_$cmd
  fi

  eval "$cmd ${args[*]}" >| $completion_file &|
}

# Constants at the top
GENCOMPL_FPATH="${HOME}/.zsh/complete"

# zstyles
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' completer _complete _prefix _match _approximate
zstyle ':completion:*' matcher-list 'r:[[:ascii:]]||[[:ascii:]]=** r:|=* m:{a-z\-}={A-Z\_}'
zstyle ':completion:*:approximate:*' max-errors 3 numeric
zstyle :plugin:zsh-completion-generator programs ggrep kubedebug docker_copy_between_regions ab

# Initialize completion system
autoload -U +X bashcompinit && bashcompinit

# Group related paths together
fpath+=(
  "${ZSH_CACHE_DIR}/completions"
  "/opt/homebrew/share/zsh/site-functions"
  "${ASDF_DIR}/completions"
  "${GENCOMPL_FPATH}"
)

# Group related completions together
# Infrastructure tools
complete -o nospace -C terraform terraform
complete -o nospace -C terragrunt terragrunt
complete -o nospace -C 'aws_completer' aws

# Development tools
load_completion_from_cmd docker completion zsh
load_completion_from_cmd kubectl completion zsh
load_completion_from_cmd helm completion zsh

# CLI tools
load_completion_from_cmd gh completion --shell zsh
load_completion_from_cmd argocd completion zsh
load_completion_from_cmd wezterm shell-completion --shell zsh
load_completion_from_cmd op completion zsh
