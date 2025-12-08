# 使用 Label Studio 標註 test-01.txt 教學

這份指南將協助您將 `test-01.txt` 導入 Label Studio 並進行自然語言處理 (NLP) 的標註（以 NER 命名實體識別為例）。

## 1. 安裝與啟動
如果您尚未安裝 Label Studio，請在終端機 (Terminal/CMD) 執行：

```bash
# 安裝
pip install label-studio

# 啟動 (啟動後會自動開啟瀏覽器，預設 <http://localhost:8080>)
label-studio start
```

## 2. 建立專案
1. 點擊 "Create Project"。
2. Project Name: 輸入專案名稱（例如：`Transformer_Annotation`）。
3. Data Import:
    - 拖曳或上傳您的 `test-01.txt` 檔案。
    - 選擇 "List of Tasks" (如果希望每一段落或整篇作為一個標註單位)。
    - 注意：若要整篇只有一個標註介面，請確認導入選項，通常 txt 會被視為純文字內容。

## 3. 設定標籤 (Labeling Setup)
這是最關鍵的一步。針對您的文本內容（Transformer、深度學習、神經網路），建議使用 Named Entity Recognition (NER)。
1. 點擊 "Labeling Setup" (`Projects/text-02/Settings/Labeling Interface` 然後 `Browse Templates`)。
2. 選擇 "Natural Language Processing" -> "Named Entity Recognition"。
3. 雖然可以用圖形介面增減標籤，但為了符合您的文本，建議點擊 "Code" 模式，貼上以下 XML 配置：

```html
<View>
  <!-- 建立Label(region)之間的標籤關係 -->
  <Relations>
    <Relation value="proposes" />
    <Relation value="contains" />
  </Relations>
  
  <Labels name="label" toName="text">
    <!-- 針對 test-01.txt 內容設計的建議標籤 -->
    <Label value="模型名稱" background="#FF0000"/>
    <Label value="核心機制" background="#0000FF"/>
    <Label value="組件/架構" background="#00FF00"/>
    <Label value="年份/人物" background="#FFA500"/>
    <Label value="應用領域" background="#800080"/>
  </Labels>

  <!-- 顯示文本內容 -->
  <Text name="text" value="$text"/>
</View>
```

**標籤說明：**
模型名稱: 標註 `Transformer`, `BERT`, `GPT`, `RNN`, `CNN` 等。
核心機制: 標註 `自注意力機制`, `位置編碼`, `多頭注意力` 等。
組件/架構: 標註 `編碼器`, `解碼器`, `嵌入層` 等。
年份/人物: 標註 `2017`, `Vaswani` 等。

## 4. 開始標註
1. 儲存設定後，點擊專案進入任務列表。
    - 空白行可以刪除。
2. 點擊您的任務（test-01.txt 的內容）。
    - 專案列表中的 "Label All Tasks"
3. 操作方式：
    - 點擊上方對應的標籤（如「模型名稱」）。
    - 使用滑鼠選取文本中的關鍵字（如「Transformer」）。
    - 重複標註關鍵字。
    - create relation between two regions 建立已標記區域之間的關係，並設定關係的標籤
    - 完成後點擊 "Submit"。

## 5. 匯出資料 (Export)
標註完成後：
1. 點擊右上角 "Export"。
2. 選擇格式：
    - JSON / JSON-MIN: 最常用，適合機器學習訓練。
    - CSV: 適合試算表查看。
    - CoNLL 2003: 傳統 NLP 模型常用格式。
3. 即可用於模型訓練。
