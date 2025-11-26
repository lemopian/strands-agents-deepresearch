"""
Utility functions for Telemetry tracing.
"""

import base64
import logging
import os
from strands.telemetry import StrandsTelemetry

logger = logging.getLogger(__name__)


def initialize_telemetry() -> bool:
    """
    Initialize Strands telemetry with OTLP exporter.

    When deployed via AgentCore, OTEL env vars (OTEL_EXPORTER_OTLP_ENDPOINT,
    OTEL_EXPORTER_OTLP_HEADERS) are already configured via Terraform.

    For local development, this function will construct them from individual
    Langfuse credentials if they're not already set.

    Returns:
        True if telemetry was initialized, False if skipped due to missing config.
    """
    # Check if OTEL endpoint is already configured (e.g., via Terraform in AgentCore)
    has_otel_endpoint = "OTEL_EXPORTER_OTLP_ENDPOINT" in os.environ

    # Check if Langfuse credentials are available for local development
    has_langfuse_config = all(
        key in os.environ
        for key in ["LANGFUSE_PUBLIC_KEY", "LANGFUSE_SECRET_KEY", "LANGFUSE_HOST"]
    )

    if not has_otel_endpoint and not has_langfuse_config:
        logger.info(
            "Telemetry skipped: No OTEL_EXPORTER_OTLP_ENDPOINT or Langfuse credentials configured"
        )
        return False

    # Configure OTEL from Langfuse credentials if not already set
    if "OTEL_EXPORTER_OTLP_HEADERS" not in os.environ and has_langfuse_config:
        langfuse_auth_token = base64.b64encode(
            f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}".encode()
        ).decode()
        os.environ["OTEL_EXPORTER_OTLP_HEADERS"] = (
            f"Authorization=Basic {langfuse_auth_token}"
        )

    if "OTEL_EXPORTER_OTLP_ENDPOINT" not in os.environ and has_langfuse_config:
        os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = (
            os.environ["LANGFUSE_HOST"] + "/api/public/otel"
        )

    strands_telemetry = StrandsTelemetry()
    strands_telemetry.setup_otlp_exporter()
    logger.info(
        f"Telemetry initialized with endpoint: {os.environ.get('OTEL_EXPORTER_OTLP_ENDPOINT')}"
    )
    return True
