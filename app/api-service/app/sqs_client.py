"""Cliente SQS partilhado.

boto3 resolve as credenciais automaticamente:
- Local: variáveis dummy + endpoint do LocalStack.
- AWS:   IAM Role da EC2 (sem credenciais no código).
"""
import boto3

from .config import settings


def get_sqs_client():
    kwargs = {"region_name": settings.aws_region}
    # Só definimos endpoint_url em local (LocalStack). Em AWS fica None.
    if settings.aws_endpoint_url:
        kwargs["endpoint_url"] = settings.aws_endpoint_url
    return boto3.client("sqs", **kwargs)
