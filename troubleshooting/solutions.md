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

