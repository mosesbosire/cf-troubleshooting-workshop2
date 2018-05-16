resource "aws_route53_record" "system_domain" {
	zone_id = "${var.hosted_zone_id}"
	name = "*.sys.${var.stack_name}"
	type = "CNAME"
	ttl = 300

	records = [
		"${aws_elb.cf_sys_lb.dns_name}"
	]
}
