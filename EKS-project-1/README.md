
**Run the following command to create the resources**

terraform init

terraform plan --var-file=variables.tfvars

terraform apply --var-file=variables.tfvars --auto-approve

# Once Cluster status get active

**Set the EKS Cluster context using following command**

aws eks update-kubeconfig --region ap-southeast-1 --name EKS-Cluster

Also, Enable proxy using

kubectl proxy --port=80

Note: Rerun the "terraform apply" command in case of any failure. However, you can terminate the execution if it remains stuck for an extended period during coreDNS creation or when a node joins the cluster.

