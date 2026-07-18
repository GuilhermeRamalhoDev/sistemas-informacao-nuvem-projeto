# Disaster Recovery (DR) — Runbook

Estratégia de resiliência e recuperação de desastres, e como disparar, observar
e reverter um *failover*.

## Objetivos

| Métrica | Alvo | Como é conseguido |
|---------|------|-------------------|
| **RTO** (Recovery Time Objective) | < 1 min | Failover automático do Route 53 por health checks |
| **RPO** (Recovery Point Objective) | ≤ intervalo de snapshot | Snapshots automáticos do RDS (+ cópia cross-region) |

## Estratégia

Padrão **warm standby** em duas regiões, com failover automático por DNS:

```
                 Route 53  (failover routing + health check ao /health)
                       │  responde com o IP saudável
            ┌──────────┴───────────┐
            ▼ PRIMÁRIO — us-east-1   ▼ STANDBY — us-west-2
       EC2 (API + Worker) + EIP     EC2 (API + Worker) + EIP
       RDS PostgreSQL               RDS PostgreSQL
       (Ansible)                    (auto-provisionado por user_data)
```

- Ambos os ambientes são **instâncias do mesmo módulo Terraform**
  (`modules/stack`), parametrizado por região — o standby é uma cópia
  parametrizada do primário.
- Cada EC2 tem um **Elastic IP** estável (não muda em stop/start), usado pelos
  health checks e pelo failover.
- O standby **auto-provisiona-se** por `user_data`: vai buscar a password ao
  **SSM Parameter Store** e arranca os containers a partir de imagens públicas
  no GHCR — sem SSH e sem intervenção manual.

## Failover automático (Route 53)

Um **health check** do Route 53 monitoriza `http://<primary_eip>:8000/health`.
Dois registos com *failover routing policy*:

- **PRIMARY** → IP do primário (associado ao health check)
- **SECONDARY** → IP do standby

Se o primário ficar *unhealthy*, o Route 53 passa automaticamente a responder com
o IP do standby. **Zero cliques na consola.**

### Porquê Route 53 (e não Global Accelerator)

O Global Accelerator exige uma subscrição que **não está disponível na conta Free
Tier** usada. O Route 53 oferece failover automático por health checks sem esse
requisito e sem domínio pago — a zona é consultada diretamente pelos seus
nameservers na demonstração (`dig @<ns> <fqdn>`).

## Resiliência de dados

A conta Free Tier **não inclui RDS Multi-AZ**, pelo que a resiliência de dados é
garantida por **snapshots automáticos** do RDS (retenção de 1 dia) e por cópia de
snapshot para a região standby. Em produção (conta paga), ativar-se-ia
`multi_az = true` — o código já suporta esse parâmetro (`modules/database`).

- **RPO:** limitado ao intervalo entre snapshots.
- **Recuperação:** restauro do último snapshot na região standby (documentado).

## Pipeline: um só workflow provisiona os dois ambientes

- `terraform plan` corre em **cada Pull Request**, cobrindo primário **e** standby
  (ambos estão na mesma configuração).
- `terraform apply` corre em merge para `main`, **protegido por aprovação
  manual** no GitHub Environment `production` (*required reviewers*).
- Autenticação por **OIDC**, sem access keys de longa duração.

## Gestão de secrets (nas duas regiões)

A password da BD é guardada no **SSM Parameter Store** como `SecureString`, com um
parâmetro **em cada região** (`/<prefixo>/db_password`). Em ambos os ambientes é a
própria EC2 que a lê, com as credenciais temporárias do seu IAM Instance Profile:

- **Primário:** o Ansible corre `aws ssm get-parameter --with-decryption` na EC2.
- **Standby:** o `user_data` faz o mesmo no arranque.

A password **nunca** passa pelo pipeline nem aparece em outputs do Terraform.

## Custo: porquê warm standby (tradeoff)

| Padrão | Custo | RTO |
|--------|-------|-----|
| Backup & restore | mínimo | horas |
| **Pilot light** | baixo (BD replicada, compute desligado) | dezenas de minutos |
| **Warm standby** ← escolhido | médio (tudo a correr, dimensão mínima) | **segundos** |
| Multi-site ativo/ativo | alto (capacidade dupla) | ~zero |

Escolhi **warm standby** com recursos mínimos (`t3.micro`, RDS single-AZ): o
standby está sempre a correr e pronto a receber tráfego, o que dá um RTO de
segundos, mas com custo reduzido por ser dimensionado ao mínimo. Um *pilot light*
seria mais barato, mas exigiria arrancar o compute durante o incidente,
aumentando muito o RTO.

## Tudo codificado (sem cliques na consola)

- Infraestrutura dos dois ambientes: `modules/stack` (parametrizado).
- Failover: `modules/dns` (Route 53 + health checks).
- *Failover drill*: workflow `failover-drill.yml`, disparado manualmente, que
  simula a falha do primário e **mede o RTO**.

## Como disparar um failover drill

1. GitHub → **Actions** → **Failover Drill** → **Run workflow**.
2. O workflow:
   - regista o instante inicial;
   - **para a EC2 primária** (simula a falha);
   - faz *polling* ao `route53 test-dns-answer` até a resposta passar a ser o IP
     do standby;
   - regista o instante final e calcula o **RTO medido** (no resumo da execução).
3. Opcionalmente faz *failback* (reinicia o primário).

## Como observar

- **Route 53** → consola → *Hosted zones* → *Health checks*: estado do primário.
- **Resolução:** `aws route53 test-dns-answer --hosted-zone-id <id>
  --record-name app.sinuvem-eventos.dr --record-type A` → mostra o IP atual.

## Como reverter (failback)

1. Reiniciar/recuperar a EC2 primária (`aws ec2 start-instances` ou novo apply).
2. Quando o health check do primário voltar a *Healthy*, o Route 53 volta a
   responder com o IP do primário automaticamente.

## Números medidos

Drill executado com sucesso (paragem da EC2 primária, medição via
`route53 test-dns-answer`):

| Cenário | RTO medido | RPO |
|---------|-----------|-----|
| Falha do primário → standby | **~38 s** | ≤ intervalo de snapshot |

Observação do drill: o Route 53 respondeu com o IP do primário
(`34.229.4.87`) até ~t+31s e passou a responder com o IP do standby
(`54.245.237.71`) a ~t+38s — coerente com `request_interval=10s` e
`failure_threshold=2` (≈2-3 falhas consecutivas + propagação).

## Nota sobre custos

Standby e health checks só são mantidos durante os testes/demonstração. Padrão
**warm standby** com recursos mínimos (`t3.micro`, RDS single-AZ). Após a
demonstração, `terraform destroy` remove ambos os ambientes.
