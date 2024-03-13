#!/bin/bash
# aws ec2 describe-regions | jq -r '.Regions[].RegionName' | while read -r line; do
#   export AWS_REGION=$line
#   export AWS_DEFAULT_REGION=$line
#   aws ecr get-login-password --region $line | docker login --username AWS --password-stdin $(aws sts get-caller-identity | jq \
#     -r ".Account").dkr.ecr.$line.amazonaws.com
# done

# Define your AWS regions
IFS=$'\n' read -r -d '' -a AWS_REGIONS < <(aws ec2 describe-regions | jq -r '.Regions[].RegionName')

# Define your Docker login function
docker_login() {
  region=$1
  echo "Logging in to Docker in region: $region"
  export AWS_REGION=$region
  export AWS_DEFAULT_REGION=$region
  aws ecr get-login-password \
    --region $region | docker login \
    --username AWS \
    --password-stdin \
    $(aws sts get-caller-identity | jq -r ".Account").dkr.ecr.$region.amazonaws.com
}

# Export the function
export -f docker_login

# Use GNU Parallel to run the function in parallel for each region
parallel 'docker_login' ::: "${AWS_REGIONS[@]}"
