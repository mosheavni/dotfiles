#!/bin/bash

# Sync configuration from various sources to local targets.
#
# MCP servers (local → local):
#   Source of truth: .config/mcphub/servers.json (edit via nvim UI)
#   Targets: ~/.claude.json, ~/.cursor/mcp.json
#
# Remote files (URL → local):
#   multica-ai/andrej-karpathy-skills → cursor/AGENTS.md
#   multica-ai/andrej-karpathy-skills → cursor/.cursor/rules/agents.mdc

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/.config/mcphub/servers.json"
CLAUDE_TARGET="$SCRIPT_DIR/.claude.json"
CURSOR_TARGET="${HOME}/.cursor/mcp.json"

# Check if jq is available
if ! command -v jq &>/dev/null; then
  echo "Warning: jq is not installed. Cannot sync MCP servers." >&2
  exit 1
fi

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
  echo "Warning: Source file $SOURCE_FILE not found" >&2
  exit 1
fi

# Extract mcpServers from source
SOURCE_MCP=$(jq '.mcpServers' "$SOURCE_FILE")

# Sync mcpServers into a target file.
# Returns: 0 = updated, 1 = error, 2 = already in sync
sync_mcp_servers() {
  local target_file="$1"
  local display_name="$2"
  local create_if_missing="${3:-false}"

  if [ ! -f "$target_file" ]; then
    if [ "$create_if_missing" = "true" ]; then
      mkdir -p "$(dirname "$target_file")"
      echo '{"mcpServers":{}}' >"$target_file"
    else
      echo "Warning: Target file $target_file not found" >&2
      return 1
    fi
  fi

  local current_mcp
  current_mcp=$(jq '.mcpServers' "$target_file")

  if [ "$SOURCE_MCP" = "$current_mcp" ]; then
    return 2
  fi

  jq --argjson mcp "$SOURCE_MCP" '.mcpServers = $mcp' "$target_file" >"${target_file}.tmp"
  mv "${target_file}.tmp" "$target_file"
  echo "✓ Synced MCP servers from mcphub to $display_name"
  return 0
}

set +e
sync_mcp_servers "$CLAUDE_TARGET" "${HOME}/.claude.json" false
claude_result=$?
sync_mcp_servers "$CURSOR_TARGET" "${HOME}/.cursor/mcp.json" true
cursor_result=$?
set -e

if [ "$claude_result" -eq 1 ] && [ "$cursor_result" -eq 1 ]; then
  exit 1
fi

if [ "$claude_result" -eq 2 ] && [ "$cursor_result" -eq 2 ]; then
  exit 0
fi

# Sync a remote file from a URL to a local path.
# Returns: 0 = updated, 1 = error, 2 = already in sync
sync_remote_file() {
  local url="$1"
  local target="$2"
  local display_name="$3"

  if ! command -v curl &>/dev/null; then
    echo "Warning: curl is not installed. Cannot sync $display_name." >&2
    return 1
  fi

  local content
  content=$(curl -fsSL "$url") || {
    echo "Warning: Failed to fetch $url" >&2
    return 1
  }

  if [ -f "$target" ] && [ "$(cat "$target")" = "$content" ]; then
    return 2
  fi

  mkdir -p "$(dirname "$target")"
  printf '%s\n' "$content" >"$target"
  echo "✓ Synced $display_name from $url"
  return 0
}

KARPATHY_BASE="https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main"

LAST_SYNC_FILE="${HOME}/last-ai-sync.txt"

set +e
sync_remote_file \
  "$KARPATHY_BASE/CLAUDE.md" \
  "$SCRIPT_DIR/AGENTS.md" \
  "cursor/AGENTS.md"
sync_remote_file \
  "$KARPATHY_BASE/.cursor/rules/karpathy-guidelines.mdc" \
  "$SCRIPT_DIR/.cursor/rules/agents.mdc" \
  "ai/.cursor/rules/agents.mdc"
set -e

date >"$LAST_SYNC_FILE"
