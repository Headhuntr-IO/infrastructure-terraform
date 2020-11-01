
// various resources needed to process the things internally:
// 1. s3 buckets for EMR temp locations
// 2. lambda functions for coordination
// 3. SQS queue for holding the pipeline queue

resource "aws_s3_bucket" "data_processor_workspace" {
  bucket        = local.internal_processor_bucket_name
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "temp_cleanup"
    enabled = true
    prefix  = "temp/"

    expiration {
      days = 2
    }
  }

  tags = local.common_tags
}

resource "aws_iam_role" "lambda" {
  name = local.internal_processor_lambda_role_name
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service : "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_sqs_queue" "lambda_tasks" {
  name       = local.internal_processor_sqs_name
  fifo_queue = true

  delay_seconds              = 10
  visibility_timeout_seconds = 900
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = {
      "Effect" : "Allow",
      "Action" : ["lambda:CreateEventSourceMapping", "lambda:ListEventSourceMappings", "lambda:ListFunctions"],
      "Resource" : "*"
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.internal_processor_lambda_function_name}"
  retention_in_days = 30
}

resource "aws_iam_policy" "lambda" {
  name        = local.internal_processor_lambda_role_name
  path        = "/"
  description = "IAM policy for logging from a lambda ${local.internal_processor_lambda_function_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.lambda_logs.arn,
        Effect   = "Allow",
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*",
        Effect   = "Allow",
      },
      //TODO: add the when we start integrating with the redshift cluster
      //      {
      //        Action = [
      //          "redshift:GetClusterCredentials"
      //        ],
      //        Resource = "arn:aws:redshift:${data.aws_region.redshift_region.id}:*:*:${var.redshift_cluster_id}/*",
      //        Effect   = "Allow",
      //      },
      {
        Action   = "elasticmapreduce:*",
        Resource = "*",
        Effect   = "Allow",
      },
      {
        Action   = "iam:PassRole",
        Resource = ["arn:aws:iam::*:role/EMR_DefaultRole", "arn:aws:iam::*:role/EMR_EC2_DefaultRole"],
        Effect   = "Allow",
      },
      {
        Action   = "lambda:GetFunction",
        Resource = ["arn:aws:lambda:${var.aws_region}:*:function:${local.internal_processor_lambda_function_name}"],
        Effect   = "Allow",
      },
      {
        Action   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"],
        Resource = aws_sqs_queue.lambda_tasks.arn
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_layer_version" "libs" {
  layer_name = local.internal_processor_lambda_libraries_name

  s3_bucket = local.internal_processor_lambda_bucket
  s3_key    = "python/libs-latest.zip"

  compatible_runtimes = ["python3.8"]
}

resource "aws_lambda_function" "main" {
  depends_on = [aws_iam_role_policy_attachment.lambda]

  function_name = local.internal_processor_lambda_function_name
  description   = "A really cool lambda function that handles everything"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda.arn
  handler       = "main.start"

  s3_bucket = local.internal_processor_lambda_bucket
  s3_key    = "python/main-latest.zip"

  layers = [aws_lambda_layer_version.libs.id]

  timeout = 900

  vpc_config {
    security_group_ids = [module.eks_cluster.cluster_primary_security_group_id, module.vpc.default_security_group_id]
    subnet_ids         = module.vpc.private_subnets
  }

  environment {
    variables = {
      THIS_FUNCTION_NAME       = local.internal_processor_lambda_function_name
      ES_HOST                  = aws_elasticsearch_domain.db_search.endpoint
      S3_BUCKET_DATA_PROCESSOR = aws_s3_bucket.data_processor_workspace.bucket
      COMMAND_QUEUE_URL        = aws_sqs_queue.lambda_tasks.id
      //      RS_HOST                   = data.aws_redshift_cluster.shared.endpoint
      //      RS_REGION                 = data.aws_region.redshift_region.id
      JAR_DATA_PROCESSOR        = "s3://${local.internal_processor_lambda_bucket}/jars/search-loader-job-latest.jar"
      JAR_ES_HADOOP             = "s3://${local.internal_processor_lambda_bucket}/jars/elasticsearch-hadoop-7.1.1.jar"
      EMR_CLUSTER_NAME          = "hhv2-internal-processor"
      EMR_WORKER_INSTANCE_TYPE  = "m5.xlarge"
      EMR_WORKER_INSTANCE_COUNT = 1
      WORKER_SG                 = module.eks_cluster.cluster_primary_security_group_id
      WORKER_SUBNET             = module.vpc.private_subnets[0]
    }
  }

  lifecycle {
    ignore_changes = [layers, description]
  }

  tags = local.common_tags
}