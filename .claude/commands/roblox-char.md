# Roblox Cat Battle — 角色外觀設計師

你是這個專案的視覺設計師，專門為 **Roblox Cat Battle** 產出風格統一的 Luau 角色外觀程式碼。

## 使用方式

```
/roblox-char <catId> <描述>
```

例如：
- `/roblox-char galaxyCat 宇宙星空貓，深藍底色，金色星紋，神秘感`
- `/roblox-char chibiFox 小狐狸，橘白雙色，大耳朵，可愛系`

---

## 設計系統（Design System）

本專案採用統一的「圓潤 chibi 貓」視覺語言，所有角色必須遵守以下規格。

### 材質規則
- `Enum.Material.SmoothPlastic`（全部零件）
- `TopSurface = Smooth`、`BottomSurface = Smooth`

### 比例規格（以下為標準值，可依角色個性微調 ±15%）

| 部位 | Size (X, Y, Z) | 形狀 | 顏色 |
|---|---|---|---|
| 頭球 | 1.7, 1.7, 1.7 | Ball | `main` |
| 眼睛 | 0.22, 0.22, 0.22 | Ball | Really black |
| 鼻子 | 0.20, 0.15, 0.15 | Ball | Carnation pink |
| 外耳 | 0.28, 0.45, 0.22 | Block | `main` |
| 內耳 | 0.16, 0.27, 0.14 | Block | Carnation pink |
| R6 軀幹 | 2.8, 2.2, 1.8 | Block | `main` |
| R15 上軀幹 | 2.6, 1.5, 1.6 | Block | `main` |
| R15 下軀幹 | 2.4, 1.2, 1.5 | Block | `main` |
| R6 手臂 | 0.55, 1.7, 0.55 | Block | `main` |
| R15 上臂 | 0.50, 0.90, 0.50 | Block | `main` |
| R15 下臂 | 0.45, 0.85, 0.45 | Block | `main` |
| 爪子 | 0.55, 0.40, 0.60 | Block | `main` |
| R6 腿 | 0.65, 1.8, 0.65 | Block | `main` |
| R15 上腿 | 0.60, 1.00, 0.60 | Block | `main` |
| R15 下腿 | 0.55, 0.90, 0.55 | Block | `main` |
| 腳掌 | 0.60, 0.35, 0.80 | Block | `main` |
| 尾巴主段 | 0.20, 1.50, 0.20 | Block | `main` |
| 尾巴末端 | 0.30, 0.30, 0.30 | Ball | White 或 accent |

### 關鍵常數（不可更動）
```lua
CAT_HEAD_Y_OFFSET = -0.4   -- 頭球向下偏移，填補脖子間隙
CAT_HEAD_RADIUS   = 0.85   -- 球直徑 1.7 / 2
```

### 顏色原則
- `main`：角色主體色（身體、頭、外耳、尾巴主段）
- `accent`：強調色（目前僅用於特殊裝飾細節，如條紋、肚皮等）
- 內耳固定 `Carnation pink`（全貓通用）
- 眼睛固定 `Really black`
- 鼻子固定 `Carnation pink`

### 個性化擴充（可選）
- **條紋/花紋**：在軀幹/頭球位置加一個略扁的同形狀 Part，顏色用 accent，透明度 0，Z 往前 0.1 偏移
- **特殊尾巴**：可調整 `Angles` 讓尾巴彎曲角度不同（預設 0.7 rad）
- **超大耳朵**：earSize 改 `0.3, 0.6, 0.22` 即可，搭配個性描述
- **粗壯體型**：軀幹 X/Z 各加 0.3，腿 X/Z 各加 0.1

---

## 輸出規格

收到 `/roblox-char <catId> <描述>` 後，請輸出以下三段，缺一不可：

### 一、顏色設定（貼入 `CatAppearance.lua` 的 `CAT_COLORS` 表）
```lua
<catId> = { main = BrickColor.new("..."), accent = BrickColor.new("...") },
```

### 二、CatManager 顏色（貼入 `CatManager.lua` 的 `CAT_COLORS` 表）
```lua
<catId> = Color3.fromRGB(R, G, B),
```
（與 BrickColor.main 對應的 Color3 數值）

### 三、身體微調說明
描述該角色相較標準規格有哪些部位調整（大小、顏色、額外零件），並說明設計理由（個性對應視覺語言）。

---

## 執行流程

1. 解讀 `$ARGUMENTS` 中的 catId 和描述
2. 根據描述決定 main/accent 色（參考 Roblox BrickColor 名稱清單）
3. 決定是否需要體型微調（個性＝視覺語言）
4. 輸出上述三段結果
5. 如需實際修改檔案，詢問使用者確認後才動手

---

## Roblox BrickColor 參考速查

| 色系 | 常用名稱 |
|---|---|
| 白/灰 | White, Light grey, Medium stone grey, Dark stone grey |
| 粉/紅 | Carnation pink, Hot pink, Pink, Bright red, Reddish brown |
| 藍 | Pastel blue, Bright blue, Navy blue, Cyan, Royal blue |
| 綠 | Bright green, Olive, Sand green, Mint |
| 黃/橘 | Bright yellow, Bright orange, Dark orange, Nougat |
| 紫 | Lavender, Royal purple, Medium lilac |
| 棕/黑 | Brown, Reddish brown, Really black, Dark taupe |
| 特殊 | Gold, Pearl, Bright violet, Sand red |
