variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace для ArgoCD"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Назва Helm release"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія ArgoCD Helm chart"
  type        = string
  default     = "5.51.6"
}

variable "service_type" {
  description = "Тип Kubernetes service"
  type        = string
  default     = "LoadBalancer"
}

variable "helm_repo_url" {
  description = "URL Helm charts репозиторію"
  type        = string
}

variable "domain" {
  description = "Домен для ArgoCD"
  type        = string
  default     = "argocd.example.com"
}
