# Interactive debug-pod launcher (kubectl run) built on gum + jq.
#
# Structure (all helpers share kubedebug's state via zsh dynamic scope):
#   _kdng_table        render the config table
#   _kdng_fheight      list height that fits a header in the terminal
#   _kdng_filter       gum filter wrapped with the config table as header
#   _kdng_edit_*       one editor per menu field (mutate caller state)
#   _kdng_build_*      assemble overrides / run command
#   _kdng_launch       final confirm / copy / launch menu
#   kubedebug       entrypoint: state init + menu loop + dispatch
#
# To add a field: add a menu entry + a table row + a _kdng_edit_<field> function.

# --- rendering helpers -------------------------------------------------------

_kdng_table() {
  gum style --foreground 212 --bold "kubedebug"
  gum table --print -c Field,Value -s '~' <<EOF
Context~$ctx_display
Namespace~$namespace
Image~$image
Shell~$docker_exe
Pod name~$pod_name
Timestamp suffix~$ts_display
Service account~$sa_display
hostNetwork~$hn_display
hostPID~$hp_display
Tolerations~$tol_display
Pull policy~$pull_policy
Extra flags~$extras_display
EOF
}

# echo a list height that leaves room for the given header within the terminal
_kdng_fheight() {
  local hdr=$1 rows=${LINES:-24} h
  local -a hlines=("${(@f)hdr}")
  h=$(( rows - ${#hlines} - 4 ))
  (( h < 3 )) && h=3
  print -r -- "$h"
}

# gum filter that pins the config table (plus an extra header line) on screen.
# usage: <options on stdin> | _kdng_filter "extra header line" [extra gum args...]
_kdng_filter() {
  local extra=$1
  shift
  local hdr=$(_kdng_table)
  [[ -n $extra ]] && hdr="${hdr}"$'\n'"$extra"
  clear
  gum filter \
    --height "$(_kdng_fheight "$hdr")" \
    --header "$hdr" \
    --header.foreground "" \
    --placeholder "type to filter..." \
    "$@"
}

# --- field editors (mutate caller state, return to re-render) -----------------

_kdng_edit_namespace() {
  local ns_list
  local -a ns_lines
  if ! ns_list=$(gum spin --spinner dot --title "Fetching namespaces..." --show-stdout -- \
    kubectl get ns --no-headers); then
    gum style --foreground 1 "kubectl failed:" "$(kubectl get ns --no-headers 2>&1)"
    return
  fi
  ns_lines=("${(@f)ns_list}")
  if ((${#ns_lines} == 0)); then
    gum style --foreground 1 "No namespaces found."
    return
  fi
  local ns
  ns=$(printf '%s\n' "${ns_lines[@]}" | _kdng_filter "Namespace" --strict | awk '{print $1}')
  [[ -z $ns ]] && return
  namespace=$ns
  service_account=
}

_kdng_edit_image() {
  local prev_image=$image new_image
  new_image=$(gum choose --header "Debug image" \
    "mosheavni/net-debug:latest" \
    "nicolaka/netshoot:latest" \
    "Custom...") || return
  if [[ $new_image == "Custom..." ]]; then
    local custom_default=
    if [[ $prev_image != mosheavni/net-debug:latest && $prev_image != nicolaka/netshoot:latest ]]; then
      custom_default=$prev_image
    fi
    new_image=$(gum input --header "Custom image" --placeholder "image:tag" --value "$custom_default") || return
  fi
  [[ -z $new_image ]] && return
  image=$new_image
}

_kdng_edit_shell() {
  local prev_shell=$docker_exe new_shell
  new_shell=$(gum choose --header "Shell" --selected "$docker_exe" bash zsh sh "Other...") || return
  if [[ $new_shell == "Other..." ]]; then
    local shell_default=
    [[ $prev_shell != bash && $prev_shell != zsh && $prev_shell != sh ]] && shell_default=$prev_shell
    new_shell=$(gum input --header "Executable" --placeholder "e.g. /bin/dash" --value "$shell_default") || return
  fi
  [[ -z $new_shell ]] && return
  docker_exe=$new_shell
}

_kdng_edit_pod_name() {
  local n
  n=$(gum input --header "Pod name" --value "$pod_name") || return
  [[ -z $n ]] && return
  pod_name=$n
}

_kdng_edit_service_account() {
  local pick
  pick=$(gum choose --header "Service account" "(default)" "Pick from list...") || return
  if [[ $pick == "(default)" ]]; then
    service_account=
    return
  fi
  local sa_list
  local -a sa_lines
  if ! sa_list=$(gum spin --spinner dot --title "Fetching service accounts..." --show-stdout -- \
    kubectl get sa -n "$namespace" --no-headers); then
    gum style --foreground 1 "kubectl failed:" "$(kubectl get sa -n "$namespace" --no-headers 2>&1)"
    return
  fi
  sa_lines=("${(@f)sa_list}")
  if ((${#sa_lines} == 0)); then
    gum style --foreground 1 "No service accounts in namespace '$namespace'."
    return
  fi
  service_account=$(printf '%s\n' "${sa_lines[@]}" |
    _kdng_filter "Service account ($namespace)" --strict |
    awk '{print $1}')
}

_kdng_edit_pull_policy() {
  local p
  p=$(gum choose --header "Image pull policy" --selected "$pull_policy" IfNotPresent Always Never) || return
  pull_policy=$p
}

_kdng_edit_extra_flags() {
  local extra_args line
  extra_args=$(gum write --header "Extra kubectl run flags" \
    --placeholder "one flag per line, e.g. -l app=debug" \
    --value="${(F)kubectl_args}")
  kubectl_args=()
  while IFS= read -r line; do
    [[ -n $line ]] && kubectl_args+=("$line")
  done <<<"$extra_args"
}

# --- tolerations -------------------------------------------------------------

_kdng_edit_tolerations() {
  local pick
  pick=$(gum choose --header "Tolerations" \
    "(none)" \
    "Tolerate all taints" \
    "Pick from node taints..." \
    "Add specific...") || return
  case $pick in
  "(none)") tolerations= ;;
  "Tolerate all taints") tolerations='[{"operator":"Exists"}]' ;;
  "Pick from node taints...") _kdng_tolerations_from_taints ;;
  "Add specific...") _kdng_tolerations_add_specific ;;
  esac
}

_kdng_tolerations_from_taints() {
  local nodes_json nodes_tmp tdisp tjson tol_obj selected taint_set selected_set
  local -a taint_jsons sel_lines preselected sel_args
  local -A tol_for_disp
  nodes_tmp=$(mktemp) || return
  if ! gum spin --spinner dot --title "Fetching node taints..." -- \
    sh -c "kubectl get nodes -o json >'$nodes_tmp' 2>'$nodes_tmp.err'"; then
    gum style --foreground 1 "kubectl failed:" "$(head -3 "$nodes_tmp.err" 2>/dev/null)"
    rm -f "$nodes_tmp" "$nodes_tmp.err"
    return
  fi
  nodes_json=$(<"$nodes_tmp")
  rm -f "$nodes_tmp" "$nodes_tmp.err"
  taint_jsons=("${(@f)$(jq -c '[.items[].spec.taints // []] | add // [] | unique_by(.key + "=" + (.value // "") + ":" + .effect) | .[]' <<<"$nodes_json")}")
  if ((${#taint_jsons[@]} == 0)) || [[ -z ${taint_jsons[1]} ]]; then
    gum style --foreground 3 "No taints found on any node."
    return
  fi
  for tjson in "${taint_jsons[@]}"; do
    [[ -z $tjson ]] && continue
    tdisp=$(jq -r '.key + (if (.value // "") != "" then "=" + .value else "" end) + ":" + .effect' <<<"$tjson")
    tol_obj=$(jq -c 'if (.value // "") != "" then {key: .key, operator: "Equal", value: .value, effect: .effect} else {key: .key, operator: "Exists", effect: .effect} end' <<<"$tjson")
    tol_for_disp[$tdisp]=$tol_obj
    if [[ -n $tolerations ]] && jq -e --argjson t "$tol_obj" 'any(.[]; . == $t)' <<<"$tolerations" >/dev/null 2>&1; then
      preselected+=("$tdisp")
    fi
  done
  ((${#preselected[@]})) && sel_args=(--selected "${(j:,:)preselected}")
  selected=$(printf '%s\n' "${(@k)tol_for_disp}" |
    _kdng_filter "Select taints to tolerate (tab to select multiple, enter to confirm)" --no-limit "${sel_args[@]}") || return
  selected_set='[]'
  sel_lines=("${(@f)selected}")
  for tdisp in "${sel_lines[@]}"; do
    [[ -z $tdisp ]] && continue
    tol_obj=${tol_for_disp[$tdisp]}
    [[ -z $tol_obj ]] && continue
    selected_set=$(jq -nc --argjson cur "$selected_set" --argjson new "$tol_obj" '$cur + [$new]')
  done
  taint_set=$(printf '%s\n' "${(@v)tol_for_disp}" | jq -sc '.')
  tolerations=$(jq -nc \
    --argjson cur "${tolerations:-[]}" \
    --argjson taintset "$taint_set" \
    --argjson sel "$selected_set" \
    '($cur | map(select(. as $x | ($taintset | any(.[]; . == $x)) | not))) + $sel | unique')
  [[ $tolerations == "[]" ]] && tolerations=
}

_kdng_tolerations_add_specific() {
  local tol_key tol_op tol_val tol_effect tol_obj
  tol_key=$(gum input --header "Toleration key" \
    --placeholder "e.g. node-role.kubernetes.io/control-plane") || return
  tol_op=$(gum choose --header "Operator" Exists Equal) || return
  if [[ $tol_op == Equal ]]; then
    tol_val=$(gum input --header "Value") || return
  else
    tol_val=
  fi
  tol_effect=$(gum choose --header "Effect" "(any)" NoSchedule PreferNoSchedule NoExecute) || return
  [[ $tol_effect == "(any)" ]] && tol_effect=
  tol_obj=$(jq -nc \
    --arg key "$tol_key" \
    --arg op "$tol_op" \
    --arg val "$tol_val" \
    --arg eff "$tol_effect" \
    '{operator: $op}
      + (if $key != "" then {key: $key} else {} end)
      + (if $op == "Equal" then {value: $val} else {} end)
      + (if $eff != "" then {effect: $eff} else {} end)')
  if [[ -z $tolerations ]]; then
    tolerations="[$tol_obj]"
  else
    tolerations=$(jq -nc --argjson cur "$tolerations" --argjson new "$tol_obj" '$cur + [$new]')
  fi
}

# echo the toleration summary shown in the table
_kdng_tol_display() {
  [[ -z $tolerations ]] && { print -r -- "(none)"; return; }
  jq -r 'map(
    if .operator == "Exists" and (has("key") | not) then "all taints"
    else ((.key // "*") + (if has("value") then "=" + .value else "" end) + (if has("effect") then ":" + .effect else "" end))
    end) | join(", ")' <<<"$tolerations"
}

# --- launch ------------------------------------------------------------------

# echo the spec overrides JSON, or nothing when no overrides are needed
_kdng_build_overrides() {
  [[ -z $service_account && $host_network == false && $host_pid == false && -z $tolerations ]] && return
  jq -nc \
    --arg sa "${service_account:-}" \
    --argjson hn "$host_network" \
    --argjson hp "$host_pid" \
    --argjson tol "${tolerations:-null}" \
    '{
      spec: (
        (if $sa != "" then {serviceAccount: $sa} else {} end)
        + (if $hn then {hostNetwork: true} else {} end)
        + (if $hp then {hostPID: true} else {} end)
        + (if $tol != null then {tolerations: $tol} else {} end)
      )
    }'
}

_kdng_launch() {
  local final_pod_name=$pod_name
  [[ $pod_name_ts == true ]] && final_pod_name="${pod_name}-$(date +%s)"
  local overrides=$(_kdng_build_overrides)

  local -a run_cmd=(
    kubectl
    "${kubectl_args[@]}"
    -n "$namespace"
    run -i --rm --tty
    --image="$image"
    --restart=Never
  )
  [[ -n $overrides ]] && run_cmd+=(--overrides="$overrides")
  [[ $pull_policy != IfNotPresent ]] && run_cmd+=(--image-pull-policy="$pull_policy")
  run_cmd+=("$final_pod_name" -- "$docker_exe")

  local -a disp_lines=("kubectl \\")
  local flag
  for flag in "${kubectl_args[@]}"; do
    disp_lines+=("  $flag \\")
  done
  disp_lines+=(
    "  -n $namespace run \\"
    "  -i \\"
    "  --rm \\"
    "  --tty \\"
    "  --image=$image \\"
    "  --restart=Never \\"
  )
  [[ -n $overrides ]] && disp_lines+=("  --overrides=$overrides \\")
  [[ $pull_policy != IfNotPresent ]] && disp_lines+=("  --image-pull-policy=$pull_policy \\")
  disp_lines+=("  $final_pod_name -- $docker_exe")

  local action
  while true; do
    clear
    gum style --foreground 212 --border rounded --padding "0 1" "${disp_lines[@]}"
    action=$(gum choose --header "Debug pod" \
      "Launch" \
      "Copy command to clipboard" \
      "Cancel") || return 0
    case $action in
    Launch) break ;;
    "Copy command to clipboard")
      printf '%s' "${(j: :)${(q-)run_cmd[@]}}" | pbcopy
      gum style --foreground 42 "Copied to clipboard."
      sleep 1
      ;;
    Cancel) return 0 ;;
    esac
  done

  [[ -n "$DEBUG" ]] && set -x
  "${run_cmd[@]}"
  local rc=$?
  [[ -n "$DEBUG" ]] && set +x
  return $rc
}

# --- entrypoint --------------------------------------------------------------

function kubedebug() {
  command -v gum >/dev/null || {
    echo "kubedebug requires gum (brew install gum)" >&2
    return 1
  }
  command -v jq >/dev/null || {
    echo "kubedebug requires jq" >&2
    return 1
  }

  local ctx namespace image docker_exe pod_name service_account choice last_choice
  local pod_name_ts=false host_network=false host_pid=false pull_policy tolerations
  local -a kubectl_args
  local ctx_display sa_display extras_display hn_display hp_display ts_display tol_display
  local green=$'\e[32m' red=$'\e[31m' gray=$'\e[90m' reset=$'\e[0m'

  ctx=$(kubectl config current-context 2>/dev/null)
  namespace=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null)
  [[ -z $namespace ]] && namespace=default
  image=mosheavni/net-debug:latest
  docker_exe=bash
  pod_name=debug
  pull_policy=IfNotPresent
  ctx_display="${gray}${ctx:-unknown}${reset}"

  while true; do
    sa_display=${service_account:-"(default)"}
    ((${#kubectl_args[@]} == 0)) && extras_display="(none)" || extras_display="${kubectl_args[*]}"
    [[ $host_network == true ]] && hn_display="${green}yes${reset}" || hn_display="${red}no${reset}"
    [[ $host_pid == true ]] && hp_display="${green}yes${reset}" || hp_display="${red}no${reset}"
    [[ $pod_name_ts == true ]] && ts_display="${green}yes${reset}" || ts_display="${red}no${reset}"
    tol_display=$(_kdng_tol_display)

    clear
    local main_tbl=$(_kdng_table)
    print -r -- "$main_tbl"

    choice=$(gum choose --header "Edit a field or launch" \
      --height "$(_kdng_fheight "$main_tbl")" \
      --selected "${last_choice:-Namespace}" \
      "Namespace" \
      "Image" \
      "Shell" \
      "Pod name" \
      "Timestamp suffix" \
      "Service account" \
      "hostNetwork" \
      "hostPID" \
      "Tolerations" \
      "Pull policy" \
      "Extra flags" \
      "Launch" \
      "Quit") || return 1
    last_choice=$choice

    case $choice in
    Namespace) _kdng_edit_namespace ;;
    Image) _kdng_edit_image ;;
    Shell) _kdng_edit_shell ;;
    "Pod name") _kdng_edit_pod_name ;;
    "Timestamp suffix") [[ $pod_name_ts == true ]] && pod_name_ts=false || pod_name_ts=true ;;
    "Service account") _kdng_edit_service_account ;;
    hostNetwork) [[ $host_network == true ]] && host_network=false || host_network=true ;;
    hostPID) [[ $host_pid == true ]] && host_pid=false || host_pid=true ;;
    Tolerations) _kdng_edit_tolerations ;;
    "Pull policy") _kdng_edit_pull_policy ;;
    "Extra flags") _kdng_edit_extra_flags ;;
    Launch) break ;;
    Quit) return 0 ;;
    esac
  done

  _kdng_launch
}
