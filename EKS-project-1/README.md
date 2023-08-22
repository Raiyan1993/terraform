
**Run the following command to create the resources**

terraform init

terraform plan --var-file=variables.tfvars

terraform apply --var-file=variables.tfvars --auto-approve

**Once the cluster status becomes "Active"**

*Set the EKS cluster context using the following command:*

aws eks update-kubeconfig --region ap-southeast-1 --name EKS-Cluster

Additionally, enable the proxy to access the EKS API server locally as here[1].

kubectl proxy --port=80

Note: Rerun the "terraform apply" command in case of any failure. However, you can terminate the execution if it remains stuck for an extended period during coreDNS creation or when a node has joined the cluster.

**Reference:**

[1] https://kubernetes.io/docs/tasks/extend-kubernetes/http-proxy-access-api/
