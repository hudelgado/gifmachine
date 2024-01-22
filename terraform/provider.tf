provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn     = "arn:aws:iam::829867256685:role/TerraformRunner"
    session_name = "TerraformRunner"
  }

  default_tags {
    tags = {
      Environment = var.environment
      Provider    = "TF Provider"
      Application = "gifmachine"
    }
  }
}
