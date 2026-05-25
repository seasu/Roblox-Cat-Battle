# 變更紀錄與驗證說明 (Walkthrough)

本文件說明了針對「自定義 3D 模型與裝備無法正常顯示問題」的具體修改內容以及驗證方式。

---

## 修正內容說明

本次修正核心圍繞在 [CatAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/CatAppearance.lua) 與 [EquipmentAppearance.lua](file:///Users/seasu.wang/Downloads/Projects/Roblox-Cat-Battle-main/src/server/EquipmentAppearance.lua) 的 3D 資產轉換邏輯。

```diff
-- 修正前：將 MeshPart 轉換為 SpecialMesh 時
- mesh.MeshId = foundMesh.MeshId
- mesh.TextureId = foundMesh.TextureID
- -- ❌ 丟失了 foundMesh.Size 縮放，導致其被預設的 1x1x1 Part 大小吞噬
- -- ❌ 建立了全新無 CFrame 偏移的 Attachment，導致掛載位置與旋轉錯誤

-- 修正後：
+ mesh.MeshId = foundMesh.MeshId
+ mesh.TextureId = (foundMesh.TextureID ~= "" and foundMesh.TextureID) or textureId or ""
+ mesh.Scale = foundMesh.Size -- ✅ 保留原始 MeshPart 的尺寸縮放
+ 
+ -- ✅ 遞迴尋找來源資產中的 Attachment 並複製，保留原有掛載對齊與偏移
+ local existingAtt = foundMesh:FindFirstChildOfClass("Attachment") or ...
+ if existingAtt then
+     att = existingAtt:Clone()
+ end
```

### 1. 貓咪身體與配件加載優化 (`CatAppearance.lua`)
- **Size 縮放保留**：當自定義的貓咪連身衣（Suit）或頭套（Hood）為 `MeshPart` 且無預設 Accessory 包裝時，自動配件化轉換會將 `SpecialMesh.Scale` 設置為 `foundMesh.Size`，以保持原本建模的縮放。
- **CFrame 偏移保留**：遞迴搜尋該資產內是否已定義 `Attachment`，如果有則直接 Clone 並沿用，完美保留原本設定的掛載位置與角度；否則才建立預設掛載點。
- **頭部貼圖回傳與回退修復**：
  - `applyAccessory` 函數增加傳入 `textureId` 參數，以便在無法載入時套用正確的貼圖。
  - 當頭部配件的 `LoadAsset` 載入失敗（例如 403 權限拒絕）時，直接回傳 `false`，觸發可靠的 Weld 貼合模式（`createVisualPart`），以確保頭部即使無權限加載 Model 也能百分之百渲染出來。

### 2. 裝備加載優化 (`EquipmentAppearance.lua`)
- **同步轉換與備案**：對帽子（Hat）、項圈（Collar）及武器（Weapon）裝備套用與 `CatAppearance` 相同的自動轉換邏輯，包含 `MeshPart.Size` 的縮放保留、`Attachment` 的 CFrame 偏移保留，以及 `LoadAsset` 失敗時強制以原始 Mesh ID 套用配件的終極備案。

### 3. 配置與日誌更新
- **GameConfig**：版本號升級為 `v0.4.7`。
- **GAME_DESIGN**：更新設計文件與變更日誌。

---

## 驗證步驟

### 1. 語法與同步編譯驗證
您可以啟動 `Rojo` 伺服器並同步檔案至 Roblox Studio：
```bash
rojo serve
```
確認所有程式碼在 Rojo 中同步正常，無 Luau 語法報錯。

### 2. 遊戲內外觀實測
1. 進入 Roblox Studio 執行 **Play (F5)**。
2. 開啟伺服器輸出日誌 (Output)，若看見以下輸出，代表修復成功運作：
   - `[CatAppearance] 嘗試載入資產 ID: ...`
   - `[CatAppearance] 成功複製並沿用來源模型原有 Attachment: ... CFrame: ...`
   - `[EquipmentAppearance] 成功將裝備內容轉換為配件: ...`
3. 觀察角色，檢查自定義的 3D 套裝（Suit）、頭套（Hood）以及戴上的帽子與武器是否顯示正常、無歪斜且尺寸正確。
