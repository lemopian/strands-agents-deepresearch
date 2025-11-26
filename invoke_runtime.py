import argparse
import json
import uuid

import boto3


def invoke_agent_runtime(
    agent_runtime_arn: str,
    prompt: str,
    region: str = "us-east-1",
    session_id: str | None = None,
) -> dict:
    """
    Invoke a Bedrock AgentCore runtime with a given prompt.

    Args:
        agent_runtime_arn: The ARN of the agent runtime to invoke.
        prompt: The prompt to send to the agent.
        region: AWS region where the agent is deployed.
        session_id: Optional session ID for conversation continuity.
                   If not provided, a new session is created.

    Returns:
        The parsed JSON response from the agent.
    """
    client = boto3.client("bedrock-agentcore", region_name=region)

    runtime_session_id = session_id or f"session-{uuid.uuid4()}"
    payload = json.dumps({"prompt": prompt})

    response = client.invoke_agent_runtime(
        agentRuntimeArn=agent_runtime_arn,
        runtimeSessionId=runtime_session_id,
        payload=payload,
        qualifier="DEFAULT",
    )

    response_body = response["response"].read()
    return json.loads(response_body)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Invoke a Bedrock AgentCore runtime with a prompt"
    )
    parser.add_argument(
        "--agent-arn", type=str, required=True, help="Agent runtime ARN"
    )
    parser.add_argument(
        "--prompt", type=str, required=True, help="Prompt to send to the agent"
    )
    parser.add_argument("--region", type=str, default="us-east-1", help="AWS region")
    parser.add_argument(
        "--session-id",
        type=str,
        default=None,
        help="Session ID for conversation continuity",
    )

    args = parser.parse_args()

    response_data = invoke_agent_runtime(
        agent_runtime_arn=args.agent_arn,
        prompt=args.prompt,
        region=args.region,
        session_id=args.session_id,
    )

    print("Agent Response:", response_data)
