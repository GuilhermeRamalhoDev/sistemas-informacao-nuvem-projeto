# Arquitetura

## Abordagem

Foi seguida a **Approach A** (track de engenharia cloud), com uma aplicação
própria e leve em Python/FastAPI para manter o foco na infraestrutura,
automação e práticas operacionais.

## Visão geral

A solução é composta por dois serviços que comunicam de forma assíncrona:

- **API Service** (FastAPI) — expõe uma API HTTP para criar e consultar eventos
  e inscrições. Ao criar uma inscrição, grava-a na base de dados com estado
  `PENDING` e publica uma mensagem na fila SQS.
- **Worker Service** — consome mensagens da fila SQS, aplica a lógica de negócio
  (validação de capacidade do evento) e atualiza o estado da inscrição na base
  de dados para `CONFIRMED` ou `REJECTED`.

```
Cliente ──HTTP──► API Service ──┬──► RDS PostgreSQL (INSERT status=PENDING)
                                └──► SQS (mensagem: {registration_id})
                                          │
                                          ▼
                                 Worker Service ──► RDS (UPDATE status)
                                          │
                                   (3 falhas) ──► Dead Letter Queue
```

## Design de rede

| Recurso | Configuração |
|---------|--------------|
| VPC | `10.0.0.0/16` |
| Subnets públicas | `10.0.1.0/24`, `10.0.2.0/24` (2 AZs) — alojam a EC2 |
| Subnets privadas | `10.0.11.0/24`, `10.0.12.0/24` (2 AZs) — alojam o RDS |
| Internet Gateway | acesso à Internet para as subnets públicas |
| Route table pública | rota `0.0.0.0/0` → IGW |

A base de dados fica em **subnets privadas, sem acesso público**, acessível
apenas a partir da EC2 (controlado por Security Group).

## Comunicação entre serviços

- **Síncrona:** o cliente fala com o API Service por HTTP (REST/JSON).
- **Assíncrona:** o API Service e o Worker comunicam via **Amazon SQS**. Isto
  desacopla a receção do pedido do seu processamento, melhora a resiliência
  (picos de carga são absorvidos pela fila) e permite escalar o Worker de forma
  independente.

## Componente event-driven e resiliência

A fila principal tem uma **redrive policy** com `maxReceiveCount = 3`: se o
Worker falhar a processar uma mensagem 3 vezes, esta é movida para a **Dead
Letter Queue**, evitando ciclos infinitos e permitindo inspecionar falhas.

## Persistência

Amazon RDS PostgreSQL. Duas tabelas: `events` (capacidade) e `registrations`
(estado da inscrição). O esquema é criado automaticamente no arranque dos
serviços (`create_all`).

## Principais decisões técnicas

| Decisão | Justificação |
|---------|--------------|
| Terraform em módulos | Reutilização e separação lógica (networking, compute, database, queue, iam) |
| Remote state (S3 + DynamoDB) | Trabalho colaborativo e locking contra escritas simultâneas |
| OIDC no GitHub Actions | Elimina access keys estáticas na pipeline |
| IAM Instance Profile na EC2 | A aplicação acede à SQS sem credenciais hardcoded |
| SQS para comunicação | Desacoplamento e resiliência entre serviços |
| Tags de imagem por commit SHA | Deploys imutáveis e rastreáveis |

## Paridade local/produção

O ambiente local (Docker Compose) replica a arquitetura usando **Postgres** em
vez de RDS e **LocalStack** em vez de SQS. O código é idêntico; muda apenas a
configuração via variáveis de ambiente (`AWS_ENDPOINT_URL`, `DATABASE_URL`,
`SQS_QUEUE_URL`).
