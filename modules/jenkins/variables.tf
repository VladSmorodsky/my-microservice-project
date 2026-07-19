variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "release_name" {
  description = "Назва Helm release"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Версія Jenkins Helm chart"
  type        = string
  default     = "5.9.33"
}

variable "admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "storage_class" {
  description = "Storage class для Jenkins PVC"
  type        = string
  default     = "gp2"
}

variable "service_type" {
  description = "Тип Kubernetes service"
  type        = string
  default     = "LoadBalancer"
}

variable "ecr_repository_url" {
  description = "URL ECR-репозиторію (з module.ecr) — підставляється в Jenkins як env для пайплайна"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS регіон для пайплайна"
  type        = string
  default     = "us-east-1"
}
