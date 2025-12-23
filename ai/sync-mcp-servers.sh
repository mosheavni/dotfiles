#!/bin/bash

# Sync MCP servers configuration from mcphub to Claude configuration
# Source of truth: .config/mcphub/servers.json (edit via nvim UI)
# Target: ~/.claude.json (user-scoped MCP servers available across all projects)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/.config/mcphub/servers.json"
TARGET_FILE="$SCRIPT_DIR/.claude.json"

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

# Check if target file exists
if [ ! -f "$TARGET_FILE" ]; then
  echo "Warning: Target file $TARGET_FILE not found" >&2
  exit 1
fi

# Extract mcpServers from source
SOURCE_MCP=$(jq '.mcpServers' "$SOURCE_FILE")

# Check if mcpServers in target matches source
CURRENT_TARGET_MCP=$(jq '.mcpServers' "$TARGET_FILE")

if [ "$SOURCE_MCP" = "$CURRENT_TARGET_MCP" ]; then
  # Already in sync, exit silently
  exit 0
fi

# Update target with synced mcpServers (preserves all other fields)
jq --argjson mcp "$SOURCE_MCP" '.mcpServers = $mcp' "$TARGET_FILE" >"$TARGET_FILE.tmp"

# Replace target file
mv "$TARGET_FILE.tmp" "$TARGET_FILE"

echo "✓ Synced MCP servers from mcphub to ~/.claude.json"
