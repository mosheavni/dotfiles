#!/bin/zsh
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
    echo $* | say -v 'Carmit (Enhanced)'
  fi
}

function set-tab-title() {
  title=$(dialog -t "Set tab title" -m "Enter the title for the tab" --bannertext Set --textfield title,required 2>/dev/null | awk -F: '{print $2}')
  echo -e "\033]0;${title}\a"
}

### Helper functions ###
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

### Random functions ###
function mwatch() {
  # log_file=/tmp/moshe_mwatch.log
  # [[ -f $log_file ]] && cat /dev/null > $log_file || touch $log_file
  final_alias=$(_alias_finder "$*")
  echo $final_alias
  watch "$final_alias"
}

function clone() {
  cd ~/Repos
  git clone $1
  cd "$(basename "$_" .git)"
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

### Kubernetes functions ###
function kdpw() {
  n_lines=$(tput lines)
  # desired_lines is n_lines minus 2
  desired_lines=$((n_lines - 2))
  watch "kubectl describe po $* | tail -${desired_lines}"
}

function grafana_web() {
  grafana_ingress=$(kubectl get ingress -n monitoring --no-headers -o custom-columns=":metadata.name" | grep -m1 grafana)
  ingress_host=$(kubectl get ingress -n monitoring "${grafana_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n monitoring grafana-credentials -ojson | jq '.data | with_entries(.value |= @base64d)')
  echo "${creds}"
  jq -r '.password' <<<"${creds}" | pbcopy
  open "https://${ingress_host}"
}

function cerebro_web() {
  cerebro_ingress=$(kubectl get ingress -l app=cerebro -A -ojson | jq -r '.items[].spec.rules[0].host')
  open https://${cerebro_ingress}
}

function kibana_web() {
  kibana_ingress=$(kubectl get ingress -n elastic --no-headers -o custom-columns=":metadata.name" | grep kb-ingress)
  ingress_host=$(kubectl get ingress -n elastic "${kibana_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n elastic logs-es-elastic-user -ojson | jq '.data | with_entries(.value |= @base64d)')
  echo "${creds}"
  jq -r '.elastic' <<<"${creds}" | pbcopy
  open "https://${ingress_host}"
}

function argocd_web() {
  argocd_ingress=$(kubectl get ingress -n argocd --no-headers -o custom-columns=":metadata.name" | grep argocd-server)
  ingress_host=https://$(kubectl get ingress -n argocd "${argocd_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq '.data | with_entries(.value |= @base64d)')

  # port forward
  if [[ -n $1 ]] && [[ $1 == "-f" ]]; then
    set -x
    kubectl port-forward -n argocd svc/argocd-server 8080:443 &
    CMDPID=$!
    set +x
    ingress_host="http://localhost:8080"
    echo "waiting for port-forward to start"
    while ! lsof -nP -iTCP:8080 | grep LISTEN; do
      echo "port 8080 is still not open"
      sleep 1
    done
    echo "Port forward for svc/argocd-server started on port 8080"
    echo "To kill, run 'kill $CMDPID' or exit the shell"
  fi
  echo "${creds}"
  jq -r '.password' <<<"${creds}" | pbcopy
  open "${ingress_host}"
}

function argocd_login() {
  argocd_ingress=$(kubectl get ingress -n argocd --no-headers -o custom-columns=":metadata.name" | grep argocd-server)
  ingress_host=$(kubectl get ingress -n argocd "${argocd_ingress}" -ojson | jq -r '.spec.rules[].host')
  pass=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq -r '.data | with_entries(.value |= @base64d) | .password')
  argocd login "${ingress_host}" --username admin --password "${pass}"
}

function kgres() {
  kubectl get pod $* \
    -ojsonpath='{range .items[*]}{.spec.containers[*].name}{" memory: "}{.spec.containers..resources.requests.memory}{"/"}{.spec.containers..resources.limits.memory}{" | cpu: "}{.spec.containers..resources.requests.cpu}{"/"}{.spec.containers..resources.limits.cpu}{"\n"}{end}' | sort \
    -u \
    -k1,1 | column -t
}

function kubedebug() {
  # image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
  local image=mosheavni/net-debug:latest
  local docker_exe=bash
  local pod_name=debug
  local kubectl_args=()
  local processing_k_args=false
  local sa_override
  while test $# -gt 0; do
    if $processing_k_args; then
      kubectl_args=($kubectl_args $1)
      shift
      continue
    fi

    case $1 in
    -h | --help)
      echo "Usage: $0 [-e executable] [-p pod_name] [-i image] [-s service_account] [-- kubernetes_arguments]"
      echo "  -e  executable        Executable to run in the pod"
      echo "  -p  pod_name          Pod name"
      echo "  -i  image             Docker image to run"
      echo "  -s  service_account   Service account to use"
      echo "  --  kubectl arguments"
      return
      ;;
      # exe provided
    -e)
      shift
      docker_exe=$1
      ;;
    -p)
      shift
      pod_name=$1
      ;;
    -i)
      shift
      image=$1
      ;;
    -s)
      shift
      sa_override=--overrides="{ \"spec\": { \"serviceAccount\": \"$1\" } }"
      ;;
    *)
      if [[ "$1" == "--" ]]; then
        processing_k_args=true
      fi
      ;;
    esac
    shift
  done

  set -x
  kubectl run \
    -i \
    --rm \
    --tty \
    --image=$image \
    --restart=Never \
    $sa_override \
    ${kubectl_args[*]} \
    $pod_name \
    -- \
    $docker_exe
  set +x
}

function get_pods_of_svc() {
  svc_name=$1
  shift
  label_selectors=$(kubectl get svc $svc_name $* -ojsonpath="{.spec.selector}" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" | paste -s -d "," -)
  kubectl get pod $* -l $label_selectors
}

function kgel() {
  if [[ -z $1 ]]; then
    echo "Usage: $0 <pod_name>"
    return
  fi
  kubectl get pod $* -ojson | jq -r '.metadata.labels | to_entries | .[] | "\(.key)=\(.value)"'
}

function asdf-kubectl-version() {
  K8S_VERSION=$(kubectl version -ojson | jq -r '.serverVersion | "\(.major).\(.minor)"' | sed 's/\+$//')
  TO_INSTALL=$(asdf list-all kubectl | grep "${K8S_VERSION}" | tail -1)
  if ! asdf list kubectl "${TO_INSTALL}" &>/dev/null; then
    asdf install kubectl "${TO_INSTALL}"
  fi
  asdf global kubectl "${TO_INSTALL}"
}


function mkdp() {
  kubectl get pod --no-headers | fzf | awk '{print $1}' | xargs -n 1 kubectl describe pod
}

function mklf() {
  substring=$1
  if [[ -z $substring ]]; then
    substring='.*'
  fi
  deployment=$(kubectl get deploy,sd --no-headers | grep $substring | fzf | awk '{print $1}')

  pod_labels=$(kubectl get $deployment -ojsonpath='{.spec.template.metadata.labels}' | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" | paste -s -d "," -)

  pod_or_all=$(echo -e "$(kubectl get pod --no-headers -l "$pod_labels")\nAll" | fzf | awk '{print $1}')

  since=$(echo -e "All\n1h\n1d\n1w\n1m\n1y" | fzf)

  if [[ $since == "All" ]]; then
    since=""
  else
    since="--since=$since"
  fi

  set -x
  if [[ $pod_or_all == "All" ]]; then
    kubectl logs -f -l $pod_labels $since
  else
    kubectl logs -f $pod_or_all $since
  fi
  set +x
}

# debug nvim startup time
function nvim-startuptime() {
  cat /dev/null >startuptime.txt && nvim --startuptime startuptime.txt "$@"
}

function zip-code() {
  ZIP_CODE=$(curl -s 'https://www.zipy.co.il/api/findzip/getZip' -H 'content-type: text/plain;charset=UTF-8' -H 'referer: https://www.zipy.co.il/%D7%9E%D7%99%D7%A7%D7%95%D7%93/' --data-raw '{"city":"תל אביב","street":"פלורנטין","house":"2","remote":true}' | jq -r '.result.zip')
  echo "$ZIP_CODE"
  echo "$ZIP_CODE" | pbcopy
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

function man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

export LOADED_FUNCTIONS=true
