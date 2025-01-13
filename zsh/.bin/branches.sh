#!/bin/bash

current_branch=$(git branch --show-current)
all_other_branches=$(git branch --all --color --sort=-committerdate | grep -v "^\*" | grep -v "HEAD")

# Get the first branch from all_other_branches
first_branch=$(echo "$all_other_branches" | head -n1)
# Get the remaining branches
remaining_branches=$(echo "$all_other_branches" | tail -n +2)

# Print in desired order
echo "$first_branch"
echo -e "\033[32m*\033[0m $current_branch"
echo "$remaining_branches"
