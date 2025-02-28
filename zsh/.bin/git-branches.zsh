#!/bin/zsh

setopt LOCAL_OPTIONS PIPE_FAIL ERR_EXIT

current_branch=$(git symbolic-ref -q --short HEAD || :)

print_remote_or_local() {
  local branch_name=$1
  local branch_name_no_remotes=${branch_name#remotes/origin/}
  [[ "$branch_name_no_remotes" == "$current_branch" ]] && return

  if [[ $branch_name == remotes/* ]]; then
    if [[ ! ${local_branches[(r)$branch_name_no_remotes]} ]]; then
      print -P "%F{red}  ${branch_name}%f"
    fi
  else
    print "  $branch_name"
  fi
}

all_branches=("${(@f)$(git branch --all --sort=-committerdate | grep -v "^\*\|HEAD" | tr -d " ")}")
local_branches=("${(@f)$(git branch --format="%(refname:short)")}")

print_remote_or_local $all_branches[1]
[[ -n "$current_branch" ]] && print -P "%F{green}*%f $current_branch"

# Process remaining branches without parallel
for branch in "${(@)all_branches[@]:1}"; do
  print_remote_or_local $branch
done
