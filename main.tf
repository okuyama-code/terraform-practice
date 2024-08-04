provider "aws" {
  region = "ap-northeast-1"
}

# CHAPTER --------------第5章 権限管理 p33 --------------------------------------

module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}


# = IAMポリシー IAMロール
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

# END --------------第5章 権限管理 p63 --------------------------------------


# CHAPTER ---------------- 第6章 ストレージ p64 --------------
# = S3 プライベートバケット パブリックバケット ログバケット
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
  bucket        = "force-destroy-pragmatic-terraform-${random_string.bucket_suffix.result}"
  force_destroy = true
}

# ランダムな文字列を生成（バケット名の一意性のため）
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# END ---------------- 第6章 ストレージ p69 --------------

# CHAPTER --------------------------------- 第7章 ネットワーク p71 --------------------------------------
# = VPC  subnet インターネットゲートウェイ ルート ルートテーブル パブリックネットワーク プライベートネットワーク NATゲートウェイ マルチAZ
# VPC (Virtual Private Cloud) (仮想ネットワーク)
resource "aws_vpc" "example" {
  # VPCのIPv4アドレスの範囲
  # CIDR (Classless Inter-Domain Routing) ブロック
  # CIDR ブロックを指定することで、VPC 内で使用可能な IP アドレスの範囲を定義します
  cidr_block = "10.0.0.0/16"
  # 名前解決を有効にする
  # 名前解決とは、人間にとって覚えやすいドメイン名（例：www.example.com）をコンピューターが理解できるIPアドレス（例：192.0.2.1）に変換するプロセスです。
  enable_dns_support = true
  # これにより、VPC内のEC2インスタンスにパブリックDNSホスト名が自動的に割り当てられます。
  # パブリックIPアドレスを持つインスタンスに対して、自動的にDNSホスト名が生成されます。
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }

  # これらの設定を有効にすることで、VPC内のリソースがより簡単に他のAWSサービスや外部リソースと通信できるようになり、ネットワーク管理が容易になります。
}

# バブリックサブネットの定義
# パブリックサブネットのマルチAZ化
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

# VPCがインターネットと通信できるようにするには、インターネットゲートウェイとルートテーブルが必要。
# VPCは隔離されたネットワークなので単体ではインターネットと接続できない。

# インターネットゲートウェイの定義
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# ルートテーブルの定義
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

# ルートを定義
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  gateway_id     = aws_internet_gateway.example.id
  # キャッチオールルート。他のより具体的なルートに一致しないすべてのトラフィックを処理します。
  destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルの関連付け
# これを忘れるとデフォルトルートテーブルが自動的に使われてしまう。
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#* プライベートネットワーク
# インターネットから隔離されたネットワークです。データベースサーバーのような、インターネットからアクセスできないリソースを配置する。

# プライベートサブネットの定義
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#* NATゲートウェイ
# プライベートネットワークからインターネットへアクセスできるようになります。
# EIPの定義
# NATゲートウェイのマルチAZ化
resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

# NATゲートウェイの定義
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]
}

# プライベートのルートの定義
resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.private_1.id
}


# END --------------------------------- 第7章 ネットワーク --------------------------------------
