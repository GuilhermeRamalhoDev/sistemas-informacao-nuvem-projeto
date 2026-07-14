"""Configuração do Worker lida a partir de variáveis de ambiente.

O mesmo código corre localmente (LocalStack) e na AWS (IAM Role da EC2).
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg2://app:app@db:5432/eventsdb"

    aws_region: str = "us-east-1"
    aws_endpoint_url: str | None = None
    sqs_queue_url: str = ""

    # Segundos de long-polling ao ler da fila.
    wait_time_seconds: int = 10

    service_name: str = "worker-service"


settings = Settings()
