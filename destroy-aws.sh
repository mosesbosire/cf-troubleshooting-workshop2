#!/bin/bash

set -xeuo pipefail

source build_vars
source credentials/aws_secrets

TERRAFORM_DIR=terraform
export TF_DATA_DIR=$TERRAFORM_DIR/.terraform

OUTPUT_PLAN=$TF_DATA_DIR/terraform.tfstate

[ ! -d $TF_DATA_DIR ] && terraform init $TERRAFORM_DIR

terraform destroy \
  -state="$OUTPUT_PLAN"
