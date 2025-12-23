# shellcheck disable=2148,2034,2155,1091,2086,1094
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof
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
  $HOME/.docker/bin
  $HOME/.local/bin
  $HOME/.cargo/bin
  /usr/local/sbin
  /usr/local/opt/postgresql@15/bin
  $path
)

# Add devops-scripts subdirectories to PATH (only if directory exists)
if [[ -d "$HOME/Repos/moshe/devops-scripts" ]]; then
  for i in $HOME/Repos/moshe/devops-scripts/*; do
    [[ -d "$i" && -x "$i" ]] && path+=("$i")
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

# Defer expensive initializations for faster startup
zsh-defer eval "$(zoxide init zsh --cmd cd)"

# ================ #
#  PS1 and Random  #
# ================ #
export EDITOR='nvim'
export AWS_PAGER=""
export MANPAGER='nvim +Man!'
export cdpath=(. ~ ~/Repos)
export TMPDIR=$HOME/tmp

# zsh gh copilot configuration
zsh-defer -c '
  bindkey "^[|" zsh_gh_copilot_explain
  bindkey "^[\\" zsh_gh_copilot_suggest
'

# ===================== #
# Aliases and Functions #
# ===================== #
for ZSH_FILE in "${ZDOTDIR:-$HOME}"/zsh.d/*.zsh(N); do
    source "${ZSH_FILE}"
done
[[ -f $HOME/corp-aliases.sh ]] && zsh-defer source $HOME/corp-aliases.sh


# ================ #
# Kubectl Contexts #
# ================ #
# Load all contexts
export KUBECONFIG=$HOME/.kube/config
export KUBECTL_EXTERNAL_DIFF="kdiff"
export KUBERNETES_EXEC_INFO='{"apiVersion": "client.authentication.k8s.io/v1beta1"}'

# Starship prompt (loaded synchronously as it's needed immediately)
eval "$(starship init zsh)"

export K8S_DEV=true
export PR_REVIEW_DEV=true
export CMP_COMPLETION='<C-Space>'
export PJ_DIRS='~/Repos/,~/.dotfiles,~/Repos/moshe/'

# ==================== #
# MCP Servers Sync     #
# ==================== #
# Sync MCP servers from mcphub to Claude (once per day, background)
MCP_SYNC_TIMESTAMP="$HOME/.cache/mcp-sync-last-run"
if [[ ! -f "$MCP_SYNC_TIMESTAMP" ]] || [[ "$(date +%Y%m%d)" != "$(date -r "$MCP_SYNC_TIMESTAMP" +%Y%m%d 2>/dev/null)" ]]; then
  (
    ~/.dotfiles/ai/sync-mcp-servers.sh 2>/dev/null && touch "$MCP_SYNC_TIMESTAMP"
  ) &|
fi
