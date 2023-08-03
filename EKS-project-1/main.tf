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
# # Create an EKS cluster
# resource "aws_eks_cluster" "my_cluster" {
#   name     = "Cluster02"
#   role_arn = aws_iam_role.eks_cluster.arn
#   version  = "1.23" # Replace with your desired Kubernetes version

#   vpc_config {
#     subnet_ids = [aws_subnet.pub_subnetA.id, aws_subnet.pub_subnetB.id] # Replace with your desired private subnet IDs for the EKS cluster
#   }
# }
# # Create an IAM role for the EKS cluster
# resource "aws_iam_role" "eks_cluster" {
#   name = "eks-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }
# # Attach the necessary IAM policies to the EKS cluster role
# resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_cluster.name
# }
# # Create an IAM role for the EKS node group
# resource "aws_iam_role" "eks_node_group" {
#   name = "eks-node-group-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }
# # Attach the necessary IAM policies to the EKS node group role
# resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_node_group.name
# }

# resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_node_group.name
# }

# resource "aws_iam_role_policy_attachment" "eks_ec2_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_node_group.name
# }

# Create an EKS node group
# resource "aws_eks_node_group" "my_node_group" {
#   cluster_name    = aws_eks_cluster.my_cluster.name
#   node_group_name = "my-node-group"
#   node_role_arn   = aws_iam_role.eks_node_group.arn
#   subnet_ids      = [aws_subnet.pub_subnetA.id, aws_subnet.pub_subnetB.id]  # Add your subnet IDs here
#   #instance_type   = "t3.medium"  # Replace with your desired instance type
#   #desired_capacity = 2  # Replace with your desired number of nodes
#   scaling_config {
#     desired_size = 2  # Replace with your desired number of nodes
#     max_size     = 4  # Replace with your desired maximum number of nodes
#     min_size     = 1  # Replace with your desired minimum number of nodes
#   }
# }

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
        }
    }
  
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }  
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<-EOT
      - rolearn: "arn:aws:iam::255229340250:role/self_mg_4-node-group-20230802170652623100000006"
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
    EOT
  }
}

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

