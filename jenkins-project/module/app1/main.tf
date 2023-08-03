provider "aws" {
  region = var.app_region
  # access_key = "AKIA6FTLNT35C435UT7H"
  # secret_key = "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"
}

variable "app_region" {
    #default = "ap-southeast-1"
}

# 1. Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

variable "subnet_prefix" {
  description = "cidr block for subnet"
  #default = "10.0.30.0/24"
}
# 2. Create Subnet
resource "aws_subnet" "pub_subnetA" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_prefix[0].cidr_block
  map_public_ip_on_launch = true
  availability_zone = var.app_region == "ap-southeast-1" ? "ap-southeast-1a" : "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}
resource "aws_subnet" "pub_subnetB" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_prefix[1].cidr_block
  map_public_ip_on_launch = true
  availability_zone = var.app_region == "ap-southeast-1" ? "ap-southeast-1b" : "us-east-1b"

  tags = {
    Name = var.subnet_prefix[1].name
  }
}
# 3. Create internet gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "myIGW"
  }
}
# 4. Create route table
resource "aws_route_table" "pub-RT" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "pub-RT"
  }
}
# 5. Create route table association
resource "aws_route_table_association" "pub-RT-association" {
  subnet_id      = aws_subnet.pub_subnetA.id
  route_table_id = aws_route_table.pub-RT.id
}
resource "aws_route_table_association" "pubB-RT-association" {
  subnet_id      = aws_subnet.pub_subnetB.id
  route_table_id = aws_route_table.pub-RT.id
}
# 6. Create security group
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "open HTTPS from everywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "open HTTP everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "open SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mySG"
  }
}
# 7. Create network interface
resource "aws_network_interface" "my-ENI" {
  subnet_id       = aws_subnet.pub_subnetA.id
  security_groups = [aws_security_group.mySG.id]
}
# 8. Create EIP
resource "aws_eip" "my_eip" {
  domain = "vpc"
  network_interface = aws_network_interface.my-ENI.id
  # associate_with_private_ip = "10.0.10.50"
  depends_on = [aws_internet_gateway.myIGW]
}
# Create ssh keypair
resource "aws_key_pair" "my-keypair" {
  key_name = "terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxCsaSC8vCHsmONR10Bz+GqvrMCM6+RpajuUcbRsBPkkYT+p8bNw5oDZhOdgsvCp+Blaj5LhHCjTZhGT3C1+LvRMwb4IZNdhfhy0SrQDtN0dQnJlgwnaLkXGMsQ6I6ehJkNeDQ0wU5NOTITOZ4Q4AOmlaVRvjWcHjmAg4jVkOOLBNsl42Cw0aRSgOMo5RQSAuINl8OF8qbXh9rMcdrApAdS2UvLaD1zxpfeAIOjfdF2ZQL0UDafwEuOnyVVRCdMDrt6VcyXWNyo7NCr85jUGMTieMuSVL6ARJ+Aer4npKLRb7P4tsgKgIQKhu5J8coAm/GmfoVeWisGRpqZiqb8dZ5OYT6yPK2XUEwi69kmffiEmyfMJtOoRyomsPwP93WrxUtaJA037bBB/FmwYv80Zgbic1ZRdO6DQ2pRDs4uZ6dSh2QHBMWstfNB80OJ1mjw8iVtV4G1Dd9oBMuoqYC5QeQGxUn5gwpH+vAG7yMnBXXLPKvfAJHkE6QjnO2WD0qevM= raiyan@DESKTOP-670C4M2"
}
#
variable "resource_list" {
  type = set(string)
  default = ["web1", "web2"]  
}

variable "ec2-ami" {
    default = "ami-0df7a207adb9748c7"
}

resource "aws_instance" "aws_instance" {
  ami           = var.ec2-ami
  instance_type = "t3.medium" 
  availability_zone = var.app_region == "ap-southeast-1" ? "ap-southeast-1a" : "us-east-1a"
  for_each = var.resource_list

  network_interface {
    network_interface_id = aws_network_interface.my-ENI.id
    device_index         = 0
  }
  tags = {
    Name = each.value
  }
}  

