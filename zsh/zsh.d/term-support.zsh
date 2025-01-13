export TERM=xterm-256color
export WEZTERM_SHELL_SKIP_CWD=1
[[ -f /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]] && \
  source /Applications/WezTerm.app/Contents/Resources/wezterm.sh

# Emits the control sequence to notify many terminal emulators
# of the cwd
function termsupport_cwd { print -Pn "\e]0;zsh: $(basename $(pwd))\a"; }

# Use a precmd hook instead of a chpwd hook to avoid contaminating output
# i.e. when a script or function changes directory without `cd -q`, chpwd
# will be called the output may be swallowed by the script or function.
autoload -Uz add-zsh-hook
add-zsh-hook precmd termsupport_cwd
