#!/bin/zsh
# Poll GitHub unread notifications and surface them as native macOS notifications.
# Depends only on gh (with built-in --jq) and terminal-notifier.

GH=/opt/homebrew/bin/gh
TN=/opt/homebrew/bin/terminal-notifier
STATE_DIR="$HOME/.cache/gh-notify"
mkdir -p "$STATE_DIR"

# Each unread thread -> id, updated_at, repo, title, type, reason (tab-separated).
"$GH" api notifications \
  --jq '.[] | [.id, .updated_at, .repository.full_name, .subject.title, .subject.type, .reason] | @tsv' \
  2>>"$STATE_DIR/error.log" |
while IFS=$'\t' read -r id updated repo title type reason; do
  [ -z "$id" ] && continue
  # Key on id + updated_at so renewed activity on a thread re-notifies once.
  marker="$STATE_DIR/${id}_${updated//[:T]/-}"
  [ -f "$marker" ] && continue
  "$TN" \
    -title "GitHub · $repo" \
    -subtitle "$type · $reason" \
    -message "$title" \
    -open "https://github.com/notifications" \
    -group "gh-$id" \
    -sound default
  : > "$marker"
done

# Forget markers older than 30 days so the cache dir stays small.
find "$STATE_DIR" -type f -name '*_*' -mtime +30 -delete 2>/dev/null
