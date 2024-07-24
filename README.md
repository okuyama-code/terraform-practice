## 参考本
実践Terraform　AWSにおけるシステム設計とベストプラクティス
完成コード
https://github.com/tmknom/example-pragmatic-terraform/tree/main


ハンズオン 54
流し見 76

## 今回作るAWS アーキテクチャー図
<img width="349" alt="tf-book" src="https://github.com/user-attachments/assets/02bc29b0-f229-43d5-bd8c-1a2a24f086cf">

README.mdに画像を表示させる方法
https://qiita.com/r_midori/items/2c4feb5de05535441bc8

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
設定を永続的にするため、　~/.zshrcに記載する
```
export AWS_PROFILE=tf
```
環境変数AWS_PROFILEの設定を確認する方法
```
echo $AWS_PROFILE
```

### 余談　
export: これはシェル（bash, zsh など）のビルトインコマンドで、環境変数を設定し、その変数をそのシェルから起動されるすべてのプロセスで利用可能にします。
このコマンドを実行すると、現在のシェルセッションとそこから起動されるすべてのプロセス（AWS CLI を含む）で、AWS_PROFILE 変数が "tf" に設定されます。
このコマンドを実行したターミナルウィンドウ（シェルセッション）でのみ有効です。

echo: これはテキストを標準出力に表示するコマンドです。
$AWS_PROFILE: $ 記号は、シェルに対してこれが変数名であることを示します。シェルは $AWS_PROFILE を変数の値で置き換えます。


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

## ファイルレイアウト
第5章から第16で登場するサンプルコードは、基本的に同一ディレクトリ内での実装できる。
├── は、これがリストの最初または中間の項目であることを示しています。
└── はこれがリストの最後の項目であることを示しています。

```
└── main.tf
```

あるいは、次のように複数ファイルへ分割することもできる。
Terraformは拡張子(tf)のファイルを自動的に読み込むため、単一ファイルと同様に動作します。
network.tf: VPC、サブネット、セキュリティグループなどのネットワークインフラ
lb.tf: Application Load BalancerやNetwork Load Balancerの設定
ecs.tf: ECSクラスター、タスク定義、サービスなどのコンテナ関連の設定
```
├── network.tf
├── lb.tf
└── ecs.tf
```

例外はモジュールで「5.2.4 IAM ロールのモジュール化」や「7.4.2 セキュリティグループのモジュール化」では、サブディレクトリは以下にコードを実装します。

```
├── iam_role/
  └── main.tf
├── security_group/
  └── main.tf
└── main.tf
```