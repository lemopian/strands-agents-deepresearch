"""
Utility functions for session management.
"""
import logging
import os
import uuid

from deepresearch.config import get_memory_config

logger = logging.getLogger(__name__)

def get_session_id(context=None) -> str:
    """
    Get session ID from context or environment, or generate a new one.

    This is the single source of truth for session ID.

    Args:
        context: Optional AgentCore context with session_id attribute.

    Returns:
        Session ID string.
    """
    if context and hasattr(context, "session_id") and context.session_id:
        return context.session_id
    return os.environ.get("AGENTCORE_SESSION_ID") or str(uuid.uuid4())


def create_session_manager(session_id: str):
    """
    Create a session manager for AgentCore memory if enabled.

    Args:
        session_id: Session ID to use for memory operations.

    Returns:
        AgentCoreMemorySessionManager instance or None if memory is disabled.
    """
    memory_config = get_memory_config(session_id=session_id)
    if memory_config is None:
        logger.info("AgentCore memory is disabled")
        return None

    from bedrock_agentcore.memory.integrations.strands.config import (
        AgentCoreMemoryConfig,
    )
    from bedrock_agentcore.memory.integrations.strands.session_manager import (
        AgentCoreMemorySessionManager,
    )

    agentcore_memory_config = AgentCoreMemoryConfig(
        memory_id=memory_config["memory_id"],
        actor_id=memory_config["actor_id"],
        session_id=memory_config["session_id"],
    )
    logger.info(f"Creating session manager with memory_id={memory_config['memory_id']}")
    return AgentCoreMemorySessionManager(
        agentcore_memory_config=agentcore_memory_config,
        region_name=memory_config["region_name"],
    )
