terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = var.release_name
  namespace        = var.namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  create_namespace = true

  timeout       = 900
  wait          = true
  wait_for_jobs = true

  values = [
    templatefile("${path.module}/values.yaml", {
      grafana_admin_user      = var.grafana_admin_user
      grafana_admin_password  = var.grafana_admin_password
      grafana_service_type    = var.grafana_service_type
      storage_class           = var.storage_class
      prometheus_storage_size = var.prometheus_storage_size
      prometheus_retention    = var.prometheus_retention
    })
  ]
}
