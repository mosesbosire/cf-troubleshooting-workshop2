#!/usr/bin/env bash

set -xeuo pipefail

source build_vars
source credentials/aws_secrets

# JUMPBOX_IP=$(terraform output -state=terraform/.terraform/terraform.tfstate jumpbox_ip)
# SSH_PIDS="$(lsof -t -i :12345||true)"
#
# if [ "$SSH_PIDS" != "" ]; then
#   kill -9 $SSH_PIDS
# fi
#
# ssh -4 -D 12345 -fNC "ubuntu@$JUMPBOX_IP" -i credentials/cf-training-default-key
# export BOSH_ALL_PROXY=socks5://localhost:12345
# bosh -e troubleshooting delete-deployment -d cf
# bosh delete-env bosh/bosh-deployment/bosh.yml \
#   --state=bosh/bosh-state.json \
#   --vars-store=credentials/bosh-creds.yml \
#   -o bosh/bosh-deployment/aws/cpi.yml \
#   -v director_name=bosh-1 \
#   -v internal_cidr="$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_cidr)" \
#   -v internal_gw="$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_gateway_ip)" \
#   -v internal_ip="$(terraform output -state=terraform/.terraform/terraform.tfstate director_private_ip)" \
#   -v access_key_id="$AWS_ACCESS_KEY_ID" \
#   -v secret_access_key="$AWS_SECRET_ACCESS_KEY" \
#   -v region="$AWS_DEFAULT_REGION" \
#   -v az="$AVAILABILITY_ZONE" \
#   -v default_key_name=cf-training-default-key \
#   -v default_security_groups="[$(terraform output -state=terraform/.terraform/terraform.tfstate bosh_security_group_name)]" \
#   -v subnet_id="$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_id)" \
#   --var-file private_key=credentials/cf-training-default-key

TERRAFORM_DIR=terraform
export TF_DATA_DIR=$TERRAFORM_DIR/.terraform

OUTPUT_PLAN=$TF_DATA_DIR/terraform.tfstate

[ ! -d $TF_DATA_DIR ] && terraform init $TERRAFORM_DIR

terraform destroy \
  -state="$OUTPUT_PLAN"
