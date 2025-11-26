variable "agent_name" {
  type        = string
  description = "Name of the agent (used for resource naming)"
}

variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "DeepSearch Agent - Research agent with internet search capabilities"
}

variable "region" {
  type        = string
  description = "AWS region where the AgentCore runtime will be deployed"
}

# Optional S3 and IAM overrides
variable "bucket_name" {
  type        = string
  description = "Optional: S3 bucket name. If not provided, a unique bucket will be created."
  default     = null
}

variable "object_key" {
  type        = string
  description = "Optional: S3 object key for the deployment package."
  default     = null
}

variable "role_arn" {
  type        = string
  description = "Optional: IAM role ARN. If not provided, uses default AmazonBedrockAgentCoreSDKRuntime-{region} role."
  default     = null
}

# Runtime configuration
variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the agent runtime"
  default = {
    "BYPASS_TOOL_CONSENT"         = "true"
  }
}

variable "secrets_names" {
  type        = map(string)
  description = "Map of environment variable names to Secrets Manager secret names"
  default = {
    "LINKUP_API_KEY" = "linkup/api-key"
    "TAVILY_API_KEY" = "tavily/api-key"
  }
}

variable "network_mode" {
  type        = string
  description = "Network mode for the agent runtime"
  default     = "PUBLIC"
}

variable "enable_memory" {
  type        = bool
  description = "Whether to enable AgentCore memory for the agent"
  default     = true
}

variable "memory_event_expiry_duration" {
  type        = number
  description = "Event expiry duration for agent memory in days"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

# Outputs bucket configuration
variable "create_outputs_bucket" {
  type        = bool
  description = "Whether to create an S3 bucket for agent outputs"
  default     = true
}

variable "outputs_bucket_name" {
  type        = string
  description = "Optional: Custom S3 bucket name for agent outputs"
  default     = null
}

variable "outputs_retention_days" {
  type        = number
  description = "Number of days to retain outputs in S3 (0 = never expire)"
  default     = 90
}

variable "idle_runtime_session_timeout" {
  type        = number
  description = "Idle runtime session timeout in seconds"
  default     = 60
}

variable "max_lifetime" {
  type        = number
  description = "Max lifetime in seconds"
  default     = 1000
}