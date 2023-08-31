variable "aws_region" {
  # default = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR Range"
  # default = "192.168.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "terraform-eks",
  }
}

# 2. Create Subnet
resource "aws_subnet" "pub_subnet" {
  count = "${length(data.aws_availability_zones.available.names)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block              = "192.168.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.my_vpc.id
  tags = {
    Name = "terraform-eks",
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
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = aws_subnet.pub_subnet.*.id[count.index]
  route_table_id = aws_route_table.pub-RT.id
}

# Create SSH Keypair
resource "aws_key_pair" "my-keypair" {
  key_name   = "tarraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIEj7w17D/w9H9L+9hB72vON7Q7R018qvhdc33yDbDEZ2goVm63zuBB16QtkjQz1VRbiu2PFNRfwyCHTKbmG+uON3RkAnAfKm4/WdZv/mydNnzsRNqYHitrRvzi68zWo0ixOQQwQXzznyggYbcb2XpaQZzwhEwEdyPRNxk0kcjDzatmcWrrIlcL8SrYwacceylg1mMJBDApH2x0EloBvdJKw1My8ru9mCO5HBX3Z/1WRWzSwPNqEshJIaZ0CSNW56UkRh23Y0Z47mgoVCKXMYUBwFjVBlRrHgfRG/8pu6jCxehjM8hpwVEyIAu4z+JlE9baCmbuxxjWWOCtD0hPxTDa5qupF/e7qKY5hy8MIIe+DvWKaR8qUNVM/veTF5hie1OzLRXVoYcZNtsFdF7NiZ96Je4dweCWyuM0yLYrGFCY8XD7IXjpAZUbtiPmP5C4cWUvE8kx+/Bu2+UQ3kkjUpsTGvIP+o7h+F5+sjw1+FNBYC0feVOhY8o/8ciMfKPkMc= raiyan@EPINCHEW015C"
}

locals {
  name            = "EKS-Cluster"
  cluster_version = "1.24"
  region          = var.aws_region
  instance_type   = "t3.medium"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.2"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  subnet_ids                     = aws_subnet.pub_subnet[*].id
  vpc_id                         = aws_vpc.my_vpc.id
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  self_managed_node_groups = {
    self_mng = {
      node_group_name    = "self-managed-ondemand"
      launch_template_os = "amazonlinux2eks"
      subnet_ids         = aws_subnet.pub_subnet[*].id
      instance_type      = local.instance_type
      key_name           = aws_key_pair.my-keypair.key_name
      min_size           = 0
      max_size           = 3
      desired_size       = 2
    }
  }

  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  
  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::968020774214:role/self_mng-node-group-20230813042528843400000006"
  #     username = "system:node:{{EC2PrivateDNSName}}"
  #     groups   = ["system:bootstrappers", "system:nodes"]
  #   },
  # ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}