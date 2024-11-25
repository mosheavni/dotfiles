export TERM=wezterm
export WEZTERM_SHELL_INTEGRATION=1

# Emits the control sequence to notify many terminal emulators
# of the cwd
function termsupport_cwd {
  printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "$(_urlencode "$PWD")"
}

# Use a precmd hook instead of a chpwd hook to avoid contaminating output
# i.e. when a script or function changes directory without `cd -q`, chpwd
# will be called the output may be swallowed by the script or function.
autoload -Uz add-zsh-hook
add-zsh-hook precmd termsupport_cwd
