# This command is used a LOT both below and in daily life
alias k=kubectl

# Execute a kubectl command against all namespaces
alias kca='_kca(){ kubectl "$@" --all-namespaces;  unset -f _kca; }; _kca'

# Apply a YML file
alias kaf='kubectl apply -f'

# Drop into an interactive terminal on a container
alias keti='kubectl exec -t -i'

# Manage configuration quickly to switch contexts between local, dev ad staging.
alias kcuc='kubectl config use-context'
alias kcsc='kubectl config set-context'
alias kcdc='kubectl config delete-context'
alias kccc='kubectl config current-context'

# List all contexts
alias kcgc='kubectl config get-contexts'

# General aliases
alias kdel='kubectl delete'
alias kdelf='kubectl delete -f'

# Pod management.
alias kgp='kubectl get pods'
alias kgpl='kgp -l'
alias kgpn='kgp -n'
alias kgpsl='kubectl get pods --show-labels'
alias kgpa='kubectl get pods --all-namespaces'
alias kgpw='kgp --watch'
alias kgpwide='kgp -o wide'
alias kep='kubectl edit pods'
alias kdp='kubectl describe pods'
alias kdelp='kubectl delete pods'
alias kgpall='kubectl get pods --all-namespaces -o wide'

# Service management.
alias kgs='kubectl get svc'
alias kgsa='kubectl get svc --all-namespaces'
alias kgsw='kgs --watch'
alias kgswide='kgs -o wide'
alias kes='kubectl edit svc'
alias kds='kubectl describe svc'
alias kdels='kubectl delete svc'

# Ingress management
alias kgi='kubectl get ingress'
alias kgia='kubectl get ingress --all-namespaces'
alias kei='kubectl edit ingress'
alias kdi='kubectl describe ingress'
alias kdeli='kubectl delete ingress'

# Namespace management
alias kgns='kubectl get namespaces'
alias kens='kubectl edit namespace'
alias kdns='kubectl describe namespace'
alias kdelns='kubectl delete namespace'
alias kcn='kubectl config set-context --current --namespace'

# ConfigMap management
alias kgcm='kubectl get configmaps'
alias kgcma='kubectl get configmaps --all-namespaces'
alias kecm='kubectl edit configmap'
alias kdcm='kubectl describe configmap'
alias kdelcm='kubectl delete configmap'

# Secret management
alias kgsec='kubectl get secret'
alias kgseca='kubectl get secret --all-namespaces'
alias kdsec='kubectl describe secret'
alias kdelsec='kubectl delete secret'

# Deployment management.
alias kgd='kubectl get deployment'
alias kgda='kubectl get deployment --all-namespaces'
alias kgdw='kgd --watch'
alias kgdwide='kgd -o wide'
alias ked='kubectl edit deployment'
alias kdd='kubectl describe deployment'
alias kdeld='kubectl delete deployment'
alias ksd='kubectl scale deployment'
alias krsd='kubectl rollout status deployment'

function kres() {
  kubectl set env "$@" REFRESHED_AT="$(date +%Y%m%d%H%M%S)"
}

# Rollout management.
alias kgrs='kubectl get replicaset'
alias kdrs='kubectl describe replicaset'
alias kers='kubectl edit replicaset'
alias krh='kubectl rollout history'
alias kru='kubectl rollout undo'

# Statefulset management.
alias kgss='kubectl get statefulset'
alias kgssa='kubectl get statefulset --all-namespaces'
alias kgssw='kgss --watch'
alias kgsswide='kgss -o wide'
alias kess='kubectl edit statefulset'
alias kdss='kubectl describe statefulset'
alias kdelss='kubectl delete statefulset'
alias ksss='kubectl scale statefulset'
alias krsss='kubectl rollout status statefulset'

# Port forwarding
alias kpf="kubectl port-forward"

# Tools for accessing all information
alias kga='kubectl get all'
alias kgaa='kubectl get all --all-namespaces'

# Logs
alias kl='kubectl logs'
alias kl1h='kubectl logs --since 1h'
alias kl1m='kubectl logs --since 1m'
alias kl1s='kubectl logs --since 1s'
alias klf='kubectl logs -f'
alias klf1h='kubectl logs --since 1h -f'
alias klf1m='kubectl logs --since 1m -f'
alias klf1s='kubectl logs --since 1s -f'

# File copy
alias kcp='kubectl cp'

# Node Management
alias kgno='kubectl get nodes'
alias kgnosl='kubectl get nodes --show-labels'
alias keno='kubectl edit node'
alias kdno='kubectl describe node'
alias kdelno='kubectl delete node'

# PVC management.
alias kgpvc='kubectl get pvc'
alias kgpvca='kubectl get pvc --all-namespaces'
alias kgpvcw='kgpvc --watch'
alias kepvc='kubectl edit pvc'
alias kdpvc='kubectl describe pvc'
alias kdelpvc='kubectl delete pvc'

# Kubectl Persistent Volume
alias kgpv='kubectl get persistentvolume'
alias kdpv='kubectl describe persistentvolume'
alias kepv='kubectl edit persistentvolume'
alias kdelpv='kubectl delete persistentvolume'

# Service account management.
alias kdsa="kubectl describe sa"
alias kdelsa="kubectl delete sa"

# DaemonSet management.
alias kgds='kubectl get daemonset'
alias kgdsa='kubectl get daemonset --all-namespaces'
alias kgdsw='kgds --watch'
alias keds='kubectl edit daemonset'
alias kdds='kubectl describe daemonset'
alias kdelds='kubectl delete daemonset'

# CronJob management.
alias kgcj='kubectl get cronjob'
alias kecj='kubectl edit cronjob'
alias kdcj='kubectl describe cronjob'
alias kdelcj='kubectl delete cronjob'

# Job management.
alias kgj='kubectl get job'
alias kej='kubectl edit job'
alias kdj='kubectl describe job'
alias kdelj='kubectl delete job'

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
    [[ -n "$DEBUG" ]] && set -x
    kubectl port-forward -n argocd svc/argocd-server 8080:443 &
    CMDPID=$!
    [[ -n "$DEBUG" ]] && set +x
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
  argocd_ingress=$(kubectl get ingress -n argocd --no-headers -o custom-columns=":metadata.name" argocd-server)
  ingress_host=$(kubectl get ingress -n argocd "${argocd_ingress}" -ojson | jq -r '.spec.rules[].host')
  pass=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq -r '.data | with_entries(.value |= @base64d) | .password')
  argocd login --grpc-web "${ingress_host}" --username admin --password "${pass}"
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

  [[ -n "$DEBUG" ]] && set -x
  kubectl run \
    -i \
    --rm \
    --tty \
    --image="$image" \
    --restart=Never \
    $sa_override \
    "${kubectl_args[@]}" \
    "$pod_name" \
    -- \
    "$docker_exe"
  [[ -n "$DEBUG" ]] && set +x
}

function get_pods_of_svc() {
  svc_name=$1
  shift
  label_selectors=$(kubectl get svc $svc_name $* -ojsonpath="{.spec.selector}" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" | paste -s -d "," -)
  kubectl get pod $* -l $label_selectors
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

  [[ -n "$DEBUG" ]] && set -x
  if [[ $pod_or_all == "All" ]]; then
    kubectl logs -f -l $pod_labels $since
  else
    kubectl logs -f $pod_or_all $since
  fi
  [[ -n "$DEBUG" ]] && set +x
}

