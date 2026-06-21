#!/usr/bin/env bash
# Idempotent, interactive installer/verifier for the native GitHub notifier.
# Ensures deps, stow symlinks, gh auth + scope, the launchd agent, and fires a
# test banner. Safe to re-run any number of times.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
PACKAGE="ghnotify"
LABEL="com.mosheavni.ghnotify"
DOMAIN="gui/$(id -u)"
SCRIPT="$HOME/.local/bin/gh-notify.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DEPS=(gh terminal-notifier gum)

# ── pretty helpers (degrade to plain echo if gum isn't installed yet) ──────────
have() { command -v "$1" >/dev/null 2>&1; }

_style() { # _style <fg> <prefix> <msg...>
  local fg="$1" prefix="$2"; shift 2
  if have gum; then gum style --foreground "$fg" "$prefix $*"; else echo "$prefix $*"; fi
}
ok()   { _style 42  "✓" "$@"; }
warn() { _style 214 "!" "$@"; }
err()  { _style 196 "✗" "$@"; }
info() { _style 244 "·" "$@"; }

header() {
  if have gum; then
    gum style --border rounded --margin "1 0" --padding "1 2" --border-foreground 212 "$@"
  else
    echo "== $* =="
  fi
}

confirm() { # confirm <prompt> -> 0 if yes
  if have gum; then
    gum confirm "$1"
  else
    local a; read -r -p "$1 [y/N] " a; [[ "$a" == [yY]* ]]
  fi
}

# ── steps ──────────────────────────────────────────────────────────────────────
ensure_deps() {
  local missing=() d
  for d in "${DEPS[@]}"; do have "$d" || missing+=("$d"); done
  if ((${#missing[@]} == 0)); then
    ok "Dependencies present: ${DEPS[*]}"
    return
  fi
  warn "Missing dependencies: ${missing[*]}"
  if ! have brew; then
    err "Homebrew not found — install it first (see dotfiles README), then re-run."
    exit 1
  fi
  if confirm "Install missing deps via brew?"; then
    brew install "${missing[@]}"
    ok "Installed: ${missing[*]}"
  else
    err "Cannot continue without: ${missing[*]}"
    exit 1
  fi
}

ensure_stow() {
  if [[ -L "$SCRIPT" && -L "$PLIST" ]]; then
    ok "Stow symlinks in place"
    return
  fi
  info "Stowing '$PACKAGE' from $DOTFILES …"
  (cd "$DOTFILES" && stow -R "$PACKAGE")
  if [[ -e "$SCRIPT" && -e "$PLIST" ]]; then
    ok "Stowed '$PACKAGE'"
  else
    err "Stow did not produce $SCRIPT and $PLIST"
    exit 1
  fi
}

ensure_auth() {
  if ! gh auth status >/dev/null 2>&1; then
    warn "gh is not authenticated"
    if confirm "Run 'gh auth login' now?"; then
      gh auth login
    else
      err "gh auth is required for the notifications API"
      exit 1
    fi
  fi
  local scopes
  scopes=$(gh auth status 2>&1 | sed -n 's/.*Token scopes: //p' | head -1 || true)
  if echo "$scopes" | grep -Eq "'(repo|notifications)'"; then
    ok "Token scope OK for notifications"
  else
    warn "Token scopes ($scopes) may lack notifications access"
    if confirm "Refresh token to add the 'notifications' scope?"; then
      gh auth refresh -s notifications
    fi
  fi
  if gh api notifications --jq 'length' >/dev/null 2>&1; then
    ok "Notifications API reachable"
  else
    err "Notifications API call failed — check 'gh auth status'"
    exit 1
  fi
}

ensure_agent() {
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  launchctl bootstrap "$DOMAIN" "$PLIST"
  launchctl enable "$DOMAIN/$LABEL"
  launchctl kickstart "$DOMAIN/$LABEL"
  sleep 1
  local rc
  rc=$(launchctl print "$DOMAIN/$LABEL" 2>/dev/null | sed -n 's/.*last exit code = //p' | head -1 | tr -d ' ' || true)
  if [[ "$rc" == "0" ]]; then
    ok "launchd agent loaded and ran cleanly (interval 60s, runs at login)"
  else
    warn "Agent loaded but last exit code = ${rc:-unknown}; check ~/.cache/gh-notify/stderr.log"
  fi
}

verify_banner() {
  if confirm "Fire a test notification now?"; then
    terminal-notifier -title "gh-notify ✅" \
      -message "Setup test — if you can read this, native GitHub notifications work." \
      -sound default
    if confirm "Did the banner appear?"; then
      ok "Notifications are working"
    else
      warn "No banner → System Settings ▸ Notifications ▸ terminal-notifier ▸ Allow (style: Alerts/Banners), then re-run."
    fi
  fi
}

main() {
  header "GitHub → macOS notifier setup"
  ensure_deps
  ensure_stow
  ensure_auth
  ensure_agent
  verify_banner
  echo
  ok "Done. Manage with:"
  info "launchctl bootout  $DOMAIN/$LABEL      # pause"
  info "launchctl bootstrap $DOMAIN $PLIST     # resume"
  info "$SCRIPT                                 # run once"
  info "tail -f ~/.cache/gh-notify/error.log    # debug"
}

main "$@"
