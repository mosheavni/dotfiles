#!/bin/bash

# Maintain local AI tooling configuration.
#
# - MCP servers (servers.json → native per-client entries in Claude/Copilot)
# - Karpathy agent guidelines (remote → AGENTS.md)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly MCPHUB_SOURCE="${SCRIPT_DIR}/.config/mcphub/servers.json"
readonly CLAUDE_MCP_TARGET="${HOME}/.claude.json"
readonly COPILOT_MCP_TARGET="${HOME}/.copilot/mcp-config.json"
readonly KARPATHY_BASE="https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main"
readonly LAST_SYNC_FILE="${HOME}/last-ai-sync.txt"

# Helper exit codes: 0 = updated, 1 = error, 2 = already in sync
readonly SYNC_UPDATED=0
readonly SYNC_ERROR=1
readonly SYNC_UNCHANGED=2

require_commands() {
  local cmd missing=0
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Warning: ${cmd} is not installed." >&2
      missing=1
    fi
  done
  return "$missing"
}

write_file_atomically() {
  local target="$1"
  local content="$2"

  mkdir -p "$(dirname "$target")"
  printf '%s\n' "$content" >"${target}.tmp"
  mv "${target}.tmp" "$target"
}

# --- MCP servers (servers.json is source of truth; translated per client) -----

read_mcphub_servers() {
  if [ ! -f "$MCPHUB_SOURCE" ]; then
    echo "Warning: Source file ${MCPHUB_SOURCE} not found" >&2
    return 1
  fi

  # Drop servers marked "disabled": true (set via mcp-manager's UI toggle)
  # before they ever reach a client config.
  jq '.mcpServers | to_entries | map(select(.value.disabled != true)) | from_entries' "$MCPHUB_SOURCE"
}

ensure_mcp_target_file() {
  local target_file="$1"
  local create_if_missing="$2"

  if [ -f "$target_file" ]; then
    return 0
  fi

  if [ "$create_if_missing" = "true" ]; then
    write_file_atomically "$target_file" '{"mcpServers":{}}'
    return 0
  fi

  echo "Warning: Target file ${target_file} not found" >&2
  return 1
}

sync_mcp_servers_into() {
  local target_file="$1"
  local display_name="$2"
  local create_if_missing="${3:-false}"
  local target_format="${4:-native}"
  local source_mcp current_mcp

  ensure_mcp_target_file "$target_file" "$create_if_missing" || return "$SYNC_ERROR"

  source_mcp="$(read_mcphub_servers)" || return "$SYNC_ERROR"

  if [ "$target_format" = "copilot" ]; then
    source_mcp="$(echo "$source_mcp" | jq 'map_values(
      if .command then
        . + { type: "stdio", tools: ["*"], deferTools: "never" }
      else .
      end
    )')"
  fi

  current_mcp="$(jq '.mcpServers' "$target_file")"

  if [ "$source_mcp" = "$current_mcp" ]; then
    return "$SYNC_UNCHANGED"
  fi

  write_file_atomically "$target_file" "$(jq --argjson mcp "$source_mcp" '.mcpServers = $mcp' "$target_file")"
  echo "✓ Synced MCP servers from servers.json to ${display_name}"
  return "$SYNC_UPDATED"
}

sync_all_mcp_servers() {
  local claude_result copilot_result

  set +e
  sync_mcp_servers_into "$CLAUDE_MCP_TARGET" "${HOME}/.claude.json" false native
  claude_result=$?
  sync_mcp_servers_into "$COPILOT_MCP_TARGET" "${HOME}/.copilot/mcp-config.json" true copilot
  copilot_result=$?
  set -e

  if [ "$claude_result" -eq "$SYNC_ERROR" ] && [ "$copilot_result" -eq "$SYNC_ERROR" ]; then
    return "$SYNC_ERROR"
  fi

  return "$SYNC_UPDATED"
}

# --- Remote assets -------------------------------------------------------------

sync_remote_file() {
  local url="$1"
  local target="$2"
  local display_name="$3"
  local content

  content="$(curl -fsSL "$url")" || {
    echo "Warning: Failed to fetch ${url}" >&2
    return "$SYNC_ERROR"
  }

  if [ -f "$target" ] && [ "$(cat "$target")" = "$content" ]; then
    return "$SYNC_UNCHANGED"
  fi

  write_file_atomically "$target" "$content"
  echo "✓ Synced ${display_name} from ${url}"
  return "$SYNC_UPDATED"
}

sync_karpathy_guidelines() {
  set +e
  sync_remote_file \
    "${KARPATHY_BASE}/CLAUDE.md" \
    "${SCRIPT_DIR}/AGENTS.md" \
    "ai/AGENTS.md"
  set -e
}

record_last_sync() {
  date >"$LAST_SYNC_FILE"
}

main() {
  require_commands jq curl || exit 1

  if [ "${1:-}" = "--mcp-only" ]; then
    sync_all_mcp_servers
    record_last_sync
    return
  fi

  sync_all_mcp_servers
  sync_karpathy_guidelines
  record_last_sync
}

main "$@"
