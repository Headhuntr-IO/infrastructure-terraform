
resource "helm_release" "application_search_service" {
  depends_on = [helm_release.kube_utils, aws_elasticsearch_domain.db_search]
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
}