
resource "aws_apigatewayv2_api" "main" {
  name          = "${local.vpc_name}-api-gateway"
  description   = "The only way into the backend"
  protocol_type = "HTTP"
  tags          = local.common_tags

  cors_configuration {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    max_age           = 300
  }
}

//this is just a workaround to obtain the ELB id
//currently TF has no way of getting that id directly
//also, im showing myself a way to work around certain bugs
data "external" "cluster_lb_arn" {
  depends_on = [helm_release.application_search_service]

  program = ["sh", "${path.module}/workaround/aws-cli-get-elb-id.sh"]

  query = {
    vpc    = module.vpc.vpc_id
    region = var.aws_region
  }
}

data "aws_lb" "eks_internal" {
  arn = data.external.cluster_lb_arn.result.Result
}

data "aws_lb_listener" "eks_internal" {
  load_balancer_arn = data.aws_lb.eks_internal.arn
  port              = 80
}

resource "aws_apigatewayv2_vpc_link" "eks_internal" {
  name               = "${local.vpc_name}-vpc-link"
  security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids         = module.vpc.private_subnets

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "eks_internal" {
  depends_on = [helm_release.application_search_service]

  api_id      = aws_apigatewayv2_api.main.id
  description = "Integrate to the main Backend"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.eks_internal.id

  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_lb_listener.eks_internal.arn
}

variable "http_methods" {
  description = "The HTTP Methods that are allowed to operate on our resources"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "PATCH", "DELETE"]
}

resource "aws_apigatewayv2_route" "eks_internal_http_methods" {
  count = length(var.http_methods)

  api_id         = aws_apigatewayv2_api.main.id
  route_key      = "${var.http_methods[count.index]} /{proxy+}"
  operation_name = "${var.http_methods[count.index]} Resource"
  target         = "integrations/${aws_apigatewayv2_integration.eks_internal.id}"
}

//optional if your FE web app is sitting on another domain/sub
//resource "aws_apigatewayv2_route" "eks_internal_options" {
//  api_id         = aws_apigatewayv2_api.main.id
//  route_key      = "OPTIONS /{proxy+}"
//  operation_name = "CORS Pre-flight"
//  target         = "integrations/${aws_apigatewayv2_integration.eks_internal.id}"
//}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/${local.vpc_name}/api-gateway"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  description = "Production API"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode(
      {
        httpMethod     = "$context.httpMethod"
        stage          = "$context.stage"
        path           = "$context.path"
        ip             = "$context.identity.sourceIp"
        protocol       = "$context.protocol"
        requestId      = "$context.requestId"
        requestTime    = "$context.requestTime"
        responseLength = "$context.responseLength"
        status         = "$context.status"
      }
    )
  }

  default_route_settings {
    logging_level            = "OFF"
    data_trace_enabled       = false
    detailed_metrics_enabled = false
    throttling_burst_limit   = 100
    throttling_rate_limit    = 100
  }

  tags = local.common_tags
}