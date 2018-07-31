data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "jumpbox" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  key_name               = "cf-training-moses"
  vpc_security_group_ids = ["${aws_security_group.bosh.id}"]
  subnet_id              = "${aws_subnet.public.id}"

  tags {
    Name = "jumpbox"
  }
}

# Associating a public IP to our jumbox by creating an AWS Elastic IP. This is an alternative as to setting 'associate_public_ip_address = true` on the `aws_instance` resource. This would generate a random public IP, as opposed to having our IP retained.
resource "aws_eip" "jumpbox_public_ip" {
  vpc = true
}

resource "aws_eip_association" "jumpbox_ip_assoc" {
  instance_id   = "${aws_instance.jumpbox.id}"
  allocation_id = "${aws_eip.jumpbox_public_ip.id}"
}
