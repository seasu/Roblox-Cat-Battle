# 實作計畫 — 修復自定義 3D 模型無法顯示問題

本計畫旨在解決遊戲中自定義 3D 模型（自定義貓咪身體 Suit、頭套 Hood、裝備等）載入後無法正常顯示、尺寸縮水（變為 1x1x1）或位置歪斜的核心問題。

## 使用者審查請求

> [!IMPORTANT]
> **根本原因分析：**
> 1. **MeshPart 轉換縮放丟失**：當自定義 3D 模型（通常為 `MeshPart`）透過 `InsertService:LoadAsset` 載入時，若內部無預設 `Accessory`，系統會執行「自動配件化轉換」。然而在將 `MeshPart` 轉換為 `SpecialMesh` 時，**未設定 `SpecialMesh.Scale`**，導致其尺寸直接縮小為 `Vector3.new(1, 1, 1)`，埋在角色身體內部而看不見。
> 2. **對齊偏移丟失**：在自動配件化時，程式碼建立了一個全新且無偏移的 `Attachment`（`CFrame.new(0,0,0)`），丟棄了原本模型中可能設定的掛載位置與旋轉偏移，導致模型歪斜。
> 3. **終極備案無效回傳**：當 `LoadAsset` 失敗（例如 HTTP 403 權限問題）時，終極備案建立了無效配件並直接回傳 `true`，使得頭套（Hood）無法正常回退至不受權限限制的「舊有 Mesh 貼合模式（`createVisualPart`）」。

---

## 預估變更範圍

### 1. 核心外觀管理器修復

#### [MODIFY] [CatAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/CatAppearance.lua)
- 修改 `applyAccessory` 函數簽章，接受 `textureId` 參數，以便在備案中正確指定貼圖。
- 優化轉換邏輯：
  - 若來源是 `MeshPart`，將 `SpecialMesh.Scale` 設為 `foundMesh.Size`，以保持原本尺寸。
  - 遞迴尋找來源模型中的 `Attachment`。如果存在，複製該 `Attachment` 並保留其 `CFrame` 偏移量。
  - 若來源模型中沒有 `Attachment`，再建立預設的 `Attachment`。
- 修改終極備案：若 `LoadAsset` 失敗且無法判斷為有效 Mesh，或是當該資產不符合原始 Mesh 模式時，回傳 `false`，以便觸發頭套的 Weld 回退模式。

### 2. 裝備外觀管理器修復（同步優化）

#### [MODIFY] [EquipmentAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/EquipmentAppearance.lua)
- 將類似的 Accessory 轉換與縮放保留邏輯套用至 `EquipmentAppearance.lua`，確保 3D 裝備（例如武器、項圈、帽子）若發生自動轉換時也不會縮小或歪斜。

### 3. 版本號與變更日誌更新

#### [MODIFY] [GameConfig.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/shared/GameConfig.lua)
- 更新版本號：`v0.4.6` -> `v0.4.7`

#### [MODIFY] [GAME_DESIGN.md](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/docs/GAME_DESIGN.md)
- 新增 `v0.4.7` 的變更日誌。

---

## 驗證計畫

### 手動驗證
1. 進入 Roblox Studio 執行測試。
2. 切換至使用自定義 3D 模型的貓咪（例如 `whiteCat` 具有 Suit 與 Hood）。
3. 觀察輸出日誌，確認自定義配件的載入模式與轉換日誌。
4. 檢查角色外觀，確認：
   - 貓咪頭套（Hood）與身體（Suit）是否完整顯示，沒有縮水。
   - 貼圖與配色是否正常套用。
   - 裝備配件（如巫師帽、迷你劍）是否正常對齊手部與頭部，無位移偏差。
