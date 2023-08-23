terraform {
  backend "s3" {
    bucket = "terraform-state-s3-raiyan"
    key    = "my-terraform-project"
    region = "ap-southeast-1"
    #dynamodb_table          = "terraform-state-lock-dynamo"
  }
}
# terraform {
#    backend "local" {}
# }   

variable "app_region" {
  default = "ap-southeast-1"
}

provider "aws" {
  region = var.app_region
  # access_key = "AKIA6FTLNT35C435UT7H"
  # secret_key = "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"
}

resource "aws_s3_bucket" "my-s3" {
  bucket = "terraform-state-s3-raiyan"
}
resource "aws_s3_bucket_versioning" "my-versioning" {
  bucket = aws_s3_bucket.my-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 1. Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
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
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_prefix[0].cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.app_region == "ap-southeast-1" ? "ap-southeast-1a" : "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}
resource "aws_subnet" "pub_subnetB" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_prefix[1].cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.app_region == "ap-southeast-1" ? "ap-southeast-1b" : "us-east-1b"

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
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.myIGW.id
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
    description = "open port 8080 for jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "open port 9000 for sonarqube"
    from_port   = 9000
    to_port     = 9000
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
  private_ips     = ["10.0.10.50"]
  security_groups = [aws_security_group.mySG.id]
}
# 8. Create EIP
resource "aws_eip" "my_eip" {
  #vpc                       = true
  network_interface         = aws_network_interface.my-ENI.id
  associate_with_private_ip = "10.0.10.50"
  depends_on                = [aws_internet_gateway.myIGW]
}
# Create ssh keypair
resource "aws_key_pair" "my-keypair" {
  key_name   = "terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIEj7w17D/w9H9L+9hB72vON7Q7R018qvhdc33yDbDEZ2goVm63zuBB16QtkjQz1VRbiu2PFNRfwyCHTKbmG+uON3RkAnAfKm4/WdZv/mydNnzsRNqYHitrRvzi68zWo0ixOQQwQXzznyggYbcb2XpaQZzwhEwEdyPRNxk0kcjDzatmcWrrIlcL8SrYwacceylg1mMJBDApH2x0EloBvdJKw1My8ru9mCO5HBX3Z/1WRWzSwPNqEshJIaZ0CSNW56UkRh23Y0Z47mgoVCKXMYUBwFjVBlRrHgfRG/8pu6jCxehjM8hpwVEyIAu4z+JlE9baCmbuxxjWWOCtD0hPxTDa5qupF/e7qKY5hy8MIIe+DvWKaR8qUNVM/veTF5hie1OzLRXVoYcZNtsFdF7NiZ96Je4dweCWyuM0yLYrGFCY8XD7IXjpAZUbtiPmP5C4cWUvE8kx+/Bu2+UQ3kkjUpsTGvIP+o7h+F5+sjw1+FNBYC0feVOhY8o/8ciMfKPkMc= raiyan@EPINCHEW015C"
}
#
variable "resource_list" {
  type    = set(string)
  default = ["web1"]

}
# 9. Create instance
resource "aws_instance" "jenkins_instance" {
  ami               = "ami-0df7a207adb9748c7" # ap-southeast-1
  instance_type     = "t3.medium"
  key_name          = aws_key_pair.my-keypair.key_name
  availability_zone = var.app_region == "ap-southeast-1" ? "ap-southeast-1a" : "us-east-1a"
  # subnet_id     = aws_subnet.pub_subnetA.id
  for_each = var.resource_list

  network_interface {
    network_interface_id = aws_network_interface.my-ENI.id
    device_index         = 0
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb
              sudo dpkg -i jdk-17_linux-x64_bin.deb
              curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee \
              /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install jenkins -y
              sudo apt-get install docker.io -y
              sudo su -
              usermod -aG docker jenkins
              usermod -aG docker ubuntu
              systemctl restart docker
              apt-get install unzip
              mkdir /home/sonarqube
              useradd -p $(openssl passwd -1 sonar) sonarqube -s /bin/bash
              echo "sonarqube ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
              wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.1.69595.zip
              unzip sonarqube-9.9.1.*
              mv sonarqube-9.9.1.69595 /home/sonarqube
              chmod -R 755 /home/sonarqube/
              chown -R sonarqube:sonarqube /home/sonarqube/
              su -c '/home/sonarqube/sonarqube-9.9.1.69595/bin/linux-x86-64/sonar.sh start' sonarqube
              EOF
  tags = {
    Name = each.value
  }
  lifecycle {
    # prevent_destroy = true
    # create_before_destroy = true
  }
}