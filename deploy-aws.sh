#!/bin/bash

set -xeuo pipefail

source build_vars
source credentials/aws_secrets

TERRAFORM_DIR=terraform
export TF_DATA_DIR=$TERRAFORM_DIR/.terraform

OUTPUT_PLAN=$TF_DATA_DIR/terraform.tfstate

[ ! -d $TF_DATA_DIR ] && terraform init $TERRAFORM_DIR

terraform apply \
  -var "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
  -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  -var "aws_region=$AWS_DEFAULT_REGION" \
  -var "my_ip=$MY_IP" \
  -var "stack_name=$STACK_NAME" \
  -var "availability_zone=$AVAILABILITY_ZONE" \
  -var "hosted_zone_id=$HOSTED_ZONE_ID" \
  -state="$OUTPUT_PLAN" \
  "$TERRAFORM_DIR"

# terraform output -state $OUTPUT_PLAN
