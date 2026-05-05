local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillData = require(ReplicatedStorage.Shared.SkillData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataStore = require(script.Parent.DataStore)

local SkillManager = {}

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local skillResultEvent = remoteEvents:WaitForChild("SkillResult")
local skillUnlockedEvent = remoteEvents:WaitForChild("SkillUnlocked")
local combatHitEvent = remoteEvents:WaitForChild("CombatHit")

-- 冷卻記憶：cooldowns[userId][skillId] = os.clock() 結束時間
local cooldowns: { [number]: { [string]: number } } = {}

-- TailcoatShield 格擋旗標：shields[userId] = os.clock() 結束時間
local shields: { [number]: number } = {}

-- FoodRage 下一擊增傷旗標
local foodRageReady: { [number]: boolean } = {}

-- LuckyCharm 結束時間
local luckyCharmEnds: { [number]: number } = {}

-- ColorShift 當前形態索引（1=Fire, 2=Ice, 3=Thunder）
local colorShiftIndex: { [number]: number } = {}

function SkillManager.initPlayer(player: Player)
	cooldowns[player.UserId] = {}
	shields[player.UserId] = 0
	foodRageReady[player.UserId] = false
	luckyCharmEnds[player.UserId] = 0
	colorShiftIndex[player.UserId] = 1
end

function SkillManager.initInnateSkills(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	local innate = SkillData.getInnateSkillsForCat(data.activeCatId)
	for _, skillId in ipairs(innate) do
		data.unlockedSkills[skillId] = true
	end
end

function SkillManager.checkSkillUnlocks(player: Player, newLevel: number)
	local data = DataStore.getData(player)
	if not data then return end
	local unlocked = SkillData.getLevelUnlockedSkills(newLevel)
	for _, skillId in ipairs(unlocked) do
		data.unlockedSkills[skillId] = true
		skillUnlockedEvent:FireClient(player, skillId, SkillData.getSkillById(skillId))
	end
end

function SkillManager.isOnCooldown(player: Player, skillId: string): boolean
	local cd = cooldowns[player.UserId]
	if not cd then return false end
	local endTime = cd[skillId] or 0
	return os.clock() < endTime
end

function SkillManager.setCooldown(player: Player, skillId: string)
	local skill = SkillData.getSkillById(skillId)
	if not skill or skill.cooldown <= 0 then return end
	if not cooldowns[player.UserId] then cooldowns[player.UserId] = {} end
	cooldowns[player.UserId][skillId] = os.clock() + skill.cooldown
end

function SkillManager.getCooldownRemaining(player: Player, skillId: string): number
	local cd = cooldowns[player.UserId]
	if not cd then return 0 end
	local endTime = cd[skillId] or 0
	return math.max(0, endTime - os.clock())
end

function SkillManager.isShielded(player: Player): boolean
	local endTime = shields[player.UserId] or 0
	return os.clock() < endTime
end

function SkillManager.consumeShield(player: Player)
	shields[player.UserId] = 0
end

function SkillManager.getAvailableSkills(player: Player): { string }
	local data = DataStore.getData(player)
	if not data then return {} end
	local result: { string } = {}
	for skillId in pairs(data.unlockedSkills) do
		result[#result + 1] = skillId
	end
	return result
end

-- 回傳該玩家當前 ColorShift 的數值乘數 {attackMult, defenseMult, speedMult}
local function getColorShiftMultipliers(player: Player): (number, number, number)
	local idx = colorShiftIndex[player.UserId] or 1
	local b = GameConfig.COLOR_SHIFT_BONUS
	if idx == 1 then return 1 + b, 1, 1   -- Fire: +ATK
	elseif idx == 2 then return 1, 1 + b, 1 -- Ice: +DEF
	else return 1, 1, 1 + b               -- Thunder: +SPD
	end
end

-- NPCManager 呼叫此函數取得玩家有效攻擊力（含被動、ColorShift 加成）
function SkillManager.getEffectiveAttack(player: Player, baseAttack: number): number
	local data = DataStore.getData(player)
	if not data then return baseAttack end

	local atk = baseAttack

	-- OrangeFury 被動
	if data.unlockedSkills["OrangeFury"] then
		-- HP 資訊由 NPCManager 傳入前計算，這裡只處理旗標
		-- 實際低血量判斷在 NPCManager.handleAttack 中處理
	end

	-- ColorShift 形態加成（僅 calicoCat）
	if data.activeCatId == "calicoCat" then
		local atkMult, _, _ = getColorShiftMultipliers(player)
		atk = math.floor(atk * atkMult)
	end

	-- FoodRage 下一擊增傷
	if foodRageReady[player.UserId] then
		atk = math.floor(atk * 2.5)
		foodRageReady[player.UserId] = false
	end

	return atk
end

function SkillManager.handleUseSkill(
	player: Player,
	skillId: string,
	targetInstanceId: string?,
	NPCManager: any,
	EquipmentManager: any
)
	local data = DataStore.getData(player)
	if not data then return end

	-- 驗證技能已解鎖
	if not data.unlockedSkills[skillId] then
		warn("[SkillManager] 玩家", player.Name, "未解鎖技能：", skillId)
		return
	end

	local skill = SkillData.getSkillById(skillId)
	if not skill then return end
	if skill.isPassive then return end

	-- 驗證冷卻
	if SkillManager.isOnCooldown(player, skillId) then
		return
	end

	local stats = EquipmentManager.getTotalStats(player)

	-- 特殊技能處理
	if skillId == "Vanish" then
		SkillManager.setCooldown(player, skillId)
		skillResultEvent:FireClient(player, skillId, {}, 0, skill.cooldown)
		return
	end

	if skillId == "TailcoatShield" then
		shields[player.UserId] = os.clock() + 5
		SkillManager.setCooldown(player, skillId)
		skillResultEvent:FireClient(player, skillId, {}, 0, skill.cooldown)
		return
	end

	if skillId == "FoodRage" then
		-- 消耗 10% 最大 HP（由 NPCManager 透過 PlayerHP 機制處理）
		foodRageReady[player.UserId] = true
		SkillManager.setCooldown(player, skillId)
		skillResultEvent:FireClient(player, skillId, {}, 0, skill.cooldown)
		return
	end

	if skillId == "LuckyCharm" then
		luckyCharmEnds[player.UserId] = os.clock() + GameConfig.LUCKY_CHARM_DURATION;
		(data :: any)._luckyCharmXpBonus = GameConfig.LUCKY_CHARM_XP_BONUS;
		(data :: any)._luckyCharmCoinBonus = GameConfig.LUCKY_CHARM_COIN_BONUS
		task.delay(GameConfig.LUCKY_CHARM_DURATION, function()
			if data then
				(data :: any)._luckyCharmXpBonus = nil;
				(data :: any)._luckyCharmCoinBonus = nil
			end
		end)
		SkillManager.setCooldown(player, skillId)
		skillResultEvent:FireClient(player, skillId, {}, 0, skill.cooldown)
		return
	end

	if skillId == "ColorShift" then
		local modes = GameConfig.COLOR_SHIFT_MODES
		local idx = (colorShiftIndex[player.UserId] or 1) % #modes + 1
		colorShiftIndex[player.UserId] = idx
		data.activeColorShiftMode = modes[idx]
		SkillManager.setCooldown(player, skillId)
		skillResultEvent:FireClient(player, skillId, {}, 0, skill.cooldown, modes[idx])
		return
	end

	if skillId == "HealingBloom" then
		-- 治癒技能，傷害為負數代表回血
		SkillManager.setCooldown(player, skillId)
		skillResultEvent:FireClient(player, skillId, {}, math.abs(skill.damage), skill.cooldown)
		return
	end

	-- 傷害計算
	local damage = skill.damage > 0 and skill.damage or stats.attack
	local isCrit = math.random() < stats.critChance
	if skillId == "GentlemanStrike" then
		isCrit = true
		damage = math.floor(stats.attack * 3.0)
	end
	if isCrit then
		damage = math.floor(damage * GameConfig.CRIT_MULTIPLIER)
	end

	-- 套用技能傷害至目標
	local hitTargets: { string } = {}
	if NPCManager and targetInstanceId then
		NPCManager.handleAttack(player, targetInstanceId, damage, skill.statusEffect)
		table.insert(hitTargets, targetInstanceId)

		-- ChainLightning：額外鏈接周圍最多 2 個目標
		if skillId == "ChainLightning" then
			local chainTargets = NPCManager.getNearbyNPCs(targetInstanceId, 10, 2)
			for _, chainId in ipairs(chainTargets) do
				NPCManager.handleAttack(player, chainId, math.floor(damage * 0.7), nil)
				table.insert(hitTargets, chainId)
			end
		end
	end

	-- AoE 技能：攻擊範圍內所有 NPC
	if skill.aoeRadius > 0 and NPCManager then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local pos = char.HumanoidRootPart.Position
			local aoeTargets = NPCManager.getNPCsInRadius(pos, skill.aoeRadius)
			for _, npcId in ipairs(aoeTargets) do
				NPCManager.handleAttack(player, npcId, damage, skill.statusEffect)
				table.insert(hitTargets, npcId)
			end
		end
	end

	SkillManager.setCooldown(player, skillId)
	skillResultEvent:FireClient(player, skillId, hitTargets, damage, skill.cooldown)
end

return SkillManager
