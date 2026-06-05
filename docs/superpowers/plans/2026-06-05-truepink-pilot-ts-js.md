# TruePink Pilot(TypeScript + JavaScript)Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 為 TruePink theme 加入 TypeScript 與 JavaScript 的語法上色,配色嚴格對應既有「語意色彩角色系統」,並建立可重複的截圖自評 pipeline。

**Architecture:** 在 `themes/TruePink-color-theme.json` 的 `tokenColors` 新增規則,優先用語言中性 scope。用一支 PowerShell 腳本啟動 VSCode extension development host(載入本 theme)、用 Win32 `PrintWindow` 背景截圖,AI 讀圖逐 token 對照語意角色,迭代修正,最後對既有語言做回歸截圖確保無退化。

**Tech Stack:** VSCode TextMate theme(JSONC)、PowerShell 7、Win32 `PrintWindow`、`code` CLI、Node 22(已具備)。

**驗收基準(語意色彩角色系統 — 設計憲法):**

| 角色 | 顏色 | 角色 | 顏色 |
|---|---|---|---|
| 關鍵字/控制流/storage | `#c678dd` 紫(storage bold) | 函式定義/呼叫 | `#f2747f` 深粉(定義 bold) |
| 字串 | `#fd9999` 粉(引號 `#e6a1a1`) | 變數/運算子/member | `#2c2c2c` 黑 |
| 數字/字面值/escape | `#FFA500` 橙 | 參數/語言常數 | `#72C7D2` 青 |
| 型別class/enum member/分隔符 | `#61aeee` 淺藍 | 預定義/magic/CAPS/連結 | `#ccaa6c` 金 |
| 比較/遞增 | `#EB1165` 紅 | 裝飾器/前處理/指令/引用 | `#98c379` 綠 |
| this/self | `#fd9999` 粉 | 註解 | `#a1a4aa` 灰 |

> **Commit 政策:** 作者要求「不主動 commit」。所有 commit step 標記為 **(待作者授權)**;執行時先暫存好變更,經作者同意再實際 `git commit`。

---

## File Structure

- Create: `scripts/preview.ps1` — 啟動 dev host + PrintWindow 截圖的可重用腳本(參數 `-Sample`、`-Out`)。
- Create: `samples/.vscode/settings.json` — preview workspace 設定(自動套 theme、放大字級、關 semantic、隱藏 UI 雜訊)。
- Create: `samples/typescript.ts`、`samples/javascript.js` — 語法 sample。
- Create: `samples/regression.c`、`samples/regression.py` — 回歸用既有語言 sample。
- Modify: `themes/TruePink-color-theme.json` — 新增 TS/JS `tokenColors` 規則。
- Modify: `README.md`、`CHANGELOG.md`、`package.json` — 收尾(語言清單、版本 1.5.4→1.5.5)。

---

## Task 1: 固化截圖 pipeline

**Files:**
- Create: `samples/.vscode/settings.json`
- Create: `scripts/preview.ps1`
- Create(暫時 sanity 用): `samples/sanity.py`

- [ ] **Step 1: 建立 preview workspace 設定**

Create `samples/.vscode/settings.json`:

```json
{
    "workbench.colorTheme": "TruePink",
    "editor.fontSize": 16,
    "editor.lineHeight": 24,
    "window.zoomLevel": 0,
    "workbench.startupEditor": "none",
    "editor.minimap.enabled": false,
    "workbench.activityBar.location": "hidden",
    "editor.renderWhitespace": "none",
    "window.menuBarVisibility": "compact",
    "editor.semanticHighlighting.enabled": false
}
```

- [ ] **Step 2: 建立 preview 腳本**

Create `scripts/preview.ps1`:

```powershell
param(
  [Parameter(Mandatory=$true)][string]$Sample,
  [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$workspace = Join-Path $repo "samples"
$code = "C:\Users\LTY\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd"

# 1. 啟動 dev host:載入本 theme、停用其他擴充以去雜訊、開指定 sample
& $code --extensionDevelopmentPath="$repo" --disable-extensions --new-window "$workspace" -g "${Sample}:1" | Out-Null

# 2. Win32 API(PrintWindow 可截背景視窗,不需搶前景)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Cap {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int n);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
Add-Type -AssemblyName System.Drawing

# 3. 等待 dev host 視窗(繁中標題前綴「延伸模組開發主機」;英文 fallback)
$proc = $null
for ($i=0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 750
  $proc = Get-Process Code -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -like '*延伸模組開發主機*' -or $_.MainWindowTitle -like '*Extension Development Host*' } |
    Sort-Object StartTime -Descending | Select-Object -First 1
  if ($proc) { break }
}
if (-not $proc) { throw "dev host window not found" }

# 4. maximize,留時間給 tokenizer
$h = $proc.MainWindowHandle
[Cap]::ShowWindow($h, 3) | Out-Null
Start-Sleep -Seconds 3

# 5. PrintWindow 截圖(PW_RENDERFULLCONTENT = 2)
$r = New-Object Cap+RECT
[Cap]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left; $ht = $r.Bottom - $r.Top
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[Cap]::PrintWindow($h, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 6. 關閉本次 dev host 視窗(只關 dev host,不影響使用者其他 VSCode 視窗)
$proc.CloseMainWindow() | Out-Null
Write-Output "saved $Out"
```

- [ ] **Step 3: 建立 sanity sample**

Create `samples/sanity.py`:

```python
def greet(name: str) -> str:
    message = f"Hello {name}"
    return message.upper()


VALUE = 42
print(greet("Pinky"), VALUE)
```

- [ ] **Step 4: 跑腳本驗證 pipeline 產圖**

Run:
```powershell
pwsh -File scripts/preview.ps1 -Sample "C:\Users\LTY\Desktop\vscode-TruePink\samples\sanity.py" -Out "C:\Users\LTY\Desktop\vscode-TruePink\samples\_sanity.png"
```
Expected: 輸出 `saved ..._sanity.png`,檔案存在。

- [ ] **Step 5: AI 讀圖確認 pipeline 正確**

用 Read 開 `samples/_sanity.png`。確認:
- theme 已套用(背景淺灰 `#f7f7f7`、`def`/`return` 紫、`greet` 深粉、字串粉、`42` 橙、註解灰)。
- 畫面**乾淨**(因 `--disable-extensions`:無 isort 錯誤、無聊天面板、無 mermaid 連結)。
- 若 `--disable-extensions` 導致 theme 未套用(理論上 dev path 不受影響),改為移除該旗標並於 settings 已隱藏 UI;記錄結果。

- [ ] **Step 6: 清理暫存圖、Commit(待作者授權)**

刪除 `samples/_sanity.png`(`samples/sanity.py` 保留作為快速 smoke 用)。
```bash
git add scripts/preview.ps1 samples/.vscode/settings.json samples/sanity.py
git commit -m "build: add VSCode theme preview screenshot pipeline"
```

---

## Task 2: TypeScript 支援

**Files:**
- Create: `samples/typescript.ts`
- Modify: `themes/TruePink-color-theme.json`(在 `tokenColors` 陣列尾端、`]` 之前新增 TS/JS 區塊)

- [ ] **Step 1: 寫 TypeScript sample(涵蓋各語法元素)**

Create `samples/typescript.ts`:

```typescript
// TruePink syntax preview — TypeScript
import { readFile } from "fs";
import type { Buffer } from "buffer";

export interface Animal {
    name: string;
    legs: number;
}

export enum Color {
    Pink,
    Blue,
}

type Pair<T> = [T, T];

function sealed(target: Function): void {
    Object.seal(target);
}

@sealed
export class Cat<T> extends Object implements Animal {
    public name: string = "Pinky";
    private age: number = 3;
    legs: number = 4;

    constructor(name: string, age: number = 3) {
        super();
        this.name = name;
        this.age = age;
    }

    async greet(loud: boolean = false): Promise<string> {
        const message = `Hello, I am ${this.name}!`;
        if (loud && this.age >= 2) {
            return message.toUpperCase();
        }
        return message;
    }
}

const MAX = 100;
const values: number[] = [1, 2, 3, 0x1f, 3.14];
const double = (x: number): number => x * 2;

for (let i = 0; i < values.length; i++) {
    const v = values[i];
    if (v > MAX || v === null) {
        console.log("skip", v);
    } else {
        values[i] = double(v);
    }
}

const cat = new Cat<string>("Mochi", 5);
cat.greet(true).then((s) => console.log(s));
```

- [ ] **Step 2: 截 baseline(failing — 未加規則前)**

Run:
```powershell
pwsh -File scripts/preview.ps1 -Sample "C:\Users\LTY\Desktop\vscode-TruePink\samples\typescript.ts" -Out "C:\Users\LTY\Desktop\vscode-TruePink\samples\_ts_before.png"
```
Read `samples/_ts_before.png`。預期會看到多處用預設色(例如 `interface`/`type`/`enum` 名、template string、箭頭函式、型別註記)未符合語意角色。記錄哪些角色錯。

- [ ] **Step 3: 新增 TS/JS 中性 tokenColors 規則(第一版)**

在 `themes/TruePink-color-theme.json` 的 `tokenColors` 陣列**最後一個物件之後、`]` 之前**插入(沿用既有 `// 語言` 分區風格)。注意保留前一物件結尾的逗號:

```jsonc
        //
        // TypeScript / JavaScript (language-neutral first)
        //
        {
            "name": "Template string",
            "scope": ["string.template", "string.quoted.template",
                "punctuation.definition.string.template.begin",
                "punctuation.definition.string.template.end"],
            "settings": { "foreground": "#fd9999" }
        },
        {
            "name": "Template expression braces ${ }",
            "scope": ["punctuation.definition.template-expression.begin",
                "punctuation.definition.template-expression.end"],
            "settings": { "foreground": "#61aeee" }
        },
        {
            "name": "Type / interface / enum / class names",
            "scope": ["entity.name.type.interface", "entity.name.type.enum",
                "entity.name.type.module", "entity.name.type.alias",
                "support.class"],
            "settings": { "foreground": "#61aeee", "fontStyle": "bold" }
        },
        {
            "name": "Type references / primitives (not bold)",
            "scope": ["entity.name.type", "support.type.primitive",
                "support.type.builtin"],
            "settings": { "foreground": "#61aeee" }
        },
        {
            "name": "this / super",
            "scope": ["variable.language.this", "variable.language.super"],
            "settings": { "foreground": "#fd9999" }
        },
        {
            "name": "Function declaration (bold)",
            "scope": ["meta.definition.function entity.name.function",
                "meta.definition.method entity.name.function"],
            "settings": { "foreground": "#f2747f", "fontStyle": "bold" }
        },
        {
            "name": "Function call",
            "scope": ["entity.name.function", "support.function"],
            "settings": { "foreground": "#f2747f" }
        },
        {
            "name": "Arrow function token =>",
            "scope": ["storage.type.function.arrow"],
            "settings": { "foreground": "#2c2c2c" }
        },
        {
            "name": "Relational / comparison operators",
            "scope": ["keyword.operator.relational", "keyword.operator.comparison"],
            "settings": { "foreground": "#EB1165" }
        },
        {
            "name": "Decorator",
            "scope": ["meta.decorator entity.name.function",
                "meta.decorator punctuation.decorator",
                "entity.name.function.decorator"],
            "settings": { "foreground": "#98c379" }
        }
```

- [ ] **Step 4: 截 after 圖**

Run:
```powershell
pwsh -File scripts/preview.ps1 -Sample "C:\Users\LTY\Desktop\vscode-TruePink\samples\typescript.ts" -Out "C:\Users\LTY\Desktop\vscode-TruePink\samples\_ts_after.png"
```
Read `samples/_ts_after.png`。

- [ ] **Step 5: 視覺驗收清單(逐項核對)**

對照憲法,逐項確認(❌ 者記下實際顏色與 scope):
- [ ] 註解 `// ...` → 灰 `#a1a4aa`
- [ ] `import`/`export`/`from`/`type`(import)/`extends`/`implements`/`return`/`if`/`else`/`for` → 紫 `#c678dd`
- [ ] `interface` `enum` `class` `function` `const`/`let` `public`/`private`/`async` → 紫(storage bold)
- [ ] `Animal`/`Color`/`Cat`/`Pair` 型別與類別名 → 淺藍 bold `#61aeee`
- [ ] 型別註記 `: string` `: number` `: boolean` `Promise` → 淺藍
- [ ] 函式定義 `sealed`/`greet`/`constructor`/`double` → 深粉 `#f2747f`(定義 bold)
- [ ] 函式呼叫 `console.log`/`toUpperCase`/`seal`/`then` → 深粉
- [ ] 字串 `"Pinky"` 與 template `` `Hello...` `` → 粉 `#fd9999`;`${ }` 大括號 → 淺藍
- [ ] 數字 `100`/`0x1f`/`3.14`/`5` → 橙 `#FFA500`
- [ ] `null`/`true`/`false` → 青 `#72C7D2`
- [ ] 參數 `name`/`age`/`loud`/`x` → 青 `#72C7D2`
- [ ] `this` → 粉 `#fd9999`
- [ ] `@sealed` decorator → 綠 `#98c379`
- [ ] 比較 `<`/`>`/`>=`/`===` → 紅 `#EB1165`
- [ ] `=>` 箭頭 → 黑 `#2c2c2c`(非紫)
- [ ] 一般運算子 `=`/`*`/`+`/`.` → 黑

- [ ] **Step 6: 針對 ❌ 項修正(常見調整)**

依 Step 5 結果修 `themes/TruePink-color-theme.json`。常見情況:
- 若型別名**未 bold 或顏色錯**:確認實際 scope(VSCode 指令「開發人員: 檢查編輯器 token 與範圍」),把實際 scope 補進對應規則。
- 若型別註記裡的型別**太重(不想要 bold)**:把 `entity.name.type` 從「bold 群組」確認已分到「not bold 群組」(本版已分離)。
- 若 `entity.name.function` 把**非函式識別子**也染粉:縮限為更精確 scope(如 `meta.function-call entity.name.function`)。
- 若 `=>` 仍為紫:確認 `storage.type.function.arrow` 規則在陣列中**位於** storage 通則之後(後者覆蓋前者)。
每次修改後重跑 Step 4 截圖、重核 Step 5,直到全部 ✅。

- [ ] **Step 7: Commit(待作者授權)**

刪除 `_ts_before.png`/`_ts_after.png`。
```bash
git add themes/TruePink-color-theme.json samples/typescript.ts
git commit -m "feat: add TypeScript syntax colors matching TruePink aesthetic"
```

---

## Task 3: JavaScript 支援

**Files:**
- Create: `samples/javascript.js`
- Modify: `themes/TruePink-color-theme.json`(僅在 Task 2 規則無法涵蓋 JS 專屬例外時)

- [ ] **Step 1: 寫 JavaScript sample**

Create `samples/javascript.js`:

```javascript
// TruePink syntax preview — JavaScript
const fs = require("fs");

class Cat extends Object {
    constructor(name, age = 3) {
        super();
        this.name = name;
        this.age = age;
    }

    greet(loud = false) {
        const message = `Hello, I am ${this.name}!`;
        if (loud && this.age >= 2) {
            return message.toUpperCase();
        }
        return message;
    }
}

const MAX = 100;
const values = [1, 2, 3, 0x1f, 3.14];
const double = (x) => x * 2;

for (let i = 0; i < values.length; i++) {
    const v = values[i];
    if (v > MAX || v === null) {
        console.log("skip", v);
    } else {
        values[i] = double(v);
    }
}

const cat = new Cat("Mochi", 5);
cat.greet(true);
```

- [ ] **Step 2: 截圖**

Run:
```powershell
pwsh -File scripts/preview.ps1 -Sample "C:\Users\LTY\Desktop\vscode-TruePink\samples\javascript.js" -Out "C:\Users\LTY\Desktop\vscode-TruePink\samples\_js_after.png"
```
Read `samples/_js_after.png`。

- [ ] **Step 3: 視覺驗收清單**

逐項確認(同憲法):
- [ ] 註解灰、`require` 呼叫深粉、`class`/`const`/`let`/`extends`/`return`/`if`/`else`/`for` 紫
- [ ] `Cat` 類別名 淺藍 bold
- [ ] `constructor`/`greet`/`double` 定義深粉、`console.log`/`toUpperCase` 呼叫深粉
- [ ] 字串與 template 粉、`${ }` 淺藍
- [ ] 數字橙、`null`/`true`/`false` 青、參數 `name`/`age`/`loud`/`x` 青
- [ ] `this` 粉、比較 `>=`/`>`/`===` 紅、`=>` 黑、一般運算子黑

- [ ] **Step 4: 修正 JS 專屬例外**

多數規則應由 Task 2 的中性 scope 涵蓋。若有 JS 專屬 scope 差異(例如既有 `entity.name.function.js`、`variable.language.this.js` 已存在且仍正確,保留即可),僅針對 ❌ 項在 theme 中補語言專屬 scope。每次修改重跑 Step 2、重核 Step 3,直到全 ✅。

- [ ] **Step 5: Commit(待作者授權)**

刪除 `_js_after.png`。
```bash
git add themes/TruePink-color-theme.json samples/javascript.js
git commit -m "feat: add JavaScript syntax colors matching TruePink aesthetic"
```

---

## Task 4: 既有語言回歸測試

**Files:**
- Create: `samples/regression.c`、`samples/regression.py`

- [ ] **Step 1: 建立回歸 sample**

Create `samples/regression.c`:

```c
#include <stdio.h>
#define MAXVAL 100

typedef struct Point { int x; int y; } Point;

int add(int a, int b) {
    Point p = { .x = a, .y = b };
    if (a >= b || a == 0) {
        return p.x + p.y;
    }
    return a * b;
}

int main(void) {
    int total = add(3, 5);
    printf("total = %d\n", total);
    return 0;
}
```

Create `samples/regression.py`:

```python
import os
from dataclasses import dataclass


@dataclass
class Cat:
    name: str = "Pinky"

    def greet(self) -> str:
        return f"Hi {self.name}".upper()


VALUE = 42
for i in range(VALUE):
    if i % 2 == 0:
        print(i, os.getpid())
```

- [ ] **Step 2: 截 C 與 Python 回歸圖**

Run:
```powershell
pwsh -File scripts/preview.ps1 -Sample "C:\Users\LTY\Desktop\vscode-TruePink\samples\regression.c" -Out "C:\Users\LTY\Desktop\vscode-TruePink\samples\_reg_c.png"
pwsh -File scripts/preview.ps1 -Sample "C:\Users\LTY\Desktop\vscode-TruePink\samples\regression.py" -Out "C:\Users\LTY\Desktop\vscode-TruePink\samples\_reg_py.png"
```
Read 兩張圖。

- [ ] **Step 3: 確認既有語言無退化**

對照憲法,確認新增的中性 scope(`entity.name.type`、`entity.name.function`、`keyword.operator.relational`)**沒有破壞** C/Python 既有上色:
- [ ] C:`Point` 型別淺藍、`add`/`main`/`printf` 函式深粉、`#define`/`#include` 綠 bold、`MAXVAL` 金、比較 `>=`/`==` 紅、數字橙、字串粉、`typedef`/`int`/`struct` 紫
- [ ] Python:`Cat` 淺藍、`greet` 深粉(def bold)、`self` 粉、`@dataclass` 綠、`VALUE` 與既有一致、字串粉、數字橙
- 若有退化(例如 C 的某識別子被新中性規則誤染):縮限新規則 scope(加語言限定或更精確的父 scope),重跑 Step 2,直到 C/Python 回到原樣且 TS/JS 仍正確。

- [ ] **Step 4: Commit(待作者授權)**

刪除 `_reg_c.png`/`_reg_py.png`。
```bash
git add samples/regression.c samples/regression.py themes/TruePink-color-theme.json
git commit -m "test: add C/Python regression samples; ensure no color regressions"
```

---

## Task 5: 文件與版本收尾

**Files:**
- Modify: `README.md`、`CHANGELOG.md`、`package.json`

- [ ] **Step 1: 更新 README 語言清單**

把 README 中 JavaScript/CSS 的 `PENDING`、TypeScript(新增)狀態更新為實際支援。將「完整支援」清單加入 `TypeScript`、`JavaScript`。CSS/HTML 仍標未支援(屬 Batch 1)。

- [ ] **Step 2: 更新 CHANGELOG**

在 `CHANGELOG.md` 最上方新增:
```markdown
## 1.5.5
* Added TypeScript syntax highlighting
* Completed JavaScript syntax highlighting
* Added screenshot-based preview tooling (scripts/preview.ps1, samples/)
```

- [ ] **Step 3: 修正版本號**

`package.json`:`"version": "1.5.4"` → `"version": "1.5.5"`。

- [ ] **Step 4: 最終 smoke 截圖**

對 `samples/typescript.ts` 與 `samples/javascript.js` 各跑一次 `scripts/preview.ps1`,Read 確認最終成果與憲法一致,留作給作者驗收的圖。

- [ ] **Step 5: Commit(待作者授權)**

```bash
git add README.md CHANGELOG.md package.json
git commit -m "docs: document TS/JS support, bump version to 1.5.5"
```

---

## Self-Review notes

- **Spec coverage:** 驗證 pipeline(Task 1)、TS(Task 2)、JS(Task 3)、回歸/不變量保護(Task 4)、收尾與版本修正(Task 5)皆對應 spec 第 4–7 節。非目標(semantic、暗色、icon、OverviewRuler)未納入,符合 spec 第 8 節。
- **JSX/TSX:** 依 spec 為觀察項,pilot sample 不含,留待驗收後評估。
- **已知不確定性:** TS/JS 實際 scope 命名可能與第一版假設不同(尤其函式呼叫、decorator、型別 bold 與否)——這正是 Task 2/3 截圖自評迴路要解的;`entity.name.type`/`entity.name.function` 等中性規則的副作用由 Task 4 回歸把關。
```
