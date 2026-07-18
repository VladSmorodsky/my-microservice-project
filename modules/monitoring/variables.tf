variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "namespace" {
  description = "Namespace для стеку моніторингу"
  type        = string
  default     = "monitoring"
}

variable "release_name" {
  description = "Назва Helm release"
  type        = string
  default     = "kube-prometheus-stack"
}

variable "chart_version" {
  description = "Версія kube-prometheus-stack Helm chart"
  type        = string
  default     = "65.5.1"
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "grafana_service_type" {
  description = "Тип Service для Grafana (LoadBalancer = зовнішній доступ, ClusterIP = лише через port-forward)"
  type        = string
  default     = "LoadBalancer"
}

variable "storage_class" {
  description = "Storage class для дисків Prometheus/Grafana"
  type        = string
  default     = "gp2"
}

variable "prometheus_storage_size" {
  description = "Розмір диска для Prometheus TSDB"
  type        = string
  default     = "10Gi"
}

variable "prometheus_retention" {
  description = "Скільки часу зберігати метрики"
  type        = string
  default     = "7d"
}
