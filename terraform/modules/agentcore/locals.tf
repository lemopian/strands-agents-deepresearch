locals {
  account_id           = data.aws_caller_identity.current.account_id
  agent_name_sanitized = replace(var.agent_name, "-", "_")

  # S3 bucket name: use provided or create unique one
  bucket_name = coalesce(
    var.bucket_name,
    "agentcore-${local.agent_name_sanitized}-${local.account_id}-${var.region}"
  )

  # S3 object key: use provided or default pattern
  object_key = coalesce(
    var.object_key,
    "${local.agent_name_sanitized}/deployment_package.zip"
  )

  # Determine if we need to create the bucket
  create_bucket = var.bucket_name == null

  # Determine if we need to create the role
  create_role = var.role_arn == null

  # IAM role ARN: use provided or created role
  role_arn = var.role_arn != null ? var.role_arn : aws_iam_role.agentcore[0].arn

  # Bucket ARN for IAM policies
  bucket_arn = local.create_bucket ? aws_s3_bucket.deployment[0].arn : data.aws_s3_bucket.provided[0].arn

  # Outputs bucket configuration
  # Determine if we need to create the outputs bucket resource
  create_outputs_bucket_resource = var.create_outputs_bucket && var.outputs_bucket_name == null

  outputs_bucket_name = coalesce(
    var.outputs_bucket_name,
    "agentcore-outputs-${local.agent_name_sanitized}-${local.account_id}-${var.region}"
  )

  # Outputs bucket ARN for IAM policies
  outputs_bucket_arn = var.create_outputs_bucket ? (
    var.outputs_bucket_name != null ? data.aws_s3_bucket.outputs_provided[0].arn : aws_s3_bucket.outputs[0].arn
  ) : null

  # Build output directory paths for packaging
  package_output_dir = "${path.module}/.build/${local.agent_name_sanitized}"
  dependencies_dir   = "${local.package_output_dir}/dependencies"
  package_zip_path   = "${local.package_output_dir}/deployment_package.zip"

  # Separate hashes for dependencies and code
  # Dependencies hash - only changes when pyproject.toml changes
  dependencies_hash = filesha256("${var.runtime_source_path}/pyproject.toml")

  # Code hash - changes when source files change (includes .py and .env files)
  code_files_hash = sha256(join("", concat(
    [filesha256("${var.runtime_source_path}/${var.entry_file}")],
    # Hash Python files in additional source directories
    [for dir in var.additional_source_dirs : sha256(join("", [
      for f in fileset("${var.runtime_source_path}/${dir}", "**/*.py") : filesha256("${var.runtime_source_path}/${dir}/${f}")
    ])) if length(fileset("${var.runtime_source_path}/${dir}", "**/*.py")) > 0],
    # Hash .env files in additional source directories
    [for dir in var.additional_source_dirs : sha256(join("", [
      for f in fileset("${var.runtime_source_path}/${dir}", "**/.env") : filesha256("${var.runtime_source_path}/${dir}/${f}")
    ])) if length(fileset("${var.runtime_source_path}/${dir}", "**/.env")) > 0]
  )))

  # Combined hash for S3 upload detection
  source_hash = sha256("${local.dependencies_hash}-${local.code_files_hash}")

  # Default tags
  default_tags = {
    ManagedBy = "terraform"
    Module    = "agentcore"
    Agent     = var.agent_name
  }

  tags = merge(local.default_tags, var.tags)

  # Langfuse observability configuration
  langfuse_credentials = var.enable_langfuse ? jsondecode(data.aws_secretsmanager_secret_version.langfuse_credentials[0].secret_string) : {}
  langfuse_public_key  = var.enable_langfuse ? local.langfuse_credentials["LANGFUSE_PUBLIC_KEY"] : ""
  langfuse_secret_key  = var.enable_langfuse ? local.langfuse_credentials["LANGFUSE_SECRET_KEY"] : ""
  langfuse_auth_header = var.enable_langfuse ? "Authorization=Basic ${base64encode("${local.langfuse_public_key}:${local.langfuse_secret_key}")}" : ""

  # Langfuse environment variables for OTEL export
  langfuse_env_vars = var.enable_langfuse ? {
    DISABLE_ADOT_OBSERVABILITY  = "true"
    OTEL_EXPORTER_OTLP_ENDPOINT = "https://cloud.langfuse.com/api/public/otel"
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
    OTEL_EXPORTER_OTLP_HEADERS  = local.langfuse_auth_header
    USER_ID                     = var.user_id
  } : {}
}
