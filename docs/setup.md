# Setup e Pré-requisitos

## Ferramentas necessárias

- Conta AWS (com permissões de administrador para o bootstrap)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Docker](https://docs.docker.com/get-docker/) e Docker Compose
- AWS CLI configurada (`aws configure`)
- Git

## 1. EC2 Key Pair

Cria um key pair na AWS (para o Ansible aceder à EC2 por SSH):

```bash
aws ec2 create-key-pair --key-name cloud-key \
  --query 'KeyMaterial' --output text > cloud-key.pem
chmod 600 cloud-key.pem
```

Guarda o conteúdo de `cloud-key.pem` no GitHub Secret `EC2_SSH_KEY` e usa
`cloud-key` como valor da variável `EC2_KEY_NAME`.

## 2. Bootstrap do backend e OIDC (corre UMA vez)

O Terraform principal usa um backend remoto (S3 + DynamoDB) e o GitHub Actions
autentica-se via OIDC. Estes recursos são criados pela pasta `bootstrap/`, que
usa **state local** (não pode depender do backend que está a criar).

```bash
cd bootstrap
terraform init
terraform apply -var="github_repo=OWNER/REPO"
```

No fim, anota os outputs:

- `state_bucket` e `lock_table` → já correspondem aos valores em `infrastructure/backend.tf`
- `github_actions_role_arn` → guarda no GitHub Secret `AWS_ROLE_ARN`

## 3. Configurar GitHub (Secrets e Variables)

No repositório GitHub → *Settings* → *Secrets and variables* → *Actions*:

**Secrets:**

| Nome | Valor |
|------|-------|
| `AWS_ROLE_ARN` | output `github_actions_role_arn` do bootstrap |
| `TF_VAR_DB_PASSWORD` | password à escolha para o RDS |
| `EC2_SSH_KEY` | conteúdo do `cloud-key.pem` |

**Variables:**

| Nome | Valor |
|------|-------|
| `EC2_KEY_NAME` | `cloud-key` |
| `SSH_INGRESS_CIDR` | o teu IP público em `/32` (ex: `1.2.3.4/32`) |

## 4. Próximos passos

- Para correr a aplicação localmente: [`../app/README.md`](../app/README.md)
- Para fazer deploy na AWS: [`deployment.md`](deployment.md)
