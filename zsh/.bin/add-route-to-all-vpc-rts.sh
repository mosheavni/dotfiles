#!/bin/bash
###########
## Usage ##
###########
usage() {
  echo "Usage: $0 <vpc-name> <cidr-block> <dest-type>"
  [[ $# -gt 0 ]] && echo "$@" >&2
  exit 1
}
###############
## Variables ##
###############
VPC_NAME=$1
CIDR_BLOCK=$2
DEST_ID=$3

############
## Sanity ##
############
if [ -z "$VPC_NAME" ]; then
  usage "Missing VPC name"

fi
if [ -z "$CIDR_BLOCK" ]; then
  usage "Missing CIDR block"
fi
if [ -z "$DEST_ID" ]; then
  usage "Missing destination type"
fi

# Validate CIDR block is valid
if ! echo "$CIDR_BLOCK" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'; then
  usage "CIDR block $CIDR_BLOCK is not valid"
fi

#####################################
## Define destination id parameter ##
#####################################
DEST_TYPE=$(cut -d- -f1 <<<"$DEST_ID")
CREATE_ROUTE_PARAMS=(
  ec2
  create-route
  --destination-cidr-block
  "$CIDR_BLOCK"
)
if [[ "$DEST_TYPE" == "pcx" ]]; then
  CREATE_ROUTE_PARAMS+=(
    --vpc-peering-connection-id
    "$DEST_ID"
  )
elif [[ "$DEST_TYPE" == "igw" ]]; then
  CREATE_ROUTE_PARAMS+=(
    --gateway-id
    "$DEST_ID"
  )
elif [[ "$DEST_TYPE" == "eni" ]]; then
  CREATE_ROUTE_PARAMS+=(
    --network-interface-id
    "$DEST_ID"
  )
elif [[ "$DEST_TYPE" == "vgw" ]]; then
  CREATE_ROUTE_PARAMS+=(
    --gateway-id
    "$DEST_ID"
  )
elif [[ "$DEST_TYPE" == "nat" ]]; then
  CREATE_ROUTE_PARAMS+=(
    --nat-gateway-id
    "$DEST_ID"
  )
elif [[ "$DEST_TYPE" == "tgw" ]]; then
  CREATE_ROUTE_PARAMS+=(
    --transit-gateway-id
    "$DEST_ID"
  )
else
  usage "Destination type $DEST_TYPE is not valid" "Valid values: pcx, igw, eni, vgw, nat or tgw"
fi

############
## Script ##
############
echo "Searching for VPC with name $VPC_NAME"
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name`]|[?Value==`'${VPC_NAME}'`]].VpcId' --output text)
if [ -z "$VPC_ID" ]; then
  echo "VPC with name $VPC_NAME not found"
  exit 1
fi
echo "VPC ID: $VPC_ID"
set -e
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --query 'RouteTables[*].RouteTableId' --output text | xargs -n 1 aws "${CREATE_ROUTE_PARAMS[@]}" --route-table-id
set +e
