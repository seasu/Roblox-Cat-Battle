# Roblox Cat Battle — 遊戲設計文件 & 實作狀態

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
| 武器 / 裝備系統 | ✅ | ✅ | 商城裝備 tab + 裝備面板（⚔ 按鈕） |
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
