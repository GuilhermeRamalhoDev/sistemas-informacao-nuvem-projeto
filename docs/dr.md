# Disaster Recovery (DR) — Runbook

Este documento descreve a estratégia de resiliência e recuperação de desastres,
e como disparar, observar e reverter um *failover*.

## Objetivos

| Métrica | Alvo | Justificação |
|---------|------|--------------|
| **RTO** (Recovery Time Objective) | < 2 min | Tempo até o tráfego passar para o ambiente saudável via health checks do Global Accelerator |
| **RPO** (Recovery Point Objective) — falha de AZ | ≈ 0 | RDS Multi-AZ mantém um standby **síncrono** noutra AZ |
| **RPO** — falha de Região | ≤ intervalo de snapshot | Recuperação a partir de backups automáticos / cópia de snapshot cross-region |

## Estratégia

A solução usa um padrão **warm standby** em duas regiões:

```
              AWS Global Accelerator  (IP estático anycast + health checks)
                       │                                    │
            ┌──────────┘                                    └──────────┐
            ▼ PRIMÁRIO — us-east-1                          ▼ STANDBY — us-west-2
       VPC + EC2 (API + Worker)                        VPC + EC2 (API + Worker)
       RDS PostgreSQL Multi-AZ                         RDS PostgreSQL (single-AZ)
       (standby síncrono noutra AZ)                    auto-provisionado (user_data)
```

### Camadas de resiliência

1. **Falha de instância / aplicação** → o Global Accelerator deteta pelo health
   check (`/health`, porta 8000) e encaminha o tráfego para a outra região.
2. **Falha de AZ (base de dados)** → o RDS **Multi-AZ** do primário faz failover
   automático para o standby síncrono, sem perda de dados (RPO ≈ 0).
3. **Falha de Região inteira** → o Global Accelerator encaminha para o standby em
   `us-west-2`, que se auto-provisiona. Os dados são recuperáveis a partir dos
   backups automáticos (retenção de 7 dias) / cópia de snapshot cross-region.

### Porquê Global Accelerator (e não Route 53)

O Global Accelerator dá um **IP estático único** com failover automático por
health checks, **sem exigir um domínio registado**. O cliente usa sempre o mesmo
endereço; a AWS encaminha para o endpoint saudável. Zero interação com a consola.

## Tudo codificado (sem cliques na consola)

- Ambos os ambientes são **instâncias do mesmo módulo Terraform** (`modules/stack`),
  parametrizado por região — o standby é uma cópia parametrizada do primário.
- O Global Accelerator e os health checks são definidos em Terraform
  (`modules/accelerator`).
- O *failover drill* é um workflow do GitHub Actions (`failover-drill.yml`),
  disparado manualmente, que simula a falha do primário e **mede o RTO**.

## Como disparar um failover drill

1. Na aba **Actions** do GitHub → workflow **Failover Drill** → **Run workflow**.
2. O workflow:
   - regista o instante inicial;
   - **para a aplicação no primário** (simula a falha);
   - faz *polling* ao IP do Global Accelerator até a resposta vir do **standby**;
   - regista o instante final e calcula o **RTO medido**.
3. O resultado (RTO em segundos) aparece no resumo da execução.

## Como observar

- **Global Accelerator** → consola AWS → *Global Accelerator* → *Listeners* →
  *Endpoint groups*: mostra o estado (*Healthy*/*Unhealthy*) de cada região.
- **Aplicação:** `curl http://<accelerator_ip>:8000/health` → o campo `service`/host
  indica qual região está a responder.

## Como reverter (failback)

1. Recuperar o ambiente primário (novo `terraform apply` / reiniciar a app).
2. Assim que o health check do primário voltar a *Healthy*, o Global Accelerator
   volta a encaminhar para o primário automaticamente (é a região preferida).
3. Nenhum passo manual na consola é necessário.

## Números medidos (preencher após o drill)

| Cenário | RTO medido | RPO |
|---------|-----------|-----|
| Falha da app no primário | _(preencher no drill)_ | ≈ 0 (Multi-AZ) |
| Falha de Região | _(preencher no drill)_ | ≤ intervalo de snapshot |

## Nota sobre custos

O standby e o Global Accelerator só são ligados durante os testes/demonstração.
Padrão **warm standby**: o standby corre com recursos mínimos (`t3.micro`,
RDS single-AZ) para equilibrar custo e tempo de recuperação. Após a demonstração,
`terraform destroy` remove ambos os ambientes.
