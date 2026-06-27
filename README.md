# my-microservice-project

Навчальний DevOps-проєкт: інфраструктура для додатка в AWS, описана через
Terraform за модульним підходом. Конфігурація створює бекенд для зберігання стану
Terraform (S3 + DynamoDB), мережу (VPC з підмережами) та реєстр Docker-образів (ECR).

## Передумови

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- AWS CLI з налаштованими креденшіалами:
  ```bash
  aws configure
  aws sts get-caller-identity   # перевірка, що креди працюють
  ```
- Регіон за замовчуванням — `us-east-1` (заданий у `providers.tf`).

## Команди для ініціалізації та запуску

```bash
# 1. Ініціалізація — завантажує провайдери та модулі, налаштовує бекенд
terraform init

# 2. План — показує, які ресурси буде створено/змінено/видалено (без застосування)
terraform plan

# 3. Застосування — створює інфраструктуру в AWS (запитає підтвердження)
terraform apply

# 4. Видалення — знищує всі створені ресурси (запитає підтвердження)
terraform destroy
```

Корисні outputs після `apply`:

```bash
terraform output                      # усі значення
terraform output ecr_repository_url   # URL ECR-репозиторію для docker push
```

## Опис модулів

### `s3-backend`

Створює інфраструктуру для зберігання **стану Terraform**:

- **`aws_s3_bucket`** — бакет для файлу стану (`terraform.tfstate`) з увімкненим
  версіонуванням (`aws_s3_bucket_versioning`) та `BucketOwnerEnforced`
  (`aws_s3_bucket_ownership_controls`). Прапор `force_destroy = true` дозволяє
  видалити бакет навіть із вмістом.
- **`aws_dynamodb_table`** — таблиця `terraform-locks` (hash key `LockID`,
  режим `PAY_PER_REQUEST`) для **блокування стану**, щоб двоє людей не змінювали
  його одночасно.

Змінні: `bucket_name`, `table_name`.
Outputs: `s3_bucket_name`, `dynamodb_table_name`.

> ⚠️ **Bootstrap-нюанс.** Ці ресурси і є бекендом, у якому Terraform зберігає свій
> стан. Тому блок `backend "s3"` у `backend.tf` за замовчуванням **закоментований**:
> інакше виникає проблема «курки і яйця» — Terraform намагається використати бакет/таблицю,
> яких ще не існує. Правильний порядок: спершу `apply` з локальним станом створює
> бекенд, потім розкоментовуєте блок і виконуєте `terraform init -migrate-state`.

### `vpc`

Створює **мережеву інфраструктуру**:

- **`aws_vpc`** — VPC із заданим CIDR (`10.0.0.0/16`), увімкненими DNS-підтримкою
  та DNS-іменами хостів.
- **`aws_subnet` (public)** — публічні підмережі з `map_public_ip_on_launch = true`.
- **`aws_subnet` (private)** — приватні підмережі (без авто-призначення публічних IP).
- **`aws_internet_gateway`** — шлюз в інтернет для публічних підмереж.
- **`routes.tf`** — таблиця маршрутів для публічних підмереж із маршрутом
  `0.0.0.0/0 → IGW` та асоціаціями з кожною публічною підмережею.

Змінні: `vpc_cidr_block`, `public_subnets`, `private_subnets`,
`availability_zones`, `vpc_name`.
Outputs: `vpc_id`, `public_subnets`, `private_subnets`, `internet_gateway_id`.

> ℹ️ Значення `availability_zones` мають належати регіону провайдера
> (`us-east-1a/b/c` для `us-east-1`), інакше `apply` впаде на створенні підмереж.

### `ecr`

Створює **реєстр Docker-образів** (Elastic Container Registry):

- **`aws_ecr_repository`** — репозиторій із **автоматичним скануванням образів на
  вразливості** (`image_scanning_configuration { scan_on_push = true }`).
  Прапор `force_delete = true` дозволяє знищити репозиторій разом з образами.
- **`aws_ecr_repository_policy`** — **політика доступу**, що дозволяє IAM-принципалам
  цього AWS-акаунту виконувати pull і push образів.

Змінні: `repository_name`, `scan_on_push` (default `true`),
`image_tag_mutability` (default `MUTABLE`), `force_delete` (default `true`),
`environment`.
Outputs: `repository_url`, `repository_arn`, `repository_name`.

Приклад логіну та пушу образу:

```bash
REPO=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${REPO%/*}"
docker tag my-app:latest "$REPO:latest"
docker push "$REPO:latest"
```

## Вартість ресурсів

Майже всі ресурси проєкту безкоштовні в простої: VPC, підмережі, IGW, маршрути,
порожній ECR-репозиторій, а DynamoDB у режимі `PAY_PER_REQUEST` тарифікується лише
за реальні запити. Платне з'являється тільки за наявності образів у ECR (сховище)
та об'єктів у S3. Після `terraform destroy` витрат не лишається.
