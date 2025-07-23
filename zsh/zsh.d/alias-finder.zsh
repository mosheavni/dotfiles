function _alias_parser() {
  parsed_alias=$(alias -- "$1")
  if [[ $? == 0 ]]; then
    echo $parsed_alias | awk -F\' '{print $2}'
  fi
}

function _alias_finder() {
  final_result=()
  for s in $(echo $1); do
    alias_val=$(_alias_parser "$s")
    if [[ -n $alias_val ]]; then
      # Handle nested aliases with the same name
      if [[ $alias_val == *"$s"* ]]; then
        final_result+=($alias_val)
      else
        final_result+=($(_alias_finder "$alias_val"))
      fi
    else
      final_result+=($s)
    fi
  done
  echo "${final_result[@]}"
}

# Widget function to expand aliases in the current command line
function expand-aliases-widget() {
  # Get the current buffer (command line content)
  local current_buffer="$BUFFER"

  # Skip if buffer is empty
  if [[ -z "$current_buffer" ]]; then
    return
  fi

  # Pass the buffer through _alias_finder
  local expanded_command=$(_alias_finder "$current_buffer")

  # Replace the buffer with the expanded command
  BUFFER="$expanded_command"

  # Move cursor to the end of the line
  CURSOR=$#BUFFER
}

# Create the widget
zle -N expand-aliases-widget

bindkey '^X^A' expand-aliases-widget

