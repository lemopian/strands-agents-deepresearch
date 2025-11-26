variable "agent_name" {
  type        = string
  description = "Name of the agent runtime (used for resource naming)"
}

variable "agent_description" {
  type        = string
  description = "Description of the agent"
  default     = "AgentCore Runtime"
}

variable "runtime_source_path" {
  type        = string
  description = "Path to the directory containing the runtime code (must include pyproject.toml and entry file)"
}

variable "entry_file" {
  type        = string
  description = "Name of the main Python file to use as entry point (e.g., 'main.py' or 'runtime.py')"
  default     = "main.py"
}

variable "additional_source_dirs" {
  type        = list(string)
  description = "Additional directories to include in the deployment package (relative to runtime_source_path)"
  default     = []
}

variable "region" {
  type        = string
  description = "AWS region where the AgentCore runtime will be deployed"
}

# Optional overrides - if not provided, defaults will be used
variable "bucket_name" {
  type        = string
  description = "Optional: S3 bucket name to store the deployment package. If not provided, a unique bucket will be created."
  default     = null
}

variable "object_key" {
  type        = string
  description = "Optional: S3 object key for the deployment package. If not provided, defaults to {agent_name}/deployment_package.zip"
  default     = null
}

variable "role_arn" {
  type        = string
  description = "Optional: IAM role ARN for the agent runtime. If not provided, uses default AmazonBedrockAgentCoreSDKRuntime-{region} role."
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the agent runtime"
  default     = { "BYPASS_TOOL_CONSENT" : "true" }
}

variable "enable_memory" {
  type        = bool
  description = "Whether to enable AgentCore memory for the agent"
  default     = true
}

variable "memory_event_expiry_duration" {
  type        = number
  description = "Event expiry duration for agent memory in days (must be between 7 and 365)"
  default     = 30
  validation {
    condition     = var.memory_event_expiry_duration >= 7 && var.memory_event_expiry_duration <= 365
    error_message = "memory_event_expiry_duration must be between 7 and 365 days."
  }
}

variable "network_mode" {
  type        = string
  description = "Network mode for the agent runtime"
  default     = "PUBLIC"
  validation {
    condition     = contains(["PUBLIC", "PRIVATE"], var.network_mode)
    error_message = "Network mode must be either PUBLIC or PRIVATE."
  }
}

variable "python_runtime" {
  type        = string
  description = "Python runtime version for the agent"
  default     = "PYTHON_3_13"
  validation {
    condition     = contains(["PYTHON_3_13", "PYTHON_3_12", "PYTHON_3_11"], var.python_runtime)
    error_message = "Python runtime must be one of: PYTHON_3_13, PYTHON_3_12, PYTHON_3_11"
  }
}

variable "entry_point" {
  type        = list(string)
  description = "Entry point for the agent runtime"
  default     = ["main.py"]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch logs for the agent"
  default     = 30
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of the allowed values: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653."
  }
}

variable "secrets_names" {
  type        = map(string)
  description = "Map of environment variable names to Secrets Manager secret names. The runtime will fetch these secrets at startup."
  default     = {}
}

# Outputs bucket configuration
variable "create_outputs_bucket" {
  type        = bool
  description = "Whether to create an S3 bucket for agent outputs (research documents, findings, reports)"
  default     = true
}

variable "outputs_bucket_name" {
  type        = string
  description = "Optional: Custom S3 bucket name for agent outputs. If not provided, a unique bucket will be created."
  default     = null
}

variable "outputs_retention_days" {
  type        = number
  description = "Number of days to retain outputs in S3 (0 = never expire)"
  default     = 90
}

# Langfuse observability configuration
variable "langfuse_secret_name" {
  type        = string
  description = "Name of the Secrets Manager secret containing Langfuse credentials (LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY)"
  default     = "langfuse/api-key"
}

variable "enable_langfuse" {
  type        = bool
  description = "Enable Langfuse observability integration"
  default     = true
}

variable "user_id" {
  type        = string
  description = "User ID for Langfuse tracing context"
  default     = ""
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