# Print output
 
# output "instanceId" {
#   value = aws_instance.jenkins_instance.id  
# }

# Loop over a map and output a map
# {for <KEY>, <VALUE> in <MAP> : <OUTPUT_KEY> => <OUTPUT_VALUE>}

output "instanceId" {
  value = {
    for i, j in aws_instance.jenkins_instance : i => j.id
  }  
}

# output "server_public_ip" {
#   value = aws_instance.jenkins_instance.public_ip
# }
output "server_public_ip" {
  value = {
    for i, j in aws_instance.jenkins_instance : i => j.public_ip
  }
}

# output "private_ip" {
#   value = aws_instance.jenkins_instance.private_ip
# }

output "private_ip" {
  value = {
    for i, j in aws_instance.jenkins_instance : i => j.private_ip
  }
}