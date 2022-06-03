# shellcheck disable=2148,2034,2155,1091,2086,1094
zmodload zsh/zprof
# ================ #
# Basic ZSH Config #
# ================ #

# Additional PATHs
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="/usr/local/opt/node@16/bin:$PATH"
export PATH="$HOME/.cargo/bin:${PATH}"
export PATH="$HOME/Library/Application Support/neovim/bin:${PATH}"

export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="mosherussell"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"
export GPG_TTY=$(tty)

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
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY            # Don't execute immediately upon history expansion.
setopt HIST_BEEP              # Beep when accessing nonexistent history.

plugins=(
  ag
  aliases
  ansible
  autoupdate
  aws
  branch
  colored-man-pages
  command-not-found
  common-aliases
  dircycle
  docker
  git
  git-auto-fetch
  helm
  kube-ps1
  kubectl
  terraform
  zsh-autosuggestions
  zsh-syntax-highlighting
)

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh

# =================== #
# Completions and PS1 #
# =================== #

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Terraform completion
complete -o nospace -C /usr/local/bin/terraform terraform
compdef tf='terraform'
compdef tg='terraform'
compdef terragrunt='terraform'

# ===================== #
# Aliases and Functions #
# ===================== #
if [[ -f $HOME/aliases.sh ]]; then
  source $HOME/aliases.sh
fi
[[ -f $HOME/corp-aliases.sh ]] && source $HOME/corp-aliases.sh

export EDITOR="nvim"

cnf() {
  open "https://command-not-found.com/$*"
}

# ================ #
# Kubectl Contexts #
# ================ #

# Load all contexts
export KUBECONFIG=$HOME/.kube/config
if [[ -d $HOME/.kube/contexts/ ]]; then
  for ctx in "$HOME"/.kube/contexts/*.config; do
    export KUBECONFIG=${KUBECONFIG}:${ctx}
  done
fi

export KUBECTL_EXTERNAL_DIFF="kdiff"

bookitmeinit() {
  cd $HOME/Repos/bookitme || return
  export KUBECONFIG=$HOME/.kube/contexts/bookitme-k8s.yaml.config
  source $HOME/Repos/bookitme/bookitme-terraform/.env
  kgp
}

export KUBERNETES_EXEC_INFO='{"apiVersion": "client.authentication.k8s.io/v1beta1"}'

# Load starship last
eval "$(starship init zsh)"
