output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

# output "self_managed_node_group_iam_role_arn" {
#   description = "The Amazon Resource Name (ARN) specifying the IAM role for the self managed node group"
#   value       = module.eks.self_managed_node_groups.self_mg_4.iam_role_arn
# }

# output "cluster_certificate_authority_data" {
#   description = "cluster_certificate_authority_data"
#   value       = module.eks.cluster_certificate_authority_data
# }