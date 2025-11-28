# Label-Studio-試用報告

## 1. 執行摘要 (Executive Summary)
- **一句話總結**：Label Studio 是一款功能強大且靈活的開源資料標註工具，支援多種資料類型與模型輔助標註，非常適合團隊進行資料標註流程的標準化與自動化，建議進行導入試用。
- **關鍵發現**：
  1. **多模態支援完整**：原生支援影像、音訊、文字、影片及時間序列等多種資料類型，且介面可高度客製化。
  2. **模型輔助標註 (ML-Assisted Labeling)**：可整合機器學習模型進行預標註 (Pre-labeling) 與主動學習 (Active Learning)，顯著提升標註效率。
  3. **整合性高**：提供豐富的 API、Python SDK 及 Webhooks，並能直接掛載 S3、GCS、Azure Blob 等雲端儲存，易於融入現有 MLOps 流程。
  4. **最大潛在風險**：開源版缺乏細顆粒度的權限控管 (RBAC) 與 SSO 整合，若團隊規模較大或對資安有嚴格要求，可能需自行開發或升級至企業版。

## 2. 產品規格與授權分析 (Licensing & Versions)
- **授權模式**：
  - **開源協議**：Apache License 2.0。
  - **商用可行性**：**是 (Yes)**。Apache 2.0 為寬鬆的開源授權，允許商業使用、修改與分發，無須開源衍生程式碼。

- **版本區別 (Community vs. Enterprise)**：

| 功能面向 | Community Edition (開源版) | Enterprise Edition (企業版) |
| :--- | :--- | :--- |
| **部署方式** | Docker, Pip, Source | Cloud (SaaS) / On-Premise (VPC) |
| **使用者管理** | 基本帳號管理 | SSO (SAML, LDAP), SCIM |
| **權限控管 (RBAC)** | 單一 Workspace，基本角色 | 細緻的角色權限 (Admin, Manager, Annotator, Reviewer), 多 Workspace |
| **資料安全** | 基礎 | Audit Logs (稽核日誌), SOC2 合規 |
| **品質控管** | 基本共識 (Consensus) 計算 | 進階共識規則, 標註者績效分析儀表板 |
| **技術支援** | 社群支援 (Slack, GitHub) | 專屬 SLA 支援, Customer Success Manager |
| **自動化流程** | 基本 Webhooks | 自動化工作流引擎 (Workflows) |

## 3. 重點面向評估 (Key Evaluation)
- **功能完整性 (Completeness)**：
  - 針對「資料標註」核心需求，Label Studio 覆蓋率極高。
  - 支援 **Image** (Bounding Box, Polygon, Keypoints, Segmentation), **Audio** (Regions, Transcription), **Text** (NER, Classification), **Video**, **Time Series**。
  - 具備「介面配置語言 (XML-based configuration)」，可針對特殊需求快速調整標註介面。

- **系統整合性 (Integration)**：
  - **雲端儲存**：原生支援 AWS S3, Google Cloud Storage, Azure Blob Storage，可直接讀取 bucket 資料進行標註，並將結果寫回。
  - **API 介接**：提供完整的 REST API，可透過程式化方式建立專案、匯入任務、匯出結果。
  - **ML Pipeline**：提供 Python SDK (`label-studio-sdk`)，易於與 Airflow, Kubeflow 或自建的 Model Training Pipeline 串接。

## 4. 實際試用紀錄 (Trial Log)
*指令：由於目前暫無數據，請保留此章節，但內容留空，僅列出建議填寫的測試項目清單（Checklist）。*

- [ ] **安裝部署流程耗時**：記錄從 `docker pull` 到服務啟動所需時間 (預期 < 10 分鐘)。
- [ ] **Hello World 跑通測試**：建立一個簡單的影像分類專案，上傳一張圖片並完成標註。
- [ ] **雲端儲存掛載測試**：測試是否能成功讀取 S3/GCS/Azure Blob 上的資料。
- [ ] **ML Backend 連線測試**：測試是否能連接一個簡單的 Dummy Model 進行預標註。
- [ ] **壓力測試表現**：(選填) 測試同時 10 人在線標註時的系統回應速度。

## 5. 評估結論 (Conclusion & Recommendation)
- **綜合評分**：**A** (強烈建議試用)
- **對管理層的具體建議**：
  1. **建議立即啟動 PoC**：Label Studio 開源版功能已相當完整，足以涵蓋 80% 以上的標註需求，且無授權費用風險。
  2. **採用策略**：建議先以開源版進行小規模導入，驗證其與現有 AI 模型的整合效益。
  3. **未來擴充路徑**：若未來標註團隊擴大至 20 人以上，或有嚴格的資安稽核需求 (SSO, Audit Log)，再評估升級至企業版。目前階段開源版搭配適當的網路隔離措施 (如 VPN, Internal Load Balancer) 應已足夠。
