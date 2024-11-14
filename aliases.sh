#!/bin/zsh

function take() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }

function say-hebrew() {
  # check if there's params
  if [[ -z $* ]]; then
    dialog -t "Say in hebrew" -m "Enter a sentence in hebrew" --bannertext Say --textfield message,required 2>/dev/null | awk -F: '{print $2}' | xargs say -v 'Carmit (Enhanced)'
  else
    echo $* | say -v 'Carmit (Enhanced)'
  fi
}
### Helper functions ###
function _alias_parser() {
  parsed_alias=`alias -- "$1"`
  if [[ $? == 0 ]]; then
    echo $parsed_alias | awk -F\' '{print $2}'
  fi
}

function _alias_finder() {
  final_result=()
  for s in `echo $1`;do
    alias_val=`_alias_parser "$s"`
    if [[ -n $alias_val ]]; then
      # Handle nested aliases with the same name
      if [[ $alias_val == *"$s"* ]]; then
        final_result+=($alias_val)
      else
        final_result+=(`_alias_finder "$alias_val"`)
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
  final_alias=`_alias_finder "$*"`
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
  in_url=$(sed -E 's?ip-([0-9]*)-([0-9]*)-([0-9]*)-([0-9]*)?\1.\2.\3.\4?g' <<< "$1")
  echo $in_url
  ssh $in_url
}

function grl() { grep -rl $* . }

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

### Git functions ###
# Open the github page of the repo you're in, in the browser
function opengit () { git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open }

# Create pull request = cpr
function cpr() {
  git_remote=$(git remote -v | grep '(fetch)')
  git_remote_name=$(awk '{print $1}' <<<"$git_remote")
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
function kdpw () {
  n_lines=$(tput lines)
  # desired_lines is n_lines minus 2
  desired_lines=$((n_lines - 2))
  watch "kubectl describe po $* | tail -${desired_lines}"
}

### Kubernetes find and watch pods ###
function mkgp () {
  python3 ~/.bin/mkgp.py $@
}

function mbkgp () {
  python3 ~/.bin/mkgp.py -v "1/1\|2/2\|3/3\|4/4\|5/5\|6/6\|Completed\|Evicted"
}

function grafana_web () {
  grafana_ingress=$(kubectl get ingress -n monitoring --no-headers -o custom-columns=":metadata.name" | grep -m1 grafana)
  ingress_host=$(kubectl get ingress -n monitoring "${grafana_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n monitoring grafana-credentials -ojson | jq '.data | with_entries(.value |= @base64d)')
  echo "${creds}"
  jq -r '.password' <<< "${creds}" | pbcopy
  open "https://${ingress_host}"
}

function cerebro_web() {
  cerebro_ingress=$(kubectl get ingress -l app=cerebro -A -ojson | jq -r '.items[].spec.rules[0].host')
  open https://${cerebro_ingress}
}

function kibana_web () {
  kibana_ingress=$(kubectl get ingress -n elastic --no-headers -o custom-columns=":metadata.name" | grep kb-ingress)
  ingress_host=$(kubectl get ingress -n elastic "${kibana_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n elastic logs-es-elastic-user -ojson | jq '.data | with_entries(.value |= @base64d)')
  echo "${creds}"
  jq -r '.elastic' <<< "${creds}" | pbcopy
  open "https://${ingress_host}"
}

function argocd_web () {
  argocd_ingress=$(kubectl get ingress -n argocd --no-headers -o custom-columns=":metadata.name" | grep argocd-server)
  ingress_host=https://$(kubectl get ingress -n argocd "${argocd_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq '.data | with_entries(.value |= @base64d)')

  # port forward
  if [[ -n $1 ]] && [[ $1 == "-f" ]];then
    set -x
    kubectl port-forward -n argocd svc/argocd-server 8080:443 & CMDPID=$!
    set +x
    ingress_host="http://localhost:8080"
    echo "waiting for port-forward to start"
    while ! lsof -nP -iTCP:8080 | grep LISTEN;do
      echo "port 8080 is still not open"
      sleep 1
    done
    echo "Port forward for svc/argocd-server started on port 8080"
    echo "To kill, run 'kill $CMDPID' or exit the shell"
  fi
  echo "${creds}"
  jq -r '.password' <<< "${creds}" | pbcopy
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

function kubedebug () {
  # image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
  local image=mosheavni/net-debug:latest
  local docker_exe=bash
  local pod_name=debug
  local kubectl_args=()
  local processing_k_args=false
  local sa_override
  while test $# -gt 0;do
    if $processing_k_args;then
      kubectl_args=($kubectl_args $1)
      shift
      continue
    fi

    case $1 in
      -h )
        echo "Usage: $0 [-e executable] [-p pod_name] [-i image] [-s service_account] [-- kubernetes_arguments]"
        return
        ;;
        # exe provided
      -e )
        shift
        docker_exe=$1
        ;;
      -p )
        shift
        pod_name=$1
        ;;
      -i )
        shift
        image=$1
        ;;
      -s )
        shift
        sa_override=--overrides="{ \"spec\": { \"serviceAccount\": \"$1\" } }"
        ;;
      * )
        if [[ "$1" == "--" ]];then
          processing_k_args=true
        fi
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
  if [[ -z $1 ]];then
    echo "Usage: $0 <pod_name>"
    return
  fi
  kubectl get pod $* -ojson | jq -r '.metadata.labels | to_entries | .[] | "\(.key)=\(.value)"'
}

### General aliases ###
alias watch='watch --color '
alias vim="nvim"
alias v='nvim'
alias vi='nvim'
alias sudoedit="nvim"
alias lvim='NVIM_APPNAME=LazyVim nvim'
alias sed=gsed
alias grep=ggrep
alias sort=gsort
alias awk=gawk
alias myip='curl ipv4.icanhazip.com'

alias dotfiles='cd ~/Repos/dotfiles'
alias dc='cd '

# global aliases
alias -g Wt='while :;do '
alias -g Wr=' | while read -r line;do echo "=== $line ==="; '
alias -g D=';done'
alias -g S='| sort'
alias -g SRT='+short | sort'
alias -g Sa='--sort-by=.metadata.creationTimestamp'
alias -g Srt='--sort-by=.metadata.creationTimestamp'
alias -g SECRET='-ojson | jq ".data | with_entries(.value |= @base64d)"'
alias -g IMG='-oyaml | sed -n '\''s/^\s*image:\s\(.*\)/\1/gp'\'' | sort -u'
alias -g YML='-oyaml | vim -c "set filetype=yaml | nnoremap <buffer> q :qall<cr>"'
alias -g NM=' --no-headers -o custom-columns=":metadata.name"'
alias -g RC='--sort-by=".status.containerStatuses[0].restartCount" -A | grep -v "\s0\s"'
alias -g BAD='| grep -v "1/1\|2/2\|3/3\|4/4\|5/5\|6/6\|Completed\|Evicted"'
alias -g IP='-ojsonpath="{.spec.nodeName}"'
alias -g dollar_1_line='$(awk "{print \$1}"<<<"${line}")'
alias -g dollar_2_line='$(awk "{print \$2}"<<<"${line}")'

### Git related ###
# see recently pushed branches
# alias gb="git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | fzf | xargs git checkout && git pull"
alias gb='git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2 | fzf | xargs git checkout'


### Shortcuts to directories ###
alias repos="~/Repos"
alias difff='code --diff'

# Common Used tools:
alias tf='terraform'
alias tg='terragrunt'

### Kubernetes Aliases ###
alias cinfo='kubectl cluster-info'
alias kafd='kubectl apply --validate=true --dry-run=true -f -'
alias kgdns="kubectl get services --all-namespaces -o jsonpath='{.items[*].metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}' | tr ' ' '\n'"
alias kns='kubens'
alias ctx='kubectx'
alias kmem='kubectl top node | (gsed -u 1q;sort -r -hk5)'
alias kcpu='kubectl top node | (gsed -u 1q;sort -r -hk3)'
alias ktn='kubectl top node'
alias ktp='kubectl top pod'
alias krs='kubectl rollout restart'
alias kesec='kubectl edit secret'
alias kgnol='kgno -l'
alias kg='kubectl get '
alias kd='kubectl describe '
alias ke='kubectl edit '
alias kdelrs='kubectl delete rs '
alias k8s='nvim +"lua require(\"kubectl\").open()"'

# Kubectl Persistent Volume
alias kgpv='kubectl get persistentvolume'
alias kdpv='kubectl describe persistentvolume'
alias kepv='kubectl edit persistentvolume'
alias kdelpv='kubectl delete persistentvolume'

alias kgevents='kubectl get event --sort-by=.metadata.creationTimestamp | grep -E -v "(Successfully (pulled|assigned)|(Started|Created) container|(Deleted|Created) pod)"'

asdf-kubectl-version() {
  K8S_VERSION=$(kubectl version -ojson | jq -r '.serverVersion | "\(.major).\(.minor)"' | sed 's/\+$//')
  TO_INSTALL=$(asdf list-all kubectl | grep "${K8S_VERSION}" | tail -1)
  if ! asdf list kubectl "${TO_INSTALL}" &> /dev/null;then
    asdf install kubectl "${TO_INSTALL}"
  fi
  asdf global kubectl "${TO_INSTALL}"
}

# fzf
fdf() {
  # remove trailing / from $1
  dir_clean=${1%/}
  all_files=$(find $dir_clean/* -maxdepth 0 -type d -print 2> /dev/null)
  dir_to_enter=$(sed "s?$dir_clean/??g" <<< $all_files | fzf)
  cd "$dir_clean/$dir_to_enter" && nvim
}
alias pj='fdf ~/Repos'

mkdp() {
  kubectl get pod --no-headers | fzf | awk '{print $1}' | xargs -n 1 kubectl describe pod
}

mklf() {
  substring=$1
  if [[ -z $substring ]];then
    substring='.*'
  fi
  deployment=$(kubectl get deploy,sd --no-headers | grep $substring | fzf | awk '{print $1}')

  pod_labels=$(kubectl get $deployment -ojsonpath='{.spec.template.metadata.labels}' | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" | paste -s -d "," -)

  pod_or_all=$(echo -e "$(kubectl get pod --no-headers -l "$pod_labels")\nAll" | fzf | awk '{print $1}')

  since=$(echo -e "All\n1h\n1d\n1w\n1m\n1y" | fzf)

  if [[ $since == "All" ]];then
    since=""
  else
    since="--since=$since"
  fi

  set -x
  if [[ $pod_or_all == "All" ]];then
    kubectl logs -f -l $pod_labels $since
  else
    kubectl logs -f $pod_or_all $since
  fi
  set +x
}

# debug nvim startup time
function nvim-startuptime() {
  cat /dev/null > startuptime.txt && nvim --startuptime startuptime.txt "$@"
}

zip-code ()
{
  ZIP_CODE=$(curl -s 'https://www.zipy.co.il/api/findzip/getZip' -H 'content-type: text/plain;charset=UTF-8' -H 'referer: https://www.zipy.co.il/%D7%9E%D7%99%D7%A7%D7%95%D7%93/' --data-raw '{"city":"תל אביב","street":"פלורנטין","house":"2","remote":true}' | jq -r '.result.zip')
  echo "$ZIP_CODE"
  echo "$ZIP_CODE" | pbcopy
}

alias update-nvim-nightly='asdf uninstall neovim nightly && asdf install neovim nightly'
