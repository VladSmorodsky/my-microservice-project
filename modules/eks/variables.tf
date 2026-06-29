variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane (null = AWS default)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnets for the EKS control plane ENIs (>= 2 AZs)"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnets where worker nodes run (use public subnets to avoid NAT cost)"
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lesson-7"
}
