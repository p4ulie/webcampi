provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "aws_cloudfront_related"
  region = "us-east-1"
}
