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
