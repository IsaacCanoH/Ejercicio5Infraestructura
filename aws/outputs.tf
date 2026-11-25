output "instance_id" {
  description = "Identificador del servidor EC2."
  value       = aws_instance.gestor.id
}

output "public_ip" {
  description = "Direccion IP publica del servidor."
  value       = aws_instance.gestor.public_ip
}

output "instance_type" {
  description = "Tipo de instancia utilizado."
  value       = aws_instance.gestor.instance_type
}

output "security_group_id" {
  description = "Identificador del grupo de seguridad."
  value       = aws_security_group.web.id
}