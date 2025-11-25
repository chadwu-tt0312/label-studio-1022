# Label Studio 使用說明

本文為技術人員提供在 Kubernetes (k8s) 環境中部署、維護 Label Studio 的詳細指南。

## 1. 安裝與部署 (Kubernetes)

官方建議使用 Helm 3 在 Kubernetes 上進行部署。

### 1.1. 前提條件

- Kubernetes v1.17+
- Helm v3.6.3+
- `kubectl` 已設定並連接到您的 Kubernetes 叢集

### 1.2. 新增 Helm Chart Repository

```sh
helm repo add heartex https://charts.heartex.com/
helm repo update heartex
```

### 1.3. 設定 `values.yaml`

Label Studio 的所有設定都透過 `values.yaml` 檔案進行管理。您可以建立一個 `ls-values.yaml` 檔案來覆寫預設值。

一個重要的正式環境設定是啟用 SSRF 保護：

```yaml
# ls-values.yaml
global:
  app:
    extraVars:
      - name: SSRF_PROTECTION_ENABLED
        value: "true"
```

您可以在 `helm_values.md` 文件中找到所有可用的設定選項。

### 1.4. 安裝

執行以下命令來安裝 Label Studio：

```sh
helm install <RELEASE_NAME> heartex/label-studio -f ls-values.yaml
```

將 `<RELEASE_NAME>` 替換成您的發行版名稱，例如 `label-studio`。

### 1.5. 升級與卸載

**升級：**

```sh
helm upgrade <RELEASE_NAME> heartex/label-studio -f ls-values.yaml
```

**卸載：**

```sh
helm delete <RELEASE_NAME>
```

---

## 2. 基本操作

部署完成後，您可以透過 Ingress 或 Port Forward 存取 Label Studio UI。

1.  **建立帳號**：首次進入需註冊管理員帳號。
2.  **建立專案**：登入後，點擊 "Create Project" 開始一個新專案。
3.  **匯入資料**：進入專案後，點擊 "Import" 上傳您的資料。支援檔案上傳、URL 或從雲端儲存匯入。
4.  **設定標籤介面**：在 "Settings > Labeling Interface" 中，使用 XML-based 的標籤語言自訂您的標籤工具。
5.  **開始標籤**：回到專案主頁，點擊 "Label All Tasks" 開始標註。

---

## 3. 進階設定

### 3.1. 雲端儲存設定

Label Studio 可以直接連接到雲端儲存服務來讀取來源資料或儲存標註結果。

#### **通用設定**

在專案的 "Settings > Cloud Storage" 中，您可以新增來源 (Source) 或目標 (Target) 儲存。設定時，您可以在 UI 中直接填寫憑證，或將其設定為環境變數，讓 Label Studio 自動讀取。

#### **AWS S3**

-   **環境變數**:
    -   `AWS_ACCESS_KEY_ID`
    -   `AWS_SECRET_ACCESS_KEY`
    -   `AWS_SESSION_TOKEN` (選用)
    -   `AWS_DEFAULT_REGION`
    -   `S3_ENDPOINT` (用於 S3 相容儲存，如 MinIO)

#### **Google Cloud Storage (GCS)**

-   **環境變數**:
    -   `GOOGLE_APPLICATION_CREDENTIALS`: 指向您的 Service Account JSON 檔案路徑。
    -   `GOOGLE_PROJECT_ID` (可選，也可在 UI 中設定)

#### **Microsoft Azure Blob**

-   **環境變數**:
    -   `AZURE_BLOB_ACCOUNT_NAME`
    -   `AZURE_BLOB_ACCOUNT_KEY`

### 3.2. LLM / 機器學習整合

Label Studio 透過一個獨立的 **ML Backend** 服務來整合機器學習模型，實現預標註 (pre-labeling) 和互動式標註。

#### **運作方式**

1.  **啟動 ML Backend**：您需要從官方 `label-studio-ml-backend` Repository 中選擇或建立一個模型服務，並用 Docker 啟動它。
2.  **連接 Label Studio**：在 Label Studio 專案的 "Settings > Model" 中，將 ML Backend 的 URL (例如 `http://my-ml-backend:9090`) 新增進去。

#### **範例：整合 OpenAI (GPT)**

1.  Clone ML Backend 專案：
    ```sh
    git clone https://github.com/HumanSignal/label-studio-ml-backend.git
    cd label-studio-ml-backend/label_studio_ml/examples/llm_interactive
    ```

2.  設定 `docker-compose.yml`，填入您的 OpenAI API 金鑰：
    ```yaml
    # docker-compose.yml
    environment:
      - OPENAI_API_KEY=<YOUR_OPENAI_API_KEY>
    ```

3.  啟動 ML Backend：
    ```sh
    docker-compose up
    ```

4.  在 Label Studio 的模型設定頁面，新增 URL `http://<ml-backend-host>:9090`。

**重要**：為了讓 ML Backend 能回頭存取 Label Studio 的資料，您需要在 ML Backend 的環境中設定以下變數：
-   `LABEL_STUDIO_URL`: Label Studio 的存取 URL。
-   `LABEL_STUDIO_API_KEY`: 您的 Label Studio 個人帳戶 API 金鑰。

---

## 4. 環境變數總覽

以下是在部署 Label Studio 時最常用到的環境變數。

### **資料庫 (PostgreSQL)**

-   `DJANGO_DB`: 設為 `default` 以啟用 PostgreSQL。
-   `POSTGRE_NAME`: 資料庫名稱。
-   `POSTGRE_USER`: 使用者名稱。
-   `POSTGRE_PASSWORD`: 密碼。
-   `POSTGRE_PORT`: 連接埠 (預設 `5432`)。
-   `POSTGRE_HOST`: 主機位址。

### **雲端儲存**

-   `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `S3_ENDPOINT`
-   `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_PROJECT_ID`
-   `AZURE_BLOB_ACCOUNT_NAME`, `AZURE_BLOB_ACCOUNT_KEY`

### **安全性**

-   `SSRF_PROTECTION_ENABLED`: 在正式環境中應設為 `true`。

### **ML Backend 連接**

-   `LABEL_STUDIO_URL`
-   `LABEL_STUDIO_API_KEY`

---

## 5. 故障排除

### **ML Backend 無法連接到 Label Studio**

如果您在 Docker 容器中同時執行 Label Studio 和 ML Backend，ML Backend 的 `LABEL_STUDIO_URL` 不能使用 `localhost`。請使用 Docker 的內部網路 IP 或 `host.docker.internal`。

### **權限問題**

當掛載外部 volume (例如 `NFS`) 來持久化資料時，請確保執行的容器使用者 (UID 1001) 有權限讀寫該目錄。

### **Helm 安裝失敗**

-   檢查您的 `ls-values.yaml` 語法是否正確。
-   使用 `helm template . -f ls-values.yaml` 在本地端渲染模板，檢查輸出的 Kubernetes manifests 是否符合預期。
