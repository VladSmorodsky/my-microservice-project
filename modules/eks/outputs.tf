output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded CA certificate of the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group created and managed by EKS for the control plane"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl access to the cluster"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.this.name}"
}
