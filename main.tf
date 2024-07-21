module "web_server" {
  source = "./http_server"
  instance_type = "t3.micro"
}

provider "aws" {
  region = "ap-northeast-1"
}

output "public_dns" {
  value = module.web_server.public_dns
}