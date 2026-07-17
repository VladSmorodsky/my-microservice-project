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

resource "helm_release" "jenkins" {
  name             = var.release_name
  namespace        = var.namespace
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.chart_version
  create_namespace = true

  timeout       = 1200 # 20 хвилин (збільшено з дефолтних 5 хв)
  wait          = true
  wait_for_jobs = true

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_user     = var.admin_user
      admin_password = var.admin_password
      storage_class  = var.storage_class
      service_type   = var.service_type
      namespace      = var.namespace
    })
  ]
}
