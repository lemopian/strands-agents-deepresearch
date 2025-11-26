from functools import lru_cache
import json
import os
import boto3
import logging

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def load_secrets_from_secrets_manager() -> dict[str, str]:
    """
    Load secrets from AWS Secrets Manager based on SECRETS_CONFIG environment variable.

    The SECRETS_CONFIG is a JSON map of env var names to secret names.
    Example: {"LINKUP_API_KEY": "linkup/api-key", "TAVILY_API_KEY": "tavily/api-key"}

    Returns:
        Dictionary mapping environment variable names to their secret values.
    """
    secrets_config_json = os.environ.get("SECRETS_CONFIG")
    if not secrets_config_json:
        logger.info("No SECRETS_CONFIG found, skipping secrets loading")
        return {}

    secrets_config = json.loads(secrets_config_json)
    if not secrets_config:
        return {}

    logger.info(f"Loading {len(secrets_config)} secrets from Secrets Manager")

    region_name = os.environ.get("AWS_REGION", os.environ.get("AWS_DEFAULT_REGION"))
    secrets_client = boto3.client("secretsmanager", region_name=region_name)
    loaded_secrets = {}

    for env_var_name, secret_name in secrets_config.items():
        try:
            response = secrets_client.get_secret_value(SecretId=secret_name)
            secret_value = response["SecretString"]
            loaded_secrets[env_var_name] = secret_value
            os.environ[env_var_name] = secret_value
            logger.info(f"Loaded secret '{secret_name}' into {env_var_name}")
        except Exception as e:
            logger.error(f"Failed to load secret '{secret_name}': {e}")
            raise

    return loaded_secrets
