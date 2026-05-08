# Roblox Cat Battle — 遊戲設計文件 & 實作狀態

> **Current Version:** `v0.4.5`
> 每次修改後請更新此文件，避免重複閱讀全部程式碼。

---

## 系統實作狀態總覽

| 系統 | 後端 | 前端 UI | 備註 |
|---|---|---|---|
| 玩家資料 / DataStore | ✅ | — | DataStore.lua，指數退避重試 |
| 貓咪選擇 | ✅ | ✅ | 商城貓咪 tab 已加入「切換使用」按鈕 |
| 貓咪外觀（高質感 3D） | ✅ | ✅ | v0.4.5: 精準透明度排除 + 音效 ID 修復 + 強化配件轉換 |
| 等級 / 經驗值 | ✅ | ✅ | XP bar + 升級 toast |
| 技能系統 | ✅ | ✅ | 技能列 Q/E/R/F，冷卻 overlay |
| 基礎攻擊 / 點擊 NPC | ✅ | ✅ | CombatClient 射線偵測 |
| 武器 / 裝備系統 | ✅ | ✅ | v0.4.0: 支援 3D Mesh 武器與層疊服裝 |
| 商城（Robux 買貓） | ✅ | ✅ | 商城貓咪 tab |
| 商城（金幣買裝備） | ✅ | ✅ | 商城裝備 tab，BuyEquipment 事件 |
| 寵物合成系統 | ✅ | ✅ | 碎片 drop + 合成後端 + 合成 tab |
| NPC 生成 / AI | ✅ | — | 三種 NPC 類型，追逐 + 漫步 |
| PvP 系統 | ✅ | ✅ | 新增 PvP 面板（列出線上玩家，可點擊發起挑戰） |
| 地圖 / 場景 | ✅ | — | WorldSetup，3 區圍繞出生點 |
| 3D 商店攤位 | ✅ | ✅ | 出生點南方 3 棟建築，ProximityPrompt 觸發商城各 tab |
| HP 顯示 / 自動回復 | ✅ | — | AlwaysOn + 每秒 +1 HP |
| 視覺重做 Phase 2 | ✅ | ✅ | HUD 重排（金幣圖示/等級徽章）、卡片 UIStroke + 底板、鞋貓劍客待機 Pose (C0) |
| 待機姿勢重構 | ✅ | — | setupCatWalkTilt 改用 StateChanged + TweenService，移除 RenderStepped 每幀 Lerp/sin |

---

## 地圖佈局

- **出生點**：(0, 0.5, 0)
- **玩偶區**（最簡單）：X = -150，size 120×120
- **野貓區**（中等）：Z = -150，size 120×120
- **野人區**（最難）：X = +150，size 120×120
- 地圖邊界：620×620

### 安全區（怪物不追、不攻擊）

| 區域 | 形狀 | 範圍 |
|---|---|---|
| 出生點廣場 | 圓形 | 中心 (0,0,0)，半徑 55 格 |
| 商城攤位區 | 矩形 | X=-42~42，Z=10~72（完整包含三棟建築） |

- 淡青綠色（Mint）SmoothPlastic 地板，透明度 0.72
- BillboardGui 文字標示「🛡 安全區域」，不用 Neon 光板
- NPC 進入追逐後，玩家只要跑進安全區，NPC 立即放棄並返回原位

---

## 貓咪設計

### 貓咪清單（9 種）

| catId | 名稱 | 價格 | 固有技能 | 設計定位 |
|---|---|---|---|---|
| whiteCat | 白貓 | 免費 | BasicSwipe | 初始貓，全階段成長 |
| shadowCat | 暗影貓 | 200 RB | ShadowStrike, Vanish | 暗殺刺客 |
| flameCat | 烈焰貓 | 350 RB | FireClaw, EmberAura | 爆發狂戰 |
| frostCat | 冰霜貓 | 350 RB | IceShard, FrostAura | 控場減速 |
| thunderCat | 雷霆貓 | 500 RB | ThunderPounce, ChainLightning | AoE 群攻 |
| sakuraCat | 櫻花貓 | 450 RB | PetalSlash, HealingBloom | 攻守均衡 |
| orangeCat | 橘貓 | 300 RB | OrangeFury, FoodRage | 低血爆發坦 |
| calicoCat | 三花貓 | 400 RB | LuckyCharm, ColorShift | 魔法元素系 |
| tuxedoCat | 賓士貓 | 500 RB | GentlemanStrike, TailcoatShield | 高暴擊精準 |

### 貓咪外觀設計系統

設計語言：圓潤 chibi 貓，所有 Parts 以 SmoothPlastic 製作
- **顏色規則**：`main` = 身體 / 頭 / 外耳 / 尾段；`accent` = 尾巴末端球
- **頭球偏移**：`CAT_HEAD_Y_OFFSET = -0.4`（填補脖子間隙）
- 配件（頭髮）一律隱藏

新增貓咪請使用 `/roblox-char <catId> <描述>` slash command。

---

### 主角角色重設方案（2026-05-05）

- **角色骨架策略**：主角改為 Roblox 預設人物骨架（R15 為主），戰鬥、移動、受擊一律優先沿用預設 Animation Controller。
- **外觀策略**：貓咪改為「套裝／配件層」表現（耳朵、尾巴、臉部貼圖、服裝件），不再做整套自訂身體 Part 替換。
- **動畫策略**：
  - 基礎攻擊、技能揮擊、受擊、待機全部先套用預設動畫，僅保留必要的特效與數值觸發。
  - 暫停所有客製關節 Tween/Transform 疊加流程，避免與預設 Animator 搶寫關節造成動作失效。
- **實作效益**：
  - 大幅降低實作複雜度與維護成本。
  - 降低跨平台（PC / Mobile）動作不一致風險。
  - 先保證「可玩＋穩定」，後續再逐步替換成高品質專屬動畫。
- **相容備註**：技能傷害判定與冷卻邏輯維持伺服器權威，不受外觀方案調整影響。

## 寵物合成系統

- 擊殺 NPC 有機率掉落隨機特殊貓碎片
  - 玩偶：8%，野貓：15%，野人：22%
- 收集 **10 個** 相同碎片 → 開啟商城合成 tab → 點「合成」
- 碎片存在 `PlayerData.catFragments = { [catId]: number }`
- 相關事件：`UpdateFragments`（server→client），`SynthesizeCat`（client→server），`SynthesisResult`（server→client）

---

## 裝備系統

3 槽位：項圈 / 帽子 / 武器，各 4 件，均以金幣購買

| 槽位 | 物品 | 價格 | 主要加成 |
|---|---|---|---|
| collar | 基礎項圈 | 50 | +DEF 2, +HP 10 |
| collar | 尖刺項圈 | 150 | +ATK 5, +DEF 3 |
| collar | 治癒項圈 | 200 | +HP 30 |
| collar | 迅捷項圈 | 250 | +SPD 2 |
| hat | 巫師帽 | 180 | +ATK 8 |
| hat | 騎士頭盔 | 220 | +DEF 10, +HP 20 |
| hat | 戰鬥頭巾 | 160 | +ATK 5, +DEF 5 |
| hat | 金色皇冠 | 300 | 全面加成 |
| weapon | 鐵爪 | 200 | +ATK 10 |
| weapon | 迷你劍 | 280 | +ATK 15, -DEF 2 |
| weapon | 貓盾 | 260 | -ATK 2, +DEF 18 |
| weapon | 魔法杖 | 320 | +ATK 12, +SPD 2 |

購買流程：`BuyEquipment` event → ShopManager.handleBuyEquipment（扣金幣 + 裝備）

---

## RemoteEvent 清單

| Event | 方向 | 用途 |
|---|---|---|
| RequestLoadData | C→S | 請求玩家資料 |
| LoadDataResponse | S→C | 回傳完整 PlayerData |
| AddXP | S→C | 通知 XP 變化 |
| LevelUp | S→C | 升級通知 |
| UpdateCatAppearance | S→C | 推送外觀分階 |
| SelectCat | C→S | 切換使用的貓 |
| SpawnNPC | S→C | NPC 生成通知 |
| NPCDied | S→C | NPC 死亡特效 |
| PurchaseCat | C→S | Robux 購貓 |
| PurchaseResult | S→C | 購買結果 toast |
| EquipItem | C→S | 裝備物品 |
| UnequipItem | C→S | 卸下物品 |
| EquipmentChanged | S→C | 推送裝備配置 |
| BuyEquipment | C→S | 金幣購買並裝備 |
| UseSkill | C→S | 使用技能 |
| SkillResult | S→C | 技能結果 |
| SkillUnlocked | S→C | 新技能解鎖 |
| CombatHit | S→C | 傷害數字 |
| PlayerDied | S→C | 玩家死亡 |
| UpdateUI | S→C | 通用 UI 刷新（金幣） |
| RequestPvP | C→S | 發起 PvP 挑戰 |
| PvPInvite | S→C | PvP 邀請 |
| PvPAccepted | C→S | 接受 PvP |
| PvPResult | S→C | PvP 結果 |
| SynthesizeCat | C→S | 合成貓咪 |
| SynthesisResult | S→C | 合成結果 |
| UpdateFragments | S→C | 碎片數量更新 |

---

## 變更日誌

### 2026-05-08（v0.4.6）
- **資產加載相容性大升級 (Resilience Update)**：
  - **支援原始 Mesh ID**：重構 `applyAccessory` 邏輯，現在即便 `InsertService:LoadAsset` 因為權限或資產類型（例如使用者直接上傳的原始 Mesh）而失敗，系統也會自動轉換為 `SpecialMesh` 配件模式強制載入，解決 3D 元件不顯示的核心問題。
  - **Suit 備案機制**：為連身衣 (Suit) 新增了與頭套相同的備案機制，確保全身套裝在任何資產格式下都能成功套用。
  - **詳細診斷日誌**：新增更詳盡的伺服器輸出日誌，包含每一個資產 ID 的載入嘗試與最終採用的載入模式（Accessory 模式、轉換模式、或原始 Mesh 模式）。
- **版本號更新**：升級至 `v0.4.6`。

### 2026-05-06（v0.4.5）
- **外觀系統終極加固**：
  - **精準透明度控制**：重構 `setBodyTransparency`，現在會針對 R15/R6 的標準部位名稱清單進行操作，並嚴格排除所有 `Accessory` 內部的組件，徹底解決自訂貓咪部位被誤設為透明的問題。
  - **音效系統更新**：更換了不相容的音效 ID，解決「Asset type does not match」報錯。
  - **配件轉換強化**：優化了從 `MeshPart` 到 `Accessory` 的自動轉換邏輯，現在會根據物件名稱自動選擇 `HatAttachment` 或 `BodyFrontAttachment` 進行定位。
  - **徹底移除 MeshPart 寫入**：清除了所有可能導致 `MeshId` 寫入權限報錯的代碼路徑。
- **版本號更新**：升級至 `v0.4.5`。

### 2026-05-06（v0.4.4）
- **穩定性修復與相容性強化**：
  - **資產加載最佳化**：針對資產包（Model）內部的 Accessory 改用遞迴搜尋（`true` 參數），解決部分資產因層級過深導致無法辨識的問題。
  - **虛擬配件備案**：新增「自動轉換機制」，若資產不是 `Accessory` 而是 `MeshPart` 或 `SpecialMesh`，程式會自動建立一個虛擬配件並掛載對應的 `Attachment`，確保套裝（Suit）與頭套（Hood）一定能正確定位。
  - **Enum 錯誤修復**：修正 `CombatClient.lua` 中錯誤引用 `Enum.HumanoidStateType.Idle` 的問題（應為 `None`）。
  - **除錯日誌細化**：進一步強化載入過程的詳細日誌，追蹤每一個步驟的執行結果。

### 2026-05-06（v0.4.3）
- **視覺除錯 (Visual Debugging)**：針對套裝不顯示的問題開啟除錯模式。
  - **日誌強化**：在伺服器端增加詳細的套用過程日誌，包含連身衣、頭部配件、頭部備案、尾巴的載入狀態。
  - **透明度調整**：將自動隱藏原始身體的透明度從 `1` 改為 `0.7`。這可以讓我們確認：
    1. 原始身體是否確實被正確辨識並設定透明度。
    2. 自訂貓咪組件是否有成功出現（即便位置或渲染有誤，在 0.7 透明度下應該能看見重疊部分）。
- **版本號更新**：升級至 `v0.4.3`。

### 2026-05-06（v0.4.2）
- **Bug 修復**：解決了貓咪套裝（Suit/Hood）在部分情況下完全不顯示的問題。
  - **核心渲染修復**：將 `MeshPart` 改為 `Part` + `SpecialMesh` 架構，解決在執行階段透過腳本動態建立 `MeshPart` 導致的渲染失效問題。
  - **R6/R15 兼容性**：新增對 R6 骨架的支援，現在尾巴會自動找尋 `Torso` 並套用正確位移。
  - **載入邏輯優化**：為頭部新增了 Accessory 與純 Mesh 的雙重備案機制，確保即便資產載入失敗也能顯示基礎外觀。

### 2026-05-06（v0.4.1）
- **Bug 修復**：解決了角色在遊戲開始時變為隱形的 Bug。
  - 優化 `CatAppearance.lua` 中的透明度設定邏輯，現在會智慧跳過自訂貓咪部位與配件。
  - 增加外觀載入失敗時的自動降級顯示機制（原始身體染色顯示）。
- **流程規範**：建立 `GEMINI.md` 並強制執行每次調整程式碼皆需更新版本號與變更日誌的準則。

### 2026-05-05（v0.4.0）
- **高質感人物樣貌重做 (The 3D Overhaul)**：
  - **核心架構升級**：從基礎積木拼湊遷移至「R15 透明素體 + 高模 MeshPart」架構。
  - **3D 資產整合**：匯入高品質貓頭套 (Hood)、連身衣 (Suit)、英雄小劍與彎曲尾巴。
  - **動態表情系統**：新增自動眨眼與戰鬥表情切換邏輯。
  - **可愛 NPC 優化 (Cute NPC Overhaul)**：
    - **視覺重塑**：所有 NPC 模型重構為圓潤 Chibi 風格，並導入 3D 貓頭、貓尾資產。
    - **軟萌配色**：調整 NPC 配色為粉嫩、溫暖色系，並統一加入呆萌大眼睛與腮紅。
    - **主題命名**：將「布偶」升級為「軟綿綿布偶」，「野人」升級為「圓滾滾野人」，全面提升遊戲親和力。
  - **層疊服裝支援**：裝備系統支援 Accessory 與 WrapLayer，解決穿模問題。
  - **專案結構優化**：建立 `assets/`, `scripts/blender/`, `docs/` 等目錄進行規範化管理。

### 2026-05-05（v0.3.2）
- **主角重設決策**：採用「Roblox 預設人物 + 貓咪套裝」架構，停止全身自訂貓體替換為第一優先路線。
- **動畫策略收斂**：攻擊與技能動作改以預設動畫為主，降低客製動畫與步態系統衝突。
- **開發目標調整**：先以穩定、可維護為核心，後續再分階段補強專屬動作品質。

### 2026-05-04（v0.2.11）
- **攻擊動作根因修復**：盤查確認是「步態與攻擊動畫同時寫入肩關節 Transform」造成反覆失控與不顯示，`CombatClient.lua` 改為統一揮擊控制器（`endSwing`）、強化肩關節選取優先級，並在 AoE 揮擊也啟用 `swingActive` 守衛，避免再被步態覆蓋。
- **揮擊展現強化**：單體與 AoE 皆改為多關節（肩+肘）三段式，並加入雙手對稱揮擊與收招復位，攻擊可視性與可控性大幅提升。
- **主角可愛度重做**：`CatAppearance.lua` 重調頭身比、放大眼睛與高光、口鼻與腮紅比例、加入 W 形嘴，讓擬人貓更可愛且更精緻。
- **UI 視覺重構（第一階段）**：`UIManager.lua` 新增全域 Theme（色票、圓角、描邊、漸層）與通用樣式函式，套用到基礎元件工廠、主面板、技能列、死亡畫面、toast 等核心畫面；同時補上 `buildCard`，避免裝備面板潛在崩潰。
- **修改檔案**：`src/client/CombatClient.lua`、`src/client/UIManager.lua`、`src/server/CatAppearance.lua`、`src/shared/GameConfig.lua`
- **功能狀態**：貓咪外觀（全身替換）✅、基礎攻擊 / 點擊 NPC（前端步態與動作表現）✅、技能系統（UI 呈現）✅
