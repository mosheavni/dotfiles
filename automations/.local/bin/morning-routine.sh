#!/bin/zsh
# Morning routine: restart OpenVPN Connect, then aws sso login in Terminal (auto-closes).
set -euo pipefail

OPENVPN="/Applications/OpenVPN Connect.app/Contents/MacOS/OpenVPN Connect"
# Run: "$OPENVPN" --list-profiles  to refresh this ID if profiles change.
OPENVPN_PROFILE_ID=$("$OPENVPN" --list-profiles | jq -r '.[].id')

log() { print -r -- "[morning-routine] $*"; }

# 1. Quit OpenVPN Connect if it is running.
if pgrep -qx "OpenVPN Connect"; then
  log "Quitting OpenVPN Connect..."
  "$OPENVPN" --quit
  sleep 2
fi

# 2. Open OpenVPN Connect and connect (official CLI workaround for Connect).
log "Connecting OpenVPN profile ${OPENVPN_PROFILE_ID}..."
"$OPENVPN" --connect-shortcut="${OPENVPN_PROFILE_ID}"

# 3. Run aws sso login in a new Terminal window; exit closes it when done.
log "Opening Terminal for aws sso login..."
osascript <<'EOF'
tell application "Terminal"
  do script "zsh -lic 'aws sso login; exit'"
  activate
end tell
EOF
log "Done."
