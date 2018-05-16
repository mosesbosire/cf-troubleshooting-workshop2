# Cloud Foundry Troubleshooting Workshop

Workshop for troubleshooting Cloud Foundry related network issues.

## Prerequisites

#### Installed:
* Bosh v2 CLI
* Terraform

#### On AWS:
* **AWS SSH key pair**. The current code assumes the existence of the keypair `cf-training-default-key` and the private key is in the `credentials` folder.
* **AWS IAM user**. The file `credentials/aws_secrets` contains API credentials for the user `training-user` which has EC2, VPC, S3, Route53, CertificateManager permissions.

## How to Use?

* Change `STACK_NAME` in `build_vars` to something specific (eg: include your name in it)

Deploy the AWS infrastructure:
```
./deploy-aws.sh
```

Deploy the Bosh Director:
```
./deploy-bosh.sh
```
Bosh Director deployment also logs you in the defined `troubleshooting` alias.

