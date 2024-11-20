load_completion_from_cmd() {
  local cmd=$1
  shift
  local args=$@
  local completion_file=$ZSH_CACHE_DIR/completions/_$cmd
  if ! command -v $cmd &>/dev/null; then
    return
  fi
  if [[ ! -f $completion_file ]]; then
    typeset -g -A _comps
    autoload -Uz _$cmd
    _comps[$cmd]=_$cmd
  fi
  eval "$cmd ${args[*]}" >| $completion_file &|
}

autoload -U +X bashcompinit && bashcompinit
fpath+=(
  $ZSH_CACHE_DIR/completions
  /opt/homebrew/share/zsh/site-functions
  $ASDF_DIR/completions
)

zsh-defer complete -o nospace -C terraform terraform
zsh-defer complete -o nospace -C terragrunt terragrunt
zsh-defer complete -o nospace -C 'aws_completer' aws
zsh-defer load_completion_from_cmd docker completion zsh
zsh-defer load_completion_from_cmd argocd completion zsh
zsh-defer load_completion_from_cmd helm completion zsh
zsh-defer load_completion_from_cmd gh completion --shell zsh
zsh-defer load_completion_from_cmd kubectl completion zsh
