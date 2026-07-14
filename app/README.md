# Aplicação — Sistema de Inscrições em Eventos

Dois serviços que comunicam de forma assíncrona:

- **api-service** (FastAPI, porta 8000) — cria eventos e inscrições; ao inscrever,
  grava na base de dados com estado `PENDING` e publica uma mensagem na fila SQS.
- **worker-service** — consome a fila SQS, decide `CONFIRMED`/`REJECTED` consoante
  a capacidade do evento e atualiza a base de dados. Falhas vão para a DLQ.

## Desenvolvimento local (sem custos AWS)

Replica a arquitetura de produção com **Postgres** (em vez de RDS) e **LocalStack**
(em vez de SQS). O código é o mesmo; muda só a configuração por variáveis de ambiente.

```bash
cd app
docker compose up --build
```

### Testar o fluxo end-to-end

```bash
# 1. Criar um evento com 1 vaga
curl -X POST http://localhost:8000/events \
  -H "Content-Type: application/json" \
  -d '{"name": "Workshop Cloud", "capacity": 1}'

# 2. Primeira inscrição -> ficará CONFIRMED
curl -X POST http://localhost:8000/registrations \
  -H "Content-Type: application/json" \
  -d '{"event_id": 1, "participant_name": "Ana", "email": "ana@exemplo.pt"}'

# 3. Segunda inscrição -> ficará REJECTED (evento cheio)
curl -X POST http://localhost:8000/registrations \
  -H "Content-Type: application/json" \
  -d '{"event_id": 1, "participant_name": "Rui", "email": "rui@exemplo.pt"}'

# 4. Ver os estados (após 1-2 segundos de processamento do worker)
curl http://localhost:8000/registrations
```

Documentação interativa da API: http://localhost:8000/docs
