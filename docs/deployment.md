# Deployment

Pré-requisitos e bootstrap concluídos? Ver [`setup.md`](setup.md).

## Deploy automático (recomendado)

O deploy é feito pelo pipeline CI/CD sempre que há `push` para `main`:

```bash
git add .
git commit -m "deploy"
git push origin main
```

O workflow [`deploy.yml`](../.github/workflows/deploy.yml) executa:

1. **Build & push** das imagens Docker (`api-service`, `worker-service`) para o
   GHCR, com tag imutável igual ao **commit SHA** (e `latest`).
2. **Autenticação na AWS via OIDC** (sem access keys).
3. **`terraform init` + `terraform apply`** — cria/atualiza VPC, EC2, RDS, SQS e IAM.
4. **Captura dos outputs** (IP da EC2, URL da fila, DATABASE_URL).
5. **Ansible** — instala Docker na EC2, faz pull das imagens e arranca os
   containers com as variáveis de ambiente corretas.

A aplicação fica acessível em `http://<ec2_public_ip>:8000`.

## Verificação

```bash
EC2_IP=<ip_da_ec2>

# Health
curl http://$EC2_IP:8000/health

# Criar evento e inscrição
curl -X POST http://$EC2_IP:8000/events \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo","capacity":1}'

curl -X POST http://$EC2_IP:8000/registrations \
  -H "Content-Type: application/json" \
  -d '{"event_id":1,"participant_name":"Ana","email":"ana@exemplo.pt"}'

# Ver o estado (PENDING -> CONFIRMED após o worker processar)
curl http://$EC2_IP:8000/registrations
```

## Deploy manual (alternativa)

```bash
cd terraform
terraform init
terraform apply \
  -var="db_password=<password>" \
  -var="key_name=cloud-key" \
  -var="ssh_ingress_cidr=<teu_ip>/32"
```

Depois corre o Ansible com o inventário gerado a partir do output
`ec2_public_ip` (ver [`../ansible/inventory.ini.example`](../ansible/inventory.ini.example)).

## CI em Pull Requests

O workflow [`pr-check.yml`](../.github/workflows/pr-check.yml) corre em cada PR:
lint (`ruff`) e testes da aplicação, `terraform fmt -check`, `validate` e
**`terraform plan`** — funcionando como gate antes do merge.

## Destruir a infraestrutura

Para não acumular custos após a demonstração:

```bash
cd terraform
terraform destroy \
  -var="db_password=<password>" \
  -var="key_name=cloud-key" \
  -var="ssh_ingress_cidr=<teu_ip>/32"
```
