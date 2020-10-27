
resource "aws_cognito_user_pool" "main" {
  name = local.cognito_user_pool_name

  username_configuration {
    case_sensitive = false
  }

  username_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = false
    required            = true
  }

  schema {
    name                = "birthdate"
    attribute_data_type = "String"
    required            = true
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = true

    string_attribute_constraints {
      min_length = "1"
    }
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = true

    string_attribute_constraints {
      min_length = "1"
    }
  }

  schema {
    name                = "middle_name"
    attribute_data_type = "String"
    required            = true

    string_attribute_constraints {
      min_length = "1"
    }
  }

  schema {
    name                = "gender"
    attribute_data_type = "String"
    required            = true
  }

  password_policy {
    minimum_length = 8
  }

  //TODO: figure out how to dynamically create this
  email_configuration {
    source_arn = "arn:aws:ses:us-east-1:327229172692:identity/contact@miiingle.net"
  }

  tags = local.common_tags
}