#export PATH=$PATH:$HOME/bin:/usr/local/bin:$PATH:~/Library/Python/2.7/bin:~/bin:~/.npm-global/bin:${KREW_ROOT:-$HOME/.krew}/bin
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="mosherussell"
# ZSH_THEME="typewritten/typewritten"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Set Locale
export LANG=en_US
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History settings
HISTSIZE=5000
SAVEHIST=5000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

plugins=(
    ansible
    autoupdate
    aws
    colored-man-pages
    common-aliases
    dircycle
    docker
    fzf
    git
    git-auto-fetch
    helm
    kubectl
    minikube
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
)


# Source kube_ps1
if [[ -f /usr/local/opt/kube-ps1/share/kube-ps1.sh ]];then
    source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
    function get_cluster_short() {
        echo "$1" | gsed -e 's?arn:aws:eks:[a-zA-Z0-9\-]*:[0-9]*:cluster/??g' -e 's?\.k8s\.local??g'
    }
    KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
fi

source $ZSH/oh-my-zsh.sh
if [[ -f ~/Repos/devops_scripts/aliases/aliases.sh ]];then
    source ~/Repos/devops_scripts/aliases/aliases.sh
fi

autoload -U +X bashcompinit && bashcompinit
alias vim="nvim"
export EDITOR="nvim"
alias sudoedit="nvim"
alias sed=gsed
alias cat='bat'
alias mdl='mdless README.md'
alias tf='terraform'
alias dotfiles='cd ~/src/dotfiles'
alias v='vim'
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# OktaAWSCLI
if [[ -f "$HOME/.okta/bash_functions" ]]; then
    . "$HOME/.okta/bash_functions"
fi
if [[ -d "$HOME/.okta/bin" && ":$PATH:" != *":$HOME/.okta/bin:"* ]]; then
    PATH="$HOME/.okta/bin:$PATH"
fi

# Kubectl contexts
if [[ -f ~/.kube/ctx ]];then
    alias ctx="source ~/.kube/ctx"
    local context
    context=$(cat ~/.kube/ctx.conf || ~/.kube/config)
    export KUBECONFIG=$context
fi
