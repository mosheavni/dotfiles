source <(fzf --zsh)
export FZF_CTRL_T_COMMAND='rg --color=never --files --hidden --follow -g "!.git"'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers,changes {}"'
export FZF_CTRL_R_OPTS="--ansi --color=hl:underline,hl+:underline --height 80% --preview 'echo {2..} | bat --color=always -pl bash' --preview-window 'down:4:wrap' --bind 'ctrl-/:toggle-preview'"

function fzf-rm() {
  if [[ "$#" -eq 0 ]]; then
    local files
    files=$(find . -maxdepth 1 -type f | fzf --multi)
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
    $MAN -k . | fzf --reverse --preview="echo {1,2} | sed 's/ (/./' | sed -E 's/\)\s*$//' | xargs $MAN" | awk '{print $1 "." $2}' | tr -d '()' | xargs -r $MAN
    return $?
  fi
}

function fzf-eval() {
  echo | fzf -q "$*" --preview-window=up:99% --preview="eval {q}"
}

function fzf-aliases-functions() {
  CMD=$(
    (
      (alias)
      (functions | grep "()" | cut -d ' ' -f1 | grep -v "^_")
    ) | fzf | cut -d '=' -f1
  )

  eval $CMD
}

function fzf-git-status() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "You are not in a git repository" && return
  }
  local selected
  selected=$(git -c color.status=always status --short |
    fzf --height 50% "$@" --border -m --ansi --nth 2..,.. \
      --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
    cut -c4- | sed 's/.* -> //')
  if [[ $selected ]]; then
    for prog in $(echo $selected); do
      $EDITOR $prog
    done
  fi
}
