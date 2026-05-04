# 🎮 Skill: Roblox Build & Deploy (Rojo + Open Cloud)

## 📌 描述
本技能透過 Rojo 自動化建置 Roblox 遊戲檔案 (`.rbxl`)，並透過 Roblox Open Cloud API 將其部署至指定的 Place。支援全自動部署（推送到 main）與手動觸發（跨分支部署）。

## 🛠️ 觸發方式
1.  **建置驗證：** 任何分支推送都會觸發 Rojo Build，確保代碼可正確編譯。
2.  **自動部署：** 推送至 `main` 分支時，會自動部署到測試伺服器。
3.  **手動部署：** 透過 GitHub Actions 的 `workflow_dispatch` 手動觸發，可選擇任意分支進行部署。

## 🚀 技術細節
-   **Rojo 版本：** 使用 `7.4.4` (預設)。
-   **產出物：** `game.rbxl`，保留 7 天建置記錄。
-   **API 部署：** 使用 `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`。

## ⚙️ 關鍵環境變數與密鑰 (Secrets)
| 名稱 | 類型 | 描述 |
| :--- | :--- | :--- |
| `ROBLOX_API_KEY` | Secret | 具備 `universe:place:files:write` 權限的 API 金鑰 |
| `UNIVERSE_ID` | Secret | Roblox 專案的 Universe ID |
| `PLACE_ID` | Secret | 目標 Place 的數字 ID |

## 📝 開發者指令 (AI 指引)
當用戶要求「更新遊戲」或「部署到 Roblox」時：
1.  **驗證編譯：** 確保本地或 CI 的 Rojo 建置沒有 Error。
2.  **提交代碼：** `git add .` 並 `git commit -m "feat: [Roblox 功能更新]"`。
3.  **執行部署：**
    -   方法 A (自動)：`git push origin main`。
    -   方法 B (手動)：告知用戶「已完成代碼推送，請至 GitHub Actions 手動執行 Build & Deploy to Roblox 以跨分支部署」。
4.  **確認版本：** 部署成功後，告知用戶新的版本號 (Version Number)。

## ⚠️ 注意事項
-   **環境限制：** 部署目標通常為 `test-server` 環境。
-   **API 金鑰權限：** 若部署失敗 (HTTP 401/403)，請確認 API Key 的 IP 限制與權限設定。
