# Secrets Manager data sources and configuration
# Validates that secrets exist and provides ARNs for IAM policy

# Fetch each secret to validate it exists
data "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets_names
  name     = each.value
}

locals {
  # Build the secrets configuration JSON to pass to the runtime
  secrets_config = jsonencode(var.secrets_names)

  # Collect all secret ARNs for IAM policy
  secret_arns = [for secret in data.aws_secretsmanager_secret.secrets : secret.arn]
}

