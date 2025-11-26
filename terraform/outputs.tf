output "agent_runtime_name" {
  description = "Name of the agent runtime"
  value       = module.deepsearch_agentcore.agent_runtime_name
}

output "agent_runtime_arn" {
  description = "ARN of the agent runtime"
  value       = module.deepsearch_agentcore.agent_runtime_arn
}

output "agent_runtime_id" {
  description = "ID of the agent runtime"
  value       = module.deepsearch_agentcore.agent_runtime_id
}

output "bucket_name" {
  description = "Name of the S3 bucket storing the deployment package"
  value       = module.deepsearch_agentcore.bucket_name
}

output "deployment_package_s3_uri" {
  description = "Full S3 URI of the deployment package"
  value       = module.deepsearch_agentcore.deployment_package_s3_uri
}

output "role_arn" {
  description = "IAM role ARN used by the agent runtime"
  value       = module.deepsearch_agentcore.role_arn
}

output "memory_id" {
  description = "ID of the agent memory (if created)"
  value       = module.deepsearch_agentcore.memory_id
}

output "application_log_group_name" {
  description = "Name of the CloudWatch log group for application logs (auto-created by AWS)"
  value       = module.deepsearch_agentcore.application_log_group_name
}

output "usage_log_group_name" {
  description = "Name of the CloudWatch log group for usage logs (auto-created by AWS)"
  value       = module.deepsearch_agentcore.usage_log_group_name
}

output "service_log_group_name" {
  description = "Name of the CloudWatch log group for service logs (auto-created by AWS)"
  value       = module.deepsearch_agentcore.service_log_group_name
}

output "outputs_bucket_name" {
  description = "Name of the S3 bucket for agent outputs"
  value       = module.deepsearch_agentcore.outputs_bucket_name
}

output "outputs_bucket_arn" {
  description = "ARN of the S3 bucket for agent outputs"
  value       = module.deepsearch_agentcore.outputs_bucket_arn
}

