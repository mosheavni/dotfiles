# shellcheck disable=2148,2034,2155,1091,2086,1094
zmodload zsh/zprof
# ================ #
# Basic ZSH Config #
# ================ #

export ZDOTDIR=$HOME
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
  ${ASDF_DATA_DIR:-$HOME/.asdf}/shims
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
if [[ -d "$HOME/Repos/moshe/devops-scripts" ]];then
  for i in $HOME/Repos/moshe/devops-scripts/*; do
    if [[ -d "$i" && -x "$i" ]]; then
      path+=("$i")
    fi
  done
fi
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
# asdf
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE=~/.dotfiles/requirements.txt

source $HOME/.antidote/antidote.zsh
antidote load
eval "$(zoxide init zsh --cmd cd)"

# ================ #
#  PS1 and Random  #
# ================ #
export EDITOR='nvim'
export AWS_PAGER=""
export MANPAGER='nvim +Man!'
export cdpath=(. ~ ~/Repos)
export TMPDIR=$HOME/tmp

# zsh gh copilot configuration
bindkey '^[|' zsh_gh_copilot_explain # bind Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest # bind Alt+\ to suggest

# ===================== #
# Aliases and Functions #
# ===================== #

for ZSH_FILE in "${ZDOTDIR:-$HOME}"/zsh.d/*.zsh(N); do
    source "${ZSH_FILE}"
done
[[ -f $HOME/corp-aliases.sh ]] && source $HOME/corp-aliases.sh


# ================ #
# Kubectl Contexts #
# ================ #
# Load all contexts
export KUBECONFIG=$HOME/.kube/config
export KUBECTL_EXTERNAL_DIFF="kdiff"
export KUBERNETES_EXEC_INFO='{"apiVersion": "client.authentication.k8s.io/v1beta1"}'

eval "$(starship init zsh)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mosheavni/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mosheavni/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/mosheavni/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/mosheavni/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
export K8S_DEV=true
export CMP_COMPLETION='<C-Space>'
