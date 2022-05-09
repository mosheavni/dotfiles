# ================ #
# Basic ZSH Config #
# ================ #

# Additional PATHs
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$HOME/.local/alt/shims:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="mosherussell"
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
  common-aliases
  dircycle
  docker
  git
  git-auto-fetch
  helm
  kubectl
  terraform
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# =========== #
# Pyenv Setup #
# =========== #
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# =================== #
# Completions and PS1 #
# =================== #
# Load zsh-completions
if type brew &>/dev/null; then
  fpath=( $(brew --prefix)/share/zsh-completions $fpath )

  autoload -Uz compinit
  compinit
fi
autoload -U +X bashcompinit && bashcompinit

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Terraform completion
complete -o nospace -C /usr/local/bin/terraform terraform
compdef tf='terraform'
compdef tg='terraform'
compdef terragrunt='terraform'

# Source kube_ps1
if [[ -f /usr/local/opt/kube-ps1/share/kube-ps1.sh ]];then
  source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
  function get_cluster_short() {
    echo "$1" | gsed -e 's?arn:aws:eks:[a-zA-Z0-9\-]*:[0-9]*:cluster/??g' -e 's?\.k8s\.local??g'
  }
  KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
fi

# ===================== #
# Aliases and Functions #
# ===================== #
if [[ -f ~/aliases.sh ]];then
  source ~/aliases.sh
fi
[[ -f ~/corp-aliases.sh ]] && source ~/corp-aliases.sh

export EDITOR="nvim"

# iTerm profile switching
it2prof() { printf "\e]1337;SetProfile=$1\a" }

cnf() { open "https://command-not-found.com/$*" }

# ================ #
# Kubectl Contexts #
# ================ #

# Load all contexts
export KUBECONFIG=~/.kube/config
if [[ -d ~/.kube/contexts/ ]];then
  for ctx in ~/.kube/contexts/*.config;do
    export KUBECONFIG=${KUBECONFIG}:${ctx}
  done
fi

export KUBECTL_EXTERNAL_DIFF="kdiff"

bookitmeinit() {
  cd ~/Repos/bookitme
  export KUBECONFIG=~/.kube/contexts/bookitme-k8s.yaml.config
  source ~/Repos/bookitme/bookitme-terraform/.env
  kgp
}

