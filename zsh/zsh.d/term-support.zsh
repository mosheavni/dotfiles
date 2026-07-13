# Let wezterm.sh report cwd via OSC 7 on precmd (needed for Cmd+Shift+D splits).
# Nvim :cd while nvim runs still needs OSC 7 from nvim (see wezterm.report_cwd).
[[ -f /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]] &&
  source /Applications/WezTerm.app/Contents/Resources/wezterm.sh

ZSH_TAB_TITLE="%15<..<%~%<<" #15 char left truncated PWD
function termsupport_cwd {
  emulate -L zsh
  print -Pn "\e]0;🖥️ zsh: ${ZSH_TAB_TITLE}\a" # set tab name
}

function termsupport_cwd_preexec {
  emulate -L zsh
  local CMD="${2%% *}"
  print -Pn "\e]0;${CMD}: ${ZSH_TAB_TITLE}\a" # set tab name
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd termsupport_cwd
add-zsh-hook preexec termsupport_cwd_preexec
