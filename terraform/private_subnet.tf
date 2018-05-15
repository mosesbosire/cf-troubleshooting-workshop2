resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.training_vpc.id}"
  cidr_block        = "${var.private_subnet_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name       = "private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.training_vpc.id}"

  tags {
    Name       = "private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route" "private" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}
