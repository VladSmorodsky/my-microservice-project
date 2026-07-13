module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-bucket-000002"
  table_name  = "terraform-locks"
  environment = var.environment
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_name           = "vpc"
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "my-app"
  environment     = var.environment
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = "my-eks"

  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  node_subnet_ids = module.vpc.private_subnets

  environment = var.environment
}

# Data sources for EKS cluster
data "aws_eks_cluster" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

# Random password for Jenkins admin
resource "random_password" "jenkins_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Jenkins
module "jenkins" {
  source       = "./modules/jenkins"
  cluster_name = module.eks.cluster_name

  namespace      = "jenkins"
  admin_user     = "admin"
  admin_password = random_password.jenkins_admin.result
  storage_class  = "gp2"
  service_type   = "LoadBalancer"
  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

# # ArgoCD
module "argo_cd" {
  source       = "./modules/argo_cd"
  cluster_name = module.eks.cluster_name

  namespace     = "argocd"
  service_type  = "LoadBalancer"
  helm_repo_url = "https://github.com/VladSmorodsky/my-microservice-project" # ЗМІНИТИ!
  domain        = "argocd.example.com"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}
