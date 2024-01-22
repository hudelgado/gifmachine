resource "aws_ecr_repository" "ecr_repo" {
  name                 = lower("${var.ecr_repository_name}_repository")
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}