# Agent Runtime outputs
output "agent_runtime_name" {
  description = "Name of the agent runtime"
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_name
}

output "agent_runtime_arn" {
  description = "ARN of the agent runtime"
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn
}

output "agent_runtime_id" {
  description = "ID of the agent runtime"
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_id
}

output "agent_runtime_version" {
  description = "Version of the agent runtime"
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_version
}

# S3 outputs
output "bucket_name" {
  description = "Name of the S3 bucket storing the deployment package"
  value       = local.create_bucket ? aws_s3_bucket.deployment[0].id : var.bucket_name
}

output "bucket_arn" {
  description = "ARN of the S3 bucket (only if created by this module)"
  value       = local.create_bucket ? aws_s3_bucket.deployment[0].arn : null
}

output "deployment_package_key" {
  description = "S3 object key of the deployment package"
  value       = local.object_key
}

output "deployment_package_s3_uri" {
  description = "Full S3 URI of the deployment package"
  value       = "s3://${local.create_bucket ? aws_s3_bucket.deployment[0].id : var.bucket_name}/${local.object_key}"
}

# IAM outputs
output "role_arn" {
  description = "IAM role ARN used by the agent runtime"
  value       = local.role_arn
}


output "role_name" {
  description = "IAM role name (only if created by this module)"
  value       = var.role_arn == null ? aws_iam_role.agentcore[0].name : null
}

# Memory outputs (conditional)
output "memory_id" {
  description = "ID of the agent memory (if created)"
  value       = var.enable_memory ? aws_bedrockagentcore_memory.this[0].id : null
}

output "memory_name" {
  description = "Name of the agent memory (if created)"
  value       = var.enable_memory ? aws_bedrockagentcore_memory.this[0].name : null
}

output "memory_arn" {
  description = "ARN of the agent memory (if created)"
  value       = var.enable_memory ? aws_bedrockagentcore_memory.this[0].arn : null
}

# CloudWatch Log Group outputs (managed by AWS)
output "application_log_group_name" {
  description = "Name of the CloudWatch log group for application logs (auto-created by AWS)"
  value       = "/aws/vendedlogs/bedrock-agentcore/runtime/APPLICATION_LOGS/${aws_bedrockagentcore_agent_runtime.this.agent_runtime_id}"
}

output "usage_log_group_name" {
  description = "Name of the CloudWatch log group for usage logs (auto-created by AWS)"
  value       = "/aws/vendedlogs/bedrock-agentcore/runtime/USAGE_LOGS/${aws_bedrockagentcore_agent_runtime.this.agent_runtime_id}"
}

output "service_log_group_name" {
  description = "Name of the CloudWatch log group for service logs (auto-created by AWS)"
  value       = "/aws/bedrock-agentcore/runtimes/${aws_bedrockagentcore_agent_runtime.this.agent_runtime_id}-DEFAULT"
}

# Outputs bucket
output "outputs_bucket_name" {
  description = "Name of the S3 bucket for agent outputs"
  value       = var.create_outputs_bucket ? local.outputs_bucket_name : null
}

output "outputs_bucket_arn" {
  description = "ARN of the S3 bucket for agent outputs"
  value       = var.create_outputs_bucket ? local.outputs_bucket_arn : null
}
