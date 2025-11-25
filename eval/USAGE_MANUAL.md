# Label Studio 使用說明

本文件為技術人員提供在生產環境中部署、維護及使用 Label Studio 的詳細指南。

## 1. 目標讀者

本文件主要提供給負責在 Kubernetes 環境中部署與維護 Label Studio 的技術人員（如 DevOps、SRE 或後端工程師）。

## 2. 系統需求

在開始部署之前，請確保您的環境滿足以下條件：

*   **Kubernetes Cluster**: 一個可用的 Kubernetes 叢集。
*   **Helm**: Helm 3 或更高版本。
*   **NFS Server**: 一個已設定好的 NFS 伺服器，用於提供持久化儲存。
*   **PostgreSQL Database**: 一個獨立的 PostgreSQL 資料庫（建議用於生產環境）。

## 3. 安裝與部署 (Kubernetes with Helm)

我們建議使用官方的 Helm Chart 進行生產環境部署。官方 Chart 位於獨立的 repository。

### 3.1. 新增 Helm Repository

首先，將 Label Studio 的官方 Helm repository 加入到您的 Helm 設定中：

```bash
helm repo add heartex https://charts.heartex.com/
helm repo update
```

### 3.2. 設定 NFS Persistent Volume

為了確保資料（如上傳的檔案和專案資訊）在 Pod 重啟後依然存在，您需要設定持久化儲存。以下是如何為 NFS 設定 `PersistentVolume` (PV) 和 `PersistentVolumeClaim` (PVC) 的範例。

1.  **建立 `ls-pv.yaml`**

    請根據您的 NFS 伺服器設定修改 `path` 和 `server` 欄位。

    ```yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: label-studio-pv
    spec:
      capacity:
        storage: 20Gi # 根據您的需求調整大小
      volumeMode: Filesystem
      accessModes:
        - ReadWriteMany # 對於 NFS，建議使用 ReadWriteMany
      persistentVolumeReclaimPolicy: Retain
      nfs:
        path: /path/to/your/nfs/share # NFS 伺服器上的路徑
        server: your-nfs-server-ip # NFS 伺服器的 IP 或主機名
    ```

2.  **建立 `ls-pvc.yaml`**

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: label-studio-pvc
    spec:
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 20Gi # 應與 PV 的大小相符
      volumeName: label-studio-pv
    ```

3.  **在 Kubernetes 中建立 PV 和 PVC**

    ```bash
    kubectl apply -f ls-pv.yaml
    kubectl apply -f ls-pvc.yaml
    ```

### 3.3. 設定 Helm Chart (`values.yaml`)

建立一個 `values.yaml` 檔案來自訂您的部署。以下是一個針對 NFS 和外部 PostgreSQL 的建議設定：

```yaml
# values.yaml

global:
  # -- 連接到外部 PostgreSQL 資料庫
  pgConfig:
    host: "your-postgres-host"
    port: 5432
    dbName: "labelstudio"
    userName: "user"
    password:
      secretName: "postgresql-secret" # 包含資料庫密碼的 k8s secret
      secretKey: "password"

  # -- 使用我們預先建立的 PVC
  persistence:
    enabled: true
    type: volume
    config:
      volume:
        existingClaim: "label-studio-pvc" # 指定您剛才建立的 PVC
        # 注意：Label Studio 的資料將會被掛載到 Pod 內的 /label-studio/data 路徑

  # -- 透過 extraEnvironmentVars 傳遞額外的環境變數
  extraEnvironmentVars:
    # 建議在生產環境中啟用，以防止 SSRF 攻擊
    SSRF_PROTECTION_ENABLED: "true"
    # 設定應用程式主機名，用於生成正確的資源 URL
    HOST: "https://your-label-studio-domain.com"

# -- 停用內建的 PostgreSQL sub-chart
postgresql:
  enabled: false

# -- 停用內建的 Redis sub-chart (如果使用外部 Redis)
redis:
  enabled: false # 若您有外部 Redis，建議設為 false
```

### 3.4. 部署 Label Studio

使用您自訂的 `values.yaml` 檔案來部署 Label Studio。

```bash
helm install label-studio heartex/label-studio -f values.yaml -n label-studio --create-namespace
```

部署完成後，您可以通過設定 Ingress 來從外部存取 Label Studio 的服務。

## 4. 環境變數設定

Label Studio 的行為可以透過環境變數進行深度自訂。您可以在 Helm 的 `values.yaml` 中的 `global.extraEnvironmentVars` 區塊設定這些變數。

### 通用設定

| 變數名 | 說明 | 預設值 |
|---|---|---|
| `HOST` | Label Studio 的公開 URL，必須以 `http://` 或 `https://` 開頭。用於生成資源的絕對路徑。 | `''` |
| `DEBUG` | 是否啟用 Django 的除錯模式。**生產環境中絕對不能設為 `true`**。 | `true` |
| `BASE_DATA_DIR` | 儲存 SQLite 資料庫、媒體檔案等的基礎目錄。在 Helm 部署中，此路徑對應到持久化磁碟區。 | `~/.local/share/label-studio` |
| `DISABLE_SIGNUP_WITHOUT_LINK` | 設為 `true` 時，使用者無法自行註冊，只能通過邀請連結註冊。 | `false` |
| `FROM_EMAIL` | 發送郵件時顯示的寄件人地址。 | `Label Studio <hello@labelstud.io>` |
| `LOCAL_FILES_SERVING_ENABLED` | 是否允許 Label Studio 提供本地檔案系統的檔案。需搭配 `LOCAL_FILES_DOCUMENT_ROOT` 使用。 | `false` |
| `LOCAL_FILES_DOCUMENT_ROOT` | 當 `LOCAL_FILES_SERVING_ENABLED` 為 `true` 時，指定允許存取的根目錄。 | `/` |

### 安全性設定

| 變數名 | 說明 | 預設值 |
|---|---|---|
| `SSRF_PROTECTION_ENABLED` | **強烈建議在生產環境中設為 `true`**。啟用 SSRF (伺服器端請求偽造) 保護。 | `false` |
| `SESSION_COOKIE_SECURE` | 設為 `true` 時，session cookie 只會透過 HTTPS 傳送。 | `false` |
| `CSRF_COOKIE_SECURE` | 設為 `true` 時，CSRF cookie 只會透過 HTTPS 傳送。 | `false` |
| `INACTIVITY_SESSION_TIMEOUT_ENABLED` | 是否啟用使用者閒置超時登出功能。 | `true` |
| `MAX_SESSION_AGE` | Session 的最大生命週期（秒），不論使用者是否活動。 | `1209600` (14 天) |
| `MAX_TIME_BETWEEN_ACTIVITY` | 使用者閒置多長時間後（秒），session 會被視為過期。 | `432000` (5 天) |

### 資料庫設定 (當不使用 Helm `pgConfig` 時)

| 變數名 | 說明 | 預設值 |
|---|---|---|
| `DJANGO_DB` | 指定要使用的資料庫類型。可以是 `postgresql`, `mysql`, 或 `sqlite`。 | `default` (postgresql) |
| `POSTGRE_USER` | PostgreSQL 使用者名稱。 | `postgres` |
| `POSTGRE_PASSWORD` | PostgreSQL 密碼。 | `postgres` |
| `POSTGRE_NAME` | PostgreSQL 資料庫名稱。 | `postgres` |
| `POSTGRE_HOST` | PostgreSQL 伺服器主機。 | `localhost` |
| `POSTGRE_PORT` | PostgreSQL 伺服器埠號。 | `5432` |

### 雲端儲存 (S3, GCS, Azure)

Label Studio 支援直接與雲端儲存服務整合。所有雲端儲存的設定都是透過環境變數完成的。

**通用設定:**
| 變數名 | 說明 |
|---|---|
| `STORAGE_TYPE` | 設定儲存類型，可為 `s3`, `gcs`, `azure`。 |

**Amazon S3:**
| 變數名 | 說明 |
|---|---|
| `STORAGE_AWS_ACCESS_KEY_ID` | AWS Access Key ID. |
| `STORAGE_AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key. |
| `STORAGE_AWS_BUCKET_NAME` | S3 儲存桶名稱。 |
| `STORAGE_AWS_REGION_NAME` | S3 儲存桶所在的區域。 |
| `STORAGE_AWS_ENDPOINT_URL` | S3 相容儲存的端點 URL (例如 MinIO)。 |

**Google Cloud Storage (GCS):**
| 變數名 | 說明 |
|---|---|
| `STORAGE_GCS_PROJECT_ID` | GCP 專案 ID。 |
| `STORAGE_GCS_BUCKET_NAME` | GCS 儲存桶名稱。 |
| `GOOGLE_APPLICATION_CREDENTIALS` | 指向 GCS 服務帳號金鑰 JSON 檔案的路徑 (在容器內)。 |

**Microsoft Azure Blob:**
| 變數名 | 說明 |
|---|---|
| `STORAGE_AZURE_ACCOUNT_NAME` | Azure 儲存帳戶名稱。 |
| `STORAGE_AZURE_ACCOUNT_KEY` | Azure 儲存帳戶金鑰。 |
| `STORAGE_AZURE_CONTAINER_NAME` | Azure Blob 容器名稱。 |

## 5. 基本操作

在成功部署 Label Studio 後，您可以開始進行資料標註。

1.  **建立專案**: 登入 Label Studio 後，點擊 "Create Project" 按鈕。輸入專案名稱和描述。
2.  **匯入資料**:
    *   您可以從本地上傳檔案。
    *   或者，設定與雲端儲存（S3, GCS, Azure）的同步，讓 Label Studio 自動從您的儲存桶中讀取資料。
3.  **設定標註介面**: 在專案的 "Settings > Labeling Interface" 中，您可以選擇一個預設範本，或使用 XML 來自訂您需要的標註工具和標籤。
4.  **開始標註**: 進入專案主畫面，點擊 "Label All Tasks" 開始標註您的資料。

更詳細的新手教學，請參考官方部落格文章：[Zero to One: Getting Started with Label Studio](https://labelstud.io/blog/zero-to-one-getting-started-with-label-studio/)。

## 6. 進階設定：整合 LLM

您可以將大型語言模型 (LLM) 或其他機器學習模型作為 "ML Backend" 與 Label Studio 整合，以實現自動預標註、互動式標註等功能。

ML Backend 是一個獨立於 Label Studio 運行的服務。

### 6.1. 執行 ML Backend

1.  **複製官方 ML Backend Repository**

    官方提供了包含多種模型範例的 SDK。

    ```bash
    git clone https://github.com/HumanSignal/label-studio-ml-backend.git
    cd label-studio-ml-backend
    ```

2.  **安裝依賴並啟動範例模型**

    以 OpenAI (GPT) 為例，您需要安裝相關依賴。

    ```bash
    # 建立並啟用虛擬環境
    python3 -m venv venv
    source venv/bin/activate
    
    # 安裝基礎套件
    pip install -U label-studio-ml

    # 找到您想用的模型範例，例如 openai
    cd label_studio_ml/examples/openai
    pip install -r requirements.txt
    ```

3.  **設定環境變數並啟動**

    ML Backend 需要 API 金鑰來與 LLM 服務提供商溝通。這些金鑰是為 ML Backend 服務設定的，而不是 Label Studio 主程式。

    ```bash
    # 設定 LLM 供應商的 API Key
    export OPENAI_API_KEY="sk-..." 

    # ML Backend 也需要 Label Studio 的 URL 和 API Key 來回頭存取資料
    export LABEL_STUDIO_URL="http://your-label-studio-host.com"
    export LABEL_STUDIO_API_KEY="your-ls-user-token" # 從 Label Studio 的使用者帳號設定頁面獲取

    # 啟動 ML Backend 服務
    label-studio-ml start . --port 9090
    ```

### 6.2. 連接到 Label Studio

1.  在 Label Studio 的專案中，進入 **Settings > Machine Learning**。
2.  點擊 **Add Model**。
3.  輸入 ML Backend 的 URL，例如 `http://<ml-backend-host-ip>:9090`。
4.  啟用 **Interactive pre-annotations** 開關以獲得即時的互動式標註體驗。
5.  儲存後，您的 LLM 模型就成功整合了。

## 7. 故障排除

### CORS (跨來源資源共享) 錯誤

當您發現圖片、音訊或其他資源無法在標註頁面載入時，最常見的原因是 CORS 問題。

*   **檢查瀏覽器控制台**：F12 打開開發者工具，查看 Console 中的錯誤訊息。
*   **設定雲端儲存**：如果您使用 S3, GCS, 或 Azure，請確保已為您的儲存桶設定了正確的 CORS 策略，允許來自 Label Studio `HOST` 的 `GET` 請求。
    *   [Amazon S3 CORS 文件](https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html)
    *   [Google Cloud Storage CORS 文件](https://cloud.google.com/storage/docs/configuring-cors)
    *   [Azure Storage CORS 文件](https://docs.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services)

### ML Backend 連線問題

*   **連線失敗**:
    *   確保 ML Backend 服務正在運行，且 Label Studio 伺服器可以訪問到 ML Backend 的主機和埠號。
    *   在 ML Backend 伺服器上執行健康檢查：`curl -X GET http://localhost:9090/health`。

*   **請求超時**:
    *   ML 模型處理可能需要較長時間。您可以增加 Label Studio 對 ML Backend 的請求超時時間。相關的環境變數包括 `ML_TIMEOUT_PREDICT`, `ML_TIMEOUT_TRAIN` 等。

*   **無法存取資料**:
    *   ML Backend 日誌中出現 "no such file or directory" 或類似錯誤，通常是因為 ML Backend 無法下載 Label Studio 中的檔案。
    *   請確保您已為 ML Backend 正確設定 `LABEL_STUDIO_URL` 和 `LABEL_STUDIO_API_KEY` 環境變數。

*   **預標註未顯示**:
    *   檢查 ML Backend 的預測結果格式是否符合 Label Studio 的 [JSON 格式](https://labelstud.io/guide/predictions.html)。
    *   確保標註介面設定中的 `from_name` 和 `toName` 與模型輸出的標籤名稱相符。

### 效能問題

*   **標註緩慢**: 如果您使用預設的 SQLite 資料庫並處理大量資料或多使用者同時操作，可能會遇到效能瓶頸。**強烈建議在生產環境中使用 PostgreSQL**。
*   **匯入/匯出緩慢**: 大量資料的匯入/匯出是異步執行的。您可以在 Label Studio 的管理介面 `/django-rq` 中檢查 `rq-worker` 的狀態。如果 worker 沒有運行，異步任務將不會被執行。

---
*本文件基於專案程式碼庫分析自動生成。*
