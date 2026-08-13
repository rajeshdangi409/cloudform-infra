terraform {
  backend "s3" {
    bucket         = "cloudform-tf-state-575589967956"
    key            = "infra/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "cloudform-tf-locks"
    encrypt        = true
  }
}