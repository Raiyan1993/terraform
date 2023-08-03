module "app2" {
  source = "../app1"
  app_region = "us-east-1"
  ec2-ami = "ami-053b0d53c279acc90"
  subnet_prefix = [{ cidr_block = "10.0.10.0/24", name = "pub-subA" }, { cidr_block = "10.0.20.0/24", name = "pub-subB" }]
  resource_list = ["web2"]
}

output "app2" {
  value = {
    for i, j in module.app2 : i => j.id
  }  
}