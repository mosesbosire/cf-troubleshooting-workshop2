resource "aws_security_group" "bosh" {
  name        = "${var.stack_name}-bosh"
  description = "Bosh access"
  vpc_id      = "${aws_vpc.training_vpc.id}"

  tags {
    Name = "${var.stack_name}-bosh"
    Role = "bosh"
  }
}

# create outbound security rule
resource "aws_security_group_rule" "bosh_outbound" {
  security_group_id = "${aws_security_group.bosh.id}"
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# create inbound security rule
resource "aws_security_group_rule" "bosh_inbound_ssh" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "SSH access"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["${var.my_ip}"]
}

resource "aws_security_group_rule" "bosh_inbound_6868" {
  security_group_id        = "${aws_security_group.bosh.id}"
  description              = "BOSH Agent access"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 6868
  to_port                  = 6868
  source_security_group_id = "${aws_security_group.bosh.id}"
}

resource "aws_security_group_rule" "bosh_inbound_25555" {
  security_group_id        = "${aws_security_group.bosh.id}"
  description              = "BOSH Director access"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 25555
  to_port                  = 25555
  source_security_group_id = "${aws_security_group.bosh.id}"
}

resource "aws_security_group_rule" "bosh_inbound_tcp_65535" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "Management and data access"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  self              = "true"
}

resource "aws_security_group_rule" "bosh_inbound_udp_65535" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "Management and data access"
  type              = "ingress"
  protocol          = "udp"
  from_port         = 0
  to_port           = 65535
  self              = "true"
}

resource "aws_security_group_rule" "bosh_inbound_tcp_443" {
  security_group_id = "${aws_security_group.bosh.id}"
  description       = "Management and data access"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["${var.my_ip}"]
}
