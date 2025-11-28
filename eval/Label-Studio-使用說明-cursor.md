# Label-Studio 使用說明

**專案名稱**：Label Studio  
**專案網頁**：<https://github.com/HumanSignal/label-studio>  
**參考網頁**：<https://deepwiki.com/HumanSignal/label-studio>  
**版本**：v1.23.0.dev0

---

## 1. 簡介

### 專案功能與架構

Label Studio 是一個開源的資料標註工具，主要功能包括：

- **多資料類型標註**：支援影像、音訊、文字、HTML、影片、時間序列等
- **多人協作**：內建多使用者系統，支援專案與任務分配
- **ML 模型整合**：支援預標註、線上學習、主動學習
- **雲端儲存整合**：支援 AWS S3、Google Cloud Storage、Azure Blob Storage
- **REST API**：完整的 OpenAPI 3.0 規格，支援 Webhook

**技術架構**：
- **後端**：Django 5.1+ (Python 3.10+)
- **前端**：React + MobX State Tree
- **資料庫**：PostgreSQL（生產環境推薦）/ MySQL / SQLite（開發環境）
- **部署**：支援 Docker、Docker Compose、pip、poetry

**目標讀者**：負責部署與維護的技術人員

---

## 2. 環境變數詳解 (Environment Variables)

本節列出 Label Studio 支援的主要環境變數。變數可透過 `.env` 檔案或系統環境變數設定。

### 基礎設定

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `HOST` | - | 否 | 完整主機名稱（需包含 `http://` 或 `https://`），例如：`https://labelstudio.example.com` |
| `LABEL_STUDIO_HOST` | - | 否 | 同 `HOST`，用於 Nginx 設定 |
| `BASE_DATA_DIR` | `~/.label-studio` | 否 | 資料目錄路徑（資料庫、媒體檔案存放位置） |
| `DEBUG` | `False` | 否 | 啟用除錯模式（布林值：`True`/`False`） |
| `LOG_LEVEL` | `WARNING` | 否 | 日誌等級：`DEBUG`、`INFO`、`WARNING`、`ERROR` |
| `JSON_LOG` | `False` | 否 | 使用 JSON 格式日誌（布林值） |

### 資料庫設定

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `DJANGO_DB` | `default` | 否 | 資料庫類型：`default`（PostgreSQL）、`sqlite`、`mysql` |
| `POSTGRE_USER` | `postgres` | 是* | PostgreSQL 使用者名稱（*使用 PostgreSQL 時必填） |
| `POSTGRE_PASSWORD` | `postgres` | 是* | PostgreSQL 密碼 |
| `POSTGRE_NAME` | `postgres` | 是* | PostgreSQL 資料庫名稱 |
| `POSTGRE_HOST` | `localhost` | 是* | PostgreSQL 主機位址 |
| `POSTGRE_PORT` | `5432` | 否 | PostgreSQL 連接埠 |
| `MYSQL_USER` | `root` | 是** | MySQL 使用者名稱（**使用 MySQL 時必填） |
| `MYSQL_PASSWORD` | - | 是** | MySQL 密碼 |
| `MYSQL_NAME` | `labelstudio` | 是** | MySQL 資料庫名稱 |
| `MYSQL_HOST` | `localhost` | 是** | MySQL 主機位址 |
| `MYSQL_PORT` | `3306` | 否 | MySQL 連接埠 |
| `DATABASE_NAME` | `{BASE_DATA_DIR}/label_studio.sqlite3` | 否 | SQLite 資料庫檔案路徑（僅 SQLite） |

### 安全性設定

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `SESSION_COOKIE_SECURE` | `False` | 否 | 僅透過 HTTPS 傳送 Session Cookie（生產環境建議設為 `True`） |
| `CSRF_COOKIE_SECURE` | 同 `SESSION_COOKIE_SECURE` | 否 | 僅透過 HTTPS 傳送 CSRF Cookie |
| `CSRF_COOKIE_HTTPONLY` | 同 `SESSION_COOKIE_SECURE` | 否 | CSRF Cookie 僅允許 HTTP 存取 |
| `ALLOWED_HOSTS` | `*` | 否 | 允許的主機名稱（逗號分隔），生產環境應明確指定 |
| `CORS_ALLOW_ALL_ORIGINS` | `True` | 否 | 允許所有來源的 CORS 請求（生產環境建議設為 `False`） |
| `CORS_ALLOWED_ORIGINS` | - | 否 | 允許的 CORS 來源（逗號分隔），例如：`https://app.example.com,https://api.example.com` |
| `DISABLE_SIGNUP_WITHOUT_LINK` | `False` | 否 | 停用公開註冊（需邀請連結） |

### 雲端儲存設定

#### AWS S3

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `STORAGE_TYPE` | - | 否 | 設為 `s3` 啟用 S3 儲存 |
| `STORAGE_AWS_ACCESS_KEY_ID` | - | 是* | AWS Access Key ID |
| `STORAGE_AWS_SECRET_ACCESS_KEY` | - | 是* | AWS Secret Access Key |
| `STORAGE_AWS_BUCKET_NAME` | - | 是* | S3 Bucket 名稱 |
| `STORAGE_AWS_REGION` | - | 否 | AWS 區域（例如：`us-east-1`） |

#### Google Cloud Storage

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `GOOGLE_APPLICATION_CREDENTIALS` | - | 是* | GCS 服務帳號 JSON 憑證檔案路徑 |
| `GOOGLE_STORAGE_BUCKET_NAME` | - | 是* | GCS Bucket 名稱 |

#### Azure Blob Storage

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `AZURE_BLOB_ACCOUNT_NAME` | - | 是* | Azure Storage Account 名稱 |
| `AZURE_BLOB_ACCOUNT_KEY` | - | 是* | Azure Storage Account Key |
| `AZURE_BLOB_CONTAINER_NAME` | - | 是* | Azure Blob Container 名稱 |

### Azure OpenAI 整合設定

Label Studio 支援透過 Azure OpenAI 進行 LLM 互動式標註。設定方式如下：

#### 方式 1：透過環境變數（ML Backend）

若使用 `label-studio-ml-backend` 的 `llm_interactive` 範例：

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `OPENAI_PROVIDER` | `openai` | 否 | 提供者：`openai`、`azure`、`ollama` |
| `OPENAI_API_KEY` | - | 是 | Azure OpenAI API Key |
| `AZURE_OPENAI_ENDPOINT` | - | 是* | Azure OpenAI 端點 URL（例如：`https://your-resource.openai.azure.com/`） |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | - | 是* | Azure OpenAI Deployment 名稱 |
| `OPENAI_API_VERSION` | `2024-02-15-preview` | 否 | Azure OpenAI API 版本 |

#### 方式 2：透過 Label Studio UI（Model Provider Connection）

在 Label Studio 管理介面中設定：

1. 進入 **Settings** → **Model Providers**
2. 建立新的 **Azure OpenAI** 連線
3. 填入以下欄位：
   - **API Key**：Azure OpenAI API Key
   - **Endpoint**：Azure OpenAI 端點 URL
   - **Deployment Name**：Deployment 名稱

**注意**：
- 每個 Azure OpenAI Deployment 對應單一模型
- 如需使用多個模型，需建立多個 Deployment 並分別設定連線
- API Version 通常使用預設值即可，除非 Azure 端有特殊要求

### 其他重要設定

| 變數名稱 | 預設值 | 必填 | 說明 |
|---------|--------|------|------|
| `EMAIL_BACKEND` | `django.core.mail.backends.dummy.EmailBackend` | 否 | Email 後端（生產環境需設定 SMTP） |
| `FROM_EMAIL` | `Label Studio <hello@labelstud.io>` | 否 | 發送 Email 的寄件者 |
| `REDIS_HOST` | `localhost` | 否 | Redis 主機（用於 RQ 任務佇列） |
| `REDIS_PORT` | `6379` | 否 | Redis 連接埠 |
| `SENTRY_DSN` | - | 否 | Sentry DSN（錯誤追蹤） |
| `FEATURE_FLAGS_OFFLINE` | `True` | 否 | 使用離線模式的功能標籤 |

---

## 3. 安裝與部署 (Installation & Deployment)

### 3.1 套件安裝

#### 使用 pip 安裝

```bash
# 需求：Python >= 3.10
pip install label-studio

# 啟動服務（預設 http://localhost:8080）
label-studio
```

#### 使用 poetry 安裝

```bash
# 安裝 poetry（如未安裝）
pip install poetry

# 建立專案並安裝 Label Studio
poetry new my-label-studio
cd my-label-studio
poetry add label-studio

# 啟動 poetry 環境
poetry shell

# 啟動服務
label-studio
```

#### 本機開發模式

```bash
# 安裝依賴
pip install poetry
poetry install

# 執行資料庫遷移
python label_studio/manage.py migrate

# 收集靜態檔案
python label_studio/manage.py collectstatic

# 啟動開發伺服器（http://localhost:8080）
python label_studio/manage.py runserver
```

### 3.2 Docker 部署

#### 使用 Docker 執行

```bash
# 拉取官方映像檔
docker pull heartexlabs/label-studio:latest

# 執行容器（資料目錄掛載到 ./mydata）
docker run -it -p 8080:8080 \
  -v $(pwd)/mydata:/label-studio/data \
  heartexlabs/label-studio:latest
```

#### 使用 Docker Compose 部署（生產環境推薦）

專案包含 `docker-compose.yml`，提供完整的生產環境堆疊：

- **Label Studio**：應用程式服務
- **Nginx**：反向代理與靜態檔案服務
- **PostgreSQL**：生產級資料庫

**部署步驟**：

```bash
# 1. 建立環境變數檔案（可選）
cat > .env << EOF
LABEL_STUDIO_HOST=https://labelstudio.example.com
POSTGRE_PASSWORD=your_secure_password
EOF

# 2. 啟動服務
docker-compose up -d

# 3. 查看日誌
docker-compose logs -f app

# 4. 停止服務
docker-compose down
```

**docker-compose.yml 結構**：
- **nginx**：監聽 8080/8081 埠，代理至 app 服務
- **app**：Label Studio 應用程式（uwsgi），連接 PostgreSQL
- **db**：PostgreSQL 13 資料庫

**資料持久化**：
- 應用程式資料：`./mydata`（掛載至容器內的 `/label-studio/data`）
- PostgreSQL 資料：`./postgres-data`（可透過 `POSTGRES_DATA_DIR` 環境變數自訂）

### 3.3 Kubernetes Helm 部署

由於專案包含 `Dockerfile` 與 `docker-compose.yml`，可建立 Helm Chart 進行 Kubernetes 部署。

#### 建立 Helm Chart 結構

```bash
# 建立 Chart 目錄
mkdir -p label-studio-helm/charts/label-studio
cd label-studio-helm/charts/label-studio
```

#### Chart 範例配置

**Chart.yaml**：
```yaml
apiVersion: v2
name: label-studio
description: Label Studio Helm Chart
version: 1.0.0
appVersion: "1.23.0"
```

**values.yaml**（關鍵設定）：
```yaml
service:
  type: NodePort
  port: 8080

persistence:
  enabled: true
  storageClass: nfs-client
  accessMode: ReadWriteMany
  size: 50Gi

postgresql:
  enabled: true
  auth:
    postgresPassword: "changeme"
  persistence:
    enabled: true
    storageClass: nfs-client
    size: 20Gi
```

**deployment.yaml**（範例片段）：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: label-studio
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: label-studio
        image: heartexlabs/label-studio:latest
        env:
        - name: DJANGO_DB
          value: "default"
        - name: POSTGRE_HOST
          value: "label-studio-postgresql"
        volumeMounts:
        - name: data
          mountPath: /label-studio/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: label-studio-data
```

**service.yaml**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: label-studio
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  selector:
    app: label-studio
```

**persistentVolumeClaim.yaml**（NFS 範例）：
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: label-studio-data
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 50Gi
```

**部署指令**：
```bash
# 安裝 Chart
helm install label-studio ./label-studio-helm/charts/label-studio

# 升級
helm upgrade label-studio ./label-studio-helm/charts/label-studio

# 卸載
helm uninstall label-studio
```

**注意**：
- 需預先設定 NFS StorageClass
- 建議使用 Ingress 而非 NodePort（生產環境）
- 需設定 PostgreSQL 連線資訊

---

## 4. 操作指南 (Operations)

### 4.1 基本操作

#### 啟動服務

**Docker Compose**：
```bash
docker-compose up -d
```

**本機開發**：
```bash
python label_studio/manage.py runserver
```

**Docker**：
```bash
docker run -it -p 8080:8080 \
  -v $(pwd)/mydata:/label-studio/data \
  heartexlabs/label-studio:latest
```

#### 建立管理員帳號

```bash
# 透過 Django shell
python label_studio/manage.py shell
```

```python
from users.models import User
User.objects.create_superuser('admin@example.com', 'your_password')
```

或透過 Web UI 首次登入時註冊。

#### 資料庫遷移

```bash
python label_studio/manage.py migrate
```

#### 收集靜態檔案

```bash
python label_studio/manage.py collectstatic
```

### 4.2 進階設定

#### Azure OpenAI 整合設定

##### 步驟 1：在 Azure 建立資源

1. 登入 [Azure Portal](https://portal.azure.com)
2. 建立 **Azure OpenAI** 資源
3. 在 **Azure OpenAI Studio** 建立 Deployment（例如：`gpt-4`、`gpt-35-turbo`）
4. 取得以下資訊：
   - **Endpoint**：`https://your-resource.openai.azure.com/`
   - **API Key**：在資源的 **Keys and Endpoint** 頁面取得
   - **Deployment Name**：在 **Deployments** 頁面查看
   - **API Version**：通常為 `2024-02-15-preview`（可在 API 文件中確認）

##### 步驟 2：在 Label Studio 中設定

**方法 A：透過 UI 設定（推薦）**

1. 登入 Label Studio
2. 進入 **Settings** → **Model Providers**
3. 點選 **Add Provider Connection**
4. 選擇 **Azure OpenAI**
5. 填入以下欄位：
   - **API Key**：Azure OpenAI API Key
   - **Endpoint**：`https://your-resource.openai.azure.com/`
   - **Deployment Name**：例如 `gpt-4`
6. 選擇 **Scope**：Organization（組織層級）或 User（使用者層級）
7. 儲存設定

**方法 B：透過環境變數設定（ML Backend）**

若使用 `label-studio-ml-backend` 的 `llm_interactive` 範例：

```bash
export OPENAI_PROVIDER=azure
export OPENAI_API_KEY=your_azure_openai_api_key
export AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
export AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
export OPENAI_API_VERSION=2024-02-15-preview
```

##### 步驟 3：在專案中使用

1. 建立或編輯標註專案
2. 進入 **Settings** → **Machine Learning**
3. 選擇已設定的 Azure OpenAI 連線
4. 開始使用 LLM 輔助標註

**故障排除**：

| 錯誤訊息 | 可能原因 | 解決方案 |
|---------|---------|---------|
| `401 Unauthorized` | API Key 錯誤 | 檢查 API Key 是否正確 |
| `404 Not Found` | Endpoint 或 Deployment Name 錯誤 | 確認 Endpoint 與 Deployment Name |
| `Rate limit exceeded` | 超過 API 速率限制 | 檢查 Azure 配額，或使用較低速率模型 |

#### 雲端儲存整合

##### AWS S3 整合

1. 建立 S3 Bucket
2. 建立 IAM 使用者並取得 Access Key / Secret Key
3. 在 Label Studio 專案設定中：
   - 進入 **Settings** → **Cloud Storage**
   - 選擇 **Amazon S3**
   - 填入 Bucket 名稱、Access Key、Secret Key、Region
4. 同步資料：點選 **Sync** 按鈕

##### Azure Blob Storage 整合

1. 建立 Azure Storage Account 與 Container
2. 取得 Account Name 與 Account Key
3. 在 Label Studio 專案設定中：
   - 進入 **Settings** → **Cloud Storage**
   - 選擇 **Azure Blob Storage**
   - 填入 Account Name、Account Key、Container Name
4. 同步資料

### 4.3 故障排除 (Troubleshooting)

#### Azure 連線錯誤

**問題**：無法連線至 Azure OpenAI

**排查步驟**：
1. 確認 API Key 正確：在 Azure Portal 的 **Keys and Endpoint** 頁面驗證
2. 確認 Endpoint 格式：應為 `https://your-resource.openai.azure.com/`（注意結尾斜線）
3. 確認 Deployment Name：在 Azure OpenAI Studio 的 **Deployments** 頁面查看
4. 檢查網路連線：確認伺服器可存取 Azure 端點
5. 查看日誌：`docker-compose logs app` 或檢查應用程式日誌

**常見錯誤碼**：
- `401`：認證失敗（API Key 錯誤）
- `404`：資源不存在（Endpoint 或 Deployment Name 錯誤）
- `429`：速率限制（需調整請求頻率或升級 Azure 配額）

#### NFS 掛載失敗

**問題**：Kubernetes 中無法掛載 NFS Volume

**排查步驟**：
1. 確認 NFS Server 可存取：`showmount -e <nfs-server-ip>`
2. 確認 StorageClass 設定正確：`kubectl get storageclass`
3. 檢查 PVC 狀態：`kubectl describe pvc label-studio-data`
4. 確認 Pod 權限：檢查 SecurityContext 設定

#### Python 套件相依性問題

**問題**：安裝時出現套件衝突或版本不符

**解決方案**：
1. 使用 Poetry 管理依賴（推薦）：
   ```bash
   poetry install
   ```

2. 使用虛擬環境：
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # 或
   venv\Scripts\activate  # Windows
   pip install label-studio
   ```

3. 檢查 Python 版本：需 >= 3.10
   ```bash
   python --version
   ```

#### 資料庫連線問題

**問題**：無法連線至 PostgreSQL

**排查步驟**：
1. 確認 PostgreSQL 服務運行：`docker-compose ps db`
2. 檢查連線資訊：確認 `POSTGRE_HOST`、`POSTGRE_USER`、`POSTGRE_PASSWORD`、`POSTGRE_NAME` 正確
3. 測試連線：
   ```bash
   docker-compose exec app python -c "import psycopg2; psycopg2.connect(host='db', user='postgres', password='postgres', dbname='postgres')"
   ```
4. 檢查防火牆：確認應用程式可存取資料庫連接埠（預設 5432）

#### 效能問題

**問題**：大量資料匯入/匯出緩慢

**優化建議**：
1. 使用 PostgreSQL 而非 SQLite（生產環境）
2. 調整批次大小環境變數：
   ```bash
   export IMPORT_BATCH_SIZE=1000
   export EXPORT_BATCH_SIZE=1000
   ```
3. 啟用 Redis 用於任務佇列：
   ```bash
   export REDIS_HOST=redis
   export REDIS_PORT=6379
   ```
4. 增加應用程式資源（CPU/記憶體）

---

## 5. 範例與截圖 (Examples)

### 5.1 基本使用流程

#### 建立專案

> [圖片說明：此處應顯示 Label Studio 首頁，包含「Create Project」按鈕]

1. 登入 Label Studio
2. 點選 **Create Project**
3. 輸入專案名稱與描述
4. 選擇標註模板（例如：Image Classification、Text Classification）
5. 設定標籤（Labels）

#### 匯入資料

**方法 1：檔案上傳**
- 點選 **Import** → **Upload Files**
- 選擇檔案（支援 JSON、CSV、TSV、ZIP、RAR）

**方法 2：雲端儲存**
- 點選 **Import** → **Cloud Storage**
- 選擇已設定的雲端儲存（S3/GCS/Azure Blob）
- 點選 **Sync** 同步資料

**方法 3：API 匯入**
```bash
curl -X POST http://localhost:8080/api/projects/{project_id}/import \
  -H "Authorization: Token {your_token}" \
  -H "Content-Type: application/json" \
  -d '{"tasks": [{"data": {"text": "Sample text to label"}}]}'
```

#### 執行標註

> [圖片說明：此處應顯示標註介面，包含資料內容與標籤選項]

1. 點選專案進入標註介面
2. 查看任務（Task）
3. 選擇標籤並完成標註
4. 點選 **Submit** 提交

#### 匯出標註結果

1. 進入專案 **Settings** → **Export**
2. 選擇匯出格式（例如：JSON、COCO、YOLO）
3. 點選 **Export** 下載

**API 匯出範例**：
```bash
curl -X GET "http://localhost:8080/api/projects/{project_id}/export?format=JSON" \
  -H "Authorization: Token {your_token}" \
  -o annotations.json
```

### 5.2 Azure OpenAI 整合範例

#### 設定 Azure OpenAI 連線（UI）

> [圖片說明：此處應顯示 Model Providers 設定頁面，包含 Azure OpenAI 連線表單]

1. **Settings** → **Model Providers** → **Add Provider Connection**
2. 選擇 **Azure OpenAI**
3. 填入連線資訊（見 4.2 節）
4. 儲存

#### 在專案中使用 LLM 輔助標註

> [圖片說明：此處應顯示標註介面，包含 LLM 預測結果與互動選項]

1. 建立或編輯專案
2. **Settings** → **Machine Learning** → 選擇 Azure OpenAI 連線
3. 在標註介面中，LLM 會提供預測建議
4. 可接受、修改或拒絕建議

### 5.3 REST API 使用範例

#### 取得 API Token

1. 登入 Label Studio
2. **Account & Settings** → **Access Token**
3. 複製 Token

#### 建立專案（API）

```bash
curl -X POST http://localhost:8080/api/projects \
  -H "Authorization: Token {your_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Project",
    "description": "Project description",
    "label_config": "<View><Text name=\"text\" value=\"$text\"/><Choices name=\"label\" toName=\"text\"><Choice value=\"positive\"/><Choice value=\"negative\"/></Choices></View>"
  }'
```

#### 匯入任務（API）

```bash
curl -X POST http://localhost:8080/api/projects/{project_id}/import \
  -H "Authorization: Token {your_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "tasks": [
      {"data": {"text": "This is a positive review"}},
      {"data": {"text": "This is a negative review"}}
    ]
  }'
```

#### 取得標註結果（API）

```bash
curl -X GET "http://localhost:8080/api/projects/{project_id}/export?format=JSON" \
  -H "Authorization: Token {your_token}"
```

---

## 附錄：常用指令速查

### Docker Compose

```bash
# 啟動服務
docker-compose up -d

# 查看日誌
docker-compose logs -f app

# 停止服務
docker-compose down

# 重建映像檔
docker-compose build --no-cache

# 執行資料庫遷移
docker-compose exec app python label_studio/manage.py migrate
```

### Django 管理指令

```bash
# 資料庫遷移
python label_studio/manage.py migrate

# 建立超級使用者
python label_studio/manage.py createsuperuser

# 收集靜態檔案
python label_studio/manage.py collectstatic

# Django Shell
python label_studio/manage.py shell
```

### 備份與還原

```bash
# 備份資料庫（PostgreSQL）
docker-compose exec db pg_dump -U postgres postgres > backup.sql

# 還原資料庫
docker-compose exec -T db psql -U postgres postgres < backup.sql

# 備份資料目錄
tar -czf label-studio-data-backup.tar.gz ./mydata
```
