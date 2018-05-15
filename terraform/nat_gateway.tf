# NAT Elastic IP
resource "aws_eip" "nat" {
  vpc = true

   tags {
    Name       = "${var.stack_name}-nat-gateway"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"

  tags {
    Name       = "${var.stack_name}"
  }
}
