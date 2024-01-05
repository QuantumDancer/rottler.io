provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      created-by  = "terraform"
      environment = var.environment
    }
  }
}
