variable "environment" {
  description = "Environment tag applied across all modules (single source of truth)"
  type        = string
  default     = "lesson-7"
}

variable "db_password" {
  description = "Master password for the RDS/Aurora database (set via TF_VAR_db_password, never commit)"
  type        = string
  sensitive   = true
}
