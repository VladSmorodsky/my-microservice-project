# 🚀 Інструкція з розгортання

## Передумови

✅ **Встановлене ПЗ:**
- AWS CLI (налаштований з credentials)
- Terraform >= 1.5
- kubectl
- git

✅ **AWS ресурси:**
- AWS account з правами для створення EKS, ECR, VPC, IAM
- AWS credentials налаштовані (`aws configure`)

---

## Крок 1: Підготовка параметрів

### 1.1 Перевірити параметри в main.tf

**Jenkins admin password:**
✅ Генерується автоматично через `random_password` resource
- Не потрібно змінювати вручну
- Отримати пароль: `terraform output -raw jenkins_admin_password`

**Опціонально:** Створити `terraform.tfvars` для override:
```bash
cp terraform.tfvars.example terraform.tfvars
# Редагувати при потребі
```

**ArgoCD Helm repository:**
✅ Вже налаштовано на поточний репозиторій
```hcl
helm_repo_url = "https://github.com/VladSmorodsky/my-microservice-project"
```

### 1.2 Перевірити параметри в Jenkinsfile

✅ **Вже налаштовано:**

```groovy
environment {
    AWS_ACCOUNT_ID = '590183992909'  # ← Ваш AWS Account
    HELM_REPO_URL = 'github.com/VladSmorodsky/my-microservice-project'  # ← Цей репо
    VALUES_FILE_PATH = 'helm/django-app/values.yaml'
}
```

**Перевірити AWS Account ID (опціонально):**
```bash
aws sts get-caller-identity --query Account --output text
```

---

## Крок 2: Розгортання інфраструктури через Terraform

### 2.1 Ініціалізація Terraform

```bash
cd /path/to/my-microservice-project

# Ініціалізація
terraform init
```

**Очікуваний результат:**
```
Initializing modules...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 2.2 Перевірка плану

```bash
terraform plan
```

**Перевірте що буде створено:**
- VPC з підмережами
- EKS cluster
- ECR repository
- Jenkins (Helm)
- ArgoCD (Helm)

### 2.3 Застосування конфігурації

```bash
terraform apply -auto-approve
```

**⏱️ Час виконання: ~15-20 хвилин**

**Прогрес:**
```
module.vpc ... Creating...           [✓] ~2 min
module.eks ... Creating...           [✓] ~10-15 min
module.jenkins ... Creating...       [✓] ~2-3 min
module.argo_cd ... Creating...       [✓] ~2-3 min
```

### 2.4 Зберегти outputs

```bash
# Зберегти всі outputs
terraform output > terraform-outputs.txt

# Або отримати конкретні значення
terraform output eks_cluster_name
terraform output jenkins_namespace
terraform output -raw jenkins_admin_password
```

---

## Крок 3: Налаштування kubectl

### 3.1 Підключення до EKS

```bash
# Отримати назву кластера
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Налаштувати kubeconfig
aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME
```

**Перевірка:**
```bash
kubectl get nodes
```

**Очікуваний результат:**
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.ec2.internal    Ready    <none>   5m    v1.28.x
ip-10-0-2-456.ec2.internal    Ready    <none>   5m    v1.28.x
```

### 3.2 Перевірка pods

```bash
# Jenkins
kubectl get pods -n jenkins

# ArgoCD
kubectl get pods -n argocd

# Всі namespaces
kubectl get pods --all-namespaces
```

---

## Крок 4: Створення ECR Repository

```bash
# Отримати AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Створити ECR repository
aws ecr create-repository \
  --repository-name my-app \
  --region us-east-1
```

**Перевірка:**
```bash
aws ecr describe-repositories --repository-names my-app
```

---

## Крок 5: Створення AWS ECR Credentials Secret

### 5.1 Скрипт для створення secret

```bash
#!/bin/bash
# create-ecr-secret.sh

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Creating ECR credentials secret..."
echo "Registry: ${ECR_REGISTRY}"

# Отримати ECR password
ECR_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION})

# Створити auth string
AUTH_STRING=$(echo -n "AWS:${ECR_PASSWORD}" | base64)

# Створити config.json
cat > /tmp/ecr-config.json <<EOF
{
  "auths": {
    "${ECR_REGISTRY}": {
      "auth": "${AUTH_STRING}"
    }
  }
}
EOF

# Створити Kubernetes secret
kubectl create secret generic aws-ecr-credentials \
  --from-file=config.json=/tmp/ecr-config.json \
  --namespace=jenkins \
  --dry-run=client -o yaml | kubectl apply -f -

# Cleanup
rm /tmp/ecr-config.json

echo "✅ Secret created successfully!"
```

### 5.2 Виконати скрипт

```bash
chmod +x create-ecr-secret.sh
./create-ecr-secret.sh
```

**Перевірка:**
```bash
kubectl get secret aws-ecr-credentials -n jenkins
kubectl describe secret aws-ecr-credentials -n jenkins
```

---

## Крок 6: Доступ до Jenkins

### 6.1 Port-forward Jenkins

```bash
# У окремому терміналі
kubectl port-forward -n jenkins svc/jenkins 8080:80
```

### 6.2 Отримати credentials

```bash
# Username (за замовчуванням)
echo "admin"

# Password
terraform output -raw jenkins_admin_password
```

### 6.3 Відкрити Jenkins UI

```bash
open http://localhost:8080
```

**Або в браузері:**
```
http://localhost:8080
```

**Логін:**
- Username: `admin`
- Password: (з terraform output)

---

## Крок 7: Налаштування Jenkins

### 7.1 Додати GitHub Credentials

1. Jenkins → **Manage Jenkins** → **Credentials**
2. **(global)** → **Add Credentials**

**Параметри:**
- Kind: `Username with password`
- Scope: `Global`
- Username: ваш GitHub username
- Password: GitHub Personal Access Token
- ID: `github-credentials` ⚠️ **Важливо!**
- Description: `GitHub PAT for CI/CD`

**Створити GitHub PAT:**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Обрати scopes: `repo`, `admin:repo_hook`

### 7.2 Створити Pipeline Job

1. Jenkins → **New Item**
2. Enter name: `django-app-pipeline`
3. Select: **Pipeline**
4. Click **OK**

**Configuration:**

**General:**
- Description: `Build and deploy Django app`

**Build Triggers:**
- ✅ GitHub hook trigger for GITScm polling

**Pipeline:**
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: URL вашого репозиторію з Jenkinsfile
- Credentials: `github-credentials`
- Branch Specifier: `*/main`
- Script Path: `Jenkinsfile`

5. **Save**

---

## Крок 8: Доступ до ArgoCD

### 8.1 Port-forward ArgoCD

```bash
# У окремому терміналі
kubectl port-forward -n argocd svc/argocd-server 8081:80
```

### 8.2 Отримати admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
```

### 8.3 Відкрити ArgoCD UI

```bash
open http://localhost:8081
```

**Логін:**
- Username: `admin`
- Password: (з команди вище)

### 8.4 Перевірити Applications

**В UI:**
- Applications → `django-app`

**В CLI:**
```bash
kubectl get applications -n argocd
```

---

## Крок 9: Запуск Pipeline

### 9.1 Перший запуск (Manual)

1. Jenkins → `django-app-pipeline`
2. **Build Now**

**Етапи pipeline:**
```
1. Checkout Source      [~10s]
2. Build Docker Image   [~2-5 min]
3. Update Helm Values   [~10s]
```

### 9.2 Моніторинг

**Jenkins Console Output:**
```bash
Jenkins UI → Build #1 → Console Output
```

**Kubernetes pods:**
```bash
# Дивитись pipeline pod
kubectl get pods -n jenkins | grep django-app

# Логи Kaniko
kubectl logs -n jenkins <pod-name> -c kaniko -f
```

### 9.3 Перевірка в ECR

```bash
aws ecr describe-images \
  --repository-name my-app \
  --region us-east-1
```

---

## Крок 10: Перевірка ArgoCD Sync

### 10.1 Автоматична синхронізація

ArgoCD автоматично виявить зміни в Git та застосує їх.

**Моніторинг в UI:**
```
Applications → django-app
- Status: Synced / Healthy
- Last Sync: <timestamp>
```

**В CLI:**
```bash
# Статус application
kubectl get application django-app -n argocd

# Деталі
kubectl describe application django-app -n argocd

# Логи ArgoCD
kubectl logs -n argocd deployment/argocd-application-controller -f
```

### 10.2 Manual Sync (якщо потрібно)

```bash
# Використовуючи argocd CLI
argocd app sync django-app

# Або через kubectl
kubectl patch application django-app -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

---

## Крок 11: Перевірка Deploy

### 11.1 Перевірити pods Django app

```bash
kubectl get pods -n default
kubectl get deployment -n default
kubectl get service -n default
```

### 11.2 Логи application

```bash
# Список pods
kubectl get pods -n default -l app=django-app

# Логи
kubectl logs -n default <pod-name> -f
```

### 11.3 Доступ до application

```bash
# Якщо LoadBalancer
kubectl get svc -n default django-app

# Port-forward для тестування
kubectl port-forward -n default svc/django-app 8082:80

# Відкрити
open http://localhost:8082
```

---

## Troubleshooting

### Jenkins pod не запускається

```bash
# Перевірити статус
kubectl describe pod -n jenkins jenkins-0

# Логи
kubectl logs -n jenkins jenkins-0

# Events
kubectl get events -n jenkins --sort-by='.lastTimestamp'
```

### Pipeline fails на ECR push

**Проблема:** ECR token expired (TTL = 12 годин)

**Рішення:**
```bash
./create-ecr-secret.sh
```

### ArgoCD не синхронізує

```bash
# Перевірити repository connection
kubectl get secret -n argocd | grep repo

# Логи application controller
kubectl logs -n argocd deployment/argocd-application-controller

# Manual sync
kubectl patch application django-app -n argocd \
  --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

### Kaniko build fails

```bash
# Перевірити Dockerfile
cat Dockerfile

# Перевірити ECR credentials
kubectl get secret aws-ecr-credentials -n jenkins -o yaml

# Логи Kaniko
kubectl logs -n jenkins <pipeline-pod> -c kaniko
```

---

## Очищення ресурсів

⚠️ **Увага:** Це видалить всі створені ресурси!

```bash
# Видалити через Terraform
terraform destroy -auto-approve

# Видалити ECR images
aws ecr batch-delete-image \
  --repository-name my-app \
  --image-ids imageTag=latest

# Видалити ECR repository
aws ecr delete-repository \
  --repository-name my-app \
  --force
```

---

## Команди для швидкого доступу

```bash
# Скрипт для швидкого доступу до всіх сервісів
cat > access.sh <<'EOF'
#!/bin/bash

echo "🚀 Quick Access Script"
echo ""
echo "1. Jenkins:  http://localhost:8080"
echo "2. ArgoCD:   http://localhost:8081"
echo "3. Django:   http://localhost:8082"
echo ""
echo "Starting port-forwards..."

kubectl port-forward -n jenkins svc/jenkins 8080:80 &
kubectl port-forward -n argocd svc/argocd-server 8081:80 &
kubectl port-forward -n default svc/django-app 8082:80 &

echo ""
echo "✅ All services are available!"
echo ""
echo "Jenkins credentials:"
echo "  Username: admin"
terraform output -raw jenkins_admin_password | xargs -I {} echo "  Password: {}"

echo ""
echo "ArgoCD credentials:"
echo "  Username: admin"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d | xargs -I {} echo "  Password: {}"

echo ""
echo "Press Ctrl+C to stop all port-forwards"
wait
EOF

chmod +x access.sh
./access.sh
```

---

## Корисні команди

```bash
# Перезапустити Jenkins
kubectl rollout restart statefulset/jenkins -n jenkins

# Перезапустити ArgoCD
kubectl rollout restart deployment/argocd-server -n argocd

# Перезапустити Django app
kubectl rollout restart deployment/django-app -n default

# Подивитись логи всіх pods
kubectl logs -n jenkins --all-containers=true -l app.kubernetes.io/name=jenkins --tail=100

# Видалити pipeline pod
kubectl delete pod -n jenkins <pod-name>

# Форсувати ArgoCD sync
argocd app sync django-app --force

# Отримати kubeconfig
aws eks update-kubeconfig --region us-east-1 --name $(terraform output -raw eks_cluster_name)
```

---

## Структура після розгортання

```
AWS
├── VPC
│   ├── Public Subnets (3 AZs)
│   └── Private Subnets (3 AZs)
├── EKS Cluster
│   ├── Control Plane
│   └── Node Group (2 nodes)
├── ECR Repository (my-app)
└── IAM Roles

Kubernetes
├── namespace: jenkins
│   ├── Jenkins StatefulSet
│   ├── Jenkins Service (LoadBalancer)
│   └── Secret: aws-ecr-credentials
├── namespace: argocd
│   ├── ArgoCD Server
│   ├── ArgoCD Application Controller
│   └── Application: django-app
└── namespace: default
    ├── Django Deployment
    └── Django Service
```

---

## CI/CD Flow (повний цикл)

```
1. Developer → git push
   └─ GitHub webhook → Jenkins

2. Jenkins Pipeline
   ├─ Checkout code
   ├─ Build image (Kaniko)
   │  └─ Push to ECR: my-app:BUILD_NUMBER
   └─ Update helm/django-app/values.yaml
      └─ git push

3. ArgoCD (автоматично)
   ├─ Detect Git changes (~3 min)
   ├─ Pull new values
   ├─ Apply to Kubernetes
   └─ Rolling update

4. Kubernetes
   ├─ Create new pods with new image
   ├─ Wait for health checks
   ├─ Terminate old pods
   └─ Service routes to new pods
```

---

**🎉 Вітаємо! Інфраструктура розгорнута!**

**Документація:**
- [TASK_COMPLETION.md](TASK_COMPLETION.md) - Що реалізовано
- [JENKINS_ARGOCD_SETUP.md](JENKINS_ARGOCD_SETUP.md) - Детальний setup
- [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - Швидкий старт
