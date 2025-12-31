# Cache FZF initialization for performance
FZF_ZSH_CACHE="${ZSH_CACHE_DIR}/fzf-init.zsh"
if [[ ! -f "$FZF_ZSH_CACHE" ]] || [[ $(find "$FZF_ZSH_CACHE" -mtime +30 2>/dev/null) ]]; then
  fzf --zsh >| "$FZF_ZSH_CACHE"
fi
source "$FZF_ZSH_CACHE"

export FZF_DEFAULT_OPTS='--height=100% --layout=reverse --border --info=inline --highlight-line'
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers,changes {}' --walker-skip .git,node_modules"
export FZF_CTRL_R_OPTS="--scheme=history --ansi --color=hl:underline,hl+:underline,header:italic --header 'Press CTRL-Y to copy command into clipboard' --preview 'echo {2..} | bat --color=always -pl bash' --preview-window 'down:4:wrap' --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --prompt='History> '"

function fzf-rm() {
  if [[ "$#" -eq 0 ]]; then
    local files
    files=$(find . -maxdepth 1 -type f | fzf --multi --prompt="Remove> ")
    echo $files | xargs -I '{}' rm {} #we use xargs to capture filenames with spaces in them properly
  else
    command rm "$@"
  fi
}

# Man without options will use fzf to select a page
function fzf-man() {
  MAN="/usr/bin/man"
  if [ -n "$1" ]; then
    $MAN "$@"
    return $?
  else
    $MAN -k . | fzf --preview="echo {1,2} | sed 's/ (/./' | sed -E 's/\)\s*$//' | xargs $MAN" --prompt="Man Pages> " | awk '{print $1 "." $2}' | tr -d '()' | xargs -r $MAN
    return $?
  fi
}

function fzf-eval() {
  echo | fzf -q "$*" --preview-window=up:99% --preview="eval {q}" --prompt="Eval> "
}

function fzf-aliases-functions() {
  CMD=$(
    (
      (alias)
      (functions | grep "()" | cut -d ' ' -f1 | grep -v "^_")
    ) | fzf --prompt="Commands> " | cut -d '=' -f1
  )

  eval "$CMD"
}

function fzf-git-status() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "You are not in a git repository" && return
  }
  local selected
  selected=$(git -c color.status=always status --short |
    fzf "$@" -m --ansi --nth 2..,.. \
      --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' \
      --prompt="Git Status> " |
    cut -c4- | sed 's/.* -> //')
  if [[ $selected ]]; then
    for prog in $(echo $selected); do
      $EDITOR $prog
    done
  fi
}

function ghc() {
  # Validate gh CLI is available
  if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    return 1
  fi

  local org="${1:-${GIT_DEFAULT_ORG:-spotinst-private}}"

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
      --bind="ctrl-y:execute-silent(repo=\$(echo {2} | xargs); echo https://github.com/\$repo | pbcopy)+abort" \
      | awk -F'\t' '{print $2}' | xargs
  )

  # If user selected something, clone it
  if [[ -n "$selected" ]]; then
    clone "$selected"
  fi
}
