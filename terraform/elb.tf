resource "aws_elb" "cf_sys_lb" {
	name = "cf-sys-lb"
	security_groups = ["${aws_security_group.bosh.id}"]
	subnets = ["${aws_subnet.public.id}"]
	internal = false

	listener {
		lb_port = 443
		lb_protocol = "https"
		instance_port = 8080
		instance_protocol = "http"
		ssl_certificate_id = "${aws_acm_certificate.sys_cert.id}"
	}

	health_check {
    	healthy_threshold   = 2
    	unhealthy_threshold = 2
    	timeout             = 3
    	target              = "HTTP:8000/"
    	interval            = 30
	}

	tags {
		Name = "${var.stack_name}-cf-sys-lb"
	}
}