# 實作計畫 (v2) — 重新建構 3D 人物與自定義模型載入系統

為了解決本地 Studio 開發時 `InsertService:LoadAsset` 權限受限（HTTP 403）導致的貓套裝無法顯示、以及資產包轉換為配件時屬性遺失的痛點，本計畫將重新建構 3D 人物與裝備配件的載入機制。

## 使用者審查請求

> [!IMPORTANT]
> **新架構解決方案：**
> 1. **新增本地快取機制 (Local Assets Cache)**：在 `applyAccessory` 開始時，優先在 `ReplicatedStorage.Assets` 或 `ReplicatedStorage` 根目錄中尋找與配件同名（或去前綴同名）的本地實體物件（如 `Accessory`、`Model`、`MeshPart`）。若存在則直接 `Clone` 穿戴。**這能讓您在 Studio 本地測試時，只需將匯入好的 3D 模型拖入 ReplicatedStorage，即可 100% 成功套用，不受 Roblox 雲端權限限制。**
> 2. **重構自動轉換為直接克隆 (Direct Clone)**：在 `InsertService:LoadAsset` 成功但內部無 Accessory 時，不再手動建立 `Part + SpecialMesh` 並手動拷貝屬性。改為**直接 Clone 該 MeshPart 並重新命名為 Handle**。這能完整保留原本 3D 模型的所有 `Size`（防止縮水）、材質、顏色、以及 PBR 材質元組件（`SurfaceAppearance`）。
> 3. **健全的 Weld 回退與透明度防禦**：如果所有套用皆告失敗，系統會確保將身體透明度設回 `0`，防止角色在載入失敗時變成半透明隱形人。

---

## 預估變更範圍

### 1. 貓咪外觀管理器重構

#### [MODIFY] [CatAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/CatAppearance.lua)
- 重構 `applyAccessory` 函數：
  - 優先檢查 `ReplicatedStorage.Assets` 與 `ReplicatedStorage` 底下是否有本機預存物件，若有則直接克隆套用。
  - 當 `LoadAsset` 成功且需要配件化時，直接 `Clone` 原始 `MeshPart` 或 `SpecialMesh` 並更名為 `Handle`，保留其完整屬性。
  - 修復 `LoadAsset` 失敗時，若為頭套（CatHood）則回傳 `false` 觸發舊有 `Weld` 貼合。
- 優化透明度處理：若 `appliedAnything` 為 `false`，必須將角色身體透明度恢復為 `0`。

### 2. 裝備外觀管理器重構

#### [MODIFY] [EquipmentAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/EquipmentAppearance.lua)
- 引入相同的本地快取搜尋機制（搜尋 `ReplicatedStorage` 中與 `itemName` 或 `EqVis_itemName` 相同的本地資產）。
- 重構自動轉換邏輯，改為直接 `Clone` 原始裝備模型，保留尺寸與對齊 CFrame。

### 3. 版本與日誌更新

#### [MODIFY] [GameConfig.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/shared/GameConfig.lua)
- 更新版本號：`v0.4.7` -> `v0.5.0`（因重大重構，我們將其升級為 `v0.5.0`）。

#### [MODIFY] [GAME_DESIGN.md](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/docs/GAME_DESIGN.md)
- 更新版本與變更日誌。

---

## 驗證計畫

### 1. 本地預存快取測試 (Studio 測試)
1. 在 Roblox Studio 的 `ReplicatedStorage` 下建立名為 `Assets` 的資料夾。
2. 將您的自定義貓咪身體模型 (例如匯入的 MeshPart) 放入 `Assets` 資料夾中，並命名為 `CatSuit`。
3. 將您的自定義貓頭套模型放入 `Assets` 並命名為 `CatHood`。
4. 執行 Play 測試，驗證角色是否能 100% 套用本地的 `CatSuit` 與 `CatHood`。

### 2. 正式伺服器資產載入測試
1. 當發佈至正式服時，系統會自動在 `InsertService:LoadAsset` 載入雲端資產，並在無 Accessory 時進行直接克隆，驗證 PBR 貼圖與尺寸是否正確。
