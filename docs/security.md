# Segurança

## Gestão de identidades e acessos (IAM)

### GitHub Actions → AWS via OIDC

O pipeline autentica-se na AWS através de **OpenID Connect (OIDC)**, assumindo um
IAM Role temporário. Não existem access keys estáticas armazenadas no GitHub. A
trust policy do role está limitada a este repositório:

```
token.actions.githubusercontent.com:sub  StringLike  repo:OWNER/REPO:*
```

### Aplicação → SQS via Instance Profile

A EC2 tem um **IAM Instance Profile** associado. A aplicação (boto3) obtém
credenciais temporárias automaticamente a partir do *instance metadata* — **não
há credenciais AWS no código nem em variáveis de ambiente**.

A política segue o **princípio do menor privilégio**: apenas as ações SQS
estritamente necessárias e apenas sobre as filas deste projeto.

```hcl
actions   = ["sqs:SendMessage", "sqs:ReceiveMessage",
             "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
resources = [queue_arn, dlq_arn]   # apenas estas filas
```

## Gestão de secrets

Nenhuma informação sensível está no código. São usados GitHub Secrets:

| Secret | Uso |
|--------|-----|
| `AWS_ROLE_ARN` | Role assumido via OIDC |
| `TF_VAR_DB_PASSWORD` | Password do RDS (injetada como variável Terraform) |
| `EC2_SSH_KEY` | Chave privada SSH para o Ansible |

A password do RDS é passada como variável Terraform `sensitive`, nunca aparecendo
em logs ou no código.

### SSM Parameter Store (onde a aplicação vai buscar a password)

O GitHub Secret é apenas o **ponto de origem**. O Terraform guarda a password no
**AWS SSM Parameter Store** como `SecureString`, com um parâmetro **em cada
região** (`/<prefixo>/db_password`).

São as próprias instâncias EC2 que a leem, usando as credenciais temporárias do
seu **IAM Instance Profile**:

- **Primário:** o Ansible corre `aws ssm get-parameter --with-decryption` na EC2.
- **Standby:** o `user_data` faz o mesmo no arranque (sem SSH).

A política IAM permite **apenas** `ssm:GetParameter` e **apenas** sobre esse
parâmetro (menor privilégio):

```hcl
actions   = ["ssm:GetParameter"]
resources = [var.ssm_parameter_arn]   # só este parâmetro
```

Consequência importante: a password **não circula no pipeline** nem é exposta em
outputs do Terraform — os workflows só passam dados não sensíveis (endpoint da
BD, nome do parâmetro, utilizador).

### Aprovação manual antes de alterar produção

O job de deploy corre no GitHub Environment `production`, protegido por
**required reviewers**: o `terraform apply` fica em espera até ser aprovado
manualmente, evitando alterações não supervisionadas à infraestrutura.

## Segurança de rede

### Security Group da EC2 (`web-sg`)

- **HTTP (porta 8000):** aberto para acesso público à API.
- **SSH (porta 22):** restrito ao CIDR definido em `ssh_ingress_cidr` (o IP do
  administrador), **não** a `0.0.0.0/0`.
- **SSH para o CI/CD:** o pipeline não deixa o SSH aberto ao mundo. Em vez disso,
  o workflow de deploy **autoriza temporariamente apenas o IP do runner** antes de
  correr o Ansible e **revoga essa regra no fim** (passo com `if: always()`),
  minimizando a superfície de exposição.

### Security Group do RDS (`db-sg`)

- **PostgreSQL (porta 5432):** permitido **apenas** a partir do `web-sg` (a EC2).
  Referência por Security Group, não por CIDR.

## Proteção da base de dados

- Em **subnets privadas**, sem rota para a Internet.
- `publicly_accessible = false`.
- `storage_encrypted = true` (encriptação em repouso).

## Proteção do state Terraform

- **S3** com versionamento e encriptação (SSE) ativados.
- **Bloqueio de acesso público** ao bucket.
- **DynamoDB** para *state locking*, evitando escritas simultâneas.

## Boas práticas aplicadas

- Princípio do menor privilégio (IAM)
- Autenticação federada (OIDC) em vez de chaves estáticas
- Sem credenciais hardcoded
- Isolamento da base de dados em subnets privadas
- Encriptação em repouso (RDS e state)
- Infrastructure as Code e remote state com locking
