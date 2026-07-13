output "jenkins_release_name" {
  value = helm_release.jenkins.name
}

output "jenkins_namespace" {
  value = helm_release.jenkins.namespace
}

output "jenkins_service_name" {
  value = var.release_name
}

output "jenkins_url" {
  value = "http://${var.release_name}.${var.namespace}.svc.cluster.local:8080"
}

output "jenkins_admin_user" {
  value = var.admin_user
}

output "jenkins_admin_password" {
  value     = var.admin_password
  sensitive = true
}

output "jenkins_service_account" {
  value = "jenkins"
}
