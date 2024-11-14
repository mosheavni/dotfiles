# shellcheck disable=2148,2034,2155,1091,2086,1094
# ================ #
# Basic ZSH Config #
# ================ #

# Additional PATHs
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$HOME/.bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:${PATH}"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/postgresql@15/bin:$PATH"
export XDG_CONFIG_HOME=${HOME}/.config

export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="mosherussell"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"
DISABLE_AUTO_UPDATE="true"
zstyle ':omz:update' mode reminder # just remind me to update when it's time
unset ZSH_AUTOSUGGEST_USE_ASYNC

# Set Locale
export LANG=en_US
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History settings
HISTSIZE=5000
SAVEHIST=5000
setopt bang_hist              # Treat the '!' character specially during expansion.
setopt extended_history       # Write the history file in the ":start:elapsed;command" format.
setopt inc_append_history     # Write to the history file immediately, not when the shell exits.
setopt share_history          # Share history between all sessions.
setopt hist_expire_dups_first # Expire duplicate entries first when trimming history.
setopt hist_ignore_dups       # Don't record an entry that was just recorded again.
setopt hist_ignore_all_dups   # Delete old recorded entry if new entry is a duplicate.
setopt hist_find_no_dups      # Do not display a line previously found.
setopt hist_save_no_dups      # Don't write duplicate entries in the history file.
setopt hist_reduce_blanks     # Remove superfluous blanks before recording entry.
setopt hist_verify            # Don't execute immediately upon history expansion.
setopt hist_beep              # Beep when accessing nonexistent history.

# ========= #
#  Plugins  #
# ========= #
plugins=(
  argocd
  asdf
  autoupdate
  aws
  branch
  colored-man-pages
  command-not-found
  common-aliases
  docker
  fzf
  gh
  git
  git-auto-fetch
  github
  golang
  helm
  kube-ps1
  kubectl
  kubectx
  terraform
  zsh-autosuggestions
  zsh-github-copilot
  zsh-syntax-highlighting
)

# ============= #
#  Completions  #
# ============= #
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
fpath+=/opt/homebrew/share/zsh/site-functions

# ============= #
#  Autoloaders  #
# ============= #
source $ZSH/oh-my-zsh.sh
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_DEFAULT_OPTS='--color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168'
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers,changes {}"'

# ================ #
#  PS1 and Random  #
# ================ #
compdef terragrunt='terraform'
export EDITOR="nvim"
export AWS_PAGER=""
setopt menu_complete
unsetopt auto_menu
unsetopt case_glob
setopt glob_complete
eval "$(zoxide init --cmd cd zsh)"
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE=~/Repos/dotfiles/requirements.txt
[[ -f ~/.asdf/plugins/golang/set-env.zsh ]] && {
  source ~/.asdf/plugins/golang/set-env.zsh
  asdf_update_golang_env
  export PATH="$GOPATH/bin:$PATH"
  export ASDF_GOLANG_MOD_VERSION_ENABLED=true
}
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
