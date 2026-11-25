variable "project_name" {
  description = "Nombre para identificar los recursos del proyecto."
  type        = string
  default     = "gestor-devops"
}

variable "instance_type" {
  description = "Tipo de servidor EC2."
  type        = string
  default     = "t3.small"
}

variable "root_volume_gib" {
  description = "Capacidad del disco del servidor en GiB."
  type        = number
  default     = 30
}