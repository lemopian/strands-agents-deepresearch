module "deepsearch_agentcore" {
  source = "./modules/agentcore"

  agent_name          = var.agent_name
  agent_description   = var.agent_description
  runtime_source_path = "${path.root}/../deepresearch"
  region              = var.region

  entry_file             = "runtime.py"
  entry_point            = ["runtime.py"]
  additional_source_dirs = ["deepresearch"]

  environment_variables = merge(var.environment_variables, {
    "OUTPUTS_BUCKET_NAME" = var.create_outputs_bucket ? coalesce(var.outputs_bucket_name, "agentcore-outputs-${replace(var.agent_name, "-", "_")}-${data.aws_caller_identity.current.account_id}-${var.region}") : ""
  })
  secrets_names = var.secrets_names
  network_mode  = var.network_mode
  tags          = var.tags

  # Optional: override with custom values
  bucket_name = var.bucket_name
  object_key  = var.object_key
  role_arn    = var.role_arn

  enable_memory                = var.enable_memory
  memory_event_expiry_duration = var.memory_event_expiry_duration

  # Outputs bucket configuration
  create_outputs_bucket  = var.create_outputs_bucket
  outputs_bucket_name    = var.outputs_bucket_name
  outputs_retention_days = var.outputs_retention_days
}

data "aws_caller_identity" "current" {}

