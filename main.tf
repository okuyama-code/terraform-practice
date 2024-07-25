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