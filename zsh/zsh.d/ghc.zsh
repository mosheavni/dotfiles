function ghc() {
  # Validate gh CLI is available
  if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    return 1
  fi

  local org="${1:-${GIT_DEFAULT_ORG:-mosheavni}}"

  local selected
  selected=$(
    echo "" | fzf \
      --disabled \
      --ansi \
      --prompt="Search $org> " \
      --header="Type to search repositories • ✓ = already cloned • Enter: clone • Ctrl-O: open • Ctrl-Y: copy URL" \
      --delimiter=$'\t' \
      --with-nth=1,2,3,4,5 \
      --preview='repo=$(echo {2} | xargs); desc=$(echo {6} | xargs); lang=$(echo {4} | xargs); stars=$(echo {5} | xargs); echo "Repository: $repo"; echo ""; echo "Description: $desc"; echo "Language: $lang"; echo "Stars: ⭐ $stars"; echo ""; echo "URL: https://github.com/$repo"' \
      --preview-window='down:40%:wrap' \
      --bind="change:reload:sleep 0.2; [ -n {q} ] && gh search repos {q} --owner $org --limit 50 --json fullName,description,language,stargazersCount 2>/dev/null | jq -r '.[] | [.fullName, (if .description and .description != \"\" then .description else \"-\" end), (.language // \"N/A\"), .stargazersCount] | @tsv' | while IFS=\$'\\t' read -r fullName desc lang stars; do repo_name=\"\${fullName#*/}\"; icon=\" \"; [[ -d ~/Repos/\"\$repo_name\" ]] && icon=\"✓\"; desc_short=\"\${desc:0:55}\"; printf \"%s\\t%-50s\\t%-55s\\t%-12s\\t%s\\t%s\\n\" \"\$icon\" \"\$fullName\" \"\$desc_short\" \"\$lang\" \"\$stars\" \"\$desc\"; done || echo ''" \
      --bind='ctrl-/:toggle-preview' \
      --bind="ctrl-o:execute-silent(repo=\$(echo {2} | xargs); open https://github.com/\$repo)" \
      --bind="ctrl-y:execute-silent(repo=\$(echo {2} | xargs); echo https://github.com/\$repo | pbcopy)+abort" |
      awk -F'\t' '{print $2}' | xargs
  )

  # If user selected something, clone it
  if [[ -n "$selected" ]]; then
    clone "$selected"
  fi
}
