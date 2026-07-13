#!/bin/zsh
# Poll GitHub unread notifications and surface them as native macOS notifications.
# Depends only on gh (with built-in --jq) and terminal-notifier.

GH=/opt/homebrew/bin/gh
TN=/opt/homebrew/bin/terminal-notifier
STATE_DIR="$HOME/.cache/gh-notify"
mkdir -p "$STATE_DIR"

# Each unread thread -> id, updated_at, repo, title, type, reason, subject_url (tab-separated).
"$GH" api notifications \
  --jq '.[] | [.id, .updated_at, .repository.full_name, .subject.title, .subject.type, .reason, (.subject.url // "")] | @tsv' \
  2>>"$STATE_DIR/error.log" |
while IFS=$'\t' read -r id updated repo title type reason subject_url; do
  [ -z "$id" ] && continue
  # Key on id + updated_at so renewed activity on a thread re-notifies once.
  marker="$STATE_DIR/${id}_${updated//[:T]/-}"
  [ -f "$marker" ] && continue
  # Convert the API subject URL into a browsable web URL, e.g.
  # https://api.github.com/repos/OWNER/REPO/pulls/123 -> https://github.com/OWNER/REPO/pull/123
  # Fall back to the notifications inbox when there's no linkable subject.
  open_url="https://github.com/notifications"
  if [ -n "$subject_url" ]; then
    open_url="${subject_url/https:\/\/api.github.com\/repos\//https://github.com/}"
    open_url="${open_url/\/pulls\///pull/}"
  fi
  "$TN" \
    -title "GitHub · $repo" \
    -subtitle "$type · $reason" \
    -message "$title" \
    -open "$open_url" \
    -group "gh-$id" \
    -sound default
  : > "$marker"
done

# Forget markers older than 30 days so the cache dir stays small.
find "$STATE_DIR" -type f -name '*_*' -mtime +30 -delete 2>/dev/null
