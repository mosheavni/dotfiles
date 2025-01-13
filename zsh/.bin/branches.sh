#!/bin/bash

current_branch=$(git branch --show-current)

print_remote_or_local() {
  branch_name=$1
  branch_name_no_remotes=$(sed -E 's/remotes\/[^\/]*\///' <<<"$branch_name")
  [[ "$branch_name_no_remotes" == "$current_branch" ]] && return
  if [[ $branch_name == *"remotes/"* ]]; then
    # if ! grep -q "$branch_name_no_remotes" <<<"$local_branches"; then
    #   echo -e "\033[31m$branch_name\033[0m"
    # fi
    [[ ! $local_branches =~ $branch_name_no_remotes ]] &&
      echo -e "  \033[31m$branch_name\033[0m"
  else
    echo "  $branch_name"
  fi
}
export -f print_remote_or_local

all_other_branches=$(git branch --all --sort=-committerdate | grep -v "^\*\|HEAD" | tr -d " ")
local_branches=$(git branch --format="%(refname:short)")
first_branch=$(head -n1 <<<"$all_other_branches")
remaining_branches=$(tail -n +2 <<<"$all_other_branches")

# Print in desired order
print_remote_or_local "$first_branch"
echo -e "\033[32m*\033[0m $current_branch"

export current_branch
export local_branches
echo "$remaining_branches" | parallel -k print_remote_or_local
