"""Cliente SQS (igual ao do API Service)."""
import boto3

from .config import settings


def get_sqs_client():
    kwargs = {"region_name": settings.aws_region}
    if settings.aws_endpoint_url:
        kwargs["endpoint_url"] = settings.aws_endpoint_url
    return boto3.client("sqs", **kwargs)
