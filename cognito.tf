
resource "aws_cognito_user_pool" "main" {
  name = local.cognito_user_pool_name

  username_configuration {
    case_sensitive = false
  }

  username_attributes = ["email"]

  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = false
    required            = true

    string_attribute_constraints {
      min_length = "3"
      max_length = "100"
    }
  }

  schema {
    name                     = "birthdate"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true

    string_attribute_constraints {
      min_length = "10"
      max_length = "10"
    }
  }

  schema {
    name                     = "family_name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true

    string_attribute_constraints {
      min_length = "1"
      max_length = "2048"
    }
  }

  schema {
    name                     = "given_name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true

    string_attribute_constraints {
      min_length = "1"
      max_length = "2048"
    }
  }

  schema {
    name                     = "middle_name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true

    string_attribute_constraints {
      min_length = "1"
      max_length = "2048"
    }
  }

  schema {
    name                     = "gender"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = true

    string_attribute_constraints {
      min_length = "1"
      max_length = "2048"
    }
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 2
  }

  //TODO: figure out how to dynamically create this
  email_configuration {
    email_sending_account  = "DEVELOPER"
    from_email_address     = "contact@miiingle.net"
    reply_to_email_address = "contact@miiingle.net"
    source_arn             = "arn:aws:ses:us-east-1:327229172692:identity/contact@miiingle.net"
  }

  sms_authentication_message = "Your authentication code is {####}. "

  tags = local.common_tags
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = local.cognito_domain
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "ios_client" {
  name                                 = "ios_client"
  user_pool_id                         = aws_cognito_user_pool.main.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
  callback_urls                = ["http://localhost:8080/auth/callback"]
  logout_urls                  = ["http://localhost:8080/auth/logout"]
  allowed_oauth_flows          = ["code", "implicit"]
  allowed_oauth_scopes         = ["openid", "email"]
}