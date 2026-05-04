# Roblox Cat Battle — 遊戲設計文件 & 實作狀態

> **Current Version:** `v0.1.5`
> 每次修改後請更新此文件，避免重複閱讀全部程式碼。

---

## 系統實作狀態總覽

| 系統 | 後端 | 前端 UI | 備註 |
|---|---|---|---|
| 玩家資料 / DataStore | ✅ | — | DataStore.lua，指數退避重試 |
| 貓咪選擇 | ✅ | ✅ | 商城貓咪 tab 已加入「切換使用」按鈕 |
| 貓咪外觀（全身替換） | ✅ | — | CatAppearance.lua，R6/R15 均支援 |
| 等級 / 經驗值 | ✅ | ✅ | XP bar + 升級 toast |
| 技能系統 | ✅ | ✅ | 技能列 Q/E/R/F，冷卻 overlay |
| 基礎攻擊 / 點擊 NPC | ✅ | ✅ | CombatClient 射線偵測 |
| 武器 / 裝備系統 | ✅ | ✅ | ownedItems 永久持有，背包面板穿戴/卸下，商城只購買 | 商城裝備 tab + 裝備面板（⚔ 按鈕） |
| 商城（Robux 買貓） | ✅ | ✅ | 商城貓咪 tab |
| 商城（金幣買裝備） | ✅ | ✅ | 商城裝備 tab，BuyEquipment 事件 |
| 寵物合成系統 | ✅ | ✅ | 碎片 drop + 合成後端 + 合成 tab |
| NPC 生成 / AI | ✅ | — | 三種 NPC 類型，追逐 + 漫步 |
| PvP 系統 | ✅ | ✅ | 新增 PvP 面板（列出線上玩家，可點擊發起挑戰） |
| 地圖 / 場景 | ✅ | — | WorldSetup，3 區圍繞出生點 |
| 3D 商店攤位 | ✅ | ✅ | 出生點南方 3 棟建築，ProximityPrompt 觸發商城各 tab |
| HP 顯示 / 自動回復 | ✅ | — | AlwaysOn + 每秒 +1 HP |

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

### 2026-05-04（第十六批）
- **動畫與姿勢優化 (v0.1.7)**：
  - **揮手動畫修復**：重構 `getArmMotor` 邏輯，精準定位肩部關節，解決攻擊時「手不動」的 Bug。
  - **貓咪走路姿勢優化**：新增 `CatWalkTilt` 系統，移動時軀幹自動前傾 40 度，模擬四足動物奔跑感。
  - **版本號升級**：全專案同步至 `v0.1.7`。

### 2026-05-04（第十五批）
- **v0.1.6 緊急修復 (Recovery)**：
  - **修復語法錯誤**：移除 `CombatClient.lua` 末尾殘留的無效代碼，恢復客戶端腳本加載。
  - **補全觸控邏輯**：實作 `getMouseTarget` 接收 `input.Position` 的功能，確保 iOS 點擊定位精確。
  - **恢復 UI 顯示**：修復崩潰後，`UIManager` 恢復初始化，顯示金幣、版本號與按鈕。

### 2026-05-04（第十四批）
- **iOS 觸控優化與動畫修復**：
  - **輸入系統重構**：移除不可靠的 `TouchTap` 事件，改用 `InputBegan` 統一處理 `Touch` 與 `MouseButton1`。這解決了 iOS 點擊有時不被視為攻擊的問題。
  - **定位精準化**：修正移動端使用 `GetMouse()` 可能導致座標偏移或失敗的 Bug。現在 `getMouseTarget` 支援直接接收 `input.Position` 座標，顯著提升 iOS 端的點擊命中率與動畫觸發可靠性。
- **版本號升級**：全專案同步至 `v0.1.6`。

### 2026-05-04（第十三批）
- **關鍵動畫 Bug 修復**：修正了 `getArmMotor` 尋找肩部關節的錯誤邏輯。原先因抓錯 Motor6D 名稱 (R6) 或路徑 (R15)，導致腳本找不到關節而無法執行揮手動畫。現在改為動態偵測 `Part1` 目標，徹底修復原地攻擊手不動的問題。
- **版本號升級**：全專案同步至 `v0.1.4`。

### 2026-05-04（第十一批）
- **遊戲內版本顯示**：在左上角 HUD 底部新增微型版本號標籤，讀取 `GameConfig.VERSION` 自動更新。
- **攻擊動畫強化**：調整 `playSwingAnimation` 的曲線，改用三次方加速揮出，並優化 `RenderStepped` 下的 Transform 覆蓋機制，確保即使在原地 Idle 狀態下，揮動動作也不會被預設動畫壓制。
- **版本號升級**：全專案同步至 `v0.1.3`。

### 2026-05-04（第十批）
- **動畫系統核心改版**：將 `CombatClient.lua` 的揮手動畫從 `task.spawn` 改為 `RunService.RenderStepped` 強制同步。這解決了手動旋轉 Motor6D 被 Roblox 預設 Animate 腳本每幀重設（覆蓋）的問題。
- **版本號升級**：全專案同步至 `v0.1.2`。

### 2026-05-04（第九批）
- **PMAT 框架遷移**：建立 `AGENT.md` (專案大腦) 與 `SKILLS/` 目錄，將部署邏輯模組化。
- **NPC 重生修正**：在 `NPCManager.spawnNPC` 加入地面偵測 (Raycast)，解決玩家站立在重生點時 NPC 會飄在半空中的問題。
- **攻擊動畫優化**：重構 `CombatClient.lua` 的 `playSwingAnimation`，採用 EaseIn/EaseOut 插值與停頓感，使武器揮動動作更平滑自然。
- **修改檔案**：`AGENT.md`、`SKILLS/roblox-deploy/SKILL.md`、`src/server/NPCManager.lua`、`src/client/CombatClient.lua`

### 2026-05-04（第八批）
- **商城 UI 格狀化**：`openShopPanel` 全面重寫，改用 UIGridLayout 格狀圖示卡片（4欄）
  - 格狀卡片：大 Emoji 圖示 + 名稱 + 底部狀態徽章（顏色區分使用中/已擁有/未擁有）
  - 點擊卡片彈出詳情 popup（大圖示 + 說明 + 數值 + 確認按鈕）
  - 合成 tab：popup 內顯示碎片進度條
  - 已移除舊的行式 buildCard，改為 buildIconCard + showDetailPopup
- **修改檔案**：`src/client/UIManager.lua`

### 2026-05-04（第七批）
- **裝備 3D 外觀**：新增 `EquipmentAppearance.lua`，依裝備槽在角色模型上附加 WeldConstraint 配件
  - 項圈：collarBasic（棕色帶）、collarSpike（黑帶+三尖刺）、collarHeal（綠色 Neon 帶+寶石）、collarSpeed（白色細帶+雙翼）
  - 帽子：hatWizard（帽簷+高身+紫尖）、hatKnight（金屬頭盔+紅冠）、hatBandana（紅色頭巾+結）、hatCrown（金環+三色寶石）
  - 武器：weaponClaws（右手三爪）、weaponSword（握柄+護手+刀身）、weaponShield（左手盾牌+金色徽章）、weaponStaff（杖身+魔法球+光環）
- **觸發時機**：登入套用、EquipItem、UnequipItem、BuyEquipment 均呼叫 EquipmentAppearance.apply
- **修改檔案**：新增 `src/server/EquipmentAppearance.lua`，修改 `src/server/GameServer.server.lua`

### 2026-05-04（第六批）
- **頭部修正**：`CatAppearance.lua` 球頭眼睛/鼻子改為相對 `catHead`（球頭 CFrame）定位而非 `head.CFrame`；耳朵改為找 `CatHeadShape` 做錨點；Y 偏移調整為 -0.5 以確保球底貼合軀幹
- **商城看板高空化**：BillboardGui 改掛在獨立高空錨點（Y+18），背景加圓角框，不與建築本體疊加
- **安全區範圍擴大**：出生點半徑 30→55，商城矩形 X=-35~35 Z=25~65 → X=-42~42 Z=10~72（完整含三棟建築）
- **安全區視覺改版**：移除 Neon 藍光板，改用 Mint 青綠色 SmoothPlastic 地板（透明度 0.72）+ BillboardGui 文字標示
- **修改檔案**：`src/server/CatAppearance.lua`、`src/server/WorldSetup.server.lua`、`src/server/NPCManager.lua`

### 2026-05-04（第五批）
- **攻擊視覺特效**：`CombatClient.lua` 新增完整 VFX 系統
  - 武器特效：鐵爪（銀色爪痕）、迷你劍（藍白劍氣）、貓盾（金色衝擊環）、魔法杖（紫色星爆）、無武器（白色爪痕）
  - 技能特效：全部 16 種技能各有獨立特效（爆炸球、環形波、爪痕、閃電條、上升粒子等）
  - 技能特效疊加在武器特效之上；攻擊指令發出即立即播放（不等伺服器）
- **武器同步**：`EquipmentChanged` 事件同步 weapon id 到 `CombatClient.currentWeapon`
- **區域高空標示**：`WorldSetup.server.lua` 改為高空錨點（Y=90）+ AlwaysOnTop BillboardGui，附副標題等級範圍
- **光柱**：各戰鬥區域中央新增 120 格高 Neon 細光柱，遠距可見
- **修改檔案**：`src/client/CombatClient.lua`、`src/client/GameClient.client.lua`、`src/server/WorldSetup.server.lua`

### 2026-05-04（第四批）
- **NPC 三狀態 AI**：idle（漫步）→ chase（追逐）→ return（放棄返回），取代原本的無限追逐
- **感知範圍縮小**：45 格 → 28 格；漫步速度減半（更自然）
- **追逐放棄條件**：玩家進安全區、玩家跑超過 AGGRO_RANGE×1.8、NPC 離 home > 65 格，三者任一觸發
- **安全區系統**：出生點半徑 30 圓 + 商城矩形 Z=25~65，NPC 感知到玩家在安全區內不啟動追逐
- **玩偶靜止 AI**：只做近身攻擊判定，不移動，且安全區內不攻擊
- **地圖視覺**：Neon 藍色半透明安全區地板 + 告示牌「🛡 安全區域」
- **修改檔案**：`src/server/NPCManager.lua`、`src/server/WorldSetup.server.lua`

### 2026-05-04（第三批）
- **3D 商店攤位**：`WorldSetup.server.lua` 新增三棟建築（商城/裝備/合成），各帶 BillboardGui 大圖示與 ProximityPrompt
- **ProximityPrompt 接入**：`GameClient.client.lua` 的 `bindShopPrompts()` 掃描 workspace，連接到對應 tab
- **商城 startTab 參數**：`openShopPanel(startTab)` 支援 `"cats"/"equip"/"synth"`，底部 ⚔ 裝備按鈕改為直接開裝備 tab
- **卡片視覺升級**：`buildCard` 加入左側識別色條、色塊首字圖示；裝備 tab 固定排序（項圈→帽子→武器）、詳細加成字串
- **合成進度條**：合成 tab 每張卡片底部顯示碎片進度條（紫色填滿 = 可合成）
- **Tab 高亮**：當前 tab 背景深藍，切換時更新
- **修改檔案**：`src/server/WorldSetup.server.lua`、`src/client/UIManager.lua`、`src/client/GameClient.client.lua`、`.cursor/rules/dev-guide.mdc`

### 2026-05-04（第二批）
- **貓咪選擇 UI**：`showCatsTab` 已擁有的貓咪新增「切換使用」按鈕，呼叫 `SelectCat:FireServer(catId)`；目前使用中顯示「使用中」標示
- **PvP 發起 UI**：新增 `openPvPPanel` 函式，列出當前線上玩家，點擊「發起挑戰」呼叫 `RequestPvP:FireServer(userId)`；底部新增「⚔ PvP」按鈕
- **Cursor 規則**：新增 `.cursor/rules/dev-guide.mdc`，整合 CLAUDE.md / PRD.md / GAME_DESIGN.md 的快速導引，AI 可自動參照
- **修改檔案**：`src/client/UIManager.lua`、`GAME_DESIGN.md`、`.cursor/rules/dev-guide.mdc`

### 2026-05-04（第一批）
- **商城 UI**：新增 🛒 商城按鈕，三個 Tab（貓咪/裝備/合成）
- **裝備 UI**：新增 ⚔ 裝備按鈕，顯示三槽位裝備狀態
- **BuyEquipment**：合併購買+裝備為單一事件，新增後端處理
- **寵物合成系統**：全新實作（碎片 drop、CatManager.synthesizeCat、UI）
- **地圖縮小**：700×700，三區圍繞出生點（左玩偶/前野貓/右野人）
- **NPC Spawn 座標**：對應新地圖更新
- **CatAppearance 設計系統**：尾尖改用 colors.accent；頭球 -0.4 offset；修正頭髮殘留
