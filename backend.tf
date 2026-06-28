# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-000002"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
