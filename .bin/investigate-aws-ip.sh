#!/bin/bash
set -euf -o pipefail

green() {
  msg=$1
  shift
  echo -e "\033[32m${msg}\033[0m${*}"
}

ip_address=$1
main() {
  is_private=$(grep -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' <<<"$ip_address" || true)

  if [[ -z $ip_address ]]; then
    echo "Usage: $0 <ip-address>"
    exit 1
  fi

  if [[ -n $is_private ]]; then
    network_interfaces=$(aws ec2 describe-network-interfaces \
      --filter "Name=addresses.private-ip-address,Values=$ip_address")
  else
    network_interfaces=$(aws ec2 describe-network-interfaces \
      --filter "Name=addresses.association.public-ip,Values=$ip_address")
    if [[ -z $network_interfaces ]]; then
      network_interfaces=$(aws ec2 describe-network-interfaces \
        --filter "Name=association.public-ip,Values=$ip_address")
    fi
  fi

  description=$(jq -r '.NetworkInterfaces[].Description' <<<"$network_interfaces")
  account_id=$(aws sts get-caller-identity --query 'Account' --output text)
  account_region=$(aws configure get region)
  instance_id=$(jq -r '.NetworkInterfaces[] | select(.Attachment.InstanceOwnerId == "'$account_id'").Attachment.InstanceId' <<<"$network_interfaces")

  green "Description: " "$description"
  if [[ -n $instance_id ]]; then
    instance_details=$(aws ec2 describe-instances --instance-ids $instance_id)
    instance_name=$(jq -r '.Reservations[].Instances[].Tags[] | select(.Key == "Name").Value' <<<"$instance_details")
    green "Instance ID: " "$instance_id"
    green "Instance Name: " "$instance_name"
  fi

  if [[ $description == "ELB"* ]]; then
    if [[ $description == "ELB app"* ]]; then
      elb_arn=arn:aws:elasticloadbalancing:${account_region}:${account_id}:loadbalancer/$(awk '{print $NF}' <<<"$description")
      elb_details=$(aws elbv2 describe-load-balancers --load-balancer-arns "$elb_arn")
      dns_name=$(jq -r '.LoadBalancers[].DNSName' <<<"$elb_details")
      elb_name=$(jq -r '.LoadBalancers[].LoadBalancerName' <<<"$elb_details")
      green "ELB Name: " "$elb_name"
      green "ELB DNS Name: " "$dns_name"
    else
      elb_name=$(awk '{print $NF}' <<<"$description")
      elb_details=$(aws elb describe-load-balancers --load-balancer-names "$elb_name")
      dns_name=$(jq -r '.LoadBalancerDescriptions[].DNSName' <<<"$elb_details")
      green "ELB Name: " "$elb_name"
      green "ELB DNS Name: " "$dns_name"
    fi
  fi
}

main | column -t -s:
