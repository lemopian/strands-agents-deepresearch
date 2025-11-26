# IAM role for Bedrock AgentCore Runtime
# This role provides the necessary permissions for the agent to:
# - Write CloudWatch logs
# - Access Bedrock AgentCore Memory
# - Invoke Bedrock models

resource "aws_iam_role" "agentcore" {
  count = var.role_arn == null ? 1 : 0
  name  = "AmazonBedrockAgentCoreSDKRuntime"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

# CloudWatch Logs policy for the role
resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.role_arn == null ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-CloudWatchLogs"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws/bedrock-agentcore/*",
          "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws/vendedlogs/bedrock-agentcore/*"
        ]
      }
    ]
  })
}

# S3 policy for deployment bucket access
resource "aws_iam_role_policy" "s3_deployment" {
  count = var.role_arn == null ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-S3Deployment"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${local.bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = local.bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = "${local.agent_name_sanitized}/*"
          }
        }
      }
    ]
  })
}

# Bedrock model invocation policy
resource "aws_iam_role_policy" "bedrock_invoke" {
  count = var.role_arn == null ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-BedrockInvoke"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.region}::foundation-model/*",
          "arn:aws:bedrock:${var.region}:${local.account_id}:inference-profile/*",
          "arn:aws:bedrock:*::foundation-model/*"
        ]
      }
    ]
  })
}

# Bedrock AgentCore Memory policy
resource "aws_iam_role_policy" "agentcore_memory" {
  count = var.role_arn == null ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-AgentCoreMemory"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:CreateMemory",
          "bedrock-agentcore:DeleteMemory",
          "bedrock-agentcore:GetMemory",
          "bedrock-agentcore:ListMemories",
          "bedrock-agentcore:UpdateMemory",
          "bedrock-agentcore:CreateSession",
          "bedrock-agentcore:DeleteSession",
          "bedrock-agentcore:GetSession",
          "bedrock-agentcore:ListSessions",
          "bedrock-agentcore:CreateEvent",
          "bedrock-agentcore:GetEvent",
          "bedrock-agentcore:ListEvents",
          "bedrock-agentcore:DeleteEvent",
          "bedrock-agentcore:CreateMemoryEvent",
          "bedrock-agentcore:GetMemoryEvent",
          "bedrock-agentcore:ListMemoryEvents",
          "bedrock-agentcore:DeleteMemoryEvent"
        ]
        Resource = "arn:aws:bedrock-agentcore:${var.region}:${local.account_id}:memory/*"
      }
    ]
  })
}

# Secrets Manager policy - only created if secrets are configured
resource "aws_iam_role_policy" "secrets_manager" {
  count = var.role_arn == null && length(var.secrets_names) > 0 ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-SecretsManager"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = local.secret_arns
      }
    ]
  })
}

# Langfuse Secrets Manager policy - only created if Langfuse is enabled
resource "aws_iam_role_policy" "langfuse_secrets" {
  count = var.role_arn == null && var.enable_langfuse ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-LangfuseSecrets"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.aws_secretsmanager_secret.langfuse_credentials[0].arn
      }
    ]
  })
}

# S3 policy for outputs bucket access - allows agent to write research outputs
resource "aws_iam_role_policy" "s3_outputs" {
  count = var.role_arn == null && var.create_outputs_bucket ? 1 : 0
  name  = "${aws_iam_role.agentcore[0].name}-S3Outputs"
  role  = aws_iam_role.agentcore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${local.outputs_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = local.outputs_bucket_arn
      }
    ]
  })
}

