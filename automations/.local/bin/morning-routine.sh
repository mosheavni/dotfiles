#!/bin/zsh
# Morning routine: aws sso login (blocking), then restart OpenVPN Connect.
set -euo pipefail

OPENVPN="/Applications/OpenVPN Connect.app/Contents/MacOS/OpenVPN Connect"
# Run: "$OPENVPN" --list-profiles  to refresh this ID if profiles change.
OPENVPN_PROFILE_ID=$("$OPENVPN" --list-profiles | jq -r '.[].id')

log() { print -r -- "[morning-routine] $*"; }

# 1. AWS SSO login — block until the browser flow completes.
log "Running aws sso login..."
zsh -lic 'aws sso login'
log "aws sso login finished."

# 2. Quit OpenVPN Connect if it is running.
if pgrep -qx "OpenVPN Connect"; then
  log "Quitting OpenVPN Connect..."
  "$OPENVPN" --quit
  sleep 2
fi

# 3. Open OpenVPN Connect and connect (official CLI workaround for Connect).
log "Connecting OpenVPN profile ${OPENVPN_PROFILE_ID}..."
"$OPENVPN" --connect-shortcut="${OPENVPN_PROFILE_ID}"

log "Done."
