#!/bin/bash

# Sync MCP servers configuration from mcphub to Claude and Cursor
# Source of truth: .config/mcphub/servers.json (edit via nvim UI)
# Targets:
#   - ~/.claude.json (user-scoped MCP servers for Claude Code)
#   - ~/.cursor/mcp.json (global MCP servers for Cursor)

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
