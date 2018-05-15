resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.training_vpc.id}"
  cidr_block        = "${var.public_subnet_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name       = "public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.training_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name       = "public"
    Role       = "main"
  }
}