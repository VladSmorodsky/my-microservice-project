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

  node_subnet_ids = module.vpc.public_subnets

  environment = var.environment
}
