data "aws_route53_zone" "root_domain" {
	zone_id = "${var.hosted_zone_id}"
}

resource "aws_acm_certificate" "sys_cert" {
	domain_name = "${replace("*.sys.${var.stack_name}.${data.aws_route53_zone.root_domain.name}", "/\\.$/", "")}"
	validation_method = "DNS"

	subject_alternative_names = [
		"*.login.sys.${replace("${var.stack_name}.${data.aws_route53_zone.root_domain.name}", "/\\.$/", "")}",
		"*.uaa.sys.${replace("${var.stack_name}.${data.aws_route53_zone.root_domain.name}", "/\\.$/", "")}",
	]
}

resource "aws_route53_record" "sys_cert_system_validation" {
	name    = "${aws_acm_certificate.sys_cert.domain_validation_options.0.resource_record_name}"
	type    = "${aws_acm_certificate.sys_cert.domain_validation_options.0.resource_record_type}"
	zone_id = "${var.hosted_zone_id}"
	records = ["${aws_acm_certificate.sys_cert.domain_validation_options.0.resource_record_value}"]
	ttl     = 60
}

resource "aws_route53_record" "sys_cert_uaa_validation" {
	name    = "${aws_acm_certificate.sys_cert.domain_validation_options.1.resource_record_name}"
	type    = "${aws_acm_certificate.sys_cert.domain_validation_options.1.resource_record_type}"
	zone_id = "${var.hosted_zone_id}"
	records = ["${aws_acm_certificate.sys_cert.domain_validation_options.1.resource_record_value}"]
	ttl     = 60
}

resource "aws_route53_record" "sys_cert_login_validation" {
	name    = "${aws_acm_certificate.sys_cert.domain_validation_options.2.resource_record_name}"
	type    = "${aws_acm_certificate.sys_cert.domain_validation_options.2.resource_record_type}"
	zone_id = "${var.hosted_zone_id}"
	records = ["${aws_acm_certificate.sys_cert.domain_validation_options.2.resource_record_value}"]
	ttl     = 60
}

resource "aws_acm_certificate_validation" "sys_cert" {
	certificate_arn = "${aws_acm_certificate.sys_cert.arn}"

	validation_record_fqdns = [
		"${aws_route53_record.sys_cert_system_validation.fqdn}",
		"${aws_route53_record.sys_cert_uaa_validation.fqdn}",
		"${aws_route53_record.sys_cert_login_validation.fqdn}",
	]
}