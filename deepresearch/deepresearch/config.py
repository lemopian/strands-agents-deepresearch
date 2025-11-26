"""
Configuration for DeepSearch agent rate limiting and concurrency.

API Rate Limit: 10 queries per second
- Theoretical minimum: 0.1s between calls (100ms)
- Safe minimum with margin: 0.15s between calls (6.67 queries/sec)
- Conservative with overhead: 0.2s between calls (5 queries/sec)
"""

import os


def is_memory_enabled() -> bool:
    """Check if AgentCore memory is enabled via environment variable."""
    return os.environ.get("ENABLE_MEMORY", "false").lower() == "true"


def get_memory_config(session_id: str) -> dict[str, str] | None:
    """
    Get AgentCore Memory configuration if memory is enabled.

    Args:
        session_id: Session ID to use for memory operations.

    Returns:
        Dictionary with memory configuration or None if memory is disabled.
    """
    if not is_memory_enabled():
        return None

    memory_id = os.environ.get("AGENTCORE_MEMORY_ID")
    if not memory_id:
        return None

    return {
        "memory_id": memory_id,
        "session_id": session_id,
        "actor_id": os.environ.get("AGENTCORE_ACTOR_ID", "deepsearch-agent"),
        "region_name": os.environ.get("AWS_REGION"),
    }
