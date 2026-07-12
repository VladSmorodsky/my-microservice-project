variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type        = string
}

variable "public_subnets" {
  description = "CIDR block list for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR block list for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of available zones"
  type        = list(string)
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so private-subnet nodes get outbound internet"
  type        = bool
  default     = true
}
