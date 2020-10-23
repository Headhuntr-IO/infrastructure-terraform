resource "kubernetes_service_account" "tiller" {
  depends_on = [module.eks_cluster]

  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  depends_on = [module.eks_cluster]

  metadata {
    name = "tiller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    namespace = "kube-system"
    name      = "tiller"
  }
}

resource "helm_release" "kube_utils" {
  depends_on = [kubernetes_cluster_role_binding.tiller, kubernetes_service_account.tiller]
  name       = "kube-utils"
  chart      = "helm/kube-utils"

  set {
    name  = "clusterName"
    value = local.eks_cluster_name
  }

  set {
    name  = "xrayDaemonRole"
    value = module.eks_cluster.worker_iam_role_arn
  }
}