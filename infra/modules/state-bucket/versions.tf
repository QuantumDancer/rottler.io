# A range rather than a single major: the bootstrap roots run provider 6.x
# while envs/dev stays on 5.x until its own upgrade, and either may call this
# module.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38, < 7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
