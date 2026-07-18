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

  node_instance_types = ["t3.large"]
  desired_size        = 2
  min_size            = 1
  max_size            = 3

  environment = var.environment
}

# Data sources for EKS cluster
data "aws_eks_cluster" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Kubernetes provider — exec auth fetches a FRESH token on every call,
# so long applies (EKS + Aurora take ~25 min) don't hit token expiry.
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "us-east-1"]
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "us-east-1"]
    }
  }
}

# Random password for Jenkins admin
resource "random_password" "jenkins_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Random password for Grafana admin
resource "random_password" "grafana_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Prometheus + Grafana (kube-prometheus-stack)
module "monitoring" {
  source       = "./modules/monitoring"
  cluster_name = module.eks.cluster_name

  namespace              = "monitoring"
  grafana_admin_user     = "admin"
  grafana_admin_password = random_password.grafana_admin.result
  grafana_service_type   = "LoadBalancer"
  storage_class          = "gp2"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
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

module "rds" {
  source = "./modules/rds"

  name                 = "myapp-db"
  use_aurora           = false
  aurora_replica_count = 1 # Кількість reader replicas (1 writer + 1 reader)

  # --- Aurora-only ---
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.17"
  parameter_group_family_aurora = "aurora-postgresql15"


  # --- RDS-only ---
  engine                     = "postgres"
  engine_version             = "17" # мажорна версія — AWS сам обере доступний мінор
  parameter_group_family_rds = "postgres17"

  # Common
  instance_class          = "db.t3.medium"
  allocated_storage       = 20
  db_name                 = "myapp"
  username                = "postgres"
  password                = var.db_password
  subnet_private_ids      = module.vpc.private_subnets
  subnet_public_ids       = module.vpc.public_subnets
  publicly_accessible     = true
  vpc_id                  = module.vpc.vpc_id
  multi_az                = true
  backup_retention_period = 7
  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
