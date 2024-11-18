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

# ============= #
#  Autoloaders  #
# ============= #
source $HOME/.antidote/antidote.zsh
antidote load


# ================ #
#  PS1 and Random  #
# ================ #
# fzf
source <(fzf --zsh)
# export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers,changes {}"'
export FZF_CTRL_R_OPTS="--ansi --color=hl:underline,hl+:underline --height 80% --preview 'echo {2..} | bat --color=always -pl bash' --preview-window 'down:4:wrap' --bind 'ctrl-/:toggle-preview'"

export EDITOR="nvim"
export AWS_PAGER=""
export TERM=wezterm

# zsh
export WORDCHARS=""
setopt menu_complete
unsetopt auto_menu
unsetopt case_glob
setopt glob_complete
setopt multios              # enable redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs       # show long list format job notifications
setopt interactivecomments  # recognize comments
setopt autocd
zstyle ':completion:*:*:*:*:*' menu select

# asdf
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE=~/Repos/dotfiles/requirements.txt

# zsh gh copilot configuration
bindkey '^[|' zsh_gh_copilot_explain # bind Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest # bind Alt+\ to suggest

# ===================== #
# Aliases and Functions #
# ===================== #
export ASDF_DIR="$HOME/.asdf"
[[ -d $HOME/.asdf ]] && source $HOME/.asdf/asdf.sh
[[ -f $HOME/completions.zsh ]] && source $HOME/completions.zsh
[[ -f $HOME/aliases.sh ]] && source $HOME/aliases.sh
[[ -f $HOME/functions.sh ]] && source $HOME/functions.sh
[[ -f $HOME/corp-aliases.sh ]] && source $HOME/corp-aliases.sh

source $HOME/grep.zsh
source $HOME/kubectl.zsh

# ================ #
# Kubectl Contexts #
# ================ #
# Load all contexts
export KUBECONFIG=$HOME/.kube/config
export KUBECTL_EXTERNAL_DIFF="kdiff"
export KUBERNETES_EXEC_INFO='{"apiVersion": "client.authentication.k8s.io/v1beta1"}'

eval "$(starship init zsh)"
