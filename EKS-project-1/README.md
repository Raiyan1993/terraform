
**Run the following command to create the resources**

terraform init

terraform plan --var-file=variables.tfvars

terraform apply --var-file=variables.tfvars --auto-approve

# Once Cluster status get active

**Set the EKS Cluster context using following command**

aws eks update-kubeconfig --region ap-southeast-1 --name EKS-Cluster

Also, Enable proxy using

kubectl proxy --port=80

Note: Re-run "terraform apply" command incase of failure


