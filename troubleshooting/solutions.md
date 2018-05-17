# Solutions
## Issue no. 1

Define inbound rule within the `cf-training-bosh` security group  for HTTPS.

Add the following within `terraform/security_groups.tf`:

```bash
resource "aws_security_group_rule" "bosh_inbound_https" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "HTTPS access"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["${var.my_ip}"]
}
```

## Issue no. 2

The load balancer is incorrectly configured. It has wrong configuration for the listener instance port and the health check. Edit the following attributes in `elb.tf`

```bash
	listener {
		lb_port = 443
		lb_protocol = "https"
		instance_port = 80 # change this port
		instance_protocol = "http"
		ssl_certificate_id = "${aws_acm_certificate.sys_cert.id}"
	}

	health_check {
    	healthy_threshold   = 2
    	unhealthy_threshold = 2
    	timeout             = 3
    	target              = "TCP:80" # change protocol & port
    	interval            = 30
	}
```

## Issue no. 3

After logging in, create a CF space, switch within that space and push your existing app:

```bash
cf login -a https://api.sys.cf-training.training.armakuni.co.uk
cf create-space workspace
cf spaces
cf t -s workspace
cd your_app
cf push

# increase the diego-cell ephemeral disk size within `cf/cloud-config.yml` and redeploy cf via `deploy-cf.sh`
- name: cell_ephemeral_disk
  cloud_properties:
    ephemeral_disk:
      size: 25000 # increase this size
      type: gp2
```

## Issue no. 4

To diagnose the problem run `cf logs` with the `CF_TRACE=1` environment variable set.

The output will show that the CLI is doing:

```
WEBSOCKET ERROR: [2018-05-16T16:41:40+01:00]
Error dialing trafficcontroller server: dial tcp 35.177.185.23:4443: i/o timeout.
Please ask your Cloud Foundry Operator to check the platform configuration (trafficcontroller is wss://doppler.sys.cf-training.training.armakuni.co.uk:4443).. Retrying...
```

The ELB is not configured to allow websocket traffic on port 4443.

Define the cf-logs listener on port 4443, within `terraform/elb.tf`:

```bash
	listener {
		lb_port = 4443
		lb_protocol = "ssl"
		instance_port = 80
		instance_protocol = "tcp"
		ssl_certificate_id = "${aws_acm_certificate.sys_cert.id}"
	}
```

And update the inbound rules for security groups with the cf-logs one (port 4443) within the `terraform/security_groups.tf`:

```bash
resource "aws_security_group_rule" "bosh_inbound_cf_logs" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "CF logs access"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_blocks       = ["${var.my_ip}"]
}
```

After deploying the updated AWS infrastructure, log into cf, run `CF_TRACE=1 cf logs hello` on one terminal and on another one try to curl your app (`curl https://hello.sys.cf-training.training.armakuni.co.uk`). You should see logs for your app in the logs terminal you just opened.

## Issue/Improvement no. 5

Create new app domain:
- within `cf/operations/configure-app-domain.yml` define your new app domain:

```yml
---
- type: replace
  path: /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/app_domains
  value: [((app_domain))]
```

- within `deploy-cf.sh`, update:the CF deployment with this new operations script:

```bash
bosh -e $BOSH_ENVIRONMENT -d cf deploy cf/cf-deployment/cf-deployment.yml \
  --vars-store credentials/cf-creds.yml \
  -o cf/cf-deployment/operations/scale-to-one-az.yml \
  -o cf/cf-deployment/operations/use-compiled-releases.yml \
  -o cf/cf-deployment/operations/aws.yml \
  -o cf/operations/rename-disk-labels.yml \
  -o cf/operations/configure-app-domain.yml \ # use your new operations script
  -v system_domain=sys.$STACK_NAME.training.armakuni.co.uk \
  -v app_domain=app.$STACK_NAME.training.armakuni.co.uk # define your app domain name
```

- redeploy CF:
`./deploy-cf.sh`

Delete shared sys domain:
```bash
cf delete-shared-domain sys.cf-training.training.armakuni.co.uk
```

Create and bind a route for/to your app:

```bash
cf map-route hello app.cf-training.training.armakuni.co.uk --hostname test
```

## Issue no. 6

Try to connect to the app via the app domain URL you've just defined:
```bash
curl https://test.app.cf-training.training.armakuni.co.uk
curl: (6) Could not resolve host: test.app.cf-training.training.armakuni.co.uk
```

Define the route53 for your app domain:
```bash
resource "aws_route53_record" "application_domain" {
	zone_id = "${var.hosted_zone_id}"
	name = "*.app.${var.stack_name}"
	type = "CNAME"
	ttl = 300

	records = [
		"${aws_elb.cf_app_lb.dns_name}"
	]
}
```

Along with this, define the application ELB within the `terraform/elb.tf` file:
```bash
resource "aws_elb" "cf_app_lb" {
	name = "cf-app-lb"
	security_groups = ["${aws_security_group.bosh.id}"]
	subnets = ["${aws_subnet.public.id}"]
	internal = false

	listener {
		lb_port = 443
		lb_protocol = "https"
		instance_port = 80
		instance_protocol = "http"
		ssl_certificate_id = "${aws_acm_certificate.app_cert.id}"
	}

	health_check {
    	healthy_threshold   = 2
    	unhealthy_threshold = 2
    	timeout             = 3
    	target              = "TCP:80"
    	interval            = 30
	}

	tags {
		Name = "${var.stack_name}-cf-app-lb"
	}
}
```

Along with this, you will need to update the certficates with the application related ones:

```bash
resource "aws_acm_certificate" "app_cert" {
	domain_name = "${replace("*.app.${var.stack_name}.${data.aws_route53_zone.root_domain.name}", "/\\.$/", "")}"
	validation_method = "DNS"
}

resource "aws_route53_record" "app_cert_system_validation" {
	name    = "${aws_acm_certificate.app_cert.domain_validation_options.0.resource_record_name}"
	type    = "${aws_acm_certificate.app_cert.domain_validation_options.0.resource_record_type}"
	zone_id = "${var.hosted_zone_id}"
	records = ["${aws_acm_certificate.app_cert.domain_validation_options.0.resource_record_value}"]
	ttl     = 60
}

resource "aws_acm_certificate_validation" "app_cert" {
	certificate_arn = "${aws_acm_certificate.app_cert.arn}"

	validation_record_fqdns = [
		"${aws_route53_record.app_cert_system_validation.fqdn}"
	]
}
```

**Specify to the cf-router to use the app elb**:

```bash
- name: cf-router-network-properties
  cloud_properties:
    elbs: [((system_lb)), ((application_lb))] # add the app elb to this ELB list
```

Update the cloud config properties:

```bash
bosh -e $BOSH_ENVIRONMENT update-cloud-config cf/cloud-config.yml \
  -v system_lb=$(terraform output -state=terraform/.terraform/terraform.tfstate system_lb_name) \
  -v availability_zone=$AVAILABILITY_ZONE \
  -v private_subnet_range=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_cidr) \
  -v security_group=$(terraform output -state=terraform/.terraform/terraform.tfstate bosh_security_group_name) \
  -v gateway_ip=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_gateway_ip) \
  -v subnet_id=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_id) \
  -v application_lb=$(terraform output -state=terraform/.terraform/terraform.tfstate application_lb_name) # define the app ELB to use
```

For the above to work, make sure you update the CF outputs within the `terraform/outputs.tf` file:

```bash
output "application_lb_name" {
	value = "${aws_elb.cf_app_lb.name}"
}
```

## Issue no. 7

Run:
```bash
cf app hello
Showing health and status for app hello in org system / space workspace as admin...

name:              hello
requested state:   started
instances:         3/4
usage:             1G x 4 instances
routes:            test.app.cf-training.training.armakuni.co.uk
last uploaded:     Wed 16 May 16:38:04 BST 2018
stack:             cflinuxfs2
buildpack:         ruby_buildpack

     state     since                  cpu    memory        disk          details
#0   running   2018-05-17T14:31:50Z   0.0%   19.2M of 1G   87.8M of 1G
#1   running   2018-05-17T14:31:50Z   0.0%   18.4M of 1G   87.8M of 1G
#2   running   2018-05-17T14:31:51Z   0.0%   18.4M of 1G   87.8M of 1G
#3   down      2018-05-17T14:32:14Z   0.0%   0 of 1G       0 of 1G       insufficient resources: memory
```

As you can see, the issue resides with not having sufficient memory. To fix this, we can either:
- use a bigger instance type
- or we can scale out the diego cell instances
In terms of [pricing](https://www.ec2instances.info/?cost_duration=monthly), it will be mostly the same, but ideally we should opt for scaling out the diego-cell, as this way we ensure the applications are resilient.

To do so, create an ops file to overwrite the diego-cell instance number defined within `cf/cf-deployment/operations/scale-to-one-az.yml`. This new ops file, `cf/operations/scale-to-more-diego-instances.yml` should look like this:

```yml
---
- type: replace
  path: /instance_groups/name=diego-cell/instances
  value: 2
```

Make sure to update the CF Bosh deployment for scaling up the diego-cell instance:

```bash
bosh -e $BOSH_ENVIRONMENT -d cf deploy cf/cf-deployment/cf-deployment.yml \
  --vars-store credentials/cf-creds.yml \
  -o cf/cf-deployment/operations/scale-to-one-az.yml \
  -o cf/cf-deployment/operations/use-compiled-releases.yml \
  -o cf/cf-deployment/operations/aws.yml \
  -o cf/operations/rename-disk-labels.yml \
  -o cf/operations/configure-app-domain.yml \
  -o cf/operations/scale-to-more-diego-instances.yml \ # scale up the diego-cell here
  -v system_domain=sys.$STACK_NAME.training.armakuni.co.uk \
  -v app_domain=app.$STACK_NAME.training.armakuni.co.uk
```

and run this:

```bash
./deploy.cf
```

## Issue no. 8

Identifying the CF SSH endpoint:
```bash
cf curl /v2/info
{
   "name": "",
   "build": "",
   "support": "",
   "version": 0,
   "description": "",
   "authorization_endpoint": "https://login.sys.cf-training.training.armakuni.co.uk",
   "token_endpoint": "https://uaa.sys.cf-training.training.armakuni.co.uk",
   "min_cli_version": null,
   "min_recommended_cli_version": null,
   "api_version": "2.109.0",
   "app_ssh_endpoint": "ssh.sys.cf-training.training.armakuni.co.uk:2222", # this is the SSH endpoint
   "app_ssh_host_key_fingerprint": "ce:a2:5b:8c:9e:fe:fc:69:0a:ed:23:fb:56:f3:df:76",
   "app_ssh_oauth_client": "ssh-proxy",
   "doppler_logging_endpoint": "wss://doppler.sys.cf-training.training.armakuni.co.uk:4443",
   "routing_endpoint": "https://api.sys.cf-training.training.armakuni.co.uk/routing"
}
```

The obvious solution would be opening up the port 2222 in the security groups and adding a listener on port 2222 to the `sys` LB, but this would not solve the problem. SSH access does not use the HTTP protocol and therefore is not handled by the same server as all other traffic that reaches the `sys` LB.
Within `terraform/elb.tf`, add to the `sys` LB the following:

```bash
	listener {
		lb_port = 2222
		lb_protocol = "tcp"
		instance_port = 2222
		instance_protocol = "tcp"
	}
```


After examining cf-deployment.yml we can find out that the server running the CF component `ssh_proxy` is the one called the `scheduler`.

The solution is to define a new SSH ELB, with a listener on port 2222 within `terraform/elb.tf`:

```bash
resource "aws_elb" "cf_ssh_lb" {
	name = "cf-ssh-lb"
	security_groups = ["${aws_security_group.bosh.id}"]
	subnets = ["${aws_subnet.public.id}"]
	internal = false

	listener {
		lb_port = 2222
		lb_protocol = "tcp"
		instance_port = 2222
		instance_protocol = "tcp"
	}

	health_check {
    	healthy_threshold   = 2
    	unhealthy_threshold = 2
    	timeout             = 3
    	target              = "TCP:2222"
    	interval            = 30
	}

	tags {
		Name = "${var.stack_name}-cf-ssh-lb"
	}
}
```
Remark: No SSL certificate is needed as the traffic is not SSL encrypted.

Add an inbound rule for SSH on port 2222 within `terraform/ecurity_groups.tf`:

```bash
resource "aws_security_group_rule" "bosh_inbound_cf_app_ssh" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "CF app SSH access"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 2222
  to_port           = 2222
  cidr_blocks       = ["${var.my_ip}"]
}
```

Define the SSH specific domain within `terraform/route53.tf`:

```bash
resource "aws_route53_record" "ssh_domain" {
	zone_id = "${var.hosted_zone_id}"
	name = "ssh.sys.${var.stack_name}"
	type = "CNAME"
	ttl = 300

	records = [
		"${aws_elb.cf_ssh_lb.dns_name}"
	]
}
```
The most specific domain will take precedence over the one we defined for `*.sys.${var.stack_name}`.

Output this SSH LB's name within `terraform/outputs.tf`:

```bash
output "ssh_lb_name" {
	value = "${aws_elb.cf_ssh_lb.name}"
}
```

Update the cloud config properties with the newly required variable, the `ssh_lb`:

```bash
bosh -e $BOSH_ENVIRONMENT update-cloud-config cf/cloud-config.yml \
  -v system_lb=$(terraform output -state=terraform/.terraform/terraform.tfstate system_lb_name) \
  -v availability_zone=$AVAILABILITY_ZONE \
  -v private_subnet_range=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_cidr) \
  -v security_group=$(terraform output -state=terraform/.terraform/terraform.tfstate bosh_security_group_name) \
  -v gateway_ip=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_gateway_ip) \
  -v subnet_id=$(terraform output -state=terraform/.terraform/terraform.tfstate private_subnet_id) \
  -v application_lb=$(terraform output -state=terraform/.terraform/terraform.tfstate application_lb_name) \
  -v ssh_lb=$(terraform output -state=terraform/.terraform/terraform.tfstate ssh_lb_name) # update here
```

Update the SSH diego-cell with the corresponding ELB:

```yml
- name: diego-ssh-proxy-network-properties
  cloud_properties:
    elbs: [((ssh_lb))] # this is where you specify the SSH ELB
```

Redeploy AWS and CF:
```bash
./deploy-aws.sh
./deploy-cf.sh
```

SSH into your app:
```bash
cf ssh hello
```
