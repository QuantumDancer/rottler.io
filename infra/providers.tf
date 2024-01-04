provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = var.role_arn
  }

  default_tags {
    tags = {
      created-by  = "terraform"
      environment = var.environment
    }
  }
}
