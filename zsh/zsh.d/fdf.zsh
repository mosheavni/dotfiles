#!/usr/bin/env zsh

function fdf() {
  (($# != 1)) && {
    print "Usage: $0 <directory>"
    exit 1
  }

  base_dir=$1
  # Get all directories with maxdepth 0
  dirs=("$base_dir"/*(/))

  # Get wezterm panes with nvim - using read to avoid subprocess
  wezterm_json=$(wezterm cli list --format json)
  typeset -A pane_map
  while IFS=$'\t' read -r title pane_id; do
    pane_map[${title#nvim: }]=$pane_id
  done < <(print $wezterm_json | jq -r '.[] | select(.title | startswith("nvim: ")) | "\(.title)\t\(.tab_id)~\(.pane_id)"')

  # Process each directory
  for dir in $dirs; do
    dir_name=${dir:t}
    icon=${pane_map[$dir_name]:+ }
    icon=${icon:-  }
    print -f "%s%s\t%s\t%s\n" $icon $dir_name $dir ${pane_map[$dir_name]:-}
  done | fzf -d $'\t' --with-nth 1 | while IFS=$'\t' read -r _ full_dir tab_pane; do
    if [[ -n $tab_pane ]]; then
      tab_id=$(echo $tab_pane | cut -d'~' -f1)
      pane_id=$(echo $tab_pane | cut -d'~' -f2)
      wezterm cli activate-tab --tab-id "$tab_id"
      wezterm cli activate-pane --pane-id "$pane_id"
    else
      cd "$full_dir" && nvim
    fi
  done
}
