# Label-Studio-使用說明

## 1. 簡介
Label Studio 是一款開源的資料標註工具，支援影像、音訊、文字、影片等多種資料類型。本文件旨在協助技術人員進行 Label Studio 的安裝、部署與維運。

- **專案網頁**：<https://github.com/HumanSignal/label-studio>
- **參考網頁**：<https://deepwiki.com/HumanSignal/label-studio>
- **目標讀者**：負責部署與維護的 DevOps 工程師及系統管理員。

## 2. 環境變數詳解 (Environment Variables)
以下列出 Label Studio 核心與整合相關的環境變數。

| 變數名稱 | 預設值 | 必填 | 說明 |
| :--- | :--- | :--- | :--- |
| `LABEL_STUDIO_HOST` | `http://localhost:8080` | 否 | 應用程式的外部存取網址 (用於產生連結)。 |
| `DJANGO_DB` | `default` (sqlite) | 否 | 資料庫類型，生產環境建議設為 `postgresql`。 |
| `POSTGRE_HOST` | `localhost` | 否 | PostgreSQL 主機位址 (當 `DJANGO_DB=postgresql` 時必填)。 |
| `POSTGRE_PORT` | `5432` | 否 | PostgreSQL 連接埠。 |
| `POSTGRE_NAME` | `postgres` | 否 | 資料庫名稱。 |
| `POSTGRE_USER` | `postgres` | 否 | 資料庫使用者名稱。 |
| `POSTGRE_PASSWORD` | - | 否 | 資料庫密碼。 |
| `LOG_LEVEL` | `DEBUG` | 否 | 日誌等級 (`DEBUG`, `INFO`, `WARNING`, `ERROR`)。 |
| `SSRF_PROTECTION_ENABLED` | `False` | 否 | 是否開啟 SSRF 防護 (建議生產環境開啟)。 |
| `LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK` | `False` | 否 | 是否禁止未經邀請的註冊。 |

### LLM 整合 (Azure OpenAI)
若需整合 Azure OpenAI 進行預標註或輔助標註，請設定以下變數：

| 變數名稱 | 範例值 | 說明 |
| :--- | :--- | :--- |
| `AZURE_OPENAI_API_KEY` | `sk-...` | Azure OpenAI 的 API Key。 |
| `AZURE_OPENAI_ENDPOINT` | `https://my-resource.openai.azure.com/` | Azure OpenAI 的 Endpoint URL。 |
| `OPENAI_API_VERSION` | `2023-05-15` | 使用的 API 版本。 |
| `AZURE_DEPLOYMENT_NAME` | `gpt-4-turbo` | (選填) 預設使用的模型部署名稱。 |

## 3. 安裝與部署 (Installation & Deployment)

### 3.1 Docker Compose (推薦用於單機部署)
專案根目錄已包含 `docker-compose.yml`，整合了 Nginx 與 PostgreSQL。

```bash
# 啟動服務
docker-compose up -d

# 停止服務
docker-compose down
```

### 3.2 Kubernetes Helm 部署
針對 K8s 環境，請參考以下 Helm Chart 配置範例。

#### Deployment (deployment.yaml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: label-studio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: label-studio
  template:
    metadata:
      labels:
        app: label-studio
    spec:
      containers:
      - name: label-studio
        image: heartexlabs/label-studio:latest
        ports:
        - containerPort: 8080
        env:
        - name: LABEL_STUDIO_HOST
          value: "http://label-studio.local"
        - name: DJANGO_DB
          value: "postgresql"
        # 請補上 PostgreSQL 相關變數
        volumeMounts:
        - name: data-storage
          mountPath: /label-studio/data
      volumes:
      - name: data-storage
        persistentVolumeClaim:
          claimName: label-studio-pvc
```

#### Service (service.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: label-studio-svc
spec:
  type: NodePort
  selector:
    app: label-studio
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
      nodePort: 30080
```

#### PersistentVolumeClaim (pvc.yaml) - NFS 範例
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: label-studio-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client  # 請根據實際環境調整 StorageClass
  resources:
    requests:
      storage: 10Gi
```

### 3.3 Python 套件安裝 (本機開發)
若需在本機直接執行 Python 環境：

**使用 Pip:**
```bash
pip install label-studio
label-studio start
```

**使用 Poetry:**
```bash
# 安裝相依套件
poetry install

# 啟動服務
poetry run label-studio start
```

## 4. 操作指南 (Operations)

### 基本操作
- **啟動服務**：`label-studio start` (預設 Port 8080)。
- **建立帳號**：首次啟動後，瀏覽器開啟 `http://localhost:8080` 即可註冊管理員帳號。
- **重置密碼**：`label-studio reset_password`。

### 進階設定 (LLM Integration)
要啟用 Azure OpenAI 整合：
1. 確認上述 `AZURE_OPENAI_*` 環境變數已正確設定。
2. 在 Label Studio 專案設定中，選擇 "Machine Learning"。
3. 新增 ML Backend，若使用官方整合，通常無需額外執行 ML Backend 容器，直接在 UI 設定 Prompt 即可 (視版本而定，新版支援 Prompt Learning)。
4. 若需自定義 Model，請參考 `label-studio-ml-backend` 專案。

### 故障排除 (Troubleshooting)

- **Azure 連線錯誤 (401/404)**：
    - 檢查 `AZURE_OPENAI_ENDPOINT` 是否包含 `https://`。
    - 確認 `AZURE_OPENAI_API_KEY` 是否過期。
    - 確認 Deployment Name 是否與 Azure Portal 上的一致。

- **NFS 掛載失敗**：
    - 檢查 K8s Node 是否已安裝 `nfs-common`。
    - 確認 PVC 的 `accessModes` 是否為 `ReadWriteMany` (若多個 Pod 共用)。
    - 檢查 `label-studio/data` 目錄權限，建議設為 `777` 或 `1000:1000`。

- **Python 套件相依性問題**：
    - 若遇 `ModuleNotFoundError`，請嘗試 `pip install -r requirements.txt`。
    - Windows 環境請確保已安裝 `lxml` 的 binary 版本。

## 5. 範例與截圖 (Examples)
> [圖片說明：此處應顯示 Label Studio 登入畫面]

> [圖片說明：此處應顯示專案建立與 Template 選擇畫面]

**範例 API 呼叫 (建立專案):**
```bash
curl -X POST http://localhost:8080/api/projects/ \
  -H 'Authorization: Token <YOUR_API_KEY>' \
  -d '{"title": "My New Project"}'
```
