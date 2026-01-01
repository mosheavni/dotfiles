function _alias_parser() {
  local type=$(whence -w -- "$1" 2>/dev/null)
  [[ $type == *": alias" || $type == *": global alias" ]] && whence -- "$1" 2>/dev/null
}

function _alias_finder() {
  local -a final_result words
  local alias_val
  words=(${(z)1})

  for s in $words; do
    alias_val=$(_alias_parser "$s")
    if [[ -n $alias_val ]]; then
      if [[ $alias_val == *"$s"* ]]; then
        final_result+=(${(z)alias_val})
      else
        final_result+=(${(z)$(_alias_finder "$alias_val")})
      fi
    else
      final_result+=($s)
    fi
  done
  print -r -- "${final_result[*]}"
}

# Widget function to expand aliases in the current command line
function expand-aliases-widget() {
  [[ -z $BUFFER ]] && return

  BUFFER=$(_alias_finder "$BUFFER")
  CURSOR=$#BUFFER
}

# Create the widget
zle -N expand-aliases-widget

bindkey '^X^A' expand-aliases-widget
