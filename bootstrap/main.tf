# ===========================================================================
# BOOTSTRAP — corre UMA vez, manualmente, com as tuas credenciais AWS.
# Cria:
#   1. Bucket S3 + tabela DynamoDB para o remote state do Terraform principal.
#   2. OIDC provider do GitHub + IAM Role que o GitHub Actions assume
#      (sem access keys estáticas).
# ===========================================================================

# ---------------------------------------------------------------------------
# 1. Remote state backend
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ---------------------------------------------------------------------------
# 2. OIDC provider do GitHub + Role para o GitHub Actions
# ---------------------------------------------------------------------------
# NOTA: se a conta já tiver um OIDC provider do GitHub, importa-o com
# `terraform import` em vez de criar um novo (só pode existir um por URL).
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Só permite a este repositório assumir o role (qualquer branch/PR).
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "sinuvem-eventos-gha-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# Permissões para o CI gerir a infraestrutura via Terraform.
# (Largo por simplicidade académica; em produção restringir-se-ia mais.)
resource "aws_iam_role_policy_attachment" "gha" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
  ])
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
