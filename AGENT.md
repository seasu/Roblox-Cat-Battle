# 🏚️ Poor Man's Agent Team (P.M.A.T.) - Project Brain (貓咪大戰)

## 📍 1. 當前會話快照 (Context Snapshot)
> **STATUS:** 任務進行中 - 已實作版本管理。
- **Version:** `v0.1.2`
- **Last Sync:** 2026-05-04
- **Battery Level:** 🟢 [電量充足]
- **Project Goal:** 打造一款高品質的 Roblox 貓咪戰鬥 RPG 遊戲，具備完整的數值系統、裝備系統與 PvP/PvE 玩法。
- **Current Task:** 已修復攻擊動畫被預設系統覆蓋的問題，改用 RunService 強制同步。
- **Next Step:** 根據 `PRD.md` 與 `GAME_DESIGN.md` 開始開發核心系統。

---

## 🎭 2. AI 團隊角色定義 (Role Shifting Protocol)
本專案採用「角色動態切換」機制以節省 Token。請根據指令切換模式：

| 角色 (Role) | 職責描述 (Responsibilities) | 關注檔案 (Focus) |
| :--- | :--- | :--- |
| **Architect** | 全局架構、技術選型、撰寫規劃文檔。 | `AGENT.md`, `PRD.md`, `GAME_DESIGN.md` |
| **Developer** | 功能實作、撰寫 Luau 代碼、修改 `default.project.json`。 | `src/`, `default.project.json` |
| **Reviewer** | 程式碼審查、Debug、數值平衡檢查。 | 變動的 Diff, Test Logs |
| **Skill Extractor**| 分析 CI/CD 配置，將部署邏輯模組化。 | `.github/workflows/`, `SKILLS/` |

---

## 🛠️ 3. 跨工具協作規範 (Cross-Tool Protocol)
1. **SSOT (唯一事實來源):** 本檔案 `AGENT.md` 是專案的大腦。任何工具在啟動時必須先讀取此檔案。
2. **技能調度 (Skill Dispatch):** 當涉及 CI/CD、部署或特定平台操作時，AI 必須主動讀取 `SKILLS/` 目錄下的對應 `SKILL.md`。
3. **電量預警機制 (Battery Protocol):** 
   - 監控對話長度。🟢/🟡/🔴 標記。
4. **存檔指令 (`/checkpoint`):** 摘要進度並更新 `[CURRENT_STATE]`。
5. **語言規範:** **所有回覆一律使用繁體中文。**

---

## 📁 4. 專案開發規範 (來自 CLAUDE.md)
- **Rojo 管理:** 所有的物件結構都應在 `default.project.json` 中定義。
- **Luau 編碼:** 強型別優先，使用 `camelCase` 命名，異步處理必用 `pcall`。
- **系統模組化:** 邏輯封裝在 `ModuleScript` 中。
- **變更記錄:** 每次修改後必須更新 `GAME_DESIGN.md` 中的系統狀態。

---

## 🚀 5. 技能索引 (Skill Index)
- `SKILLS/roblox-deploy/`: 透過 Rojo 與 Open Cloud API 部署 Roblox 遊戲。

---

## 🎙️ 6. 語音開發協議 (Voice-First Development)
- 透過語音輸入指令時，AI 應先摘要「我理解的任務是...」，確認後再執行。
- 自動過濾贅字。

---

## 📜 7. 給接手 AI (Gemini CLI) 的特別指令
1. **初始化:** 讀取此文件後，先確認具備檔案與 Git 權限。
2. **任務優先:** 查閱 `GAME_DESIGN.md` 以了解當前開發進度。
3. **保持自律:** 僅在需要時讀取代碼，節省 Token。
