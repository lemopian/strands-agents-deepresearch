# Agent Runtime
resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name = local.agent_name_sanitized
  description        = var.agent_description
  role_arn           = local.role_arn

  agent_runtime_artifact {
    code_configuration {
      entry_point = var.entry_point
      runtime     = var.python_runtime
      code {
        s3 {
          bucket = local.create_bucket ? aws_s3_bucket.deployment[0].id : var.bucket_name
          prefix = local.object_key
        }
      }
    }
  }
  lifecycle_configuration {
    idle_runtime_session_timeout = var.idle_runtime_session_timeout
    max_lifetime = var.max_lifetime
  }
  network_configuration {
    network_mode = var.network_mode
  }

  environment_variables = merge(
    var.environment_variables,
    {
      DEPLOYMENT_HASH = aws_s3_object.deployment_package.source_hash,
      ENABLE_MEMORY   = tostring(var.enable_memory),
      AWS_REGION      = var.region,
    },
    var.enable_memory ? {
      AGENTCORE_MEMORY_ID = aws_bedrockagentcore_memory.this[0].id,
    } : {},
    length(var.secrets_names) > 0 ? {
      SECRETS_CONFIG = local.secrets_config
    } : {},
    local.langfuse_env_vars,
  )

  tags = local.tags

  depends_on = [aws_s3_object.deployment_package]
}

# Agent Memory (conditional)
resource "aws_bedrockagentcore_memory" "this" {
  count = var.enable_memory ? 1 : 0

  name                  = local.agent_name_sanitized
  description           = "${var.agent_description} Memory"
  event_expiry_duration = var.memory_event_expiry_duration

  tags = local.tags
}
