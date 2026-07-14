variable "name" {
  description = "Назва інстансу або кластера"
  type        = string
}

variable "use_aurora" {
  description = "Використовувати Aurora Cluster (true) або Standard RDS (false)"
  type        = bool
  default     = false
}

# Engine settings
variable "engine" {
  description = "Database engine для Standard RDS (postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_cluster" {
  description = "Database engine для Aurora (aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Engine version для Standard RDS"
  type        = string
  default     = "14.7"
}

variable "engine_version_cluster" {
  description = "Engine version для Aurora"
  type        = string
  default     = "15.3"
}

# Instance settings
variable "instance_class" {
  description = "Instance class (db.t3.micro, db.r5.large, etc.)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage в GB (тільки для Standard RDS)"
  type        = number
  default     = 20
}

variable "aurora_replica_count" {
  description = "Кількість reader replicas для Aurora"
  type        = number
  default     = 1
}

# Database credentials
variable "db_name" {
  description = "Ім'я бази даних"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

# Network settings
variable "vpc_id" {
  description = "VPC ID де буде розміщено RDS"
  type        = string
}

variable "subnet_private_ids" {
  description = "Private subnet IDs для RDS"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "Public subnet IDs для RDS (якщо publicly_accessible = true)"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Чи має бути RDS доступним з інтернету"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks з яких дозволено підключення до RDS"
  type        = list(string)
  default     = ["10.0.0.0/8"] # Private networks by default
}

variable "multi_az" {
  description = "Чи використовувати Multi-AZ для Standard RDS"
  type        = bool
  default     = false
}

# Backup settings
variable "backup_retention_period" {
  description = "Кількість днів для зберігання backup (0-35)"
  type        = number
  default     = 7
}

# Parameter groups
variable "parameter_group_family_aurora" {
  description = "Parameter group family для Aurora"
  type        = string
  default     = "aurora-postgresql15"
}

variable "parameter_group_family_rds" {
  description = "Parameter group family для Standard RDS"
  type        = string
  default     = "postgres15"
}

variable "parameters" {
  description = "Custom database parameters"
  type        = map(string)
  default     = {}
}

# Tags
variable "tags" {
  description = "Tags для всіх ресурсів"
  type        = map(string)
  default     = {}
}
