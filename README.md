# 🚀 Django CI/CD Infrastructure on AWS EKS

Повноцінна **CI/CD інфраструктура** для Django застосунку з автоматичним деплоєм в Kubernetes.

## 📊 Що створюється

### Infrastructure (Terraform)
- **VPC** — мережа з 3 AZs (public + private subnets)
- **EKS** — Kubernetes cluster з 2 nodes
- **ECR** — Docker registry з шифруванням
- **S3 + DynamoDB** — Terraform state backend

### CI/CD Pipeline
- **Jenkins** — CI з Kubernetes agents (Kaniko + Git)
- **ArgoCD** — GitOps CD з auto-sync
- **Kaniko** — Rootless Docker builds в Kubernetes
- **LoadBalancer** — AWS ELB для зовнішнього доступу

### Application
- **Django** — Web application з Gunicorn
- **Helm Chart** — Kubernetes deployment config
- **Auto-scaling** — HPA (2-6 pods, CPU 70%)

---

## 🏗️ Архітектура

```
┌─────────────────────────────────────────────────────────────┐
│                      CI/CD Flow                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Developer                                                   │
│      ↓                                                       │
│  Git Push → GitHub                                           │
│      ↓                                                       │
│  Jenkins Pipeline (Kubernetes Pod)                           │
│      ├─ Kaniko container: Build Docker image                │
│      ├─ Push to ECR: my-app:BUILD_NUMBER                    │
│      └─ Git container: Update values.yaml → Push            │
│      ↓                                                       │
│  GitHub (updated values.yaml)                                │
│      ↓                                                       │
│  ArgoCD (auto-sync ~3 min)                                   │
│      ├─ Detect Git changes                                   │
│      ├─ Sync Helm chart                                      │
│      └─ Rolling update pods                                  │
│      ↓                                                       │
│  Kubernetes                                                  │
│      └─ Django pods (2) + LoadBalancer                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Структура проєкту

```
my-microservice-project/
├── main.tf                   # Root Terraform config
├── providers.tf              # AWS, Kubernetes, Helm providers
├── variables.tf              # Environment variable
├── outputs.tf                # Infrastructure outputs
├── backend.tf                # S3 backend (commented for bootstrap)
│
├── modules/
│   ├── s3-backend/           # S3 + DynamoDB for Terraform state
│   ├── vpc/                  # VPC, subnets, IGW, NAT
│   ├── ecr/                  # Docker registry
│   ├── eks/                  # Kubernetes cluster + EBS CSI driver
│   ├── jenkins/              # Jenkins Helm deployment
│   │   ├── jenkins.tf        # Helm release
│   │   ├── values.yaml       # Jenkins config (Kaniko agents)
│   │   └── variables.tf      # Module variables
│   └── argo_cd/              # ArgoCD Helm deployment
│       ├── argo_cd.tf        # Helm release
│       ├── values.yaml       # ArgoCD config
│       └── charts/           # ArgoCD Application chart
│           ├── Chart.yaml
│           ├── values.yaml   # Application definition
│           └── templates/
│               └── application.yaml
│
├── django/                   # Django application
│   ├── Dockerfile            # Multi-stage build
│   ├── requirements.txt
│   ├── manage.py
│   └── docker_project/
│       └── settings.py       # Reads from os.environ
│
├── helm/django-app/          # Helm chart for Django
│   ├── Chart.yaml
│   ├── values.yaml           # Updated by Jenkins Pipeline
│   └── templates/
│       ├── deployment.yaml   # Pods config
│       ├── service.yaml      # LoadBalancer
│       ├── configmap.yaml    # Non-sensitive env vars
│       ├── secret.yaml       # Sensitive env vars
│       └── hpa.yaml          # Auto-scaling
│
├── Jenkinsfile               # CI Pipeline definition
├── DEPLOYMENT_GUIDE.md       # Detailed setup instructions
├── SECRETS_MANAGEMENT.md     # Security best practices
└── README.md                 # This file
```

---

## 🎯 Передумови

### Required:
- **Terraform** >= 1.5
- **AWS CLI** налаштований: `aws configure`
- **kubectl** для Kubernetes
- **Git** для version control

### Optional (for manual testing):
- **Docker** для локальної розробки
- **Helm** для ручного deploy
- **GitHub Personal Access Token** для Jenkins

---

## 🚀 Quick Start

### 1️⃣ Підготовка

```bash
# Clone repository
git clone https://github.com/VladSmorodsky/my-microservice-project
cd my-microservice-project

# Configure AWS credentials
aws configure
aws sts get-caller-identity  # Verify
```

### 2️⃣ Bootstrap S3 Backend

```bash
# Backend is commented by default (chicken-egg problem)
# Initialize with local state
terraform init

# Create S3 backend resources only
terraform apply -target=module.s3_backend

# Uncomment backend.tf
# sed -i '' 's/^# //g' backend.tf  # macOS
# OR manually uncomment lines in backend.tf

# Migrate state to S3
terraform init -migrate-state
```

### 3️⃣ Deploy Infrastructure

```bash
# Review plan
terraform plan

# Deploy (15-20 min)
terraform apply

# Save outputs
terraform output > outputs.txt
```

**What gets created:**
- VPC with 6 subnets across 3 AZs
- EKS cluster (my-eks) with 2 t3.medium nodes
- ECR repository (my-app)
- Jenkins with Kaniko agents
- ArgoCD with auto-sync enabled

### 4️⃣ Configure kubectl

```bash
# Connect to EKS
aws eks update-kubeconfig --region us-east-1 --name my-eks

# Verify
kubectl get nodes
kubectl get pods --all-namespaces
```

### 5️⃣ Create ECR Credentials Secret

```bash
# Jenkins needs this to push images to ECR
./create-ecr-secret.sh

# OR manually:
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION})

kubectl create secret docker-registry aws-ecr-credentials \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com \
  --docker-username=AWS \
  --docker-password=${ECR_PASSWORD} \
  --namespace=jenkins
```

### 6️⃣ Access Jenkins

```bash
# Port-forward (in separate terminal)
kubectl port-forward -n jenkins svc/jenkins 8080:80

# Get admin password
terraform output -raw jenkins_admin_password

# Open browser
open http://localhost:8080
```

**Login:**
- Username: `admin`
- Password: (from terraform output)

### 7️⃣ Configure Jenkins Pipeline

**Add GitHub Credentials:**
1. Jenkins → Manage Jenkins → Credentials
2. Add: Username with password
   - Username: Your GitHub username
   - Password: [GitHub Personal Access Token](https://github.com/settings/tokens)
   - ID: `github-credentials` (exactly!)
   - Scopes needed: `repo`, `admin:repo_hook`

**Create Pipeline Job:**
1. New Item → `django-app-pipeline` → Pipeline
2. Build Triggers: ✅ GitHub hook trigger
3. Pipeline:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository: `https://github.com/VladSmorodsky/my-microservice-project`
   - Credentials: `github-credentials`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. Save

### 8️⃣ Access ArgoCD

```bash
# Port-forward (in separate terminal)
kubectl port-forward -n argocd svc/argocd-server 8081:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Open browser
open http://localhost:8081
```

**Login:**
- Username: `admin`
- Password: (from command above)

### 9️⃣ Test CI/CD Pipeline

```bash
# Trigger pipeline by pushing to main
echo "test" >> README.md
git add README.md
git commit -m "test: trigger CI/CD"
git push origin main

# Jenkins automatically:
# 1. Builds Docker image
# 2. Pushes to ECR with tag BUILD_NUMBER
# 3. Updates helm/django-app/values.yaml
# 4. Commits and pushes to Git

# ArgoCD automatically (~3 min):
# 1. Detects Git changes
# 2. Syncs Helm chart
# 3. Deploys to Kubernetes
```

### 🔟 Access Application

```bash
# Get LoadBalancer URL
kubectl get svc -n default django-app-django-app

# OR
terraform output
```

**Open:** `http://<EXTERNAL-IP>`

> ⚠️ App returns HTTP 500 (no database configured), but CI/CD pipeline works!

---

## ✅ Як застосувати та перевірити CI/CD

Цей розділ описує повний цикл: **Terraform → Jenkins → Argo CD**.

### 1. Як застосувати Terraform

```bash
# 1. Ініціалізація (провайдери + backend)
terraform init

# 2. (перший запуск) Bootstrap S3 backend
terraform apply -target=module.s3_backend
# розкоментувати backend.tf, потім:
terraform init -migrate-state

# 3. Переглянути, що буде створено
terraform plan

# 4. Застосувати всю інфраструктуру (VPC, EKS, ECR, Jenkins, Argo CD) — 15-20 хв
terraform apply        # підтвердити: yes

# 5. Зберегти та переглянути outputs
terraform output
```

**Перевірка, що Terraform відпрацював успішно:**

```bash
# Підключитись до створеного EKS-кластера
aws eks update-kubeconfig --region us-east-1 --name my-eks

# Ноди мають бути у стані Ready
kubectl get nodes

# Jenkins та Argo CD мають бути Running
kubectl get pods -n jenkins
kubectl get pods -n argocd
```

Очікуваний результат: `terraform apply` завершується без помилок (`Apply complete!`), ноди у статусі `Ready`, поди Jenkins і Argo CD — `Running`.

---

### 2. Як перевірити Jenkins job

```bash
# Відкрити доступ до Jenkins UI
kubectl port-forward -n jenkins svc/jenkins 8080:80

# Пароль адміністратора
terraform output -raw jenkins_admin_password

# Браузер: http://localhost:8080  (логін: admin)
```

**Запуск та перевірка job `django-app-pipeline`:**

1. Зробити `git push` у гілку `main` (або натиснути **Build Now** у джобі).
2. У Jenkins UI відкрити **django-app-pipeline → останній білд**.
3. Перевірити **Stage View** — усі 3 стадії мають бути зелені:
   - **Checkout Source** — клонування репозиторію
   - **Build Docker Image** — Kaniko збирає образ і пушить у ECR (`my-app:BUILD_NUMBER` + `latest`)
   - **Update Helm Values** — оновлює `helm/django-app/values.yaml` і робить commit у `main`
4. Відкрити **Console Output** — наприкінці має бути банер `PIPELINE COMPLETED SUCCESSFULLY! ✅`.

**Перевірка результату job через CLI:**

```bash
# Новий образ з тегом = номер білда з'явився в ECR
aws ecr describe-images --repository-name my-app --region us-east-1 \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags'

# Jenkins зробив автоматичний commit "ci: update my-app image tag ..."
git log --oneline -5
```

Очікуваний результат: білд зелений, у ECR новий тег, у git — автоматичний commit від `Jenkins CI` з новим тегом у `values.yaml`.

---

### 3. Як побачити результат в Argo CD

```bash
# Відкрити доступ до Argo CD UI
kubectl port-forward -n argocd svc/argocd-server 8081:80

# Пароль адміністратора
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Браузер: http://localhost:8081  (логін: admin)
```

**Перевірка синхронізації застосунку `django-app`:**

1. В Argo CD UI відкрити застосунок **django-app**.
2. Після commit від Jenkins (авто-sync ~3 хв) статуси мають стати:
   - **Sync Status: `Synced`** — Git = кластер
   - **Health Status: `Healthy`** — поди піднялись
3. На діаграмі ресурсів видно нову ревізію Deployment з оновленим тегом образу.
4. Кнопка **Refresh** / **Sync** — щоб синхронізувати вручну, не чекаючи 3 хв.

**Перевірка через CLI:**

```bash
# Статус застосунку в Argo CD
kubectl get application django-app -n argocd

# Поди перерозгорнулись з новим образом
kubectl get pods -n default
kubectl get deployment django-app-django-app -n default \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Примусовий hard-refresh, якщо sync не відбувся
kubectl patch application django-app -n argocd --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

Очікуваний результат: застосунок `django-app` у стані `Synced` + `Healthy`, поди у `default` перезапущені з образом, тег якого збігається з номером білда Jenkins.

**Доступ до самого застосунку:**

```bash
kubectl get svc -n default django-app-django-app   # взяти EXTERNAL-IP (LoadBalancer)
```
> ⚠️ Застосунок повертає HTTP 500 (БД не налаштована), але це підтверджує, що CI/CD-ланцюг Terraform → Jenkins → Argo CD відпрацював повністю.

---

## 🔐 Secrets Management

**Current state:** Demo secrets in `values.yaml` (⚠️ NOT secure for production)

**For production, use:**
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [External Secrets Operator](https://external-secrets.io/)
- AWS Secrets Manager
- HashiCorp Vault

See [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md) for details.

---

## 📊 Pipeline Details

### Jenkinsfile Stages

**Stage 1: Checkout Source** (~10s)
- Clones Git repository

**Stage 2: Build Docker Image** (~2-5 min)
- Runs in Kaniko container (rootless)
- Builds from `django/Dockerfile`
- Pushes to ECR with tags: `BUILD_NUMBER` and `latest`

**Stage 3: Update Helm Values** (~10s)
- Runs in Git container
- Clones repository
- Updates `helm/django-app/values.yaml` with new image tag
- Commits and pushes to `main` branch

### ArgoCD Application

**Configuration:**
- Repository: `https://github.com/VladSmorodsky/my-microservice-project`
- Path: `helm/django-app`
- Branch: `main`
- Sync Policy: Automated
  - Prune: true
  - Self-heal: true

---

## 🛠️ Troubleshooting

### Jenkins not responding

```bash
# Restart port-forward
pkill -f "port-forward.*jenkins"
kubectl port-forward -n jenkins svc/jenkins 8080:80
```

### Pipeline fails on ECR push

```bash
# ECR token expires every 12 hours
# Recreate secret
./create-ecr-secret.sh
```

### ArgoCD not syncing

```bash
# Check application status
kubectl get application django-app -n argocd

# Force sync
kubectl patch application django-app -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Pods in CrashLoopBackOff

```bash
# Check logs
kubectl logs -n default <pod-name>

# Check events
kubectl describe pod -n default <pod-name>

# Common issue: missing database
# Django needs PostgreSQL or use SQLite for demo
```

### Image pull errors

```bash
# Create ECR secret in default namespace
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=default
```

---

## 🧹 Cleanup

```bash
# 1. Delete Helm releases first
helm uninstall django-app

# 2. Wait for LoadBalancer to be deleted
kubectl get svc --all-namespaces | grep LoadBalancer

# 3. Destroy infrastructure
terraform destroy

# Confirm: yes
```

**Order matters!** Helm creates LoadBalancer (not Terraform), so delete it first.

---

## 📚 Additional Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Detailed step-by-step guide
- [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md) - Security best practices
- [JENKINS_ARGOCD_SETUP.md](JENKINS_ARGOCD_SETUP.md) - CI/CD configuration details

---
