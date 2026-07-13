output "argocd_release_name" {
  value = helm_release.argocd.name
}

output "argocd_namespace" {
  value = helm_release.argocd.namespace
}

output "argocd_server_url" {
  value = "http://${var.release_name}-server.${var.namespace}.svc.cluster.local"
}

output "argocd_admin_password_command" {
  value = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
