#!/bin/zsh
# Guard against re-loading
[[ -n "$LOADED_FUNCTIONS" ]] && return

function take() {
  [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"
}

function delete-zcompdump() {
  rm -f ~/.cache/zsh/zcomp*
  rm -f ~/.zcompdump*
}

function say-hebrew() {
  # check if there's params
  if [[ -z $* ]]; then
    dialog -t "Say in hebrew" -m "Enter a sentence in hebrew" --bannertext Say --textfield message,required 2>/dev/null | awk -F: '{print $2}' | xargs say -v 'Carmit (Enhanced)'
  else
    echo $* | say -v 'Carmit'
  fi
}

function set-tab-title() {
  title=$(dialog -t "Set tab title" -m "Enter the title for the tab" --bannertext Set --textfield title,required 2>/dev/null | awk -F: '{print $2}')
  echo -e "\033]0;${title}\a"
}

function pj() {
    fdf "$(sed 's/,/ /g' <<<"${PJ_DIRS:-~/Repos/,~/.dotfiles}")"
}

### Random functions ###
function mwatch() {
  # log_file=/tmp/moshe_mwatch.log
  # [[ -f $log_file ]] && cat /dev/null > $log_file || touch $log_file
  final_alias=$(_alias_finder "$*")
  echo $final_alias
  watch "$final_alias"
}

function ecr-login() {
  [[ -n "$DEBUG" ]] && set -x
  region=$1
  if [[ -z $region ]]; then
    region=$(aws configure get region --output text)
  fi
  aws ecr get-login-password \
    --region $region | docker login \
    --username AWS \
    --password-stdin $(aws sts get-caller-identity | jq \
      -r ".Account").dkr.ecr.${region}.amazonaws.com
  [[ -z $1 ]] && aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
  [[ -n "$DEBUG" ]] && set +x
}

function clone() {
  cd ~/Repos
  REPO=$1
  CD_INTO=$REPO
  # check if $REPO starts with git@ or https://
  if [[ $REPO == git@* || $REPO == https://* ]]; then
    git clone $REPO
    CD_INTO=$(sed 's/\.git$//' <<<"$REPO" | awk -F/ '{print $NF}')
  else
    # check if $REPO is in user/repo format
    if [[ $REPO == */* ]]; then
      git clone https://github.com/${REPO}.git
      CD_INTO=$(awk -F'/' '{print $2}' <<<$REPO)
    else
      # Use GIT_DEFAULT_ORG environment variable
      GIT_DEFAULT_ORG="${GIT_DEFAULT_ORG:-spotinst-private}"
      git clone git@github.com:${GIT_DEFAULT_ORG}/${1}.git
    fi
  fi
  echo "CDing into $CD_INTO"
  cd $CD_INTO
  nvim
}

function gitcd() {
  cd $(git rev-parse --show-toplevel)
}

function ssh2() {
  in_url=$(sed -E 's?ip-([0-9]*)-([0-9]*)-([0-9]*)-([0-9]*)?\1.\2.\3.\4?g' <<<"$1")
  echo $in_url
  ssh $in_url
}

function grl() {
  grep -rl $* .
}

function cnf() {
  open "https://command-not-found.com/$*"
}

function docker_build() {
  docker build . \
    --platform linux/amd64 $*
}

function docker_build_push() {
  docker_build --push $*
}

function docker_copy_between_regions() {
  # Function to copy Docker images between AWS ECR regions
  # Help message
  function print_help() {
    echo "Usage: docker_copy_between_regions -n IMAGE_NAME -t IMAGE_TAG -s SRC_REGION -d DEST_REGION"
    echo "  -n  IMAGE_NAME   Name of the Docker image"
    echo "  -t  IMAGE_TAG    Tag of the Docker image"
    echo "  -s  SRC_REGION   Source AWS region"
    echo "  -d  DEST_REGION  Destination AWS region"
  }

  # Parse parameters
  while getopts "n:t:s:d:h" opt; do
    case ${opt} in
    n) IMAGE_NAME=$OPTARG ;;
    t) IMAGE_TAG=$OPTARG ;;
    s) SRC_REGION=$OPTARG ;;
    d) DEST_REGION=$OPTARG ;;
    h)
      print_help
      return
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_help
      return
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      print_help
      return
      ;;
    esac
  done

  # Validate parameters
  if [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ] || [ -z "$SRC_REGION" ] || [ -z "$DEST_REGION" ]; then
    echo "Error: All parameters are required."
    print_help
    return
  fi

  # Get AWS account ID
  ACC_ID=$(aws sts get-caller-identity | jq -r ".Account")

  # Copy Docker image between regions
  echo "FROM $ACC_ID.dkr.ecr.${SRC_REGION}.amazonaws.com/spotinst-production/${IMAGE_NAME}:${IMAGE_TAG}" | docker_build_push \
    -t $ACC_ID.dkr.ecr.${DEST_REGION}.amazonaws.com/spotinst-production/${IMAGE_NAME}:${IMAGE_TAG} \
    -f -
}

# Open the github page of the repo you're in, in the browser
function opengit() {
  git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open
}

# Create pull request = cpr
function cpr() {
  git_remote=$(git remote -v | grep '(fetch)')
  git_remote_name=origin
  git_remote_url=$(awk '{print $2}' <<<"$git_remote")
  git_name=$(gsed -E 's?'$git_remote_name'\s*(git@|https://)(\w+).*?\2?g' <<<"$git_remote")
  project_name=$(gsed -E "s/.*com[:\/](.*)\/.*/\\1/" <<<"$git_remote")
  repo_name=$(gsed -E -e "s/.*com[:\/].*\/(.*).*/\\1/" -e "s/\.git\s*\((fetch|push)\)//" <<<"$git_remote")
  branch_name=$(git branch --show-current)

  if [[ $git_name == "gitlab" ]]; then
    pr_link="-/merge_requests/new?merge_request[source_branch]="
  else
    pr_link="/pull/new/"
  fi
  open "https://${git_name}.com/${project_name}/${repo_name}/${pr_link}${branch_name}"
}

# debug nvim startup time
function nvim-startuptime() {
  cat /dev/null >startuptime.txt && nvim --startuptime startuptime.txt "$@"
}

function zip-code() {
curl -s 'https://apimftprd.israelpost.co.il/mypost-zip/SearchZip' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: en-US,en;q=0.9,ru;q=0.8' \
  -H 'authorization: Bearer null' \
  -H 'content-type: application/json' \
  -H 'ocp-apim-subscription-key: 5ccb5b137e7444d885be752eda7f767a' \
  -H 'origin: https://doar.israelpost.co.il' \
  -H 'priority: u=1, i' \
  -H 'sec-ch-ua: "Chromium";v="142", "Google Chrome";v="142", "Not_A Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36' \
  --data-raw '{"CityID":"1212","StreetID":"104347","House":"2","Entry":"א","ByMaanimID":true}' | jq
}

function matrix() {
  lines=$(tput lines)
  cols=$(tput cols)

  awkscript='
    {
      letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*"

      lines=$1
      random_col=$3

      c=$4
      letter=substr(letters,c,1)

      cols[random_col]=0;

      for (col in cols) {
        line=cols[col];
        cols[col]=cols[col]+1;

        printf "\033[%s;%sH\033[2;32m%s", line, col, letter;
        printf "\033[%s;%sH\033[1;37m%s\033[0;0H", cols[col], col, letter;

        if (cols[col] >= lines) {
          cols[col]=0;
        }
      }
    }
  '

  echo -e "\e[1;40m"
  clear

  while :; do
    echo $lines $cols $(($RANDOM % $cols)) $(($RANDOM % 72))
    sleep 0.05
  done | awk "$awkscript"
}

export LOADED_FUNCTIONS=true
