output "s3_bucket_name" {
  description = "S3-bucket for states"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for locked states"
  value       = module.s3_backend.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "Command to configure kubectl access to the cluster"
  value       = module.eks.kubeconfig_command
}

# Jenkins Outputs
output "jenkins_release" {
  description = "Jenkins Helm release name"
  value       = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_url" {
  description = "Jenkins internal URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = module.jenkins.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

# ArgoCD Outputs
output "argocd_release" {
  description = "ArgoCD Helm release name"
  value       = module.argo_cd.argocd_release_name
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.argo_cd.argocd_namespace
}

output "argocd_server_url" {
  description = "ArgoCD server internal URL"
  value       = module.argo_cd.argocd_server_url
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = module.argo_cd.argocd_admin_password_command
}

# RDS Outputs
output "rds_endpoint" {
  description = "Database host for Django DATABASE_HOST (Aurora writer or standard RDS)"
  value       = try(coalesce(module.rds.aurora_cluster_endpoint, module.rds.rds_address), null)
}

output "rds_port" {
  description = "Database port"
  value       = module.rds.db_port
}

output "rds_db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

# Monitoring Outputs
output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = module.monitoring.grafana_admin_user
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

output "grafana_url_command" {
  description = "Command to get Grafana external address"
  value       = module.monitoring.grafana_url_command
}

output "prometheus_portforward_command" {
  description = "Command to access Prometheus UI locally"
  value       = module.monitoring.prometheus_portforward_command
}
