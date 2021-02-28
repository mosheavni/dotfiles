### General aliases ###
alias watch='watch '
alias -g S='| sort'
alias -g SRT='+short | sort'
# function mwatch () {
#   final_cmd=$1
#   shift
#   args="$@"
#   while tmp_alias=$(alias "$final_cmd") &>/dev/null;do
#     full_final_cmd=$(awk -F"'" '{print $2}' <<< "$tmp_alias")
#     final_cmd="${full_final_cmd%% *}"
#     args="${full_final_cmd#* } ${args}"
#   done
#   watch $final_cmd $args
# }
function docke () { [[ $1 == "r"* ]] && docker ${1#r} }
function ssh2 () { [[ $1 == "ip-"* ]] && ( in_url=$(sed -e 's/^ip-//' -e 's/-/./g' <<< "$1" ) ; echo $in_url && ssh $in_url ) || ssh $1 }
function jsonlint () { pbcopy && open https://jsonlint.com/ }
function grl () { grep -rl $* . }


### Git related ###
# Open the github page of the repo you're in, in the browser
function opengit () { git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open }
# see recently pushed branches
alias gbrecent='git for-each-ref --sort=-committerdate refs/heads/'
# Create pull request = cpr
alias cpr='open https://github.com/Natural-Intelligence/$(basename $(git rev-parse --show-toplevel))/pull/new/$(git branch --show-current)'

### Shortcuts to directories ###
alias repos="~/Repos"
alias nginx="~/Repos/ingress-domains"
alias nidock="~/Repos/ni-docker"
alias devops="~/Repos/devops_scripts"
alias jenkins="~/Repos/jenkins-shared-libraries"
alias www="~/Repos/www.naturalint.com"
alias nik8s="~/Repos/ni-k8s"
alias difff='code --diff'

### Kubernetes Aliases ###
export KOPS_STATE_STORE=s3://ni-k8s-state-store
alias kafd='kubectl apply --validate=true --dry-run=true -f -'
function kdpw () { watch "kubectl describe po $* | tail -20" }
alias gtiller="kubectl get pod --namespace kube-system -lapp=helm,name=tiller"
alias kgdns="kubectl get services --all-namespaces -o jsonpath='{.items[*].metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}' | tr ' ' '\n'"
alias -g YML='-oyaml | less'
alias -g NM='-ojsonpath="{.metadata.name}"'
function airfloweb () { open http://$(minikube ip):$(kubectl get svc -n airflow airflow-web -ojsonpath='{.spec.ports[*].nodePort}') }

# Kubectl Persistent Volume
alias kgpv='kubectl get persistentvolume'
alias kdpv='kubectl describe persistentvolume'
alias kepv='kubectl edit persistentvolume'
alias kdelpv='kubectl delete persistentvolume'

# Kubectl Persistent Volume Claim
alias kgpvc='kubectl get persistentvolumeclaim'
alias kdpvc='kubectl describe persistentvolumeclaim'
alias kepvc='kubectl edit persistentvolumeclaim'
alias kdelpvc='kubectl delete persistentvolumeclaim'
function jn () {
  open "http://$(kubectl get svc -n jenkins jenkins -o=jsonpath="{ .metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname }")" && \
        printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode) | pbcopy
}

function kubedebug () {
  image=busybox:1.28
  if [[ $# > 0 ]] && [[ $1 != "-"* ]];then
    image=$1
    shift 1
  fi
  kubectl run -i --rm --tty debug $* --image=$image --restart=Never -- sh
}

alias kns='kubens'
