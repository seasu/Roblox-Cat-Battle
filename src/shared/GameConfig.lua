local GameConfig = {}

GameConfig.VERSION = "v0.2.11"

GameConfig.MAX_LEVEL = 100
GameConfig.BASE_XP = 80
GameConfig.EXPONENT = 1.85
GameConfig.FLAT_INCREMENT = 20

-- 預先計算升級門檻表，XP_TABLE[i] = 從 i 級升到 i+1 級所需 XP
GameConfig.XP_TABLE = {} :: { number }
for i = 1, GameConfig.MAX_LEVEL do
	GameConfig.XP_TABLE[i] = math.floor(
		GameConfig.BASE_XP * (i ^ GameConfig.EXPONENT) + GameConfig.FLAT_INCREMENT * i
	)
end

-- 各 NPC 類型的 XP 倍率
GameConfig.XP_MULTIPLIERS = {
	Doll = 1.0,
	WildCat = 1.25,
	WildHuman = 1.5,
}

-- 戰鬥常數
GameConfig.BASE_ATTACK_INTERVAL = 0.8  -- 自動攻擊間隔（秒）
GameConfig.CRIT_MULTIPLIER = 2.0
GameConfig.MAX_ATTACK_RANGE = 10        -- 最大近戰距離（studs）

-- DataStore
GameConfig.DATASTORE_NAME = "PlayerData_v1"
GameConfig.AUTOSAVE_INTERVAL = 60  -- 自動存檔間隔（秒）

-- PvP
GameConfig.PVP_XP_BONUS = 50    -- 勝者額外 XP
GameConfig.PVP_COIN_BONUS = 100 -- 勝者額外金幣
GameConfig.PVP_TICK_INTERVAL = 1.0  -- PvP 每輪傷害間隔（秒）

-- NPC 重生緩衝（加在 NPCData.respawnTime 之後，避免多隻同時重生）
GameConfig.NPC_RESPAWN_BUFFER = 2

-- LuckyCharm 加成持續時間
GameConfig.LUCKY_CHARM_DURATION = 30
GameConfig.LUCKY_CHARM_XP_BONUS = 0.5
GameConfig.LUCKY_CHARM_COIN_BONUS = 0.3

-- ColorShift 各形態加成
GameConfig.COLOR_SHIFT_MODES = { "Fire", "Ice", "Thunder" }
GameConfig.COLOR_SHIFT_BONUS = 0.15

return GameConfig
