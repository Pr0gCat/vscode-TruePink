# TruePink 語言支援擴充 — 設計文件

- 日期:2026-06-05
- 狀態:草案(待使用者 review)
- 範圍:為 TruePink VSCode color theme 擴充語法上色支援至更多語言,且新語言配色嚴格遵循既有美學。

---

## 1. 背景

TruePink(`themes/TruePink-color-theme.json`,v1.5.4)是一個淺色粉紅 color theme。
目前**完整支援**的語言:C、C++、Python、VHDL、Markdown。`tokenColors` 中另有少量 JavaScript、C# 的零散規則,README 將 JavaScript & CSS 標記為 PENDING、C# 標記為 WIP,已停滯超過一年。

使用者(theme 作者)已對現有語言「悉心調配」,要求新語言**比照其美學**,而非隨意上色。本案核心難度不在填色,而在**讀懂並延伸作者既有的配色邏輯**。

## 2. 目標

- 將語法上色支援擴充至以下 16 種語言。
- 每種語言的配色都與既有語言視覺一致(同一語意 → 同一顏色)。
- 建立可重複、自動化的截圖自評迴路,讓 AI 能在每個語言上自我驗證,降低對人工檢視的依賴。
- release 前由作者做最終人工驗收。

### 目標語言(依批次)

- **Batch 0(pilot)**:TypeScript、JavaScript
- **Batch 1**:CSS、HTML
- **Batch 2**:JSON、YAML、TOML、XML
- **Batch 3**:Rust、Go、Verilog/SystemVerilog
- **Batch 4**:Java、PHP、Ruby、Shell、SQL

每批為獨立的 spec → plan → 實作 → 驗收 循環。本文件涵蓋整體藍圖 + Batch 0 細節。

## 3. 不變量:語意色彩角色系統(設計憲法)

這是 theme 既有的配色邏輯,**所有新語言必須對應到此表,不得發明新顏色**:

| 語意角色 | 顏色 | 備註 |
|---|---|---|
| 關鍵字 / 控制流 / 型別宣告(storage、modifier) | `#c678dd` 紫 | storage 類 bold |
| 函式(定義 / 呼叫) | `#f2747f` 深粉 | 定義 bold,呼叫不 bold |
| 字串 | `#fd9999` 主粉 | 引號標點 `#e6a1a1` 淺粉 |
| 變數 / 運算子 / member access | `#2c2c2c` 黑 | |
| 數字 / 字面值 / escape | `#FFA500` 橙 | |
| 參數 / 語言常數(true/false/null) | `#72C7D2` 青 | |
| 型別 class / enum member / 分隔符 | `#61aeee` 淺藍 | |
| 預定義 / magic / 全大寫常數 / 連結 | `#ccaa6c` 金 | |
| 比較 / 遞增 | `#EB1165` 紅 | |
| 裝飾器 / 前處理 / 指令 / 引用 | `#98c379` 綠 | |
| `this` / `self` | `#fd9999` 主粉 | |
| 註解 | `#a1a4aa` 灰 | |

(此表來源:`themes/TruePink-color-theme.json` 開頭的 tokenColors 註解與 `COLORS.json`。)

## 4. 驗證基礎設施(已驗證可行)

已完成技術 spike,確認下列 pipeline 可在本機(Windows、PowerShell 7、Node 22、VSCode 繁中)全自動運作:

1. **準備 preview workspace**:一個資料夾,內含
   - 該語言的 sample 檔(刻意涵蓋各語法元素)
   - `.vscode/settings.json`:`"workbench.colorTheme": "TruePink"`、放大字級、隱藏 minimap/activity bar、`"editor.semanticHighlighting.enabled": false`(只看 theme 控制的 TextMate 結果)
2. **啟動 dev host**:
   ```
   code --extensionDevelopmentPath="<專案路徑>" --disable-extensions --new-window "<preview資料夾>" -g "<sample檔>:1"
   ```
   `--disable-extensions` 去除其他已安裝 extension 的雜訊(isort 錯誤、聊天面板等);theme 的 dev path 不受其影響。
3. **截圖**:用 Win32 `PrintWindow`(flag `PW_RENDERFULLCONTENT = 2`)直接截 dev host 視窗內容。
   - **不需搶前景、不干擾使用者正在用的視窗**,可在背景重複執行。
   - dev host 視窗以標題 `*tp-preview*` 之類關鍵字辨識(繁中標題前綴為「[延伸模組開發主機]」)。
4. **AI 自評**:用 Read 讀 PNG,逐 token 比對是否符合第 3 節語意色彩角色。不符即修 `tokenColors`,重截,直到一致。
5. **作者驗收**:每批 release 前由作者在真機檢視。

> spike 已用現有 theme 成功渲染 Python sample,AI 讀圖確認每個語意角色顏色正確,證明「AI 的眼睛與 theme 校準一致」。

此 pipeline 會固化成可重用腳本(啟動 + 截圖),避免每次手刻。

## 5. 每語言標準作業流程(SOP)

1. **研究 grammar**:確認該語言在 VSCode 使用的 TextMate grammar 與其 scope 命名(內建 grammar 或官方 grammar repo)。
2. **對應語意角色**:把關鍵 scope 對應到第 3 節表格。
3. **寫入 tokenColors**:在 `TruePink-color-theme.json` 沿用既有 `// 語言名` 分區結構新增規則。優先使用語言中性 scope(可跨語言生效),語言專屬 scope 僅用於修正例外。
4. **寫 sample 檔**:涵蓋該語言的函式定義/呼叫、型別/類別、字串/數字、運算子/比較、控制流、註解、語言特性(如 TS 的型別註記、泛型、decorator)。
5. **截圖自評**:跑 pipeline,逐 token 比對。
6. **修正迭代**:直到所有語意角色一致。
7. **作者驗收**:納入該批 release 前檢視。

## 6. Batch 0(pilot)範圍:TypeScript + JavaScript

選為 pilot 理由:現有 JS 規則近乎空白、PENDING 最久、生態最大、語法元素最豐富,最具代表性。match 好這個,其餘皆為延伸。

需涵蓋並對應的語法元素(對應顏色見第 3 節):
- 變數宣告 `const`/`let`/`var`、`function`、`class`、`extends`、`return`、`if`/`for`/`while` 等控制流 → 紫
- 函式定義與呼叫、方法 → 深粉(定義 bold)
- 類別名 / 型別名 / interface / enum 成員 → 淺藍
- 字串(含模板字串)與內插 `${}`、字串引號標點 → 粉 / 淺粉
- 數字、`true`/`false`/`null`/`undefined` → 橙 / 青
- 參數 → 青
- 比較運算子 → 紅;一般運算子 / member access(`.`) → 黑
- `this` → 粉
- decorator(`@Component`)→ 綠
- 註解 → 灰
- TS 專屬:型別註記(`: string`)、泛型(`<T>`)、`interface`/`type`/`as`/`implements`、存取修飾(`public`/`private`)→ 對應 storage/type(紫/淺藍)
- JSX/TSX:暫列觀察項,pilot 先以 `.ts`/`.js` 為主,JSX 視驗收情況決定是否納入本批

驗收標準:TS 與 JS sample 截圖中,每個語意角色顏色與第 3 節表一致,且與既有語言(C/Python)觀感連貫。

## 7. 收尾事項(每批與全案)

- 更新 `README.md` 的語言支援清單(移除 PENDING/WIP 標記為實際狀態)。
- 更新 `CHANGELOG.md`。
- 修正版本號不一致:`package.json` 1.5.4 → 1.5.5(CHANGELOG 已提及 1.5.5)。
- 以新版 sample 取代 `test/` 內無關的通用 Markdown 教學檔(視情況)。

## 8. 非目標(YAGNI)

- 不做 icon theme / product icon theme。
- 不做暗色變體。
- 不導入 semantic token 配色(`semanticTokenColors`)——本案專注 TextMate 上色;semantic 議題另案討論。
- 不做與語言支援無關的重構。
- 程式碼中 `//TODO: Colorize OverviewRuler` 不混入本案,另行處理。

## 9. 風險與緩解

- **scope 不如預期**:某些語言的實際 scope 命名與假設不符 → 以截圖自評即時發現並修正;必要時用 VSCode「開發人員:檢查編輯器 token 與範圍」確認真實 scope。
- **語言中性 scope 衝突**:新增的跨語言 scope 可能影響既有已調好的語言 → 每批完成後對既有語言(C/Python/VHDL/Markdown)各截一張回歸截圖,確認沒有退化。
- **semantic highlighting 落差**:真實使用時若使用者開啟 semantic highlighting,部分 token 會被引擎預設覆蓋,與截圖(已關 semantic)有出入 → 列為已知限制,semantic 另案。
- **JSX/TSX 複雜度**:嵌入式語法 scope 較雜 → pilot 先不含,視驗收再評估。

## 10. 開放問題

- 暫無阻擋性問題。pilot 完成後依驗收結果調整後續批次節奏。
