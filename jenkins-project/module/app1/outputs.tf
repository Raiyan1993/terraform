output "instanceId" {
  value = {
    for i, j in aws_instance.app-instance : i => j.id
  }  
}

output "server_public_ip" {
  value = {
    for i, j in aws_instance.app-instance : i => j.public_ip
  }
}

output "private_ip" {
  value = {
    for i, j in aws_instance.app-instance : i => j.private_ip
  }
}