output "vpc_id" {
  description = "ID der VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID des Public Subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID der Security Group"
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID der EC2-Instanz"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Öffentliche IP der EC2-Instanz"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Öffentlicher DNS der EC2-Instanz"
  value       = aws_instance.web.public_dns
}

output "webserver_url" {
  description = "URL zum Webserver"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ssh_command" {
  description = "SSH-Befehl zum Verbinden"
  value       = var.ssh_public_key != "" ? "ssh -i ~/.ssh/your-key ubuntu@${aws_instance.web.public_ip}" : "SSH nicht konfiguriert"
}