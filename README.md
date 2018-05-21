# Cloud Foundry Troubleshooting Workshop

Workshop for troubleshooting Cloud Foundry related network issues.

## Prerequisites

#### Installed

* [Bosh v2 CLI](https://bosh.io/docs/cli-v2/)
* [Terraform](https://www.terraform.io/downloads.html)

#### Including submodules

This repository uses submodules. Initialize them with this command.

```shell
git submodule init
git submodule update
```

#### On AWS

Ensure you have [created a Access Key in AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

Once you have done this create a new file at `credentials/aws_secrets` that looks like below, replacing the values your access key and secret.

```shell
export AWS_ACCESS_KEY_ID=AKIAI7QP5U4TFDYN5UCQ
export AWS_SECRET_ACCESS_KEY=KuLS6Y8Gvn7l7h24IiUNwN6ag9+/2+GAwk3+3HPM
```

For this to work you'll need at least the EC2, VPC, S3, Route53, CertificateManager permissions.

## How to Use?

Deploy the AWS infrastructure

```shell
./deploy-aws.sh
```

If you see an error about the ELB not being created, like below, rerun the above command, and it should be resolved.

```shell
Error: Error applying plan:

1 error(s) occurred:

* aws_elb.cf_sys_lb: 1 error(s) occurred:

* aws_elb.cf_sys_lb: [WARN] Error creating ELB Listener with SSL Cert, retrying: CertificateNotFound: Server Certificate not found for the key: arn:aws:acm:eu-west-2:689146710931:certificate/ff94730c-8cfc-45f6-a555-8b03106bec62
	status code: 400, request id: 093d3331-5ce2-11e8-80e7-07c00bdf4980
```

Deploy the Bosh Director:

```shell
./deploy-bosh.sh
```

Bosh Director deployment also logs you in the defined `troubleshooting` alias.

Deploy Cloud Foundry via Bosh

```shell
./deploy-cf.sh
```

Next add to your `.bashrc`

```shell
export BOSH_ALL_PROXY=socks5://localhost:12345
```

## The Task

The Cloud Foundry solution we have deployed is not in working status.
Contains on purpose issues that you will need to fix.

Within the `troubleshooting` folder, you will find two READMEs, one containing the issues to fix, [`issues-to-fix.md`](troubleshooting/issues-to-fix.md), and one containing the solutions for those issues, [`solutions.md`](troubleshooting/solutions.md).

**Please don't change anything in the `cf/cf-deployment` folder. Use [ops (operations) files](https://bosh.io/docs/cli-ops-files/) to modify the yaml.**

### Recommendations

We recommend you start by having a look at the issues and trying to figure out the solution yourself. The [`solutions.md`](troubleshooting/solutions.md) file is there to help you compare your results.

Have fun troubleshooting Cloud Foundry! :)
