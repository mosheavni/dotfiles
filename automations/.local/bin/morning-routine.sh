#!/bin/zsh
# Morning routine: aws sso login (if needed), then OpenVPN Connect (if not connected).
set -euo pipefail

# Shortcuts/automation often run with a minimal PATH (no /sbin).
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

OPENVPN="/Applications/OpenVPN Connect.app/Contents/MacOS/OpenVPN Connect"
# Buffer before SSO expiry to re-login proactively (seconds).
AWS_SSO_EXPIRY_BUFFER=300

log() { print -r -- "[morning-routine] $*"; }

notify() {
  /usr/bin/osascript -e 'on run argv' \
    -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
    -e 'end run' -- "$@"
}

status() {
  log "$@"
  notify 'Morning routine' "$*"
}

on_error() {
  local ec=$?
  notify 'Morning routine' "Failed (exit $ec)"
  exit $ec
}
trap on_error ERR

# SSO portal session lives in ~/.aws/sso/cache/*.json (the file with accessToken).
# Match by .startUrl — do not hash the URL (aws configure get prints a trailing newline).
aws_sso_session_valid() {
  local start_url expires_at expires_epoch now_epoch

  start_url=$(zsh -lic 'aws configure get sso_start_url --output text' 2>/dev/null)
  [[ -n $start_url && $start_url != None ]] || return 1

  expires_at=$(
    jq -rs --arg url "$start_url" '
      [.[] | select(.startUrl == $url and .accessToken) | .expiresAt] | first // empty
    ' "$HOME"/.aws/sso/cache/*.json 2>/dev/null
  )
  [[ -n $expires_at ]] || return 1

  expires_epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$expires_at" +%s 2>/dev/null) || return 1
  now_epoch=$(date -u +%s)

  ((now_epoch < expires_epoch - AWS_SSO_EXPIRY_BUFFER))
}

# OpenVPN Connect has no --status flag. Detect an active tunnel via utun IPv4 or routes.
vpn_connected() {
  /sbin/ifconfig 2>/dev/null | /usr/bin/awk '
    /^utun[0-9]+:/ { iface=$1; sub(/:$/, "", iface) }
    /^[[:space:]]+inet / && $2 !~ /^127\./ && $2 !~ /^169\.254\./ {
      if (iface ~ /^utun/) connected=1
    }
    END { exit connected ? 0 : 1 }
  ' && return 0

  usr/sbin/netstat -rn 2>/dev/null | /usr/bin/awk '
    $NF ~ /^utun[0-9]+$/ && $1 !~ /^default$/ && $1 !~ /:/ { connected=1 }
    END { exit connected ? 0 : 1 }
  '
}

# 1. AWS SSO login — only when the portal session is missing or near expiry.
if aws_sso_session_valid; then
  status 'AWS SSO session still valid; skipping login.'
else
  status 'AWS SSO session expired or missing; running aws sso login...'
  zsh -lic 'aws sso login'
  status 'AWS SSO login finished.'
fi

# 2. OpenVPN — skip restart when already connected.
if vpn_connected; then
  status 'OpenVPN already connected; skipping.'
  sleep 2
else
  OPENVPN_PROFILE_ID=$("$OPENVPN" --list-profiles | jq -er '.[0].id')

  if pgrep -qx 'OpenVPN Connect'; then
    status 'Quitting OpenVPN Connect...'
    "$OPENVPN" --quit
    sleep 2
  fi

  status "Connecting OpenVPN profile ${OPENVPN_PROFILE_ID}..."
  "$OPENVPN" --connect-shortcut="${OPENVPN_PROFILE_ID}"
fi

status 'Done.'
