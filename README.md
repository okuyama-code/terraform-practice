## 参考記事
https://qiita.com/keke21/items/6daaa8a5b9b360ad2369

## terraform コマンド
```
terraform init
```

コード整形
```
terraform fmt
```

planは実際の変更を行わず、何が作成されるかをプレビューするものです。
```
terraform plan
```
Terraform の設定ファイル（通常は .tf 拡張子を持つファイル）に定義されたインフラストラクチャの変更を実際に適用するコマンドです。つまり、このコマンドを実行することで、クラウド環境（この場合はAWS）に実際にリソースを作成、更新、または削除します。
```
terraform apply
```
```
terraform apply -auto-approve
```
Terraform で管理されているインフラストラクチャリソースを安全かつ体系的に削除するために使用されます。
```
terraform destroy
```
確認プロンプトをスキップし、自動的に削除を実行します。
```
terraform destroy -auto-approve
```

コマンド一覧
```
terraform --help
```

### モジュールを利用する場合
applyモジュールを利用する側のディレクトリで実行する
モジュールを取得するための事前準備あり。
```
terraform get
terraform init
```

## aws コマンド
アクセスキーなどの設定
```
aws configure
```

設定確認
```
aws configure list
```



## AWS 用語
### インスタンス
クラウドとは、データをインターネット上に保管する考え方のこと
https://www.skygroup.jp/media/article/2160/

### Amazon Machine Image (AMI)
インスタンスの基本となるOSとソフトウェアを含みます。


## 新しく作る場合
```
rm -rf .terraform
```