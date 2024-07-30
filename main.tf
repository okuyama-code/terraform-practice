module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}

provider "aws" {
  region = "ap-northeast-1"  # 東京リージョン。必要に応じて変更してください
}

# ポリシードキュメント (権限)
# これは単なる説明や設計図ではなく、AWS環境で直接機能する実行可能な設定です。このJSONを適切な場所に適用することで、実際のアクセス制御が実装されます。
# 下のaws_iam_policy_documentと同じないようなのでコメントアウト
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": ["ec2:DescribeRegions"],
#       "Resource": ["*"]
#     }
#   ]
# }

# ポリシードキュメントの定義
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"] # リージョンの一覧を取得する
    resources = ["*"]
  }
}

# IAMポリシーの定義
resource "aws_iam_policy" "example" {
  name   = "example"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
}

# AWSのサービスへの権限を付与するために、IAMロールを作成する。
# IAMロールでは、自信をなんのサービスに関連付けるか宣言する必要がある。
# 信頼ポリシーの定義
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      # このIAMロールは『EC2にのみ関連付けできる』
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAMロールの定義
# assume 引き受ける
resource "aws_iam_role" "example" {
  name = "example"
  # ロール信頼ポリシー
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# IAMポリシーのアタッチ
resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

# 外部公開しないプライベートバケットから作成
resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform-${random_string.bucket_suffix.result}"

  versioning {
    enabled = true
  }

  # バケット内のデータを自動的に暗号化する設定
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# バケットへのパブリックアクセスをブロックする設定
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 外部公開するパブリックバケットの作成
resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform-${random_string.bucket_suffix.result}"

  cors_rule {
    # リクエストを許可するオリジン（ドメイン）
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# AWSの各種サービスがログを保持するためのログバケットを作成
# ログバケットの定義
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform-${random_string.bucket_suffix.result}"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

// バケットポリシーを定義
resource "aws_s3_bucket_policy" "alb_log" {
  # ポリシーを適用するバケットのID
  bucket = aws_s3_bucket.alb_log.id
  # ポリシーの内容を指定
  policy = data.aws_iam_policy_document.alb_log.json
}

# IAM ポリシードキュメントの定義
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect = "Allow"
    # S3にオブジェクトを配置する権限を付与
    actions = ["s3:PutObject"]
    # 権限を適用するリソース（S3バケット内のすべてのオブジェクト）
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    # 権限を付与する対象（プリンシパル）
    principals {
      type = "AWS"
      # 特定のAWSアカウントID
      identifiers = ["582318560864"]
    }
  }
}

//S3バケットの強制削除
resource "aws_s3_bucket" "force_destroy" {
  bucket = "force-destroy-pragmatic-terraform-${random_string.bucket_suffix.result}"
  force_destroy = true
}

# ランダムな文字列を生成（バケット名の一意性のため）
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}