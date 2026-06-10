#!/bin/zsh
[[ -n "$LOADED_AWS_PROFILE" ]] && return

: ${AWS_PROFILE_ENV:=$HOME/.aws/profile.env}

_aws_profile_load() {
  [[ -r $AWS_PROFILE_ENV ]] && source $AWS_PROFILE_ENV
}

_aws_profile_save() {
  local profile=$1
  if [[ $profile == default ]]; then
    [[ -f $AWS_PROFILE_ENV ]] && rm -f $AWS_PROFILE_ENV
  else
    mkdir -p "${AWS_PROFILE_ENV:h}"
    print -r -- "export AWS_PROFILE=${(q)profile}" >|$AWS_PROFILE_ENV
  fi
}

_aws_profile_account() {
  local profile=$1
  local account role_arn

  account=$(aws configure get sso_account_id --profile "$profile" 2>/dev/null)
  [[ -n $account && $account != None ]] && print -r -- "$account" && return 0

  role_arn=$(aws configure get role_arn --profile "$profile" 2>/dev/null)
  if [[ -n $role_arn && $role_arn != None ]]; then
    account=${${(s.:.)role_arn}[5]}
    [[ -n $account ]] && print -r -- "$account" && return 0
  fi

  account=$(aws sts get-caller-identity --profile "$profile" --query Account --output text 2>/dev/null)
  [[ -n $account && $account != None ]] && print -r -- "$account" && return 0

  print -r -- '?'
}

function aws-profile() {
  emulate -L zsh -o err_return -o pipefail

  command -v aws >/dev/null 2>&1 || {
    echo "aws CLI not found" >&2
    return 1
  }
  command -v fzf >/dev/null 2>&1 || {
    echo "fzf not found" >&2
    return 1
  }

  local -a profiles lines
  local profile account selected current marker line

  profiles=("${(@f)$(aws configure list-profiles 2>/dev/null)}")
  if ((${#profiles} == 0)); then
    echo "No AWS profiles found in ~/.aws/config or ~/.aws/credentials" >&2
    return 1
  fi

  current=${AWS_PROFILE:-default}
  lines=()
  for profile in "${profiles[@]}"; do
    account=$(_aws_profile_account "$profile")
    marker='  '
    [[ $profile == "$current" ]] && marker='* '
    line="${profile}"$'\t'"$(printf '%s%-14s  %s' "$marker" "$account" "$profile")"
    lines+=("$line")
  done

  selected=$(printf '%s\n' "${lines[@]}" | fzf --delimiter=$'\t' --with-nth=2 --prompt='AWS Profile> ' --header='  account         profile (* = current)')
  [[ -z $selected ]] && return 1

  profile=${selected%%$'\t'*}

  if [[ $profile == default ]]; then
    unset AWS_PROFILE
    _aws_profile_save default
    echo "AWS_PROFILE unset (using default profile)"
  else
    export AWS_PROFILE=$profile
    _aws_profile_save "$profile"
    echo "AWS_PROFILE=$AWS_PROFILE"
  fi
}

_aws_profile_load

export LOADED_AWS_PROFILE=true
