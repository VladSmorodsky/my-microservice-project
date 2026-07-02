# my-microservice-project

Навчальний DevOps-проєкт: повний цикл розгортання Django-застосунку в AWS.
Інфраструктура описана через **Terraform** (модульний підхід), а сам застосунок
розгортається в **Kubernetes (EKS)** через **Helm**.

Що створюється:

- **S3 + DynamoDB** — бекенд для стану Terraform і блокування;
- **VPC** — мережа з публічними/приватними підмережами та Internet Gateway;
- **ECR** — реєстр Docker-образів зі скануванням і шифруванням;
- **EKS** — кластер Kubernetes у цьому VPC з керованою групою вузлів;
- **Helm-чарт** — Deployment + Service (LoadBalancer) + HPA + ConfigMap + Secret для Django.

## Структура проєкту

```
my-microservice-project/
├── backend.tf            # Remote S3-бекенд (за замовчуванням ВИМКНЕНИЙ/закоментований)
├── providers.tf          # Провайдер AWS (us-east-1), pin версії (~> 6.0)
├── variables.tf          # Коренева змінна environment (єдине джерело правди)
├── main.tf               # Підключає модулі s3-backend, vpc, ecr, eks
├── outputs.tf            # Зведені outputs
├── django/               # Django-застосунок із теми 4 (Dockerfile, код)
├── modules/
│   ├── s3-backend/       # S3-бакет + DynamoDB для стану/локів Terraform
│   ├── vpc/              # VPC, public/private підмережі, IGW, маршрути
│   ├── ecr/              # ECR-репозиторій (scan + encryption + policy)
│   └── eks/              # EKS-кластер + IAM-ролі + node group
└── helm/django-app/      # Helm-чарт застосунку Django
```

## Передумови

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- AWS CLI з налаштованими креденшіалами: `aws configure` → `aws sts get-caller-identity`
- `kubectl`, `helm`, `docker` (для деплою застосунку)
- Регіон за замовчуванням — `us-east-1` (у `providers.tf`).

## Конфігурація середовища

Тег середовища задається **в одному місці** — кореневий [variables.tf](variables.tf):

```hcl
variable "environment" {
  default = "lesson-7"
}
```

Значення пробрасується в усі модулі (`s3-backend`, `ecr`, `eks`). Щоб змінити —
правте лише цей файл або `terraform apply -var="environment=lesson-8"`.

## Команди Terraform

```bash
terraform init       # завантажує провайдери/модулі, налаштовує бекенд
terraform plan       # показує план змін без застосування
terraform apply      # створює інфраструктуру (підтвердження: yes)
terraform destroy    # знищує всі ресурси (підтвердження: yes)
```

Корисні outputs:

```bash
terraform output ecr_repository_url       # URL ECR для docker push
terraform output eks_kubeconfig_command   # команда налаштування kubectl
```

## Опис модулів

### `s3-backend`

Інфраструктура для зберігання **стану Terraform**:

- **`aws_s3_bucket`** — бакет стану з версіонуванням, `BucketOwnerEnforced`,
  **шифруванням SSE (AES256)** та **блокуванням публічного доступу**
  (`aws_s3_bucket_public_access_block`, усі 4 прапори). `force_destroy = true`.
- **`aws_dynamodb_table`** — `terraform-locks` (`LockID`, `PAY_PER_REQUEST`) для блокування стану.

Змінні: `bucket_name`, `table_name`, `environment`.
Outputs: `s3_bucket_name`, `dynamodb_table_name`.

> ⚠️ **Bootstrap-нюанс.** Ці ресурси і є бекендом, у якому Terraform зберігає свій
> стан, тому блок `backend "s3"` у `backend.tf` за замовчуванням **закоментований**
> (проблема «курки і яйця»). Порядок: спершу `apply` з локальним станом створює
> бекенд → розкоментовуєте блок → `terraform init -migrate-state`.
> **Перед `destroy`** робіть зворотне (мігруйте стейт у локальний), інакше знищення
> бакета/таблиці зламає збереження стану.

### `vpc`

- **`aws_vpc`** — CIDR `10.0.0.0/16`, DNS-підтримка та DNS-імена.
- **`aws_subnet`** — 3 публічні (`map_public_ip_on_launch = true`) і 3 приватні підмережі.
- **`aws_internet_gateway`** + таблиця маршрутів (`0.0.0.0/0 → IGW`) для публічних підмереж.
- **`aws_nat_gateway`** + EIP (`nat.tf`) — вихідний інтернет для **приватних** підмереж
  (`0.0.0.0/0 → NAT`); один NAT для економії. Вимикається змінною `enable_nat_gateway = false`.

Змінні: `vpc_cidr_block`, `public_subnets`, `private_subnets`, `availability_zones`, `vpc_name`, `enable_nat_gateway`.
Outputs: `vpc_id`, `public_subnets`, `private_subnets`, `internet_gateway_id`, `nat_gateway_id`.

> ℹ️ `availability_zones` мають належати регіону провайдера (`us-east-1a/b/c`).

### `ecr`

- **`aws_ecr_repository`** — сканування образів (`scan_on_push = true`),
  **шифрування at-rest (AES256)**, `force_delete = true`.
- **`aws_ecr_repository_policy`** — доступ pull/push для IAM-принципалів акаунту.

Змінні: `repository_name`, `scan_on_push`, `image_tag_mutability` (default `MUTABLE`),
`force_delete`, `environment`.
Outputs: `repository_url`, `repository_arn`, `repository_name`.

### `eks`

Кластер Kubernetes **у вже існуючому VPC**:

- **IAM-ролі** для control plane (`AmazonEKSClusterPolicy`) та вузлів
  (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`).
- **`aws_eks_cluster`** — control plane у підмережах VPC; `bootstrap_cluster_creator_admin_permissions = true`
  дає творцю кластера admin-доступ (kubectl працює одразу).
- **`aws_eks_node_group`** — керована група вузлів у **приватних** підмережах
  (без публічних IP; вихідний інтернет — через NAT Gateway у VPC-модулі).

Змінні: `cluster_name`, `kubernetes_version` (default `null` → версія AWS),
`subnet_ids`, `node_subnet_ids`, `node_instance_types`, `desired_size`/`min_size`/`max_size`, `environment`.
Outputs: `cluster_name`, `cluster_endpoint`, `cluster_certificate_authority`,
`cluster_security_group_id`, `kubeconfig_command`.

## Збірка та публікація образу в ECR

```bash
REGION=us-east-1
REPO=$(terraform output -raw ecr_repository_url)

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "${REPO%/*}"
docker build --platform linux/amd64 -t my-app:latest ./django   # amd64 обов'язково для вузлів EKS!
docker tag my-app:latest "$REPO:latest"
docker push "$REPO:latest"
```

## Розгортання застосунку (Helm)

Чарт [helm/django-app](helm/django-app) реалізує:

- **Deployment** — образ Django з ECR, env через `envFrom` (ConfigMap + Secret),
  **liveness/readiness проби** (HTTP `GET /`, порт 8000);
- **Service** типу `LoadBalancer` — зовнішній доступ (ELB, порт 80 → 8000);
- **HPA** — масштабування подів **2 → 6** при CPU **> 70%**;
- **ConfigMap** — несекретні env-змінні (`DEBUG`, `ALLOWED_HOSTS`, `DATABASE_*`);
- **Secret** — чутливі змінні (`SECRET_KEY`, `DATABASE_PASSWORD`).

```bash
# 1. Налаштувати kubectl на кластер
aws eks update-kubeconfig --region us-east-1 --name my-eks
kubectl get nodes

# 2. metrics-server (потрібен для HPA — на EKS не встановлений за замовчуванням)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3. Деплой (секрети передаються ззовні, НЕ комітяться)
helm install django-app helm/django-app \
  --set secrets.SECRET_KEY="$SECRET_KEY" \
  --set secrets.DATABASE_PASSWORD="$DATABASE_PASSWORD"

# 4. Дочекатись зовнішньої адреси LoadBalancer
kubectl get svc django-app-django-app -w
```

> 🔐 **Секрети.** Значення `SECRET_KEY`/`DATABASE_PASSWORD` не зберігаються у `values.yaml`.
> Передавайте їх через `--set` або git-ignored файл `-f secrets.values.yaml`.

## Порядок вимкнення (важливо!)

```bash
# 1. Прибрати застосунок і ELB (поки кластер живий)
helm uninstall django-app
aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[].LoadBalancerName'  # має бути порожньо

# 2. Якщо бекенд був на S3 — мігрувати стейт у локальний, поки бакет існує
#    (закоментувати backend "s3" → terraform init -migrate-state)

# 3. Знищити інфраструктуру
terraform destroy
```

> ⚠️ Спершу `helm uninstall` — інакше залишковий ELB (створений Kubernetes, а не Terraform)
> заблокує видалення VPC і `terraform destroy` зависне.

## Вартість

Безкоштовні в простої: VPC, підмережі, IGW, маршрути, порожній ECR, DynamoDB (`PAY_PER_REQUEST`).

**Платні** (вмикаються разом з EKS-частиною):

| Ресурс | Орієнтовно |
|--------|-----------|
| EKS control plane | ~$0.10/год (~$73/міс) |
| Вузли (2× t3.medium) | ~$60/міс |
| LoadBalancer (ELB) | ~$18/міс + трафік |
| NAT Gateway | ~$32/міс + плата за трафік |

Тому після експериментів обов'язково робіть `terraform destroy` (та `helm uninstall` перед ним).
NAT Gateway можна вимкнути окремо (`enable_nat_gateway = false`), але тоді вузли в приватних
підмережах втратять вихід в інтернет — тож вимикайте лише разом з усім кластером.
