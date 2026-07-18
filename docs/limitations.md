# Limitações e Melhorias Futuras

## Limitações atuais

### Resiliência e Disaster Recovery

- **Sem replicação de dados entre regiões (limitação assumida).** O ambiente
  standby tem a sua própria instância RDS, que **não replica os dados do
  primário**. O failover de tráfego é automático (Route 53), mas o standby não
  assume o *estado* da base de dados. A resiliência de dados assenta em
  **snapshots automáticos** do RDS, com o RPO documentado em [`dr.md`](dr.md).
  - **Passo seguinte identificado:** criar uma **read replica cross-region**
    (`replicate_source_db`) e **promovê-la** (`promote-read-replica`) como parte
    do *failover drill*, reduzindo o RPO para segundos.
- **RDS single-AZ:** a conta usada é **Free Tier**, que não inclui Multi-AZ. O
  código já suporta o parâmetro (`var.multi_az` em `modules/database`); basta
  ativá-lo numa conta paga para obter failover automático da base de dados com
  RPO ≈ 0.
- **Sem Global Accelerator:** era a escolha inicial para o failover, mas a conta
  Free Tier devolve `SubscriptionRequiredException`. Foi substituído por
  **Route 53 com health checks**, que cumpre o mesmo objetivo.
- **Zona DNS placeholder:** não há domínio registado, pelo que a hosted zone é
  consultada diretamente pelos seus nameservers (ou por `route53
  test-dns-answer`) na demonstração. Com um domínio real, a resolução seria
  pública e transparente para os clientes.

### Aplicação e infraestrutura

- **Uma instância EC2 por região:** não há Auto Scaling nem balanceamento de
  carga dentro de cada região; a redundância é entre regiões.
- **Sem monitorização centralizada:** os logs ficam nas EC2 (via `docker logs`),
  sem agregação em CloudWatch nem alarmes.
- **Permissões do role de CI largas:** o role do GitHub Actions usa políticas
  *FullAccess* por simplicidade; em produção seriam restringidas às ações exatas.
  (As permissões da **aplicação** já seguem o menor privilégio — ver
  [`security.md`](security.md).)
- **Esquema da BD criado em runtime:** usa-se `create_all` em vez de migrações
  versionadas (ex: Alembic).
- **Mecanismos de deploy diferentes por ambiente:** o primário é configurado por
  **Ansible** (SSH) e o standby por **`user_data`** (auto-provisionamento). Foi
  uma decisão deliberada para o standby não depender de chaves SSH na segunda
  região, mas significa dois caminhos de configuração a manter.

## Melhorias futuras

| Área | Melhoria |
|------|----------|
| **Disaster Recovery** | **Read replica cross-region + promoção automática no drill (RPO de segundos)** |
| Base de dados | RDS Multi-AZ (conta paga) e read replicas de leitura |
| Disponibilidade | Auto Scaling Group + Application Load Balancer por região |
| Observabilidade | CloudWatch Logs, métricas e alarmes; tracing (X-Ray) |
| Rede | Domínio registado para resolução DNS pública; VPC Endpoints para a SQS |
| Containers | Migração de EC2 para ECS/Fargate |
| Migrações | Gestão de esquema com Alembic |
| IAM | Política do role de CI restringida ao menor privilégio |

## Já implementado (não são limitações)

Para evitar confusão, estes pontos **estão feitos**:

- ✅ **Standby multi-região** provisionado pelo mesmo módulo Terraform
- ✅ **Failover automático** por health checks do Route 53 (RTO medido: ~38 s)
- ✅ **Secrets no SSM Parameter Store** (`SecureString`) nas **duas** regiões,
  lidos pela EC2 via Instance Profile — a password nunca passa pelo pipeline
- ✅ **Aprovação manual** (*environment approval*) antes do `terraform apply`
- ✅ **Autenticação OIDC**, sem access keys de longa duração

## Nota sobre custos

A infraestrutura usa recursos elegíveis para o **AWS Free Tier** (EC2 `t3.micro`,
RDS `db.t3.micro`, SQS). O padrão **warm standby** duplica o compute e a base de
dados, pelo que deve correr-se `terraform destroy` após a demonstração para
evitar custos de recursos deixados ativos.
