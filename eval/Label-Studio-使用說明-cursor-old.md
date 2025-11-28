# Label Studio 使用說明

本文件提供 Label Studio 在 Kubernetes (K8s) 生產環境的完整使用說明，適用於技術人員進行部署與維護。

---

## 目錄

1. [系統需求與前置準備](#1-系統需求與前置準備)
2. [Kubernetes 部署](#2-kubernetes-部署)
3. [基本操作](#3-基本操作)
4. [進階設定](#4-進階設定)
5. [環境變數完整說明](#5-環境變數完整說明)
6. [故障排除](#6-故障排除)
7. [維護與升級](#7-維護與升級)

---

## 1. 系統需求與前置準備

### 1.1 軟體需求

部署 Label Studio 到 Kubernetes 前，請確認以下軟體已安裝並符合版本要求：

| 軟體 | 最低版本 | 說明 |
|------|---------|------|
| Kubernetes | 1.17+ | Kubernetes 叢集 |
| kubectl | 1.17+ | Kubernetes 命令列工具 |
| Helm | 3.6.3+ | Kubernetes 套件管理工具 |

### 1.2 容量規劃

根據預設配置，Label Studio 的資源需求如下：

```yaml
app:
  replicas: 1
  resources:
    requests:
      memory: 1024Mi
      cpu: 1000m
    limits:
      memory: 6144Mi
      cpu: 4000m
```

**容量調整建議：**

| 使用情境 | 建議調整 |
|---------|---------|
| 超過 10 位同時標註人員 | 調整 `app.resources` 的 requests 和 limits |
| 提升容錯能力 | 增加 `app.replicas` 數量 |
| 生產環境 | replicas 數量應 ≥ 可用性區域數量 |

### 1.3 資料庫需求

- **PostgreSQL**: 11.9+（生產環境建議）
- **Redis**: 6.0.5+（用於任務佇列）

---

## 2. Kubernetes 部署

### 2.1 準備 Kubernetes 叢集

確認 Kubernetes 叢集已就緒：

```bash
# 檢查叢集連線
kubectl cluster-info

# 檢查節點狀態
kubectl get nodes
```

### 2.2 新增 Helm Chart Repository

```bash
# 新增 Label Studio Helm repository
helm repo add heartex https://charts.heartex.com/
helm repo update heartex

# 檢查可用版本
helm search repo heartex/label-studio
```

### 2.3 建立 values.yaml 設定檔

建立 `ls-values.yaml` 設定檔，範例如下：

```yaml
global:
  image:
    repository: heartexlabs/label-studio
    tag: "latest"  # 建議使用特定版本標籤
    pullPolicy: IfNotPresent

  # PostgreSQL 設定
  pgConfig:
    host: "postgres-service"  # 或使用外部 PostgreSQL
    port: 5432
    dbName: "labelstudio"
    userName: "labelstudio"
    password:
      secretName: "postgres-secret"
      secretKey: "password"

  # Redis 設定（可選）
  redisConfig:
    host: "redis://redis-service:6379/1"
    password:
      secretName: "redis-secret"
      secretKey: "password"

  # 額外環境變數
  extraEnvironmentVars:
    DEBUG: "false"
    LOG_LEVEL: "INFO"
    SSRF_PROTECTION_ENABLED: "true"  # 生產環境必設
    DISABLE_SIGNUP_WITHOUT_LINK: "true"  # 關閉自由註冊

  # 持久化儲存設定
  persistence:
    enabled: true
    type: volume  # 或 s3, azure, gcs
    config:
      volume:
        storageClass: "standard"
        size: "50Gi"
        accessModes: ["ReadWriteOnce"]

# App 設定
app:
  replicas: 2  # 生產環境建議 ≥ 2
  resources:
    requests:
      memory: "1024Mi"
      cpu: "1000m"
    limits:
      memory: "6144Mi"
      cpu: "4000m"

  # Ingress 設定
  ingress:
    enabled: true
    className: "nginx"
    host: "labelstudio.example.com"
    tls:
      - secretName: "labelstudio-tls"
        hosts:
          - "labelstudio.example.com"

# PostgreSQL 子圖表設定（如使用內建 PostgreSQL）
postgresql:
  enabled: true
  architecture: standalone
  auth:
    username: "labelstudio"
    password: "your-secure-password"
    database: "labelstudio"

# Redis 子圖表設定（如使用內建 Redis）
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: true
    password: "your-redis-password"
```

### 2.4 建立 Kubernetes Secrets

建立必要的 Secrets：

```bash
# PostgreSQL 密碼 Secret
kubectl create secret generic postgres-secret \
  --from-literal=password=your-secure-password

# Redis 密碼 Secret（如需要）
kubectl create secret generic redis-secret \
  --from-literal=password=your-redis-password

# TLS 憑證 Secret（如使用 HTTPS）
kubectl create secret tls labelstudio-tls \
  --cert=tls.crt \
  --key=tls.key
```

### 2.5 安裝 Label Studio

使用 Helm 安裝 Label Studio：

```bash
# 安裝 Label Studio
helm install label-studio heartex/label-studio -f ls-values.yaml

# 檢查安裝狀態
kubectl get pods -l app=label-studio

# 檢查服務狀態
kubectl get svc -l app=label-studio
```

### 2.6 驗證部署

```bash
# 檢查 Pod 狀態
kubectl get pods

# 查看 Pod 日誌
kubectl logs -l app=label-studio --tail=100

# 檢查服務端點
kubectl get ingress
```

部署成功後，可透過 Ingress 設定的網址（如 `https://labelstudio.example.com`）存取 Label Studio。

---

## 3. 基本操作

### 3.1 首次登入與註冊

1. 開啟 Label Studio 網頁介面
2. 點選「Sign Up」建立第一個帳號
   - 第一個註冊的使用者會自動成為管理員
   - 如已設定 `DISABLE_SIGNUP_WITHOUT_LINK=true`，需使用管理員發送的邀請連結

### 3.2 建立專案

1. 登入後，點選「Create」建立新專案
2. 填寫專案資訊：
   - **專案名稱**：必填
   - **描述**：選填
   - **顏色標籤**：選填
3. 點選「Save」儲存

### 3.3 匯入資料

Label Studio 支援多種資料匯入方式：

#### 方式一：上傳檔案

1. 在專案中點選「Data Import」
2. 選擇「Upload Files」
3. 上傳資料檔案（支援圖片、文字、音訊、影片等）

#### 方式二：從雲端儲存匯入

1. 在專案設定中點選「Cloud Storage」
2. 選擇儲存類型（AWS S3、Google Cloud Storage、Azure Blob）
3. 設定連線資訊（詳見[雲端儲存設定](#42-雲端儲存設定)）
4. 選擇要匯入的檔案

#### 方式三：使用 API 匯入

```bash
# 取得 API Token（在 Account & Settings 頁面）
export LABEL_STUDIO_TOKEN="your-api-token"
export LABEL_STUDIO_URL="https://labelstudio.example.com"

# 匯入任務
curl -X POST "${LABEL_STUDIO_URL}/api/projects/1/import" \
  -H "Authorization: Token ${LABEL_STUDIO_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "tasks": [
      {"data": {"image": "https://example.com/image1.jpg"}},
      {"data": {"image": "https://example.com/image2.jpg"}}
    ]
  }'
```

### 3.4 設定標註介面

1. 在專案中點選「Labeling Setup」
2. 選擇標註模板或自訂標註介面
3. 使用 Label Studio 標籤語言定義標註介面

**範例：圖片分類標註**

```xml
<View>
  <Image name="image" value="$image"/>
  <Choices name="choice" toName="image">
    <Choice value="cat" alias="貓"/>
    <Choice value="dog" alias="狗"/>
  </Choices>
</View>
```

### 3.5 開始標註

1. 在專案首頁點選「Label」開始標註
2. 使用標註工具進行標記
3. 完成後點選「Submit」提交標註結果

### 3.6 匯出標註結果

1. 在專案中點選「Export」
2. 選擇匯出格式（JSON、CSV、COCO、YOLO 等）
3. 下載匯出檔案

---

## 4. 進階設定

### 4.1 LLM 整合設定

Label Studio 支援多種 LLM 服務，用於 AI 輔助標註。

#### 4.1.1 OpenAI 整合

1. **取得 API Key**
   - 前往 [OpenAI API Keys](https://platform.openai.com/api-keys)
   - 建立新的 API Key

2. **在 Label Studio 中設定**
   - 登入 Label Studio
   - 前往「Account & Settings」→「Model Providers」
   - 選擇「OpenAI」
   - 輸入 API Key
   - 點選「Save」

3. **在標註介面中使用**

```xml
<View>
  <Text name="text" value="$text"/>
  <Chat name="chat" llm="openai/gpt-4o-mini" toName="text"/>
</View>
```

#### 4.1.2 Azure OpenAI 整合

1. **取得連線資訊**
   - Azure OpenAI 端點 URL
   - API Key
   - 部署名稱（Deployment Name）

2. **在 Label Studio 中設定**
   - 前往「Model Providers」
   - 選擇「Azure OpenAI」
   - 輸入端點、API Key、部署名稱
   - 點選「Save」

#### 4.1.3 自訂 LLM（Ollama 範例）

1. **設定 Ollama 服務**
   ```bash
   # 安裝並啟動 Ollama
   ollama run llama3.2
   ```

2. **建立外部端點**
   - 確保 Ollama API 可從 Kubernetes 叢集存取
   - 端點格式：`https://your-ollama-endpoint.com/v1`

3. **在 Label Studio 中設定**
   - 前往「Model Providers」
   - 選擇「Custom」
   - 輸入：
     - **Name**: `llama3.2`（需與 Ollama 模型名稱一致）
     - **Endpoint**: `https://your-ollama-endpoint.com/v1`（需包含 `/v1` 後綴）
     - **API Key**: `ollama`（預設值）
   - 點選「Save」

#### 4.1.4 透過環境變數設定（K8s）

在 `ls-values.yaml` 中設定：

```yaml
global:
  extraEnvironmentVars:
    # OpenAI API Key（不建議，應使用 Secret）
    OPENAI_API_KEY: "sk-..."
    
    # 或使用 Secret
  extraEnvironmentSecrets:
    OPENAI_API_KEY:
      secretName: "openai-secret"
      secretKey: "api-key"
```

建立 Secret：

```bash
kubectl create secret generic openai-secret \
  --from-literal=api-key=sk-your-api-key
```

### 4.2 雲端儲存設定

#### 4.2.1 AWS S3 設定

**方式一：透過 UI 設定**

1. 在專案中點選「Cloud Storage」
2. 選擇「Amazon S3」
3. 輸入設定：
   - **Bucket Name**: S3 bucket 名稱
   - **AWS Access Key ID**: AWS 存取金鑰 ID
   - **AWS Secret Access Key**: AWS 秘密存取金鑰
   - **Region**: AWS 區域（如 `us-east-1`）
   - **Prefix**: 可選，指定 bucket 內的前綴路徑
4. 點選「Test Connection」測試連線
5. 點選「Save」儲存

**方式二：透過環境變數設定（K8s）**

在 `ls-values.yaml` 中設定：

```yaml
global:
  persistence:
    enabled: true
    type: s3
    config:
      s3:
        accessKey: "your-access-key"
        secretKey: "your-secret-key"
        region: "us-east-1"
        bucket: "label-studio-bucket"
        folder: "data"  # 可選
        urlExpirationSecs: 86400
```

或使用 Secret：

```yaml
global:
  persistence:
    enabled: true
    type: s3
    config:
      s3:
        accessKeyExistingSecret: "s3-secret"
        accessKeyExistingSecretKey: "access-key"
        secretKeyExistingSecret: "s3-secret"
        secretKeyExistingSecretKey: "secret-key"
        region: "us-east-1"
        bucket: "label-studio-bucket"
```

建立 Secret：

```bash
kubectl create secret generic s3-secret \
  --from-literal=access-key=your-access-key \
  --from-literal=secret-key=your-secret-key
```

#### 4.2.2 Google Cloud Storage 設定

**透過 UI 設定：**

1. 在專案中點選「Cloud Storage」
2. 選擇「Google Cloud Storage」
3. 上傳 Service Account JSON 金鑰檔案
4. 輸入：
   - **Bucket Name**: GCS bucket 名稱
   - **Project ID**: GCP 專案 ID
5. 點選「Test Connection」測試連線
6. 點選「Save」儲存

**透過環境變數設定（K8s）：**

```yaml
global:
  persistence:
    enabled: true
    type: gcs
    config:
      gcs:
        projectID: "your-gcp-project-id"
        applicationCredentialsJSONExistingSecret: "gcs-secret"
        applicationCredentialsJSONExistingSecretKey: "credentials.json"
        bucket: "label-studio-bucket"
        folder: "data"
        urlExpirationSecs: 86400
```

建立 Secret：

```bash
# 將 Service Account JSON 檔案內容存入 Secret
kubectl create secret generic gcs-secret \
  --from-file=credentials.json=/path/to/service-account-key.json
```

#### 4.2.3 Azure Blob Storage 設定

**透過 UI 設定：**

1. 在專案中點選「Cloud Storage」
2. 選擇「Azure Blob Storage」
3. 輸入設定：
   - **Account Name**: Azure 儲存帳戶名稱
   - **Account Key**: Azure 儲存帳戶金鑰
   - **Container Name**: Blob 容器名稱
4. 點選「Test Connection」測試連線
5. 點選「Save」儲存

**透過環境變數設定（K8s）：**

```yaml
global:
  persistence:
    enabled: true
    type: azure
    config:
      azure:
        storageAccountName: "your-storage-account"
        storageAccountKey: "your-account-key"
        containerName: "label-studio-container"
        folder: "data"
        urlExpirationSecs: 86400
```

或使用 Secret：

```yaml
global:
  persistence:
    enabled: true
    type: azure
    config:
      azure:
        storageAccountNameExistingSecret: "azure-secret"
        storageAccountNameExistingSecretKey: "account-name"
        storageAccountKeyExistingSecret: "azure-secret"
        storageAccountKeyExistingSecretKey: "account-key"
        containerName: "label-studio-container"
```

---

## 5. 環境變數完整說明

Label Studio 支援透過環境變數進行設定。在 Kubernetes 部署中，可透過 `global.extraEnvironmentVars` 設定。

### 5.1 資料庫相關環境變數

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `DJANGO_DB` | 資料庫類型 | `sqlite` | `default` (PostgreSQL) |
| `POSTGRE_HOST` | PostgreSQL 主機 | `localhost` | `postgres-service` |
| `POSTGRE_PORT` | PostgreSQL 埠號 | `5432` | `5432` |
| `POSTGRE_NAME` | PostgreSQL 資料庫名稱 | `postgres` | `labelstudio` |
| `POSTGRE_USER` | PostgreSQL 使用者名稱 | `postgres` | `labelstudio` |
| `POSTGRE_PASSWORD` | PostgreSQL 密碼 | `postgres` | （應使用 Secret） |
| `MYSQL_HOST` | MySQL 主機 | `localhost` | `mysql-service` |
| `MYSQL_PORT` | MySQL 埠號 | `3306` | `3306` |
| `MYSQL_NAME` | MySQL 資料庫名稱 | `labelstudio` | `labelstudio` |
| `MYSQL_USER` | MySQL 使用者名稱 | `root` | `labelstudio` |
| `MYSQL_PASSWORD` | MySQL 密碼 | `""` | （應使用 Secret） |
| `DATABASE_NAME` | SQLite 資料庫檔案路徑 | `label_studio.sqlite3` | `/data/label_studio.sqlite3` |

### 5.2 應用程式設定

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `DEBUG` | 除錯模式 | `False` | `false`（生產環境必設） |
| `DEBUG_PROPAGATE_EXCEPTIONS` | 傳播例外 | `False` | `false` |
| `LOG_LEVEL` | 日誌等級 | `WARNING` | `INFO`, `DEBUG`, `ERROR` |
| `JSON_LOG` | JSON 格式日誌 | `False` | `true` |
| `HOST` | 主機名稱 | `""` | `https://labelstudio.example.com` |
| `LABEL_STUDIO_HOST` | Label Studio 主機 URL | `""` | `https://labelstudio.example.com` |
| `PORT` | 服務埠號 | `8080` | `8080` |
| `BASE_DATA_DIR` | 資料目錄 | 自動產生 | `/label-studio/data` |

### 5.3 安全性設定

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `SSRF_PROTECTION_ENABLED` | 啟用 SSRF 保護 | `False` | `true`（生產環境必設） |
| `DISABLE_SIGNUP_WITHOUT_LINK` | 關閉自由註冊 | `False` | `true` |
| `SESSION_COOKIE_SECURE` | 安全 Cookie | `False` | `true`（HTTPS 環境） |
| `CSRF_TRUSTED_ORIGINS` | CSRF 信任來源 | `[]` | `https://labelstudio.example.com` |
| `CORS_ALLOW_ALL_ORIGINS` | 允許所有 CORS 來源 | `True` | `false`（生產環境） |

### 5.4 儲存相關環境變數

#### 5.4.1 本機檔案儲存

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `ENABLE_LOCAL_FILES_STORAGE` | 啟用本機檔案儲存 | `True` | `true` |
| `LABEL_STUDIO_LOCAL_FILES_SERVING_ENABLED` | 啟用本機檔案服務 | `False` | `true` |
| `LABEL_STUDIO_LOCAL_FILES_DOCUMENT_ROOT` | 本機檔案根目錄 | `/` | `/data/files` |

#### 5.4.2 AWS S3 儲存

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `STORAGE_TYPE` | 儲存類型 | `""` | `s3` |
| `STORAGE_AWS_ACCESS_KEY_ID` | AWS 存取金鑰 ID | `""` | （應使用 Secret） |
| `STORAGE_AWS_SECRET_ACCESS_KEY` | AWS 秘密存取金鑰 | `""` | （應使用 Secret） |
| `STORAGE_AWS_BUCKET_NAME` | S3 Bucket 名稱 | `""` | `label-studio-bucket` |
| `STORAGE_AWS_REGION_NAME` | AWS 區域 | `""` | `us-east-1` |
| `STORAGE_AWS_ENDPOINT_URL` | S3 端點 URL | `""` | `https://s3.amazonaws.com` |
| `STORAGE_AWS_FOLDER` | S3 資料夾路徑 | `""` | `data` |
| `STORAGE_AWS_X_AMZ_EXPIRES` | URL 過期時間（秒） | `86400` | `86400` |
| `STORAGE_AWS_S3_USE_SSL` | 使用 SSL | `True` | `true` |
| `STORAGE_AWS_S3_VERIFY` | 驗證 SSL | `None` | `true` |

#### 5.4.3 Google Cloud Storage

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `STORAGE_TYPE` | 儲存類型 | `""` | `gcs` |
| `STORAGE_GCS_PROJECT_ID` | GCP 專案 ID | `""` | `my-gcp-project` |
| `STORAGE_GCS_BUCKET_NAME` | GCS Bucket 名稱 | `""` | `label-studio-bucket` |
| `STORAGE_GCS_FOLDER` | GCS 資料夾路徑 | `""` | `data` |
| `STORAGE_GCS_EXPIRATION_SECS` | URL 過期時間（秒） | `86400` | `86400` |
| `STORAGE_GCS_ENDPOINT` | GCS 端點 URL | `""` | （通常不需要） |
| `GCS_CLOUD_STORAGE_FORCE_DEFAULT_CREDENTIALS` | 使用預設憑證 | `False` | `false` |

#### 5.4.4 Azure Blob Storage

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `STORAGE_TYPE` | 儲存類型 | `""` | `azure` |
| `STORAGE_AZURE_ACCOUNT_NAME` | Azure 儲存帳戶名稱 | `""` | `mystorageaccount` |
| `STORAGE_AZURE_ACCOUNT_KEY` | Azure 儲存帳戶金鑰 | `""` | （應使用 Secret） |
| `STORAGE_AZURE_CONTAINER_NAME` | Blob 容器名稱 | `""` | `label-studio-container` |
| `STORAGE_AZURE_FOLDER` | Azure 資料夾路徑 | `""` | `data` |
| `STORAGE_AZURE_URL_EXPIRATION_SECS` | URL 過期時間（秒） | `86400` | `86400` |

### 5.5 Redis 設定

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `REDIS_HOST` | Redis 主機 | `localhost` | `redis-service` |
| `REDIS_PORT` | Redis 埠號 | `6379` | `6379` |
| `REDIS_DB` | Redis 資料庫編號 | `1` | `1` |
| `REDIS_PASSWORD` | Redis 密碼 | `""` | （應使用 Secret） |

### 5.6 任務佇列設定

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `RQ_LONG_JOB_TIMEOUT` | 長時間任務逾時（秒） | `36000` | `36000` |
| `RQ_FAILED_JOB_TTL` | 失敗任務保留時間（秒） | `2592000` | `2592000` |
| `BATCH_JOB_RETRY_TIMEOUT` | 批次任務重試逾時（秒） | `60` | `60` |

### 5.7 檔案上傳設定

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `DATA_UPLOAD_MAX_MEMORY_SIZE` | 最大上傳記憶體大小（位元組） | `262144000` | `262144000` |
| `DATA_UPLOAD_MAX_NUMBER_FILES` | 最大上傳檔案數量 | `100` | `100` |
| `USE_NGINX_FOR_UPLOADS` | 使用 Nginx 處理上傳 | `True` | `true` |
| `USE_NGINX_FOR_EXPORT_DOWNLOADS` | 使用 Nginx 處理下載 | `False` | `true` |

### 5.8 LLM 相關環境變數

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `OPENAI_API_KEY` | OpenAI API 金鑰 | `""` | （應使用 Secret） |
| `AZURE_OPENAI_API_KEY` | Azure OpenAI API 金鑰 | `""` | （應使用 Secret） |
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI 端點 | `""` | `https://your-resource.openai.azure.com` |

### 5.9 監控與日誌

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `SENTRY_DSN` | Sentry DSN | （預設值） | `https://...@sentry.io/...` |
| `SENTRY_ENVIRONMENT` | Sentry 環境 | `opensource` | `production` |
| `SENTRY_RATE` | Sentry 錯誤回報率 | `0.02` | `0.02` |
| `FRONTEND_SENTRY_DSN` | 前端 Sentry DSN | （預設值） | `https://...@sentry.io/...` |
| `FRONTEND_SENTRY_ENVIRONMENT` | 前端 Sentry 環境 | `opensource` | `production` |
| `GOOGLE_LOGGING_ENABLED` | 啟用 Google Cloud Logging | `False` | `true` |

### 5.10 功能開關

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `FEATURE_FLAGS_OFFLINE` | 功能開關離線模式 | `True` | `true` |
| `FEATURE_FLAGS_FILE` | 功能開關檔案 | `feature_flags.json` | `feature_flags.json` |
| `STORAGE_PERSISTENCE` | 儲存持久化 | `True` | `true` |

### 5.11 其他設定

| 環境變數 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `TASK_LOCK_TTL` | 任務鎖定 TTL（秒） | `86400` | `86400` |
| `LABEL_STREAM_HISTORY_LIMIT` | 標註歷史限制 | `100` | `100` |
| `RANDOM_NEXT_TASK_SAMPLE_SIZE` | 隨機任務樣本大小 | `50` | `50` |
| `FROM_EMAIL` | 發信者郵件地址 | `Label Studio <hello@labelstud.io>` | `Label Studio <noreply@example.com>` |
| `EMAIL_BACKEND` | 郵件後端 | `django.core.mail.backends.dummy.EmailBackend` | `django.core.mail.backends.smtp.EmailBackend` |

### 5.12 在 Kubernetes 中設定環境變數

在 `ls-values.yaml` 中設定：

```yaml
global:
  extraEnvironmentVars:
    DEBUG: "false"
    LOG_LEVEL: "INFO"
    SSRF_PROTECTION_ENABLED: "true"
    DISABLE_SIGNUP_WITHOUT_LINK: "true"
    # ... 其他環境變數
```

使用 Secret：

```yaml
global:
  extraEnvironmentSecrets:
    OPENAI_API_KEY:
      secretName: "openai-secret"
      secretKey: "api-key"
    POSTGRE_PASSWORD:
      secretName: "postgres-secret"
      secretKey: "password"
```

---

## 6. 故障排除

### 6.1 Pod 無法啟動

**問題：** Pod 處於 `CrashLoopBackOff` 或 `Error` 狀態

**檢查步驟：**

```bash
# 查看 Pod 狀態
kubectl get pods -l app=label-studio

# 查看 Pod 詳細資訊
kubectl describe pod <pod-name>

# 查看 Pod 日誌
kubectl logs <pod-name> --tail=100
```

**常見原因與解決方案：**

1. **資料庫連線失敗**
   - 檢查 PostgreSQL 服務是否正常
   - 確認資料庫連線資訊（host, port, user, password）正確
   - 檢查網路連線與防火牆設定

2. **環境變數設定錯誤**
   - 檢查 `ls-values.yaml` 中的環境變數設定
   - 確認 Secret 已正確建立

3. **資源不足**
   - 檢查節點資源使用情況：`kubectl top nodes`
   - 調整 Pod 的 resource requests 和 limits

### 6.2 資料庫連線問題

**問題：** 無法連線到 PostgreSQL

**檢查步驟：**

```bash
# 檢查 PostgreSQL Pod 狀態
kubectl get pods -l app=postgresql

# 測試資料庫連線（在 Label Studio Pod 中）
kubectl exec -it <label-studio-pod> -- \
  psql -h <postgres-host> -U <user> -d <database>
```

**解決方案：**

1. 確認 PostgreSQL 服務正常運行
2. 檢查連線字串設定
3. 確認網路策略允許連線
4. 檢查 Secret 中的密碼是否正確

### 6.3 儲存空間問題

**問題：** 無法存取雲端儲存或上傳檔案失敗

**檢查步驟：**

```bash
# 查看 Pod 日誌
kubectl logs <pod-name> | grep -i storage

# 檢查 PersistentVolume 狀態
kubectl get pv
kubectl get pvc
```

**解決方案：**

1. **S3 儲存問題**
   - 確認 AWS 憑證正確
   - 檢查 IAM 權限設定
   - 確認 bucket 存在且可存取

2. **GCS 儲存問題**
   - 確認 Service Account JSON 正確
   - 檢查 Service Account 權限
   - 確認 bucket 存在

3. **Azure 儲存問題**
   - 確認儲存帳戶名稱和金鑰正確
   - 檢查容器是否存在

### 6.4 LLM 整合問題

**問題：** LLM 功能無法使用

**檢查步驟：**

```bash
# 查看 Pod 日誌中的 LLM 相關錯誤
kubectl logs <pod-name> | grep -i "openai\|llm\|model"
```

**解決方案：**

1. 確認 API Key 已正確設定（透過 UI 或環境變數）
2. 檢查網路連線（Label Studio Pod 需能存取外部 LLM API）
3. 確認 API 配額未用盡
4. 檢查 API 端點 URL 是否正確

### 6.5 效能問題

**問題：** 標註介面載入緩慢或操作無回應

**檢查步驟：**

```bash
# 檢查 Pod 資源使用情況
kubectl top pods -l app=label-studio

# 檢查資料庫連線數
kubectl exec -it <postgres-pod> -- \
  psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

**解決方案：**

1. **增加資源**
   - 調整 `app.resources` 的 requests 和 limits
   - 增加 Pod replicas 數量

2. **資料庫優化**
   - 使用 PostgreSQL 取代 SQLite
   - 檢查資料庫索引設定
   - 考慮資料庫連線池設定

3. **快取設定**
   - 確認 Redis 正常運行
   - 檢查 Redis 記憶體使用情況

### 6.6 Ingress 無法存取

**問題：** 無法透過 Ingress 網址存取 Label Studio

**檢查步驟：**

```bash
# 檢查 Ingress 狀態
kubectl get ingress

# 檢查 Ingress Controller
kubectl get pods -n ingress-nginx

# 檢查 Service
kubectl get svc -l app=label-studio
```

**解決方案：**

1. 確認 Ingress Controller 已安裝並運行
2. 檢查 Ingress 設定中的 host 和 path
3. 確認 TLS 憑證已正確設定
4. 檢查 DNS 設定是否指向正確的 IP

### 6.7 日誌查看

**查看應用程式日誌：**

```bash
# 查看所有 Label Studio Pod 日誌
kubectl logs -l app=label-studio --tail=100 -f

# 查看特定 Pod 日誌
kubectl logs <pod-name> --tail=100 -f

# 查看前一個容器的日誌（如 Pod 重啟）
kubectl logs <pod-name> --previous
```

**查看資料庫日誌：**

```bash
# PostgreSQL 日誌
kubectl logs <postgres-pod-name>
```

**查看 Redis 日誌：**

```bash
# Redis 日誌
kubectl logs <redis-pod-name>
```

---

## 7. 維護與升級

### 7.1 備份資料

#### 7.1.1 備份資料庫

```bash
# 備份 PostgreSQL（如使用內建 PostgreSQL）
kubectl exec -it <postgres-pod> -- \
  pg_dump -U labelstudio labelstudio > backup.sql

# 或使用 kubectl cp 複製備份檔案
kubectl exec <postgres-pod> -- \
  pg_dump -U labelstudio labelstudio | \
  kubectl exec -i <postgres-pod> -- cat > backup.sql
```

#### 7.1.2 備份持久化儲存

```bash
# 如使用 Volume 儲存
kubectl get pvc
# 備份 PVC 資料（需使用對應的備份工具）

# 如使用雲端儲存，直接備份雲端儲存內容
```

### 7.2 升級 Label Studio

#### 7.2.1 檢查可用版本

```bash
# 更新 Helm repository
helm repo update heartex

# 查看可用版本
helm search repo heartex/label-studio --versions
```

#### 7.2.2 執行升級

```bash
# 1. 備份現有設定和資料
kubectl get secret,configmap -l app=label-studio -o yaml > backup-config.yaml

# 2. 更新 ls-values.yaml 中的 image tag
# 編輯 ls-values.yaml，將 tag 更新為目標版本

# 3. 執行升級
helm upgrade label-studio heartex/label-studio -f ls-values.yaml

# 4. 檢查升級狀態
kubectl get pods -l app=label-studio
kubectl rollout status deployment/<release-name>-ls-app
```

#### 7.2.3 回滾升級

```bash
# 查看升級歷史
helm history label-studio

# 回滾到上一個版本
helm rollback label-studio <revision-number>
```

### 7.3 擴展部署

#### 7.3.1 水平擴展

```yaml
# 在 ls-values.yaml 中調整
app:
  replicas: 3  # 增加 Pod 數量
```

```bash
# 或使用 kubectl 直接擴展
kubectl scale deployment <release-name>-ls-app --replicas=3
```

#### 7.3.2 垂直擴展

```yaml
# 在 ls-values.yaml 中調整資源
app:
  resources:
    requests:
      memory: "2048Mi"  # 增加記憶體
      cpu: "2000m"      # 增加 CPU
    limits:
      memory: "8192Mi"
      cpu: "4000m"
```

### 7.4 監控與告警

建議設定以下監控指標：

- **Pod 狀態**：Pod 是否正常運行
- **資源使用**：CPU、記憶體使用率
- **資料庫連線**：資料庫連線數和回應時間
- **API 回應時間**：API 端點回應時間
- **錯誤率**：應用程式錯誤率

可使用 Prometheus 和 Grafana 進行監控，或整合現有的監控系統。

---

## 附錄

### A. 常用命令參考

```bash
# 查看所有資源
kubectl get all -l app=label-studio

# 進入 Pod 執行命令
kubectl exec -it <pod-name> -- /bin/bash

# 查看設定
kubectl get configmap -l app=label-studio -o yaml

# 查看 Secret（不顯示內容）
kubectl get secret -l app=label-studio

# 重啟部署
kubectl rollout restart deployment/<release-name>-ls-app

# 查看事件
kubectl get events --sort-by='.lastTimestamp'
```

### B. 參考資源

- **官方文件**：<https://labelstud.io/guide/>
- **GitHub Repository**：<https://github.com/HumanSignal/label-studio>
- **Helm Chart**：<https://charts.heartex.com/>
- **社群支援**：<https://slack.labelstud.io/>

### C. 版本資訊

- **文件版本**：1.0
- **Label Studio 版本**：1.23.0.dev0
- **最後更新**：2025年11月

---

**注意事項：**

1. 生產環境部署時，務必設定 `SSRF_PROTECTION_ENABLED=true`
2. 敏感資訊（如 API Key、密碼）應使用 Kubernetes Secret 管理，避免直接寫在 values.yaml
3. 定期備份資料庫和持久化儲存
4. 監控系統資源使用情況，適時調整資源配置
5. 保持 Label Studio 和相關依賴套件更新至最新穩定版本
