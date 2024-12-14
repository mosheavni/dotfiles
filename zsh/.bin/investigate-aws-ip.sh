#!/bin/bash
set -euf -o pipefail

blue() { echo -e "\033[34m${*}\033[0m"; }
green() {
  msg=$1
  rest=""
  if [[ "$#" -gt 1 ]]; then
    shift
    rest=$*
  fi
  echo -e "\033[32m${msg}\033[0m${rest[*]}"
}

ip_address=$1
debug=false
if [[ "$#" -gt 1 ]] && [[ $2 == "-d" ]]; then
  debug=true
fi
main() {
  useful_links=()
  is_private=$(grep -qE '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' <<<"$ip_address" && echo "true" || echo "false")

  if [[ -z $ip_address ]]; then
    echo "Usage: $0 <ip-address> [-d]"
    echo "  -d: debug mode"
    exit 1
  fi

  blue "Getting network interfaces for IP address $ip_address..."
  if $is_private; then
    if $debug; then
      blue "using cache..."
      network_interfaces=$(<~/temp/investigate-aws-ip-cache/network-interface.json)
    else
      network_interfaces=$(aws ec2 describe-network-interfaces \
        --filter "Name=addresses.private-ip-address,Values=$ip_address")
    fi
  else
    if $debug; then
      blue "using cache..."
      network_interfaces=$(<~/temp/investigate-aws-ip-cache/public-network-interface.json)
    else
      network_interfaces=$(aws ec2 describe-network-interfaces \
        --filter "Name=addresses.association.public-ip,Values=$ip_address")
    fi
    if [[ -z $network_interfaces ]]; then
      network_interfaces=$(aws ec2 describe-network-interfaces \
        --filter "Name=association.public-ip,Values=$ip_address")
    fi
  fi

  description=$(jq -r '.NetworkInterfaces[].Description' <<<"$network_interfaces")
  eni_id=$(jq -r '.NetworkInterfaces[].NetworkInterfaceId' <<<"$network_interfaces")
  account_id=$(aws sts get-caller-identity --query 'Account' --output text)
  account_region=$(aws configure get region)
  instance_id=$(jq -r '.NetworkInterfaces[] | select(.Attachment.InstanceOwnerId == "'$account_id'").Attachment.InstanceId' <<<"$network_interfaces")

  useful_links+=("ENI: https://${account_region}.console.aws.amazon.com/ec2/home?region=${account_region}#NetworkInterface:networkInterfaceId=$eni_id")

  green "Description: " "$description"
  if [[ -n $instance_id ]]; then
    useful_links+=("Instance: https://${account_region}.console.aws.amazon.com/ec2/home?region=${account_region}#Instances:instanceId=$instance_id")
    blue "Getting instance details"
    if $debug; then
      blue "using cache..."
      instance_details=$(<~/temp/investigate-aws-ip-cache/instance.json)
    else
      instance_details=$(aws ec2 describe-instances --instance-ids $instance_id)
    fi
    instance_name=$(jq -r '.Reservations[].Instances[].Tags[] | select(.Key == "Name").Value' <<<"$instance_details")
    green "Instance Name: " "$instance_name"
    green "Instance ID: " "$instance_id"
  fi

  if [[ $description == "ELB"* ]]; then
    if [[ $description == "ELB app"* ]]; then
      blue "Getting ELBv2 details..."
      elb_arn=arn:aws:elasticloadbalancing:${account_region}:${account_id}:loadbalancer/$(awk '{print $NF}' <<<"$description")
      useful_links+=("ELBv2: https://${account_region}.console.aws.amazon.com/ec2/home?region=${account_region}#LoadBalancer:loadBalancerArn=$elb_arn;tab=listeners")
      if $debug; then
        blue "using cache..."
        elb_details=$(<~/temp/investigate-aws-ip-cache/elbv2.json)
      else
        elb_details=$(aws elbv2 describe-load-balancers --load-balancer-arns "$elb_arn")
      fi
      dns_name=$(jq -r '.LoadBalancers[].DNSName' <<<"$elb_details")
      elb_name=$(jq -r '.LoadBalancers[].LoadBalancerName' <<<"$elb_details")
      blue "Getting ELBv2 tags..."
      if $debug; then
        blue "using cache..."
        alb_tags=$(<~/temp/investigate-aws-ip-cache/elbv2-tags.json)
      else
        alb_tags=$(aws elbv2 describe-tags --resource-arns "$elb_arn")
      fi
      alb_tags_formatted="$(jq -r '.TagDescriptions[].Tags[] | "\(.Key): \(.Value)"' <<<"$alb_tags" | sort | column -t)"
      green "ELBv2 Name: " "$elb_name"
      green "ELBv2 DNS Name: " "$dns_name"
      green "ELBv2 Tags" "\n$alb_tags_formatted"
      blue "Getting ELBv2 listeners details..."
      if $debug; then
        blue "using cache..."
        listeners=$(<~/temp/investigate-aws-ip-cache/listeners.json)
      else
        listeners=$(aws elbv2 describe-listeners \
          --load-balancer-arn "$elb_arn")
      fi
      port=$(jq -r '.Listeners[].Port' <<<"$listeners" | fzf \
        --prompt 'Select listener> ')
      listener_arn=$(jq -r '.Listeners[] | select(.Port == '$port').ListenerArn' <<<"$listeners")
      green "Listener Port: " "$port"
      green "Listener ARN: " "$listener_arn"
      blue "Getting ELBv2 listeners rules details..."
      if $debug; then
        blue "using cache..."
        rules=$(<~/temp/investigate-aws-ip-cache/rules.json)
      else
        rules=$(aws elbv2 describe-rules \
          --listener-arn "$listener_arn")
      fi
      # https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#ELBListenerV2:loadBalancerArn=arn:aws:elasticloadbalancing:us-east-1:178579023202:loadbalancer/app/spotinst-radius-core-ecs/fcbd757c1921a2df;listenerPort=2800;action=None;tab=Rules
      useful_links+=("ELBv2 Listener: https://${account_region}.console.aws.amazon.com/ec2/home?region=${account_region}#ELBListenerV2:loadBalancerArn=$elb_arn;listenerPort=$port;action=None;tab=Rules")
      rule_arns=()
      count=0
      green "Rules"
      while read -r rule; do
        rule_arn=$(jq -r '.RuleArn' <<<"$rule")
        host_header=$(jq -r '.Conditions[] | select(.Field == "host-header").Values[]?' <<<"$rule")
        path_pattern=$(jq -r '.Conditions[] | select(.Field == "path-pattern").Values[]?' <<<"$rule")
        http_header=$(jq -r '.Conditions[] | select(.Field == "http-header").HttpHeaderConfig.HttpHeaderName' <<<"$rule")
        if [[ -n $http_header ]]; then
          http_header="${http_header}: $(jq -r '.Conditions[] | select(.Field == "http-header").HttpHeaderConfig.Values[]' <<<"$rule")"
        fi
        tg_arn=$(jq -r '.Actions[] | select(.Type == "forward").ForwardConfig.TargetGroups[0].TargetGroupArn' <<<"$rule")
        if [[ -z $tg_arn ]]; then
          continue
        fi
        rule_arns+=("$rule_arn~$host_header~$path_pattern~$http_header~$tg_arn")
        count=$((count + 1))

        echo -n "${count}) ${host_header}${path_pattern}"
        if [[ -n $http_header ]]; then
          echo -n " [HTTP Header: $http_header]"
        fi
        echo ""
      done <<<"$(jq -c '.Rules[]' <<<"$rules")"
      read -r -p "Select rule: " rule_number
      rule_arn=$(cut -d'~' -f1 <<<"${rule_arns[$rule_number - 1]}")
      host_header=$(cut -d'~' -f2 <<<"${rule_arns[$rule_number - 1]}")
      path_pattern=$(cut -d'~' -f3 <<<"${rule_arns[$rule_number - 1]}")
      http_header=$(cut -d'~' -f4 <<<"${rule_arns[$rule_number - 1]}")
      tg_arn=$(cut -d'~' -f5 <<<"${rule_arns[$rule_number - 1]}")
      green 'Rule ARN: ' "$rule_arn"
      green 'Host Header: ' "$host_header"
      green 'Path Pattern: ' "$path_pattern"
      green 'HTTP Header: ' "$http_header"
      green 'Target Group ARN: ' "$tg_arn"
      blue "Getting Target Group's target health details..."
      useful_links+=("Target Group: https://${account_region}.console.aws.amazon.com/ec2/home?region=${account_region}#TargetGroup:targetGroupArn=$tg_arn")
      aws elbv2 describe-target-health --target-group-arn "$tg_arn"
      targets_health_check=$(aws elbv2 describe-target-groups --target-group-arns ${tg_arn} | jq -r '.TargetGroups[].HealthCheckPath')
      healthcheck_curl="curl -k -L -v -H 'Host: ${host_header}'"
      if [[ -n $http_header ]]; then
        healthcheck_curl+=" -H '$http_header'"
      fi
      healthcheck_curl+=" https://${dns_name}${targets_health_check}"
      useful_links+=("Healthcheck: ${healthcheck_curl}")
    else
      blue "Getting ELB details..."
      elb_name=$(awk '{print $NF}' <<<"$description")
      if $debug; then
        blue "using cache..."
        elb_details=$(<~/temp/investigate-aws-ip-cache/elb.json)
      else
        elb_details=$(aws elb describe-load-balancers --load-balancer-names "$elb_name")
      fi
      dns_name=$(jq -r '.LoadBalancerDescriptions[].DNSName' <<<"$elb_details")
      healthcheck=$(jq -r '.LoadBalancerDescriptions[].HealthCheck.Target' <<<"$elb_details" | cut -d: -f2-)
      blue "Getting ELB tags..."
      if $debug; then
        blue "using cache..."
        elb_tags=$(<~/temp/investigate-aws-ip-cache/elb-tags.json)
      else
        elb_tags=$(aws elb describe-tags --load-balancer-names "$elb_name")
      fi
      elb_tags_formatted="$(jq -r '.TagDescriptions[].Tags[] | "\(.Key): \(.Value)"' <<<"$elb_tags" | sort | column -t)"
      green "ELB Name: " "$elb_name"
      green "ELB DNS Name: " "$dns_name"
      green "ELB Tags" "\n$elb_tags_formatted"
      useful_links+=("ELB: https://${account_region}.console.aws.amazon.com/ec2/home?region=${account_region}#LoadBalancer:loadBalancerArn=$elb_name;tab=listeners")
      useful_links+=("Healthcheck: curl -L -v http://${dns_name}:${healthcheck}")
    fi
  fi
  green "Useful links" "$(printf "\n%s" "${useful_links[@]}")"
}

main
