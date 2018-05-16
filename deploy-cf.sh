#!/bin/bash -e

source build_vars
source credentials/aws_secrets

chmod 600 credentials/cf-training-default-key

JUMPBOX_IP=$(terraform output -state=terraform/.terraform/terraform.tfstate jumpbox_ip)
kill -9 $(ps x | grep ssh | grep -- "-D 12345" | cut -d ' ' -f 1) || true
ssh -4 -D 12345 -fNC ubuntu@$JUMPBOX_IP -i credentials/cf-training-default-key
export BOSH_ALL_PROXY=socks5://localhost:12345

bosh -e $BOSH_ENVIRONMENT update-cloud-config cf/cloud-config.yml \
  -v system_lb=$(terraform output -state=terraform/.terraform/terraform.tfstate system_lb_name) \
  -v availability_zone=$AVAILABILITY_ZONE \
  -v private_subnet_range=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_cidr) \
  -v security_group=$(terraform output -state=terraform/.terraform/terraform.tfstate bosh_security_group_name) \
  -v gateway_ip=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_gateway_ip) \
  -v subnet_id=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_id)

bosh -e $BOSH_ENVIRONMENT upload-stemcell https://s3.amazonaws.com/bosh-aws-light-stemcells/light-bosh-stemcell-3586.7-aws-xen-hvm-ubuntu-trusty-go_agent.tgz

bosh -e $BOSH_ENVIRONMENT -d cf deploy cf/cf-deployment/cf-deployment.yml \
  --vars-store credentials/cf-creds.yml \
  -o cf/cf-deployment/operations/scale-to-one-az.yml \
  -o cf/cf-deployment/operations/use-compiled-releases.yml \
  -o cf/cf-deployment/operations/aws.yml \
  -o cf/operations/rename_disk_labels.yml \
  -v system_domain=sys.$STACK_NAME.training.armakuni.co.uk