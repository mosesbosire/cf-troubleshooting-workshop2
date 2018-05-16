output "jumpbox_ip" {
	value = "${aws_eip.jumpbox_public_ip.public_ip}"
}

output "private_subnet_id" {
	value = "${aws_subnet.private.id}"
}

output "private_subnet_cidr" {
	value = "${aws_subnet.private.cidr_block}"
}

output "private_subnet_gateway_ip" {
	value = "${cidrhost("${aws_subnet.private.cidr_block}", 1)}"
}

output "director_private_ip" {
	value = "${cidrhost("${aws_subnet.private.cidr_block}", 6)}"
}

output "bosh_security_group_name" {
	value = "${aws_security_group.bosh.name}"
}

output "system_lb_name" {
	value = "${aws_elb.cf_sys_lb.name}"
}
