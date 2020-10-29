
resource "helm_release" "application_search_service" {
  depends_on = [helm_release.kube_utils, aws_elasticsearch_domain.db_search, aws_cognito_user_pool.main]
  name       = "search-service"
  chart      = "helm/search-service"

  set {
    name  = "config.es.host"
    value = aws_elasticsearch_domain.db_search.endpoint
  }

  set {
    name  = "service.annotations.albTags"
    value = "hhv2"
  }

  set {
    name = "config.cognito.poolId"
    value = aws_cognito_user_pool.main.id
  }

  //TODO: use a reference to the cognito user pool
  set {
    name = "config.cognito.region"
    value = var.aws_region
  }
}