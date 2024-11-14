# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update 'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard 'mac'

# Don't start tmux.
zstyle ':z4h:' start-tmux no

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
# zstyle ':z4h:direnv' enable 'no'
# Show "loading" and "unloading" notifications from direnv.
# zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
# zstyle ':z4h:ssh:example-hostname1' enable 'yes'
# zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*' enable 'yes'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
# zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it up-to-date.
z4h install ohmyzsh/ohmyzsh || return
z4h install loiccoyle/zsh-github-copilot || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
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

# Export environment variables.
export GPG_TTY=$TTY
export XDG_CONFIG_HOME=${HOME}/.config
unset ZSH_AUTOSUGGEST_USE_ASYNC
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers,changes {}"'

export EDITOR="nvim"
export AWS_PAGER=""

# Set Locale
export LANG=en_US
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh # source an individual file
z4h load ohmyzsh/ohmyzsh/plugins/gh
z4h load loiccoyle/zsh-github-copilot
z4h source -- $HOME/.asdf/asdf.sh

# Define key bindings.
# z4h bindkey undo Ctrl+/   Shift+Tab  # undo the last command line change
# z4h bindkey redo Option+/            # redo the last undone command line change

z4h bindkey z4h-cd-back Shift+Left     # cd into the previous directory
z4h bindkey z4h-cd-forward Shift+Right # cd into the next directory
z4h bindkey z4h-cd-up Shift+Up         # cd into the parent directory
z4h bindkey z4h-cd-down Shift+Down     # cd into a child directory
bindkey '^[|' zsh_gh_copilot_explain   # bind Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest   # bind Alt+\ to suggest

# Autoload functions.
# autoload -Uz zmv

# completions
[[ -n "$ZSH_CACHE_DIR" ]] || ZSH_CACHE_DIR="$ZSH/cache"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"
fpath+=($ZSH_CACHE_DIR/completions /opt/homebrew/share/zsh/site-functions)
complete -o nospace -C terraform terraform
complete -o nospace -C terragrunt terragrunt
complete -C 'aws_completer' aws
[[ -f $ZSH_CACHE_DIR/completions/_docker ]] || docker completion zsh >$ZSH_CACHE_DIR/completions/_docker

# Define aliases.
if [[ -f $HOME/aliases.sh ]]; then
  source $HOME/aliases.sh
fi
[[ -f $HOME/corp-aliases.sh ]] && source $HOME/corp-aliases.sh

# Add flags to existing aliases.
alias ll="${aliases[ls]:-ls} -la"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots # no special treatment for file names with a leading dot
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
