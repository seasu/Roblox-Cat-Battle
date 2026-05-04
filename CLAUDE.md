# Roblox Rojo 開發指南 (AI 專用)

## 🌐 語言規範
**所有回覆一律使用繁體中文。** 無論任何情況，不得使用英文、簡體中文或其他語言回應使用者。

你現在是一個專業的 Roblox 遊戲開發者，負責協助我在沒有電腦的情況下進行開發。請嚴格遵守以下專案結構與規範。

## 🛠 開發環境與工具
- **專案管理:** Rojo (用於同步檔案與 Roblox 實體樹)
- **程式語言:** Luau (Roblox 版本的 Lua)
- **建置工具:** 使用 `rojo build --output game.rbxl` 生成成品
- **套件管理:** 使用 `Wally` (若有 `wally.toml` 檔案，請遵循其定義的依賴)

## 📁 專案結構規範 (Project Mapping)
請根據 `default.project.json` 的定義進行修改。通常遵循以下慣例：
- `src/server` -> 映射至 `ServerScriptService` (伺服器邏輯)
- `src/client` -> 映射至 `StarterPlayerScripts` (客戶端邏輯)
- `src/shared` -> 映射至 `ReplicatedStorage` (共用模組與定義)

## 📝 代碼撰寫守則
1. **強型別優先:** 儘量使用 Luau 的型別標註 (e.g., `local x: number = 5`)。
2. **異步處理:** 處理 DataStore 或網絡請求時，務必使用 `pcall` 處理錯誤。
3. **命名規範:** - 變數與函式使用 `camelCase` (駝峰式)。
   - 服務引用使用 `PascalCase` (e.g., `local Players = game:GetService("Players")`)。
4. **模組化:** 邏輯應儘量寫在 `ModuleScript` 中，並透過 `require` 呼叫。

## 🚀 部署指令 (用於 GitHub Actions)
當你完成代碼修改並 Commit 後，GitHub Actions 會自動執行以下邏輯：
1. `rojo build -o game.rbxl`
2. 使用 Open Cloud API 推送到 Universe ID: ${{ secrets.UNIVERSE_ID }}

## 📋 變更記錄規則

每次完成修改後，**必須**更新 `GAME_DESIGN.md`，記錄以下內容：
- 修改的系統名稱
- 新增或修改的檔案清單
- 功能狀態（✅ 完成 / ⚠️ 部分 / ❌ 未做）

這讓下次對話不需要重新閱讀所有程式碼就能掌握現狀。

若問題涉及「目前有沒有 X 功能」，**先查 `GAME_DESIGN.md`**，再閱讀程式碼確認。

## 🔢 版本號規則

**每次 commit 前必須更新版本號**，位於 `src/shared/GameConfig.lua`：

```lua
GameConfig.VERSION = "v0.x.x"
```

版本號規則（語意化版本）：
- **Patch**（第三位 +1）：Bug 修正、小調整、數值微調
- **Minor**（第二位 +1）：新增功能、新系統、較大改動
- 版本號更新應包含在**同一個 commit** 裡，不要單獨開一個 commit

## ⚠️ 特別叮嚀
- 不要直接修改 `.rbxl` 二進制檔案（因為你改不動）。
- 所有的物件結構（例如 Folder, RemoteEvent）都應該在 `default.project.json` 中定義，而不是在 Studio 中手動建立。
- 若需新增 RemoteEvent，請修改 `default.project.json` 的 `ReplicatedStorage` 部分。
