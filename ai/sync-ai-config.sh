#!/bin/bash

# Maintain local AI tooling configuration.
#
# - MCP servers (mcphub → Claude + Cursor)
# - Karpathy agent guidelines (remote → AGENTS.md + agents.mdc)
# - Cursor CLI policy (cli-config.base.json → ~/.cursor/cli-config.json)
# - Superpowers plugin (~/.cursor/plugins/local/superpowers)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly MCPHUB_SOURCE="${SCRIPT_DIR}/.config/mcphub/servers.json"
readonly CLAUDE_MCP_TARGET="${SCRIPT_DIR}/.claude.json"
readonly CURSOR_MCP_TARGET="${HOME}/.cursor/mcp.json"
readonly CLI_CONFIG_BASE="${SCRIPT_DIR}/.cursor/cli-config.base.json"
readonly CLI_CONFIG_TARGET="${HOME}/.cursor/cli-config.json"
readonly SUPERPOWERS_REPO="${HOME}/.cursor/plugins/local/superpowers"
readonly SUPERPOWERS_REMOTE="https://github.com/obra/superpowers.git"
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

# --- MCP servers (mcphub is source of truth) ---------------------------------

read_mcphub_servers() {
  if [ ! -f "$MCPHUB_SOURCE" ]; then
    echo "Warning: Source file ${MCPHUB_SOURCE} not found" >&2
    return 1
  fi

  jq '.mcpServers' "$MCPHUB_SOURCE"
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
  local source_mcp current_mcp

  ensure_mcp_target_file "$target_file" "$create_if_missing" || return "$SYNC_ERROR"

  source_mcp="$(read_mcphub_servers)" || return "$SYNC_ERROR"
  current_mcp="$(jq '.mcpServers' "$target_file")"

  if [ "$source_mcp" = "$current_mcp" ]; then
    return "$SYNC_UNCHANGED"
  fi

  write_file_atomically "$target_file" "$(jq --argjson mcp "$source_mcp" '.mcpServers = $mcp' "$target_file")"
  echo "✓ Synced MCP servers from mcphub to ${display_name}"
  return "$SYNC_UPDATED"
}

sync_all_mcp_servers() {
  local claude_result cursor_result

  set +e
  sync_mcp_servers_into "$CLAUDE_MCP_TARGET" "${HOME}/.claude.json" false
  claude_result=$?
  sync_mcp_servers_into "$CURSOR_MCP_TARGET" "${HOME}/.cursor/mcp.json" true
  cursor_result=$?
  set -e

  if [ "$claude_result" -eq "$SYNC_ERROR" ] && [ "$cursor_result" -eq "$SYNC_ERROR" ]; then
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
  sync_remote_file \
    "${KARPATHY_BASE}/.cursor/rules/karpathy-guidelines.mdc" \
    "${SCRIPT_DIR}/.cursor/rules/agents.mdc" \
    "ai/.cursor/rules/agents.mdc"
  set -e
}

# --- Cursor CLI config (base → live, preserve machine-local cache) ---------------

merge_cursor_cli_config() {
  local merged

  if [ ! -f "$CLI_CONFIG_BASE" ]; then
    echo "Warning: ${CLI_CONFIG_BASE} not found" >&2
    return "$SYNC_ERROR"
  fi

  mkdir -p "$(dirname "$CLI_CONFIG_TARGET")"

  if [ ! -f "$CLI_CONFIG_TARGET" ]; then
    cp "$CLI_CONFIG_BASE" "$CLI_CONFIG_TARGET"
    echo "✓ Created ${CLI_CONFIG_TARGET} from cli-config.base.json"
    return "$SYNC_UPDATED"
  fi

  merged="$(
    jq --slurpfile base "$CLI_CONFIG_BASE" '
      .permissions = $base[0].permissions |
      .editor = $base[0].editor |
      .display = $base[0].display |
      .notifications = $base[0].notifications |
      .hints = $base[0].hints |
      .rewind = $base[0].rewind |
      .suggestNextPrompt = $base[0].suggestNextPrompt |
      .network = $base[0].network |
      .approvalMode = $base[0].approvalMode |
      .sandbox = $base[0].sandbox |
      .attribution = $base[0].attribution |
      .version = $base[0].version
    ' "$CLI_CONFIG_TARGET"
  )" || return "$SYNC_ERROR"

  if [ "$(cat "$CLI_CONFIG_TARGET")" = "$merged" ]; then
    return "$SYNC_UNCHANGED"
  fi

  write_file_atomically "$CLI_CONFIG_TARGET" "$merged"
  echo "✓ Merged dotfiles policy into ${CLI_CONFIG_TARGET}"
  return "$SYNC_UPDATED"
}

# --- Superpowers plugin (git pull) ---------------------------------------------

sync_superpowers_plugin() {
  if [ ! -d "$SUPERPOWERS_REPO/.git" ]; then
    mkdir -p "$(dirname "$SUPERPOWERS_REPO")"
    git clone "$SUPERPOWERS_REMOTE" "$SUPERPOWERS_REPO" || {
      echo "Warning: Failed to clone superpowers to ${SUPERPOWERS_REPO}" >&2
      return "$SYNC_ERROR"
    }
    echo "✓ Cloned superpowers to ${SUPERPOWERS_REPO}"
    return "$SYNC_UPDATED"
  fi

  local before after
  before="$(git -C "$SUPERPOWERS_REPO" rev-parse HEAD)"
  git -C "$SUPERPOWERS_REPO" pull --ff-only -q || {
    echo "Warning: Failed to update superpowers in ${SUPERPOWERS_REPO}" >&2
    return "$SYNC_ERROR"
  }
  after="$(git -C "$SUPERPOWERS_REPO" rev-parse HEAD)"

  if [ "$before" = "$after" ]; then
    return "$SYNC_UNCHANGED"
  fi

  echo "✓ Updated superpowers (${before:0:7} → ${after:0:7})"
  return "$SYNC_UPDATED"
}

record_last_sync() {
  date >"$LAST_SYNC_FILE"
}

main() {
  require_commands jq curl git || exit 1

  sync_all_mcp_servers
  sync_karpathy_guidelines
  set +e
  merge_cursor_cli_config
  sync_superpowers_plugin
  set -e
  record_last_sync
}

main "$@"
