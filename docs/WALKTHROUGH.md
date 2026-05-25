# 變更紀錄與驗證說明 (Walkthrough v2)

本文件說明了針對「重新建構 3D 人物與本地資產快取系統 (v0.5.0)」的具體修改內容以及驗證方式。

---

## 修正內容說明

本次修正對自定義模型的載入與渲染流程進行了深度的重構，主要涉及 [CatAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/CatAppearance.lua) 與 [EquipmentAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/EquipmentAppearance.lua)。

```diff
-- 修正前：依靠 InsertService 從網路上 LoadAsset
- local success, model = pcall(function() return InsertService:LoadAsset(...) end)
- -- ❌ 在本地 Studio 協作開發時，因無非公開資產之權限會下載失敗 (HTTP 403)
- -- ❌ 導致身體被設為半透明，但配件一個都沒載入

-- 修正後：
+ -- 1. ✅ 本地資產快取機制
+ local localAsset = replicatedStorage.Assets:FindFirstChild(accessoryName) or ...
+ if localAsset then
+     -- 直接克隆本地物件穿戴，不受權限影響！
+ end
+ 
+ -- 2. ✅ 自動配件化改為「直接 Clone 原始 Mesh 命名為 Handle」
+ local handle = foundMesh:Clone()
+ handle.Name = "Handle"
+ -- 避免了原先手動轉 SpecialMesh 丟失的 Size 縮放、材質顏色、PBR 貼圖屬性！
```

### 1. 本地快取與直接 Clone 重構 (`CatAppearance.lua`)
- **本地快取機制 (Local Assets Cache)**：在呼叫 LoadAsset 之前，優先在 `ReplicatedStorage.Assets` 與 `ReplicatedStorage` 根目錄中檢查是否存在與配件同名（或去前綴同名）的本地實體物件（如白貓 Suit、頭套 Hood 等）。若存在則直接 `Clone` 並套用。**這讓開發者只要在 Studio 中將匯入的 3D 模型放進 ReplicatedStorage，就能 100% 成功渲染。**
- **直接克隆技術 (Direct Clone)**：在遠端資產載入成功且需要轉換配件時，不再手動拷貝屬性到 SpecialMesh。而是直接 `Clone` 原始的 `MeshPart` 或 `SpecialMesh` 並重新命名為 `Handle` 裝入 `Accessory`。這能 100% 保留 3D 模型的原始材質、顏色、`Size` 尺寸與 PBR 貼圖元件（`SurfaceAppearance`）。
- **透明度安全防禦**：如果由於任何原因（例如未上架、無本地實體等）導致沒有任何自定義配件套用成功（`appliedAnything == false`），系統會將標準身體的透明度恢復為 `0`，避免角色變成半透明隱形人。

### 2. 裝備載入機制重構 (`EquipmentAppearance.lua`)
- **同步快取與克隆**：帽子（Hat）、項圈（Collar）及武器（Weapon）同步導入了本地資產快取搜尋與直接 `Clone` 的自動轉換邏輯，確保自定義 3D 裝備也能在 Studio 測試與正式服中完美呈現。

---

## 驗證步驟

### 1. 本地 Studio 快取測試
1. 在您的 Roblox Studio 中，於 `ReplicatedStorage` 底下建立一個 `Folder` 命名為 `Assets`。
2. 將您匯入好的 3D 貓咪身體模型命名為 `CatSuit` (或 `whiteCatSuit`) 並放入該資料夾。
3. 將您匯入好的 3D 貓咪頭套模型命名為 `CatHood` 並放入該資料夾。
4. 執行 **Play (F5)**，若輸出日誌看到：
   - `[CatAppearance] 找到本地預存 CatSuit 資產, 直接 Clone 套用: ...`
   - `[CatAppearance] 找到本地預存 CatHood 資產, 直接 Clone 套用: ...`
5. 檢查角色，客製貓套裝應能完美顯示，且尺寸與貼圖均無失真。

### 2. 失敗回退安全測試
1. 移除 `ReplicatedStorage` 中所有的本地資產，且故意斷開網路或使用無法下載的 ID。
2. 執行測試，確認角色身體透明度為 `0` (正常不透明身體)，不會變成半透明，且輸出警告：`未能套用任何自訂組件，保持原始身體顯示 (Alpha 0)`。
