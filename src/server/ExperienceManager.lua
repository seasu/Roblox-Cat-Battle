local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataStore = require(script.Parent.DataStore)

local ExperienceManager = {}

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local addXPEvent = remoteEvents:WaitForChild("AddXP")
local levelUpEvent = remoteEvents:WaitForChild("LevelUp")

-- 前向宣告，由 GameServer 在初始化後注入
ExperienceManager._catManager = nil :: any
ExperienceManager._skillManager = nil :: any

function ExperienceManager.onLevelUp(player: Player, newLevel: number)
	levelUpEvent:FireClient(player, newLevel)

	if ExperienceManager._catManager then
		ExperienceManager._catManager.checkAppearanceUpgrade(player)
	end
	if ExperienceManager._skillManager then
		ExperienceManager._skillManager.checkSkillUnlocks(player, newLevel)
	end
end

function ExperienceManager.checkLevelUp(player: Player)
	local data = DataStore.getData(player)
	if not data then return end

	while data.level < GameConfig.MAX_LEVEL do
		local required = GameConfig.XP_TABLE[data.level]
		if data.xp >= required then
			data.xp -= required
			data.level += 1
			ExperienceManager.onLevelUp(player, data.level)
		else
			break
		end
	end
end

function ExperienceManager.addXP(player: Player, amount: number)
	local data = DataStore.getData(player)
	if not data then return end
	if data.level >= GameConfig.MAX_LEVEL then return end

	-- 若持有三花貓且 LuckyCharm 加成中，則乘以倍率
	-- 加成旗標由 SkillManager 寫入 data 的臨時欄位
	local bonus = (data :: any)._luckyCharmXpBonus or 0
	local finalAmount = math.floor(amount * (1 + bonus))

	data.xp += finalAmount
	local required = GameConfig.XP_TABLE[data.level]
	addXPEvent:FireClient(player, finalAmount, data.xp, required, data.level)

	ExperienceManager.checkLevelUp(player)
end

function ExperienceManager.getLevel(player: Player): number
	local data = DataStore.getData(player)
	return data and data.level or 1
end

function ExperienceManager.getXP(player: Player): number
	local data = DataStore.getData(player)
	return data and data.xp or 0
end

return ExperienceManager
