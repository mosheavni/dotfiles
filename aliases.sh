### Helper functions ###
function _alias_parser() {
  parsed_alias=`alias -- "$1"`
  if [[ $? == 0 ]]; then
    echo $parsed_alias | awk -F\' '{print $2}'
  fi
}

function _alias_finder() {
  # log_file=/tmp/moshe_mwatch.log
  # echo "Got in _alias_finder with $*" >> $log_file
  final_result=()
  for s in `echo $1`;do
    alias_val=`_alias_parser "$s"`
    if [[ -n $alias_val ]]; then
      # Handle nested aliases with the same name
      if [[ $alias_val == *"$s"* ]]; then
        # echo "$s is contained in $alias_val" >> $log_file
        final_result+=($alias_val)
      else
        final_result+=(`_alias_finder "$alias_val"`)
      fi
    else
      final_result+=($s)
    fi
  done
  echo "${final_result[@]}"
  # echo "final_result: ${final_result[@]}" >> $log_file
}

### Random functions ###
function mwatch() {
  # log_file=/tmp/moshe_mwatch.log
  # [[ -f $log_file ]] && cat /dev/null > $log_file || touch $log_file
  final_alias=`_alias_finder "$*"`
  echo $final_alias
  watch --color "$final_alias"
}

function docke () { [[ $1 == "r"* ]] && docker ${1#r} }
function ssh2 () {
  in_url=$(sed -E 's?ip-([0-9]*)-([0-9]*)-([0-9]*)-([0-9]*)?\1.\2.\3.\4?g' <<< "$1")
  echo $in_url
  ssh $in_url
}
function jsonlint () { pbcopy && open https://jsonlint.com/ }
function grl () { grep -rl $* . }

### Git functions ###
# Open the github page of the repo you're in, in the browser
function opengit () { git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open }

# Create pull request = cpr
function cpr() {
  git_remote=$(git remote -v | head -1)
  git_name=$(gsed -E 's?origin\s*(git@|https://)(\w+).*?\2?g' <<<"$git_remote")
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
function kdpw () { watch "kubectl describe po $* | tail -20" }

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

alias k_get_failed_pods='kubectl get pods --field-selector status.phase!=Running'
alias kgfp='k_get_failed_pods'

### General aliases ###
alias watch='watch --color '
alias vim="nvim"
alias v='nvim'
alias vi='nvim'
alias sudoedit="nvim"
alias sed=gsed
alias grep=ggrep
alias sort=gsort

alias dotfiles='cd ~/Repos/dotfiles'
alias dc='cd '

# global aliases
alias -g Wt='while :;do '
alias -g Wr=' | while read -r line;do '
alias -g D=';done'
alias -g S='| sort'
alias -g SRT='+short | sort'
alias -g Sa='--sort-by=.metadata.creationTimestamp'
alias -g Srt='--sort-by=.metadata.creationTimestamp'
alias -g SECRET='-ojson | jq ".data | with_entries(.value |= @base64d)"'
alias -g YML='-oyaml | vim -c "set filetype=yaml | nnoremap <buffer> q :qall<cr>"'
alias -g NM=' --no-headers -o custom-columns=":metadata.name"'
alias -g RC='--sort-by=".status.containerStatuses[0].restartCount" -A | grep -v "\s0\s"'

### Git related ###
# see recently pushed branches
# alias gb="git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | fzf | xargs git checkout && git pull"
alias gb='git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2 | fzf | xargs git checkout'


### Shortcuts to directories ###
alias repos="~/Repos"
alias difff='code --diff'

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
alias kgpname='kubectl get pod --no-headers -o custom-columns=":metadata.name"'
alias kgdname='kubectl get deployment --no-headers -o custom-columns=":metadata.name"'
alias kg='kubectl get '
alias kd='kubectl describe '
alias ke='kubectl edit '
alias kdel='kubectl delete '

# Kubectl Persistent Volume
alias kgpv='kubectl get persistentvolume'
alias kdpv='kubectl describe persistentvolume'
alias kepv='kubectl edit persistentvolume'
alias kdelpv='kubectl delete persistentvolume'

# Kubectl jobs
alias kgj='kubectl get job'
alias kdj='kubectl describe job'
alias kej='kubectl edit job'
alias kdelj='kubectl delete job'

# Kubectl Statefulsets
alias kgsts='kubectl get statefulsets'
alias kdsts='kubectl describe statefulsets'
alias kests='kubectl edit statefulsets'
alias kdelsts='kubectl delete statefulsets'

# Common Used tools:
alias tf='terraform'
alias tg='terragrunt'
