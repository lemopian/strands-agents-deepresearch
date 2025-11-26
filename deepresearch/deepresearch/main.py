"""
DeepSearch Agent implementation using Strands DeepAgents.

This example demonstrates a sophisticated research agent architecture with:
- Research lead agent for strategy and coordination
- Research subagents for focused investigation
- Citations agent for adding source references
"""

import argparse
import logging
import os
import time

from .prompts.citations_agent import CITATIONS_AGENT_PROMPT
from .prompts.research_lead import RESEARCH_LEAD_PROMPT
from .prompts.research_subagent import RESEARCH_SUBAGENT_PROMPT
from strands.types.exceptions import EventLoopException
from strands_tools import file_read, file_write
from .tools import internet_search
from urllib3.exceptions import ProtocolError

from strands_deep_agents import SubAgent, create_deep_agent
from strands_deep_agents.ai_models import basic_claude_haiku_4_5, get_default_model

# Configure logging for better visibility
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[logging.StreamHandler()],
)

# Configure specific loggers
logger = logging.getLogger("deepsearch")
logger.setLevel(logging.INFO)

strands_logger = logging.getLogger("strands")
strands_logger.setLevel(logging.WARNING)  # Reduce noise

deepagents_logger = logging.getLogger("strands_deep_agents")
deepagents_logger.setLevel(logging.INFO)  # Reduce from DEBUG

print(f"Logging to: {log_file}")


def create_deepsearch_agent(
    research_tool,
    tool_name: str | None = None,
    session_manager=None,
    session_id: str | None = None,
):
    """
    Create a DeepSearch agent with research capabilities.

    Args:
        research_tool: Tool to use for research.
        tool_name: Name of the tool to use in prompts (auto-detected if not provided).
        session_manager: Optional session manager for memory integration.
        session_id: Optional session ID for tracing/telemetry.

    Returns:
        Configured DeepSearch agent.
    """
    if tool_name is None:
        if hasattr(research_tool, "__name__"):
            tool_name = research_tool.__name__
        else:
            raise ValueError(
                "Tool name not provided and could not be auto-detected, pass it as a string"
            )

    lead_prompt = RESEARCH_LEAD_PROMPT.format(internet_tool_name=tool_name)
    subagent_prompt = RESEARCH_SUBAGENT_PROMPT.format(internet_tool_name=tool_name)

    research_subagent = SubAgent(
        name="research_subagent",
        description=(
            "Specialized research agent for conducting focused investigations on specific topics. "
            "Use this agent to research specific questions, gather facts, analyze sources, and compile findings. "
            f"This agent has access to {tool_name} for comprehensive web search capabilities. "
            "Results are written to files to keep context lean. "
            "Source documents are saved to research_documents_[topic]/ directories for citation purposes."
        ),
        prompt=subagent_prompt,
        tools=[research_tool, file_write],
        model=get_default_model(),
    )

    citations_agent = SubAgent(
        name="citations_agent",
        description=(
            "Specialized agent for adding citations to research reports. "
            "Use this agent after completing a research report to add proper source citations. "
            "This agent reads the synthesized report and all source documents from research_documents_[topic]/ directories. "
            "It then adds proper inline citations and a references section."
        ),
        model=basic_claude_haiku_4_5(),
        prompt=CITATIONS_AGENT_PROMPT,
        tools=[file_read, file_write],
    )

    agent_kwargs = {
        "instructions": lead_prompt,
        "subagents": [research_subagent, citations_agent],
        "tools": [file_read, file_write],
        "disable_parallel_tool_calling": True,
    }

    if session_manager is not None:
        agent_kwargs["session_manager"] = session_manager

    if session_id is not None:
        agent_kwargs["trace_attributes"] = {
            "session.id": session_id,
            "langfuse.tags": ["DeepResearch"],
        }

    return create_deep_agent(**agent_kwargs)


def main():
    bypass_consent = os.environ.get("BYPASS_TOOL_CONSENT", "true")
    logger.info(f"BYPASS_TOOL_CONSENT status: {bypass_consent}")

    # pass the prompt using terminal args
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-p",
        "--prompt",
        type=str,
        default="""Current state of AI safety in 2025.""",
    )
    args = parser.parse_args()
    prompt = args.prompt

    # Create DeepSearch agent (no memory for local execution)
    agent = create_deepsearch_agent(research_tool=internet_search, session_manager=None)

    # Wrap agent execution in a retry loop for ProtocolError
    max_retries = 3
    retry_delay = 5
    result = None

    for attempt in range(max_retries):
        try:
            logger.info(
                f"Starting agent execution (attempt {attempt + 1}/{max_retries})..."
            )
            result = agent(prompt)
            logger.info("Agent execution completed successfully!")
            break  # Success, exit retry loop
        except (ProtocolError, EventLoopException) as e:
            # Check if it's a streaming/connection error
            error_msg = str(e).lower()
            is_retryable = any(
                keyword in error_msg
                for keyword in [
                    "response ended prematurely",
                    "protocol error",
                    "connection",
                    "timeout",
                ]
            )

            if is_retryable:
                logger.warning(
                    f"Streaming error encountered (attempt {attempt + 1}/{max_retries}): {e}"
                )
                if attempt < max_retries - 1:
                    logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    logger.error(
                        "All retry attempts exhausted. Please try again later."
                    )
                    raise
            else:
                # Non-retryable error, re-raise immediately
                logger.error(f"Non-retryable error: {e}")
                raise
        except Exception as e:
            logger.error(f"Unexpected error during agent execution: {e}")
            raise  # Re-raise other exceptions

    if result is None:
        logger.error("Agent execution failed after all retries")
        return

    logger.info("\nResearch completed successfully!")
    logger.info(f"Agent response: {result}")

    # Show the research plan
    todos = agent.state.get("todos")
    if todos:
        logger.info("\nResearch Plan Execution:")
        for todo in todos:
            status_icon = {
                "completed": "✅",
                "in_progress": "🔄",
                "pending": "⏳",
            }.get(todo["status"], "❓")
            logger.info("  %s %s", status_icon, todo["content"])
        logger.info("")

    logger.info("=" * 80)
    logger.info("DeepSearch example completed!")
    logger.info("=" * 80)


if __name__ == "__main__":
    main()
