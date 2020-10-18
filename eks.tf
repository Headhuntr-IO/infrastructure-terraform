
module "eks_cluster" {
  source           = "terraform-aws-modules/eks/aws"
  cluster_name     = local.eks_cluster_name
  cluster_version  = "1.18"
  vpc_id           = module.vpc.vpc_id
  subnets          = module.vpc.private_subnets
  write_kubeconfig = false

  map_accounts = [data.aws_caller_identity.current.account_id]
  map_users = [
    for user, iam in var.eks_iam_mapping :
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${iam}"
      username = user
      groups   = ["system:masters"]
    }
  ]

  node_groups = [
    {
      name = "hhv2-worker"
      additional_tags = merge({
        Name = "hhv2-eks-worker"
      }, local.common_tags)
      k8s_labels = {
        Environment = "hhv2"
        Type        = "standard"
      }
      instance_type    = local.eks_worker_instance_type
      desired_capacity = 1
      min_capacity     = 1
      max_capacity     = 10
      subnets          = module.vpc.private_subnets
    }
  ]

  worker_create_security_group  = false
  cluster_create_security_group = false

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_AWSXRayDaemonWriteAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = module.eks_cluster.worker_iam_role_name
}

resource "aws_iam_role_policy_attachment" "cluster_AutoScalingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = module.eks_cluster.worker_iam_role_name
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}