"""
S3 output uploader for DeepSearch agent.

Uploads all research outputs (documents, findings, reports) to S3
with a session-based prefix for organization.
"""

import logging
import os
from pathlib import Path

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger("deepsearch.s3_outputs")

# File patterns for intermediate outputs (research documents)
RESEARCH_DOCUMENTS_PATTERN = "research_documents_"
# File patterns for final outputs (findings and reports)
FINDINGS_PATTERN = "research_findings_"
REPORT_PATTERN = "_report"


def get_s3_client(region_name: str | None = None):
    """
    Get S3 client for uploads.

    Args:
        region_name: AWS region name. If not provided, uses default region.

    Returns:
        boto3 S3 client.
    """
    region = region_name or os.environ.get("AWS_REGION")
    return boto3.client("s3", region_name=region)


def upload_file_to_s3(
    s3_client,
    file_path: Path,
    bucket_name: str,
    s3_key: str,
) -> bool:
    """
    Upload a single file to S3.

    Args:
        s3_client: boto3 S3 client.
        file_path: Local path to the file.
        bucket_name: S3 bucket name.
        s3_key: S3 object key.

    Returns:
        True if upload successful, False otherwise.
    """
    try:
        content_type = "text/markdown" if file_path.suffix == ".md" else "text/plain"
        s3_client.upload_file(
            str(file_path),
            bucket_name,
            s3_key,
            ExtraArgs={"ContentType": content_type},
        )
        logger.info(f"Uploaded {file_path.name} to s3://{bucket_name}/{s3_key}")
        return True
    except ClientError as e:
        logger.error(f"Failed to upload {file_path.name}: {e}")
        return False


def collect_output_files(working_dir: Path) -> dict[str, list[Path]]:
    """
    Collect all output files from the working directory.

    Args:
        working_dir: Directory to scan for output files.

    Returns:
        Dictionary with 'intermediate' and 'final' keys containing lists of file paths.
    """
    outputs = {
        "intermediate": [],  # Research documents (sources)
        "final": [],  # Findings and reports
    }

    # Collect research documents directories
    for item in working_dir.iterdir():
        if item.is_dir() and item.name.startswith(RESEARCH_DOCUMENTS_PATTERN):
            for doc_file in item.glob("*.md"):
                outputs["intermediate"].append(doc_file)
            for doc_file in item.glob("*.txt"):
                outputs["intermediate"].append(doc_file)

    # Collect findings and report files
    for item in working_dir.iterdir():
        if item.is_file():
            if item.name.startswith(FINDINGS_PATTERN):
                outputs["final"].append(item)
            elif REPORT_PATTERN in item.name and item.suffix in (".md", ".txt"):
                outputs["final"].append(item)

    return outputs


def upload_session_outputs(
    session_id: str,
    bucket_name: str,
    working_dir: Path | str | None = None,
    region_name: str | None = None,
) -> dict[str, list[str]]:
    """
    Upload all session outputs to S3 with session prefix.

    Uploads are organized as:
    - {session_id}/intermediate/{research_topic}/{source_file.md}
    - {session_id}/final/{findings_or_report.md}

    Args:
        session_id: Unique session identifier used as S3 prefix.
        bucket_name: S3 bucket name for outputs.
        working_dir: Directory containing output files. Defaults to current directory.
        region_name: AWS region name.

    Returns:
        Dictionary with 'uploaded' and 'failed' keys containing lists of S3 URIs.
    """
    if not bucket_name:
        logger.warning("No outputs bucket configured, skipping S3 upload")
        return {"uploaded": [], "failed": []}

    work_path = Path(working_dir) if working_dir else Path.cwd()
    s3_client = get_s3_client(region_name=region_name)

    outputs = collect_output_files(working_dir=work_path)
    result = {"uploaded": [], "failed": []}

    # Upload intermediate outputs (research documents)
    for file_path in outputs["intermediate"]:
        # Extract topic from parent directory name (research_documents_{topic})
        topic = file_path.parent.name.replace(RESEARCH_DOCUMENTS_PATTERN, "")
        s3_key = f"{session_id}/intermediate/{topic}/{file_path.name}"

        if upload_file_to_s3(
            s3_client=s3_client,
            file_path=file_path,
            bucket_name=bucket_name,
            s3_key=s3_key,
        ):
            result["uploaded"].append(f"s3://{bucket_name}/{s3_key}")
        else:
            result["failed"].append(str(file_path))

    # Upload final outputs (findings and reports)
    for file_path in outputs["final"]:
        s3_key = f"{session_id}/final/{file_path.name}"

        if upload_file_to_s3(
            s3_client=s3_client,
            file_path=file_path,
            bucket_name=bucket_name,
            s3_key=s3_key,
        ):
            result["uploaded"].append(f"s3://{bucket_name}/{s3_key}")
        else:
            result["failed"].append(str(file_path))

    logger.info(
        f"S3 upload complete: {len(result['uploaded'])} uploaded, "
        f"{len(result['failed'])} failed"
    )
    return result


def upload_single_file(
    session_id: str,
    bucket_name: str,
    file_path: Path | str,
    output_type: str = "final",
    region_name: str | None = None,
) -> str | None:
    """
    Upload a single file to S3 outputs bucket.

    Args:
        session_id: Unique session identifier used as S3 prefix.
        bucket_name: S3 bucket name for outputs.
        file_path: Path to the file to upload.
        output_type: Either 'intermediate' or 'final'.
        region_name: AWS region name.

    Returns:
        S3 URI if successful, None if failed.
    """
    if not bucket_name:
        logger.warning("No outputs bucket configured, skipping S3 upload")
        return None

    path = Path(file_path) if isinstance(file_path, str) else file_path
    if not path.exists():
        logger.error(f"File not found: {path}")
        return None

    s3_client = get_s3_client(region_name=region_name)
    s3_key = f"{session_id}/{output_type}/{path.name}"

    if upload_file_to_s3(
        s3_client=s3_client,
        file_path=path,
        bucket_name=bucket_name,
        s3_key=s3_key,
    ):
        return f"s3://{bucket_name}/{s3_key}"
    return None
