# 🗄️ Terraform RDS Module

Універсальний модуль для розгортання AWS RDS - підтримує як **Aurora Cluster**, так і **Standard RDS Instance**.

---

## 📦 Використання

### Приклад 1: Standard RDS (PostgreSQL)

```hcl
module "rds_standard" {
  source = "./modules/rds"

  # Обов'язкові параметри
  name                   = "my-app-db"
  db_name                = "myapp"
  username               = "admin"
  password               = var.db_password # Sensitive!
  
  vpc_id                 = module.vpc.vpc_id
  subnet_private_ids     = module.vpc.private_subnet_ids
  subnet_public_ids      = module.vpc.public_subnet_ids
  
  # Тип БД
  use_aurora             = false # Standard RDS
  
  # Database engine
  engine                 = "postgres"
  engine_version         = "14.7"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  
  # Network
  publicly_accessible    = false
  allowed_cidr_blocks    = ["10.0.0.0/16"] # VPC CIDR
  
  # High Availability
  multi_az               = true
  backup_retention_period = 7
  
  # Custom parameters
  parameter_group_family_rds = "postgres14"
  parameters = {
    "max_connections"           = "200"
    "shared_buffers"            = "256MB"
    "effective_cache_size"      = "1GB"
  }
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}

# Outputs
output "db_endpoint" {
  value = module.rds_standard.rds_endpoint
}
```

---

### Приклад 2: Aurora Cluster (PostgreSQL)

```hcl
module "rds_aurora" {
  source = "./modules/rds"

  # Обов'язкові параметри
  name                   = "my-app-aurora"
  db_name                = "myapp"
  username               = "admin"
  password               = var.db_password
  
  vpc_id                 = module.vpc.vpc_id
  subnet_private_ids     = module.vpc.private_subnet_ids
  subnet_public_ids      = []
  
  # Тип БД
  use_aurora             = true # Aurora Cluster
  
  # Aurora engine
  engine_cluster         = "aurora-postgresql"
  engine_version_cluster = "15.3"
  instance_class         = "db.r5.large"
  aurora_replica_count   = 2 # 1 writer + 2 readers
  
  # Network
  publicly_accessible    = false
  allowed_cidr_blocks    = ["10.0.0.0/16"]
  
  # Backup
  backup_retention_period = 14
  
  # Custom parameters
  parameter_group_family_aurora = "aurora-postgresql15"
  parameters = {
    "shared_preload_libraries" = "pg_stat_statements"
    "max_connections"          = "500"
  }
  
  tags = {
    Environment = "production"
    Project     = "my-app"
    Type        = "aurora"
  }
}

# Outputs
output "aurora_writer_endpoint" {
  value = module.rds_aurora.aurora_cluster_endpoint
}

output "aurora_reader_endpoint" {
  value = module.rds_aurora.aurora_cluster_reader_endpoint
}
```

---

## 📥 Змінні

### Обов'язкові змінні

| Змінна | Опис | Тип | Приклад |
|--------|------|-----|---------|
| `name` | Назва інстансу або кластера | `string` | `"my-app-db"` |
| `db_name` | Ім'я бази даних | `string` | `"myapp"` |
| `username` | Master username | `string` | `"admin"` |
| `password` | Master password (sensitive) | `string` | `var.db_password` |
| `vpc_id` | VPC ID де буде розміщено RDS | `string` | `module.vpc.vpc_id` |
| `subnet_private_ids` | Private subnet IDs для RDS | `list(string)` | `module.vpc.private_subnet_ids` |
| `subnet_public_ids` | Public subnet IDs (якщо publicly_accessible = true) | `list(string)` | `module.vpc.public_subnet_ids` |

---

### Опціональні змінні

#### Тип БД

| Змінна | Опис | Тип | Default | Коментар |
|--------|------|-----|---------|----------|
| `use_aurora` | Використовувати Aurora Cluster (true) або Standard RDS (false) | `bool` | `false` | **Головний перемикач типу БД** |

---

#### Engine Settings (Standard RDS)

| Змінна | Опис | Тип | Default | Варіанти |
|--------|------|-----|---------|----------|
| `engine` | Database engine для Standard RDS | `string` | `"postgres"` | `postgres`, `mysql`, `mariadb` |
| `engine_version` | Engine version для Standard RDS | `string` | `"14.7"` | Залежить від engine |
| `parameter_group_family_rds` | Parameter group family для Standard RDS | `string` | `"postgres15"` | `postgres14`, `postgres15`, `mysql8.0` |

**Як змінити на MySQL:**
```hcl
engine                 = "mysql"
engine_version         = "8.0.35"
parameter_group_family_rds = "mysql8.0"
```

---

#### Engine Settings (Aurora)

| Змінна | Опис | Тип | Default | Варіанти |
|--------|------|-----|---------|----------|
| `engine_cluster` | Database engine для Aurora | `string` | `"aurora-postgresql"` | `aurora-postgresql`, `aurora-mysql` |
| `engine_version_cluster` | Engine version для Aurora | `string` | `"15.3"` | Залежить від engine |
| `parameter_group_family_aurora` | Parameter group family для Aurora | `string` | `"aurora-postgresql15"` | `aurora-postgresql15`, `aurora-mysql8.0` |

**Як змінити на Aurora MySQL:**
```hcl
engine_cluster         = "aurora-mysql"
engine_version_cluster = "8.0.mysql_aurora.3.04.0"
parameter_group_family_aurora = "aurora-mysql8.0"
```

---

#### Instance Settings

| Змінна | Опис | Тип | Default | Варіанти |
|--------|------|-----|---------|----------|
| `instance_class` | Instance class | `string` | `"db.t3.micro"` | `db.t3.micro`, `db.t3.small`, `db.t3.medium`, `db.r5.large`, `db.r5.xlarge` |
| `allocated_storage` | Allocated storage в GB (тільки для Standard RDS) | `number` | `20` | 20-65536 GB |
| `aurora_replica_count` | Кількість reader replicas (тільки для Aurora) | `number` | `1` | 0-15 |

**Як змінити клас інстансу:**

Для dev/test:
```hcl
instance_class = "db.t3.micro"  # 2 vCPU, 1 GB RAM
```

Для production:
```hcl
instance_class = "db.t3.medium" # 2 vCPU, 4 GB RAM
instance_class = "db.r5.large"  # 2 vCPU, 16 GB RAM (для Aurora)
```

---

#### Network Settings

| Змінна | Опис | Тип | Default |
|--------|------|-----|---------|
| `publicly_accessible` | Чи має бути RDS доступним з інтернету | `bool` | `false` |
| `allowed_cidr_blocks` | CIDR blocks з яких дозволено підключення | `list(string)` | `["10.0.0.0/8"]` |

**Приклади:**
```hcl
# Production (private)
publicly_accessible = false
allowed_cidr_blocks = ["10.0.0.0/16"] # VPC CIDR

# Dev (public access)
publicly_accessible = true
allowed_cidr_blocks = ["0.0.0.0/0"] # ⚠️ Тільки для dev!

# Multiple networks
allowed_cidr_blocks = [
  "10.0.0.0/16",  # VPC
  "10.1.0.0/16",  # Additional VPC
  "192.168.1.0/24" # Office network
]
```

---

#### High Availability & Backup

| Змінна | Опис | Тип | Default |
|--------|------|-----|---------|
| `multi_az` | Multi-AZ deployment (тільки для Standard RDS) | `bool` | `false` |
| `backup_retention_period` | Кількість днів для зберігання backup (0-35) | `number` | `7` |

**Приклади:**
```hcl
# Production
multi_az                = true
backup_retention_period = 14

# Dev
multi_az                = false
backup_retention_period = 1
```

---

#### Custom Parameters

| Змінна | Опис | Тип | Default |
|--------|------|-----|---------|
| `parameters` | Custom database parameters | `map(string)` | `{}` |

**Приклади:**

PostgreSQL:
```hcl
parameters = {
  "max_connections"        = "200"
  "shared_buffers"         = "256MB"
  "effective_cache_size"   = "1GB"
  "work_mem"               = "4MB"
  "maintenance_work_mem"   = "128MB"
}
```

Aurora PostgreSQL:
```hcl
parameters = {
  "shared_preload_libraries" = "pg_stat_statements"
  "max_connections"          = "1000"
  "log_statement"            = "all"
}
```

MySQL:
```hcl
parameters = {
  "max_connections"     = "500"
  "innodb_buffer_pool_size" = "256M"
}
```

---

#### Tags

| Змінна | Опис | Тип | Default |
|--------|------|-----|---------|
| `tags` | Tags для всіх ресурсів | `map(string)` | `{}` |

```hcl
tags = {
  Environment = "production"
  Project     = "my-app"
  ManagedBy   = "terraform"
}
```

---

## 📤 Outputs

### Aurora Outputs

| Output | Опис |
|--------|------|
| `aurora_cluster_endpoint` | Writer endpoint для запису |
| `aurora_cluster_reader_endpoint` | Reader endpoint для читання |
| `aurora_cluster_id` | Cluster ID |
| `aurora_cluster_arn` | Cluster ARN |

### Standard RDS Outputs

| Output | Опис |
|--------|------|
| `rds_endpoint` | Instance endpoint (`host:port`) |
| `rds_address` | Instance address (тільки hostname) |
| `rds_id` | Instance ID |
| `rds_arn` | Instance ARN |

### Спільні Outputs

| Output | Опис |
|--------|------|
| `db_port` | Database port |
| `db_name` | Database name |
| `db_username` | Master username (sensitive) |
| `connection_string` | Connection string (sensitive) |
| `security_group_id` | Security Group ID |
| `subnet_group_name` | Subnet Group name |

**Використання outputs:**
```hcl
output "db_endpoint" {
  value = module.rds.rds_endpoint
}

output "connection_string" {
  value     = module.rds.connection_string
  sensitive = true
}
```

---

## 🔄 Зміна типу БД

### З Standard RDS на Aurora

1. **Створити snapshot Standard RDS:**
```bash
aws rds create-db-snapshot \
  --db-instance-identifier my-app-db \
  --db-snapshot-identifier my-app-db-snapshot
```

2. **Змінити `use_aurora`:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = true # Було: false
  
  # Змінити engine
  engine_cluster         = "aurora-postgresql"
  engine_version_cluster = "15.3"
  
  # Інші параметри...
}
```

3. **Apply та відновити дані зі snapshot**

### З Aurora на Standard RDS

Аналогічно, але `use_aurora = false` та використати Standard RDS engine settings.

---

## 🔧 Зміна Engine

### PostgreSQL → MySQL (Standard RDS)

```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = false
  
  # Було PostgreSQL:
  # engine                 = "postgres"
  # engine_version         = "14.7"
  # parameter_group_family_rds = "postgres14"
  
  # Стало MySQL:
  engine                 = "mysql"
  engine_version         = "8.0.35"
  parameter_group_family_rds = "mysql8.0"
  
  # Інші параметри...
}
```

⚠️ **Увага:** Пряма зміна engine потребує міграції даних!

### Aurora PostgreSQL → Aurora MySQL

```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = true
  
  # Було:
  # engine_cluster         = "aurora-postgresql"
  # engine_version_cluster = "15.3"
  # parameter_group_family_aurora = "aurora-postgresql15"
  
  # Стало:
  engine_cluster         = "aurora-mysql"
  engine_version_cluster = "8.0.mysql_aurora.3.04.0"
  parameter_group_family_aurora = "aurora-mysql8.0"
  
  # Інші параметри...
}
```

---

## 🚀 Quick Start

```bash
# 1. Створити модуль
cd modules/rds/

# 2. Використати в main.tf
module "database" {
  source = "./modules/rds"
  
  name     = "myapp-db"
  db_name  = "myapp"
  username = "admin"
  password = var.db_password
  
  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
  subnet_public_ids  = []
  
  use_aurora = false
}

# 3. Apply
terraform init
terraform plan
terraform apply
```
