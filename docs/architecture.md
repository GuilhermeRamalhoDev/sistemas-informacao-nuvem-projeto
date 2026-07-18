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

![Arquitetura da solução](imagens/arquitetura.svg)

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

## Alta disponibilidade: dois ambientes (Disaster Recovery)

A arquitetura descrita acima é replicada em **duas regiões AWS**, a partir do
**mesmo módulo Terraform** (`modules/stack`), parametrizado por região:

| Ambiente | Região | Configuração da app |
|----------|--------|---------------------|
| **Primário** | `us-east-1` | Configurado por Ansible (via SSH do pipeline) |
| **Standby** | `us-west-2` | Auto-provisionado por `user_data` (sem SSH) |

À frente dos dois está o **Route 53** com *failover routing* e um health check ao
`/health` do primário: se este falhar, o DNS passa automaticamente a responder
com o IP do standby, sem qualquer intervenção manual.

Detalhe completo, objetivos de RTO/RPO e runbook do failover em [`dr.md`](dr.md).

## Principais decisões técnicas

| Decisão | Justificação |
|---------|--------------|
| Terraform em módulos | Reutilização e separação lógica (networking, compute, database, queue, iam, dns) |
| Módulo `stack` instanciado 2x | O standby é uma **cópia parametrizada** do primário — sem código duplicado |
| Remote state (S3 + DynamoDB) | Trabalho colaborativo e locking contra escritas simultâneas |
| OIDC no GitHub Actions | Elimina access keys estáticas na pipeline |
| IAM Instance Profile na EC2 | A aplicação acede à SQS e ao SSM sem credenciais hardcoded |
| Secrets no SSM Parameter Store | A password é lida pela EC2, não circula no pipeline |
| SQS para comunicação | Desacoplamento e resiliência entre serviços |
| Tags de imagem por commit SHA | Deploys imutáveis e rastreáveis |
| Route 53 para failover | Failover automático por health checks, sem depender de serviços indisponíveis no Free Tier |

## Paridade local/produção

O ambiente local (Docker Compose) replica a arquitetura usando **Postgres** em
vez de RDS e **LocalStack** em vez de SQS. O código é idêntico; muda apenas a
configuração via variáveis de ambiente (`AWS_ENDPOINT_URL`, `DATABASE_URL`,
`SQS_QUEUE_URL`).
