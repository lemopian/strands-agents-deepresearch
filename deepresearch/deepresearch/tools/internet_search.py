"""
Tools for searching the web using Linkup and Tavily.
"""

import asyncio
import logging
import os
import random

from linkup import LinkupClient
from strands import tool
from strands_tools import tavily

if os.environ.get("LOAD_DOTENV", "false").lower() == "true":
    from dotenv import load_dotenv

    load_dotenv()

logger = logging.getLogger(__name__)


@tool
def linkup_search(query: str) -> str:
    """Search the web using Linkup

    Args:
        query: The query to search for

    Returns:
        The search results
    """
    client = LinkupClient()

    response = client.search(
        query=query,
        depth="standard",
        output_type="sourcedAnswer",
        include_images=False,
        include_inline_citations=False,
    )

    return str(response)


@tool
def internet_search(query: str) -> str:
    """Search the web using the internet

    Args:
        query: The query to search for

    Returns:
        The search results
    """
    internet_tools = [
        "linkup_search",
        # "tavily_search", # If you have tavily credits, you can use it here, just uncomment the row, and make sure to add the tavily api key in secrets manager
        # Add your favorite internet tools here, make sure to add the api key in secrets manager, and in the variables file
    ]
    selected_tool = random.choice(internet_tools)
    logger.info("Using search tool: %s", selected_tool)

    match selected_tool:
        case "linkup_search":
            return linkup_search(query=query)
        case "tavily_search":
            return asyncio.run(tavily.tavily_search(query=query))
        case _:
            raise ValueError(f"Unknown search tool: {selected_tool}")


if __name__ == "__main__":
    print(internet_search(query="What is the capital of France?"))
