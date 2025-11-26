# Get current AWS account ID and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Validate user-provided bucket exists (only if bucket_name is provided)
data "aws_s3_bucket" "provided" {
  count  = var.bucket_name != null ? 1 : 0
  bucket = var.bucket_name
}

# Validate user-provided IAM role exists (only if role_arn is provided)
data "aws_iam_role" "provided" {
  count = var.role_arn != null ? 1 : 0
  name  = element(split("/", var.role_arn), length(split("/", var.role_arn)) - 1)
}

# Langfuse credentials from Secrets Manager (only if Langfuse is enabled)
data "aws_secretsmanager_secret" "langfuse_credentials" {
  count = var.enable_langfuse ? 1 : 0
  name  = var.langfuse_secret_name
}

data "aws_secretsmanager_secret_version" "langfuse_credentials" {
  count     = var.enable_langfuse ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.langfuse_credentials[0].id
}
