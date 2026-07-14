# Outputs для Aurora
output "aurora_cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "aurora_cluster_id" {
  description = "Aurora cluster identifier"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].id : null
}

output "aurora_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].arn : null
}

# Outputs для Standard RDS
output "rds_endpoint" {
  description = "Standard RDS instance endpoint"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].endpoint
}

output "rds_address" {
  description = "Standard RDS instance address (hostname)"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].address
}

output "rds_id" {
  description = "Standard RDS instance identifier"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].id
}

output "rds_arn" {
  description = "Standard RDS instance ARN"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].arn
}

# Спільні outputs
output "db_port" {
  description = "Database port"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_username" {
  description = "Database master username"
  value       = var.username
  sensitive   = true
}

output "security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "DB Subnet Group name"
  value       = aws_db_subnet_group.default.name
}

# Connection string
output "connection_string" {
  description = "PostgreSQL connection string"
  value = var.use_aurora ? (
    "postgresql://${var.username}:${var.password}@${aws_rds_cluster.aurora[0].endpoint}:${aws_rds_cluster.aurora[0].port}/${var.db_name}"
    ) : (
    "postgresql://${var.username}:${var.password}@${aws_db_instance.standard[0].address}:${aws_db_instance.standard[0].port}/${var.db_name}"
  )
  sensitive = true
}
