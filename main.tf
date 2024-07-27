module "describe_regions_for_ec2" {
  source = "./iam_role"
  name = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
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
    effect = "Allow"
    actions = ["ec2:DescribeRegions"] # リージョンの一覧を取得する
    resources = ["*"]
  }
}

# IAMポリシーの定義
resource "aws_iam_policy" "example" {
  name = "example"
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
  role = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

# 外部公開しないプライベートバケットから作成
resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform"

  versioning {
    enabled = true
  }

  # バケット内のデータを自動的に暗号化する設定
  server_side_encryption_configuration {
    rule {
      apply_sever_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# バケットへのパブリックアクセスをブロックする設定
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 外部公開するパブリックバケットの作成
resource "aws_s3_bucket" "public" {
  bucket = "pulic-pragmatic-terraform"
  # アクセスコントロールリスト（ACL）の設定
  # "public-read"は、オブジェクトの読み取りを全員に許可する
  acl = "public-read"

  # 特定のWebサイト（この場合は https://example.com）から安全にアクセスできる公開S3バケットが作成されます。
  # CORS（Cross-Origin Resource Sharing：クロスオリジンリソース共有）
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
resource "aws_s3_buket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}