provider "aws" {
  region  = "ap-northeast-1"
}

resource "aws_instance" "example" {
  # 2024年7月10日時点での最新Amazon Linux 2 AMI
  ami = "ami-0eda63ec8af4f056e"
  # EC2（Elastic Compute Cloud）インスタンスタイプ
  instance_type = "t3.micro"

  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
  EOF

  tags = {
    Name = "example"
  }
}