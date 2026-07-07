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
export PNPM_HOME="$HOME/Library/pnpm"
path=(
  ${ASDF_DATA_DIR:-$HOME/.asdf}/shims
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /opt/homebrew/opt/make/libexec/gnubin
  ${KREW_ROOT:-$HOME/.krew}/bin
  /opt/homebrew/opt/curl/bin
  $HOME/.bin
  $HOME/.docker/bin
  $HOME/.local/bin
  $HOME/.local/share/dotfiles-python/bin
  $HOME/.cargo/bin
  $HOME/go/bin
  /usr/local/sbin
  $PNPM_HOME
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
source $HOME/.antidote/antidote.zsh
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
if [[ ! $zsh_plugins -nt ${ZDOTDIR:-$HOME}/.zsh_plugins.txt ]]; then
  antidote bundle <${ZDOTDIR:-$HOME}/.zsh_plugins.txt >$zsh_plugins
fi
source $zsh_plugins

# ================ #
#  PS1 and Random  #
# ================ #
export EDITOR='nvim'
export AWS_PAGER=""
export MANPAGER='nvim +Man!'
export cdpath=(. ~ ~/Repos)
export TMPDIR=$HOME/tmp
export GIT_DEFAULT_ORG=mosheavni

# ===== #
#  fzf  #
# ===== #
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height=100% --layout=reverse --border --info=inline --highlight-line'
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers,changes {}' --walker-skip .git,node_modules"
export FZF_CTRL_R_OPTS="--scheme=history --ansi --color=hl:underline,hl+:underline,header:italic --header 'Press CTRL-Y to copy command into clipboard' --preview 'echo {2..} | bat --color=always -pl bash' --preview-window 'down:4:wrap' --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --prompt='History> '"

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

# ==================== #
# AI config sync       #
# ==================== #
# MCP servers, agent guidelines, Cursor CLI policy (once per day, background)
MCP_SYNC_TIMESTAMP="$HOME/last-ai-sync.txt"
if [[ ! -f "$MCP_SYNC_TIMESTAMP" ]] || [[ "$(date +%Y%m%d)" != "$(date -r "$MCP_SYNC_TIMESTAMP" +%Y%m%d 2>/dev/null)" ]]; then
  (
    ~/.dotfiles/ai/sync-ai-config.sh 2>/dev/null
  ) &|
fi

# Starship prompt (loaded synchronously as it's needed immediately)
eval "$(starship init zsh)"

export CMP_COMPLETION='<C-Space>'
export PJ_DIRS='~/Repos/,~/.dotfiles,~/.config/lightvim'
