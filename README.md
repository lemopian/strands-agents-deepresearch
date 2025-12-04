# Strands Agents Deep Agent Research

A production-ready deep research agent powered by [Strands DeepAgents](https://strandsagents.com/), deployed on AWS Bedrock AgentCore using Terraform.

## Overview

This project provides a multi-agent research system that:

- Conducts comprehensive research on any topic using parallel subagents
- Performs intelligent web searches via Linkup/Tavily APIs
- Synthesizes findings with automated citation management
- Deploys as a serverless agent on AWS Bedrock AgentCore
- Stores research outputs in S3

## Architecture
<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/b0d39c63-d02d-486a-aeb6-125263768202" />

## Langfuse traces Example
<img width="1688" height="1642" alt="image" src="https://github.com/user-attachments/assets/27bfe4f7-0b0b-4af3-82d2-ccab01ff3a92" />

## Project Structure

```
strands-agents-deepresearch/
├── deepresearch/               # Agent source code
│   ├── deepresearch/           # Main package
│   │   ├── main.py             # Agent entry point
│   │   ├── config.py           # Configuration
│   │   ├── prompts/            # Agent prompts
│   │   ├── tools/              # Custom tools
│   │   └── utils/              # Utilities
│   ├── runtime.py              # AgentCore runtime handler
│   ├── pyproject.toml          # Python dependencies
│   └── README.md               # Detailed agent documentation
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Root module
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── terraform.tfvars.example
│   └── modules/
│       └── agentcore/          # AgentCore deployment module
├── invoke_runtime.py           # CLI to invoke deployed agent
└── README.md                   # This file
```

## Prerequisites

- Python 3.13+
- [UV](https://github.com/astral-sh/uv) package manager
- AWS CLI configured with appropriate credentials
- Terraform 1.0+
- API keys for Linkup and/or Tavily stored in AWS Secrets Manager

## Quick Start

### 1. Clone and Setup

```bash
cd strands-agents-deepresearch

# Create and activate virtual environment
uv venv
source .venv/bin/activate

# Install dependencies
cd deepresearch
uv sync
```

### 2. Configure Secrets in AWS

Store your API keys in AWS Secrets Manager:

```bash
aws secretsmanager create-secret --name linkup/api-key --secret-string "your-linkup-key"
aws secretsmanager create-secret --name tavily/api-key --secret-string "your-tavily-key"
```

### 3. Deploy with Terraform

```bash
cd terraform

# Create your configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

### 4. Invoke the Agent

```bash
# From project root
python invoke_runtime.py \
  --agent-arn "arn:aws:bedrock-agentcore:REGION:ACCOUNT:runtime/AGENT_ID" \
  --prompt "Research the current state of quantum computing in 2025" \
  --region us-east-1
```

## Terraform Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `agent_name` | Name for the agent (used in resource naming) |
| `region` | AWS region for deployment |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `agent_description` | "DeepSearch Agent..." | Agent description |
| `bucket_name` | Auto-generated | S3 bucket for deployment package |
| `role_arn` | Default AgentCore role | IAM role ARN |
| `network_mode` | "PUBLIC" | Network access mode |
| `enable_memory` | true | Enable AgentCore memory |
| `create_outputs_bucket` | true | Create S3 bucket for outputs |
| `outputs_retention_days` | 90 | S3 output retention period |
| `idle_runtime_session_timeout` | 60 | Session idle timeout (seconds) |
| `max_lifetime` | 1000 | Max runtime lifetime (seconds) |

### Example terraform.tfvars

```hcl
agent_name  = "deepsearch-prod"
region      = "us-east-1"

tags = {
  Environment = "production"
  Project     = "deepsearch"
}
```

## Local Development

For local development and testing without AgentCore:

```bash
cd deepresearch
source ../.venv/bin/activate

# Set environment variables
export LINKUP_API_KEY="your-key"
export BYPASS_TOOL_CONSENT="true"

# Run directly
python -m deepresearch.main --prompt "Your research query"
```

## Invoking the Deployed Agent

The `invoke_runtime.py` script provides a CLI to invoke the deployed agent:

```bash
python invoke_runtime.py \
  --agent-arn "arn:aws:bedrock-agentcore:us-east-1:123456789:runtime/deepsearch-prod" \
  --prompt "Compare the environmental impact of electric vs hydrogen vehicles" \
  --region us-east-1 \
  --session-id "my-session-123"  # Optional: for conversation continuity
```

## Agent Capabilities

The DeepSearch agent excels at:

- **Multi-perspective research**: Analyzing topics from multiple viewpoints
- **Comparative analysis**: Comparing technologies, approaches, or concepts
- **Current events**: Researching recent developments and news
- **Technical deep-dives**: In-depth exploration of technical topics

See [deepresearch/README.md](deepresearch/README.md) for detailed agent documentation.

## Outputs

Research outputs are stored in S3 with the following structure:

```
s3://outputs-bucket/
├── {session_id}/
│   ├── final_report.md          # Synthesized research report
│   ├── research_findings/       # Individual subagent findings
│   └── sources/                 # Source documents with URLs
```

## Monitoring

- **Logs**: Available in CloudWatch Logs
- **Telemetry**: OpenTelemetry traces via Langfuse integration
- **Metrics**: AgentCore runtime metrics in CloudWatch

## Cost Considerations

Typical costs per research query:

- **Claude API**: $0.50-2.00 depending on complexity
- **AgentCore Runtime**: Pay-per-use serverless pricing
- **Search APIs**: Based on your Linkup/Tavily plan
- **S3 Storage**: Minimal for text outputs

## License

See LICENSE file for details.

