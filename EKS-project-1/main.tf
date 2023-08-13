terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }
  }
}

variable "aws_region" {
  default = "ap-southeast-1"
}

provider "aws" {
  region     = var.aws_region
  # access_key = "AKIAT256E5R7LWX5PMHT"
  # secret_key = "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"
}

# 1. Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
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
  availability_zone       = "ap-southeast-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}
resource "aws_subnet" "pub_subnetB" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_prefix[1].cidr_block
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1b"

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
# Create SSH Keypair
resource "aws_key_pair" "my-keypair" {
  key_name   = "tarraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxCsaSC8vCHsmONR10Bz+GqvrMCM6+RpajuUcbRsBPkkYT+p8bNw5oDZhOdgsvCp+Blaj5LhHCjTZhGT3C1+LvRMwb4IZNdhfhy0SrQDtN0dQnJlgwnaLkXGMsQ6I6ehJkNeDQ0wU5NOTITOZ4Q4AOmlaVRvjWcHjmAg4jVkOOLBNsl42Cw0aRSgOMo5RQSAuINl8OF8qbXh9rMcdrApAdS2UvLaD1zxpfeAIOjfdF2ZQL0UDafwEuOnyVVRCdMDrt6VcyXWNyo7NCr85jUGMTieMuSVL6ARJ+Aer4npKLRb7P4tsgKgIQKhu5J8coAm/GmfoVeWisGRpqZiqb8dZ5OYT6yPK2XUEwi69kmffiEmyfMJtOoRyomsPwP93WrxUtaJA037bBB/FmwYv80Zgbic1ZRdO6DQ2pRDs4uZ6dSh2QHBMWstfNB80OJ1mjw8iVtV4G1Dd9oBMuoqYC5QeQGxUn5gwpH+vAG7yMnBXXLPKvfAJHkE6QjnO2WD0qevM= raiyan@DESKTOP-670C4M2"
}

variable "worker_instance_type" {
  description = "worker instance type"
  default     = "t3.medium"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.15.2"
  cluster_name    = "EKS-Cluster"
  cluster_version = "1.23"
  subnet_ids      = [aws_subnet.pub_subnetA.id, aws_subnet.pub_subnetB.id]
  vpc_id          = aws_vpc.my_vpc.id
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
    self_mg_4 = {
      node_group_name    = "self-managed-ondemand"
      launch_template_os = "amazonlinux2eks"
      subnet_ids         = [aws_subnet.pub_subnetA.id, aws_subnet.pub_subnetB.id]
      instance_type      = "t3.medium"
      key_name           = aws_key_pair.my-keypair.key_name
      min_size           = 1
      max_size           = 4
      desired_size       = 2
      #iam_role_additional_policies = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

    }
  }
  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    { 
      rolearn = "arn:aws:iam::968020774214:role/self_mg_4-node-group-20230813042528843400000006"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
  ]
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::550876841141:user/Raiyan"
      username = "Raiyan"
      groups   = ["system:masters"]
    },
  ]  
  
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }  
}

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }
#   data = {
#     mapRoles = <<-EOT
#       - rolearn: "arn:aws:iam::968020774214:role/self_mg_4-node-group-20230813042528843400000006"
#         username: system:node:{{EC2PrivateDNSName}}
#         groups:
#           - system:bootstrappers
#           - system:nodes
#     EOT
#   }
# }

# data "aws_iam_roles" "my_nodegroup" {
#   name_regex  = "self_mg_.*"
# }

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }
# # import the aws-auth configmap #
# resource "kubernetes_config_map" "aws-auth" {
#   data = {
#     "mapRoles" = ""
#   }

#   metadata {
#     name      = ""
#     namespace = ""
#   }
# }

