# 貓咪大戰（Roblox-Cat-Battle）產品需求文件 (PRD)

**版本：** v1.0  
**日期：** 2026-05-03  
**語言：** Luau（Roblox）  
**建置工具：** Rojo + GitHub Actions

---

## 一、產品概述

《貓咪大戰》是一款 Roblox 多人動作 RPG 遊戲。玩家從一隻等級最低的白貓出發，透過擊敗各種 NPC（玩偶、野貓、野人）獲取經驗值與金幣，逐步升級並解鎖更強大的外觀與技能。遊戲提供豐富的貓咪收集、裝備搭配與 PvP 對戰玩法。

### 核心循環
```
擊敗 NPC → 獲取 XP + 金幣 → 升級 → 解鎖新外觀／技能 → 挑戰更強 NPC 或 PvP
```

---

## 二、遊戲模式

| 模式 | 說明 |
|---|---|
| PvE | 擊敗地圖上的玩偶、野貓、野人 NPC，獲取 XP 與金幣 |
| PvP | 向其他線上玩家發起對戰邀請，勝者獲額外 XP 與金幣 |

---

## 三、戰鬥系統

- **操作方式：** 點擊／觸碰 NPC 發動基礎攻擊（`BasicSwipe`）
- **技能快捷鍵：** Q / E / R / F 對應技能列第 2–5 格
- **射線偵測：** 客戶端從鏡頭射出射線，命中 NPC 後向伺服器發送 `UseSkill` 事件
- **傷害計算：** 伺服器權威，驗證距離與冷卻後才套用傷害

---

## 四、貨幣系統

| 貨幣 | 取得方式 | 用途 |
|---|---|---|
| Robux (RB) | 真實付費 | 購買特殊高級貓咪 |
| 金幣（Coins） | 擊敗 NPC 掉落 | 購買裝備、一般道具 |

---

## 五、經驗值與升級系統

### 升級公式

```
xpRequired(level) = floor(80 × level^1.85 + 20 × level)
```

### 各等級所需 XP

| 等級 | 升級所需 XP | 累計 XP |
|---|---|---|
| 1 | 100 | 100 |
| 5 | 476 | 1,680 |
| 10 | 1,393 | 7,200 |
| 20 | 4,612 | 36,800 |
| 30 | 9,231 | 101,500 |
| 50 | 23,019 | 360,000 |
| 75 | 49,862 | 1,050,000 |
| 100 | 80,080 | 2,200,000 |

- **等級上限：** 100 級
- **XP 倍率：** 玩偶 ×1.0、野貓 ×1.25、野人 ×1.5

---

## 六、貓咪設計

### 6.1 基礎貓——白貓（免費，起始角色）

每 10 等換一個成長分階：

| 等級區間 | 階段名稱 | 外觀鍵值 |
|---|---|---|
| 1–10 | 幼貓 | `WhiteCat_Kitten` |
| 11–20 | 小白 | `WhiteCat_Junior` |
| 21–30 | 成年白貓 | `WhiteCat_Adult` |
| 31–40 | 老練白貓 | `WhiteCat_Veteran` |
| 41–50 | 銀毛長者 | `WhiteCat_Elder` |
| 51–60 | 賢者之貓 | `WhiteCat_Sage` |
| 61–70 | 冠軍白貓 | `WhiteCat_Champion` |
| 71–80 | 傳說白貓 | `WhiteCat_Legend` |
| 81–90 | 神話白貓 | `WhiteCat_Mythic` |
| 91–100 | 天界白貓 | `WhiteCat_Celestial` |

所有特殊貓咪同樣採用 10 個成長分階，各有獨立的主題名稱。

---

### 6.2 特殊貓咪一覽（Robux 購買）

| catId | 名稱 | 價格 | Developer Product ID | 固有技能 | 風格定位 |
|---|---|---|---|---|---|
| `shadowCat` | 暗影貓 | 200 RB | 1001 | ShadowStrike、Vanish | 暗殺刺客 |
| `flameCat` | 烈焰貓 | 350 RB | 1002 | FireClaw、EmberAura | 爆發狂戰士 |
| `frostCat` | 冰霜貓 | 350 RB | 1003 | IceShard、FrostAura | 控場減速系 |
| `thunderCat` | 雷霆貓 | 500 RB | 1004 | ThunderPounce、ChainLightning | 群攻 AoE |
| `sakuraCat` | 櫻花貓 | 450 RB | 1005 | PetalSlash、HealingBloom | 攻守均衡 |
| `orangeCat` | 橘貓 | 300 RB | 1006 | OrangeFury、FoodRage | 爆發型坦克 |
| `calicoCat` | 三花貓 | 400 RB | 1007 | LuckyCharm、ColorShift | 魔法系變化 |
| `tuxedoCat` | 賓士貓 | 500 RB | 1008 | GentlemanStrike、TailcoatShield | 高爆擊精準系 |

---

### 6.3 橘貓詳細設計

**性格定位：** 貪吃懶散但爆發力驚人，越餓越強——血量越低反而攻擊越猛。

**成長分階：** 小橘 → 肥橘 → 大橘 → 橘霸 → 橘皇 → 橘神 → 橘王傳說 → 橘色巨神 → 橘色神話 → 宇宙橘貓

**固有技能：**

| 技能 ID | 名稱 | 類型 | 效果描述 |
|---|---|---|---|
| `OrangeFury` | 橘貓狂怒 | 被動 | 當 HP < 30% 時，ATK 提升 80%，持續至回血超過門檻 |
| `FoodRage` | 飢餓暴走 | 主動 | 消耗自身 10% 最大 HP，下次攻擊造成 ATK × 2.5 傷害，冷卻 15 秒 |

---

### 6.4 三花貓詳細設計

**性格定位：** 神秘魔法師，能在三種元素（火、冰、雷）之間循環切換，並附帶好運加持效果。

**成長分階：** 三花幼貓 → 彩紋少女 → 幻彩法師 → 三色術士 → 元素使者 → 虹彩聖者 → 三花傳說 → 萬色神靈 → 三花神話 → 彩虹天神

**固有技能：**

| 技能 ID | 名稱 | 類型 | 效果描述 |
|---|---|---|---|
| `LuckyCharm` | 幸運符咒 | 主動 | 施放後 30 秒內，XP 獲取提升 50%、金幣掉落提升 30%，冷卻 60 秒 |
| `ColorShift` | 三色切換 | 主動 | 在火焰（+ATK）、冰霜（+DEF）、雷電（+SPD）三種形態循環，每種加成 +15%，切換冷卻 8 秒 |

---

### 6.5 賓士貓詳細設計

**性格定位：** 優雅紳士流——高精準、高暴擊，能完全格擋一次傷害，適合單挑高難度敵人。

**成長分階：** 燕尾幼貓 → 小紳士 → 優雅武者 → 白手套騎士 → 黑白劍客 → 西裝特務 → 燕尾傳說 → 賓士之神 → 神話紳士 → 宇宙賓士王

**固有技能：**

| 技能 ID | 名稱 | 類型 | 效果描述 |
|---|---|---|---|
| `GentlemanStrike` | 紳士必殺 | 主動 | 必定暴擊，造成 ATK × 3.0 傷害，冷卻 20 秒 |
| `TailcoatShield` | 燕尾護盾 | 主動 | 下一次受到的傷害完全格擋（吸收 100%），持續 5 秒，冷卻 30 秒 |

---

## 七、技能系統

共 16 種技能，分為全體共用（升級解鎖）與各貓固有技能：

### 全體共用

| 技能 ID | 名稱 | 傷害 | 冷卻 | 解鎖條件 |
|---|---|---|---|---|
| `BasicSwipe` | 基礎爪擊 | 15 | 0 秒 | 等級 1（全貓） |
| `PowerClaw` | 強力貓爪 | 45 | 8 秒 | 等級 10（全貓），附加流血 3 秒 |

### 特殊貓固有技能

| 技能 ID | 名稱 | 傷害 | 冷卻 | 所屬貓咪 | 特殊效果 |
|---|---|---|---|---|---|
| `ShadowStrike` | 暗影突刺 | 60 | 12 秒 | 暗影貓 | 附加失明 2 秒 |
| `Vanish` | 消失術 | 0 | 20 秒 | 暗影貓 | 短暫隱身 |
| `FireClaw` | 烈焰貓爪 | 55 | 10 秒 | 烈焰貓 | 附加燃燒 4 秒 |
| `EmberAura` | 火焰氣場 | 20 | 15 秒 | 烈焰貓 | 範圍燃燒 AoE |
| `IceShard` | 冰錐射擊 | 40 | 9 秒 | 冰霜貓 | 遠程，附加緩速 4 秒 |
| `ThunderPounce` | 雷霆猛撲 | 70 | 14 秒 | 雷霆貓 | AoE，附加暈眩 1.5 秒 |
| `ChainLightning` | 連鎖閃電 | 50 | 18 秒 | 雷霆貓（等級 20） | 最多鏈接 3 個目標 |
| `PetalSlash` | 花瓣斬 | 35 | 7 秒 | 櫻花貓 | 小範圍 AoE |
| `HealingBloom` | 治癒花開 | −40（治癒） | 25 秒 | 櫻花貓 | 自我治癒 |
| `OrangeFury` | 橘貓狂怒 | — | 被動 | 橘貓 | HP < 30% 時 ATK +80% |
| `FoodRage` | 飢餓暴走 | ATK×2.5 | 15 秒 | 橘貓 | 消耗 10% HP 換超強一擊 |
| `LuckyCharm` | 幸運符咒 | — | 60 秒 | 三花貓 | 30 秒內 XP+50%、金幣+30% |
| `ColorShift` | 三色切換 | — | 8 秒 | 三花貓 | 循環切換火／冰／雷形態 |
| `GentlemanStrike` | 紳士必殺 | ATK×3.0 | 20 秒 | 賓士貓 | 必定暴擊 |
| `TailcoatShield` | 燕尾護盾 | — | 30 秒 | 賓士貓 | 格擋下一次傷害（100%） |

---

## 八、NPC 系統

共 3 類 × 3 難度等級，合計 9 種 NPC：

| npcId | 類型 | HP | 攻擊 | 經驗值 | 金幣 | 重生時間 |
|---|---|---|---|---|---|---|
| `dollEasy` | 玩偶 | 80 | 5 | 20 | 5 | 8 秒 |
| `dollMedium` | 玩偶 | 200 | 10 | 55 | 15 | 12 秒 |
| `dollHard` | 玩偶 | 450 | 18 | 130 | 35 | 20 秒 |
| `wildCatEasy` | 野貓 | 120 | 12 | 30 | 10 | 10 秒 |
| `wildCatMedium` | 野貓 | 300 | 22 | 75 | 25 | 15 秒 |
| `wildCatHard` | 野貓 | 650 | 38 | 180 | 60 | 25 秒 |
| `wildHumanEasy` | 野人 | 100 | 15 | 35 | 12 | 10 秒 |
| `wildHumanMedium` | 野人 | 260 | 28 | 90 | 30 | 18 秒 |
| `wildHumanHard` | 野人 | 580 | 48 | 210 | 70 | 30 秒 |

---

## 九、裝備系統

3 個槽位，每槽 4 件，均以金幣購買：

### 項圈槽
| itemId | 名稱 | 加成 | 金幣價格 |
|---|---|---|---|
| `collarBasic` | 基礎項圈 | +2 防禦、+10 HP | 50 |
| `collarSpike` | 尖刺項圈 | +5 攻擊、+3 防禦 | 150 |
| `collarHeal` | 治癒項圈 | +30 HP | 200 |
| `collarSpeed` | 迅捷項圈 | +2 速度 | 250 |

### 帽子槽
| itemId | 名稱 | 加成 | 金幣價格 |
|---|---|---|---|
| `hatWizard` | 巫師帽 | +8 攻擊 | 180 |
| `hatKnight` | 騎士頭盔 | +10 防禦、+20 HP | 220 |
| `hatBandana` | 戰鬥頭巾 | +5 攻擊、+5 防禦 | 160 |
| `hatCrown` | 金色皇冠 | +3 攻擊、+3 防禦、+10 HP、+1 速度 | 300 |

### 武器槽
| itemId | 名稱 | 加成 | 金幣價格 |
|---|---|---|---|
| `weaponClaws` | 鐵爪 | +10 攻擊 | 200 |
| `weaponSword` | 迷你劍 | +15 攻擊、−2 防禦 | 280 |
| `weaponShield` | 貓盾 | −2 攻擊、+18 防禦 | 260 |
| `weaponStaff` | 魔法杖 | +12 攻擊、+2 速度 | 320 |

---

## 十、技術架構

### 10.1 RemoteEvent 清單

| RemoteEvent | 方向 | 用途 |
|---|---|---|
| `RequestLoadData` | 客戶端→伺服器 | 請求讀取 DataStore |
| `LoadDataResponse` | 伺服器→客戶端 | 回傳完整 PlayerData |
| `AddXP` | 伺服器→客戶端 | XP 獲取通知 |
| `LevelUp` | 伺服器→客戶端 | 升級通知 |
| `UpdateCatAppearance` | 伺服器→客戶端 | 外觀分階同步 |
| `SelectCat` | 客戶端→伺服器 | 切換當前貓咪 |
| `SpawnNPC` | 伺服器→客戶端 | 渲染新 NPC |
| `NPCDied` | 伺服器→客戶端 | NPC 死亡特效 |
| `PurchaseCat` | 客戶端→伺服器 | 觸發 RB 購買 |
| `PurchaseResult` | 伺服器→客戶端 | 購買結果通知 |
| `EquipItem` | 客戶端→伺服器 | 裝備物品 |
| `UnequipItem` | 客戶端→伺服器 | 卸下裝備 |
| `EquipmentChanged` | 伺服器→客戶端 | 裝備配置同步 |
| `UseSkill` | 客戶端→伺服器 | 使用技能 |
| `SkillResult` | 伺服器→客戶端 | 技能結果 |
| `SkillUnlocked` | 伺服器→客戶端 | 解鎖新技能通知 |
| `CombatHit` | 伺服器→客戶端 | 傷害數字位置 |
| `PlayerDied` | 伺服器→客戶端 | 死亡畫面觸發 |
| `UpdateUI` | 伺服器→客戶端 | 通用 UI 刷新 |
| `RequestPvP` | 客戶端→伺服器 | 發起 PvP 挑戰 |
| `PvPInvite` | 伺服器→客戶端 | 傳送挑戰邀請 |
| `PvPAccepted` | 客戶端→伺服器 | 接受 PvP |
| `PvPResult` | 伺服器→客戶端 | PvP 勝負結果 |

**RemoteFunction：** `GetPlayerData`、`GetShopCatalog`

---

### 10.2 檔案結構

```
Roblox-Cat-Battle/
├── default.project.json
└── src/
    ├── shared/
    │   ├── Types.lua
    │   ├── GameConfig.lua
    │   ├── CatData.lua
    │   ├── SkillData.lua
    │   ├── EquipmentData.lua
    │   └── NPCData.lua
    ├── server/
    │   ├── GameServer.server.lua
    │   ├── DataStore.lua
    │   ├── ExperienceManager.lua
    │   ├── CatManager.lua
    │   ├── NPCManager.lua
    │   ├── ShopManager.lua
    │   ├── EquipmentManager.lua
    │   ├── SkillManager.lua
    │   └── PvPManager.lua
    └── client/
        ├── GameClient.client.lua
        ├── UIManager.lua
        └── CombatClient.lua
```

### 10.3 關鍵資料流

**擊殺 NPC + 升級：**
```
CombatClient 點擊 NPC
→ UseSkill("BasicSwipe", instanceId)
→ 伺服器驗證 → NPCManager.handleAttack
→ NPC 死亡 → ExperienceManager.addXP
→ XP 達門檻 → checkLevelUp → onLevelUp
→ 觸發 LevelUp + UpdateCatAppearance + SkillUnlocked
```

**PvP 流程：**
```
RequestPvP → PvPInvite → PvPAccepted
→ PvPManager 戰鬥迴圈 → PvPResult（雙方）
```

---

## 十一、驗證計劃

1. `rojo build --output game.rbxl` 無錯誤
2. 玩家加入：等級 1 白貓，XP 條顯示 0
3. 擊敗 `dollEasy`：+20 XP 顯示正確
4. 升至等級 10：`PowerClaw` 出現在技能列
5. 橘貓低血量：`OrangeFury` 被動觸發
6. 三花貓 `ColorShift`：三種形態依序切換
7. 賓士貓 `GentlemanStrike`：必定暴擊，傷害 ATK×3.0
8. PvP：兩客戶端互相挑戰並正確結算
9. DataStore：離線後重新加入，資料完整保存
