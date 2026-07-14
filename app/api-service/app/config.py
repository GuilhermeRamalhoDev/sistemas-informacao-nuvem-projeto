"""Configuração da aplicação lida a partir de variáveis de ambiente.

O mesmo código corre localmente (Docker Compose + LocalStack) e na AWS.
A única diferença é o valor das variáveis de ambiente:

- Local:  AWS_ENDPOINT_URL aponta para o LocalStack (http://localstack:4566)
- AWS:    AWS_ENDPOINT_URL fica vazio -> boto3 usa os endpoints reais da AWS
          e as credenciais vêm do IAM Role da EC2 (nunca hardcoded).
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Base de dados
    database_url: str = "postgresql+psycopg2://app:app@db:5432/eventsdb"

    # AWS / SQS
    aws_region: str = "us-east-1"
    # Vazio em produção (AWS real); preenchido em local para o LocalStack.
    aws_endpoint_url: str | None = None
    sqs_queue_url: str = ""

    # Metadados
    service_name: str = "api-service"


settings = Settings()
