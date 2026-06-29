variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "scan_on_push" {
  description = "Enable automatic vulnerability scanning when an image is pushed"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Tag mutability for the repository: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Allow the repository to be destroyed even if it still contains images"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lesson-7"
}
