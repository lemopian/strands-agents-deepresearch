"""
DeepSearch Agent implementation using Strands DeepAgents.
"""

import logging
import os
import sys

from bedrock_agentcore import BedrockAgentCoreApp

from deepresearch.tools import internet_search
from deepresearch.utils.s3_outputs import upload_session_outputs
from deepresearch.utils.telemetry import initialize_telemetry
from deepresearch.utils.session import get_session_id, create_session_manager
from deepresearch.utils.secrets import load_secrets_from_secrets_manager

# Configure Python logging to output to stdout (captured by runtime-logs)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("deepsearch")

app = BedrockAgentCoreApp(debug=True)


def create_agent(session_id: str):
    """
    Create a fresh deepsearch agent for each invocation.

    Args:
        session_id: Session ID for memory operations.

    Returns:
        Configured DeepSearch agent.
    """
    # load_secrets_from_secrets_manager already has @lru_cache, safe to call multiple times
    load_secrets_from_secrets_manager()

    logger.info("Initializing DeepSearch agent...")
    from deepresearch.main import create_deepsearch_agent

    session_manager = create_session_manager(session_id=session_id)

    agent = create_deepsearch_agent(
        research_tool=internet_search,
        tool_name="internet_search",
        session_manager=session_manager,
        session_id=session_id,
    )
    logger.info("DeepSearch agent initialized successfully")
    return agent


@app.entrypoint
def invoke(payload, context=None):
    """Process user prompt and return agent response."""
    user_message = payload.get("prompt", "Current state of AI safety in 2025.")
    logger.info(f"Processing user message: {user_message}")

    initialize_telemetry()

    session_id = get_session_id(context=context)
    logger.info(f"Session ID: {session_id}")

    try:
        agent = create_agent(session_id=session_id)
        result = agent(user_message)
        logger.info("Agent completed successfully")

        # Upload outputs to S3
        uploaded_outputs = upload_outputs_to_s3(session_id=session_id)

        return {
            "result": result.message,
            "outputs": uploaded_outputs,
        }
    except Exception as e:
        logger.error(f"Error during agent invocation: {e}", exc_info=True)
        return {"error": str(e)}


def upload_outputs_to_s3(session_id: str) -> dict[str, list[str]]:
    """
    Upload all session outputs to S3.

    Args:
        session_id: Session ID to use as S3 key prefix.

    Returns:
        Dictionary with 'uploaded' and 'failed' keys containing lists of S3 URIs.
    """
    bucket_name = os.environ.get("OUTPUTS_BUCKET_NAME", "")

    if not bucket_name:
        logger.info("OUTPUTS_BUCKET_NAME not set, skipping S3 upload")
        return {"uploaded": [], "failed": []}

    logger.info(
        f"Uploading outputs to S3 bucket '{bucket_name}' with prefix '{session_id}'"
    )

    return upload_session_outputs(
        session_id=session_id,
        bucket_name=bucket_name,
        region_name=os.environ.get("AWS_REGION"),
    )


if __name__ == "__main__":
    app.run()
