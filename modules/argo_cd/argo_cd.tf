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

resource "helm_release" "argocd" {
  name             = var.release_name
  namespace        = var.namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      service_type = var.service_type
      domain       = var.domain
    })
  ]
}

# Install ArgoCD Applications
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  namespace = var.namespace
  chart     = "${path.module}/charts"

  values = [
    templatefile("${path.module}/charts/values.yaml", {
      helm_repo_url = var.helm_repo_url
    })
  ]

  depends_on = [helm_release.argocd]
}
