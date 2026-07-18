output "release_name" {
  value = helm_release.kube_prometheus_stack.name
}

output "namespace" {
  value = helm_release.kube_prometheus_stack.namespace
}

output "grafana_admin_user" {
  value = var.grafana_admin_user
}

output "grafana_admin_password" {
  value     = var.grafana_admin_password
  sensitive = true
}

output "grafana_service_name" {
  value = "${var.release_name}-grafana"
}

output "grafana_url_command" {
  description = "Отримати зовнішню адресу Grafana (LoadBalancer)"
  value       = "kubectl get svc ${var.release_name}-grafana -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "prometheus_portforward_command" {
  description = "Локальний доступ до Prometheus UI"
  value       = "kubectl port-forward -n ${var.namespace} svc/${var.release_name}-prometheus 9090:9090"
}
