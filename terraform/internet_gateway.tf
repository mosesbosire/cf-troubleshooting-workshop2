resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.training_vpc.id}"

  tags {
    Name  = "${var.stack_name}"
    Role  = "internet-gateway"
  }
}