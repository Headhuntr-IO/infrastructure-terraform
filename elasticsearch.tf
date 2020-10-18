resource "aws_elasticsearch_domain" "db_search" {
  cluster_config {
    instance_type  = local.es_instance_type
    instance_count = local.es_instance_count
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = var.es_volume_size
  }

  snapshot_options {
    automated_snapshot_start_hour = 1
  }

  vpc_options {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.db_search.id]
  }

  domain_name           = local.es_domain
  elasticsearch_version = "7.7"

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" : "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:*:domain/${local.es_domain}/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_security_group" "db_search" {
  name        = "SG Elasticsearch"
  description = "Allow SSL traffic into ES"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${module.vpc.name}-Elasticsearch SG"
  }, local.common_tags)
}