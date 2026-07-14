# Limitações e Melhorias Futuras

## Limitações atuais

- **Single point of failure no compute:** apenas uma instância EC2 corre os
  containers. Não há balanceamento de carga nem auto-scaling.
- **RDS single-AZ:** a base de dados não está em configuração Multi-AZ, pelo que
  não há failover automático.
- **Sem monitorização centralizada:** os logs ficam na EC2 (via `docker logs`),
  sem agregação em CloudWatch.
- **Permissões do role de CI largas:** o role do GitHub Actions usa políticas
  *FullAccess* por simplicidade; em produção seriam restringidas às ações exatas.
- **Esquema da BD criado em runtime:** usa-se `create_all` em vez de migrações
  versionadas (ex: Alembic).
- **Um único ambiente:** existe apenas `dev`; não há separação `dev`/`prod`.

## Melhorias futuras

| Área | Melhoria |
|------|----------|
| Disponibilidade | Auto Scaling Group + Application Load Balancer |
| Base de dados | RDS Multi-AZ e read replicas |
| Observabilidade | CloudWatch Logs, métricas e alarmes; tracing (X-Ray) |
| Secrets | AWS Secrets Manager / SSM Parameter Store para a password do RDS |
| Containers | Migração de EC2 para ECS/Fargate |
| Rede | VPC Endpoints para acesso privado à SQS (sem sair para a Internet) |
| Migrações | Gestão de esquema com Alembic |
| IAM | Política do role de CI restringida ao menor privilégio |
| Ambientes | Workspaces/diretórios separados para `dev` e `prod` |

## Nota sobre custos

A infraestrutura usa recursos elegíveis para o **AWS Free Tier** (EC2 `t3.micro`,
RDS `db.t3.micro`, SQS). Ainda assim, deve correr-se `terraform destroy` após a
demonstração para evitar custos de recursos deixados ativos.
