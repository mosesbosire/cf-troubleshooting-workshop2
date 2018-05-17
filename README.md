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
```bash
./deploy-aws.sh
```

Deploy the Bosh Director:
```bash
./deploy-bosh.sh
```
Bosh Director deployment also logs you in the defined `troubleshooting` alias.

Deploy Cloud Foundry via Bosh:
```bash
./deploy-cf.sh
```

## Troubleshooting

The Cloud Foundry solution we have deployed is not in working status.
Contains on purpose issues that you will need to fix.

Within the `troubleshooting` folder, you will find two READMEs, one containing the issues to fix, `issues-to-fix.md`, and one containing the solutions for those issues, `solutions.md`.

We recommend you start by having a look at the issues and trying to figure out the solution yourself. The `solutions.md` file is there to help you compare your results.

Have fun troubleshooting Cloud Foundry! :)
