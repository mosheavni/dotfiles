### General aliases ###
alias watch='watch '
alias -g S='| sort'
alias -g SRT='+short | sort'

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

function mwatch() {
  # log_file=/tmp/moshe_mwatch.log
  # [[ -f $log_file ]] && cat /dev/null > $log_file || touch $log_file
  final_alias=`_alias_finder "$*"`
  echo $final_alias
  watch "$final_alias"
}

function docke () { [[ $1 == "r"* ]] && docker ${1#r} }
function ssh2 () { [[ $1 == *"ip-"* ]] && ( in_url=`sed -e 's/ip-//' -e 's/-/./g' <<< "$1" ` ; echo $in_url && ssh $in_url ) || ssh $1 }
function jsonlint () { pbcopy && open https://jsonlint.com/ }
function grl () { grep -rl $* . }


### Git related ###
# Open the github page of the repo you're in, in the browser
function opengit () { git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open }
# see recently pushed branches
# alias gb="git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | fzf | xargs git checkout && git pull"
alias gb='git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2 | fzf | xargs git checkout'

# Create pull request = cpr
function cpr() {
  git_remote=$(git remote -v | head -1)
  git_name=$(sed -E 's?origin\s*(git@|https://)(\w+).*?\2?g' <<<"$git_remote")
  project_name=$(sed -E "s/.*com[:\/](.*)\/.*/\\1/" <<<"$git_remote")
  repo_name=$(sed -E -e "s/.*com[:\/].*\/(.*).*/\\1/" -e "s/\.git\s*\((fetch|push)\)//" <<<"$git_remote")
  branch_name=$(git branch --show-current)

  if [[ $git_name == "gitlab" ]]; then
    pr_link="-/merge_requests/new?merge_request[source_branch]="
  else
    pr_link="/pull/new/"
  fi
  open "https://${git_name}.com/${project_name}/${repo_name}/${pr_link}${branch_name}"
}

### Shortcuts to directories ###
alias repos="~/Repos"
alias difff='code --diff'

### Kubernetes Aliases ###
alias kafd='kubectl apply --validate=true --dry-run=true -f -'
function kdpw () { watch "kubectl describe po $* | tail -20" }
alias gtiller="kubectl get pod --namespace kube-system -lapp=helm,name=tiller"
alias kgdns="kubectl get services --all-namespaces -o jsonpath='{.items[*].metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}' | tr ' ' '\n'"
alias -g YML='-oyaml | less'
alias -g NM=' --no-headers -o custom-columns=":metadata.name"'
alias -g RC='--sort-by=".status.containerStatuses[0].restartCount" -A | grep -v "\s0\s"'
alias kns='kubens'
alias kmem='kubectl top node | (gsed -u 1q;sort -r -hk5)'
alias kcpu='kubectl top node | (gsed -u 1q;sort -r -hk3)'
alias ktn='kubectl top node'
alias ktp='kubectl top pod'
alias krs='kubectl rollout restart'
alias kesec='kubectl edit secret'
function airfloweb () { open http://$(minikube ip):$(kubectl get svc -n airflow airflow-web -ojsonpath='{.spec.ports[*].nodePort}') }
alias kgpname='kubectl get pod --no-headers -o custom-columns=":metadata.name"'
alias kgdname='kubectl get deployment --no-headers -o custom-columns=":metadata.name"'
function kgres() {
  kubectl get pod \
  -ojsonpath='{range .items[*]}{.spec.containers[*].name}{" memory: "}{.spec.containers..resources.requests.memory}{"/"}{.spec.containers..resources.limits.memory}{" | cpu: "}{.spec.containers..resources.requests.cpu}{"/"}{.spec.containers..resources.limits.cpu}{"\n"}{end}' | sort \
  -u \
  -k1,1 | column -t
}

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

function kubedebug () {
  image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
  if [[ $# > 0 ]] && [[ $1 != "-"* ]];then
    image=$1
    shift 1
  fi
  kubectl run -i --rm --tty debug $* --image=$image --restart=Never -- sh
}

# Common Used tools:
alias tf='terraform'
alias tg='terragrunt'
