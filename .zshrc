# shellcheck disable=2148,2034,2155,1091,2086,1094
zmodload zsh/zprof
# ================ #
# Basic ZSH Config #
# ================ #

[[ -n "$ZSH" ]] || export ZSH="${${(%):-%x}:a:h}"
[[ -n "$ZSH_CUSTOM" ]] || ZSH_CUSTOM="$ZSH/custom"
[[ -n "$ZSH_CACHE_DIR" ]] || ZSH_CACHE_DIR="$ZSH/cache"
if [[ ! -w "$ZSH_CACHE_DIR" ]]; then
  ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/antidote"
fi
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

# Additional PATHs
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /opt/homebrew/opt/make/libexec/gnubin
  ${KREW_ROOT:-$HOME/.krew}/bin
  /usr/local/opt/curl/bin
  /usr/local/opt/ruby/bin
  $HOME/.bin
  $HOME/.local/bin
  $HOME/.cargo/bin
  /usr/local/sbin
  /usr/local/opt/postgresql@15/bin
  $path
)
export PATH
export XDG_CONFIG_HOME=${HOME}/.config
unset ZSH_AUTOSUGGEST_USE_ASYNC

# Set Locale
export LANG=en_US
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History settings
HISTSIZE=5000
SAVEHIST=5000
setopt BANG_HIST              # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY       # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY          # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY            # Don't execute immediately upon history expansion.
setopt HIST_BEEP              # Beep when accessing nonexistent history.
# setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.

# ============= #
#  Autoloaders  #
# ============= #
fpath+=($ZSH_CACHE_DIR/completions /opt/homebrew/share/zsh/site-functions)
source $HOME/.antidote/antidote.zsh
antidote load
source <(fzf --zsh)

autoload -U +X bashcompinit && bashcompinit

zsh-defer complete -o nospace -C terraform terraform
zsh-defer complete -o nospace -C terragrunt terragrunt
zsh-defer complete -C 'aws_completer' aws
[[ -f $ZSH_CACHE_DIR/completions/_docker ]] || docker completion zsh > $ZSH_CACHE_DIR/completions/_docker

# ================ #
#  PS1 and Random  #
# ================ #
# fzf
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers,changes {}"'

export EDITOR="nvim"
export AWS_PAGER=""

# zsh
export WORDCHARS=""
setopt menu_complete
unsetopt auto_menu
unsetopt case_glob
setopt glob_complete
setopt multios              # enable redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs       # show long list format job notifications
setopt interactivecomments  # recognize comments
zstyle ':completion:*:*:*:*:*' menu select

# asdf
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE=~/Repos/dotfiles/requirements.txt
[[ -f ~/.asdf/plugins/golang/set-env.zsh ]] && {
  source ~/.asdf/plugins/golang/set-env.zsh
  asdf_update_golang_env
  export PATH="$GOPATH/bin:$PATH"
  export ASDF_GOLANG_MOD_VERSION_ENABLED=true
}

# zsh gh copilot configuration
bindkey '^[|' zsh_gh_copilot_explain # bind Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest # bind Alt+\ to suggest

# ===================== #
# Aliases and Functions #
# ===================== #
if [[ -f $HOME/aliases.sh ]]; then
  source $HOME/aliases.sh
fi
[[ -f $HOME/corp-aliases.sh ]] && source $HOME/corp-aliases.sh

# ================ #
# Kubectl Contexts #
# ================ #
# Load all contexts
export KUBECONFIG=$HOME/.kube/config
export KUBECTL_EXTERNAL_DIFF="kdiff"
export KUBERNETES_EXEC_INFO='{"apiVersion": "client.authentication.k8s.io/v1beta1"}'

eval "$(starship init zsh)"
