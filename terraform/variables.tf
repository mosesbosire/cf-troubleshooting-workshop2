# common
variable "aws_region"            {}
variable "aws_access_key_id"     {}
variable "aws_secret_access_key" {}

# internal
variable "stack_name"            {}
variable "public_subnet_cidr"    {
	default = "10.0.1.0/24"
}
variable "availability_zone"     {}
variable "private_subnet_cidr"   {
	default = "10.0.2.0/24"
}
variable "my_ip"				 {}
variable "hosted_zone_id"		 {}