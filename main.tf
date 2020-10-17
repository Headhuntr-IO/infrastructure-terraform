locals {
  vpc_name         = "hhv2-vpc"
  eks_cluster_name = "hhv2-eks"


  common_tags = {
    Project     = "HeadhuntrV2"
    Owner       = "terraformV2"
    BillingCode = "hhv2-infra-2020-10-17"
    Environment = "hhv2"
  }
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "io.headhuntr.v2.infra"
    region = "us-east-1"
    key    = "terraform/dev.tfstate"
  }
}

provider "tls" {
  version = ">= 2.1.1"
}

provider "aws" {
  version = ">= 2.65.0"
  region  = var.aws_region
}
