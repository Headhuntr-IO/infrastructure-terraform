locals {
  vpc_name                 = "hhv2-vpc"
  eks_cluster_name         = "hhv2-eks"
  eks_worker_instance_type = var.eks_worker_instance_type

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

provider "aws" {
  version = ">= 2.65.0"
  region  = var.aws_region
}

provider "kubernetes" {
  host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
  token                  = element(concat(data.aws_eks_cluster_auth.cluster[*].token, list("")), 0)
  load_config_file       = false
}

provider "tls" {
  version = ">= 2.1.1"
}


