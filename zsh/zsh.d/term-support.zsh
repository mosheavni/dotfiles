export TERM=xterm-256color
export WEZTERM_SHELL_SKIP_CWD=1
[[ -f /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]] && \
  source /Applications/WezTerm.app/Contents/Resources/wezterm.sh

ZSH_TAB_TITLE="%15<..<%~%<<" #15 char left truncated PWD
function termsupport_cwd {
  emulate -L zsh
  print -Pn "\e]0;zsh: ${ZSH_TAB_TITLE}\a" # set tab name
}

function termsupport_cwd_preexec {
  emulate -L zsh
  print -Pn "\e]0;${1:-%N}: ${ZSH_TAB_TITLE}\a" # set tab name
}

# Use a precmd hook instead of a chpwd hook to avoid contaminating output
# i.e. when a script or function changes directory without `cd -q`, chpwd
# will be called the output may be swallowed by the script or function.
autoload -Uz add-zsh-hook
add-zsh-hook precmd termsupport_cwd
add-zsh-hook preexec termsupport_cwd_preexec
