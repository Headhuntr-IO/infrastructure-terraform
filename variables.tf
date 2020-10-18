
variable "aws_region" {
  description = "The AWS Region for the Main VPC"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.5.0.0/16"
}

variable "vpc_azs" {
  description = "AZs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_subnet_public" {
  description = "Public Subnet CIDR"
  type        = list(string)
  default     = ["10.5.1.0/24", "10.5.2.0/24", "10.5.3.0/24"]
}

variable "vpc_subnet_private" {
  description = "Public Subnet CIDR"
  type        = list(string)
  default     = ["10.5.101.0/24", "10.5.102.0/24", "10.5.103.0/24"]
}

variable "eks_iam_mapping" {
  type = map

  default = {
    "ci-user" = "build_pipeline"
  }
}

variable "eks_worker_instance_type" {
  type    = string
  default = "t3.medium"
}