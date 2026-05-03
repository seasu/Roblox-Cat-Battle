local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCData = require(ReplicatedStorage.Shared.NPCData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)
type ActiveNPC = Types.ActiveNPC

local NPCManager = {}

-- 前向宣告，由 GameServer 注入
NPCManager._experienceManager = nil :: any
NPCManager._skillManager = nil :: any

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local spawnNPCEvent = remoteEvents:WaitForChild("SpawnNPC")
local npcDiedEvent = remoteEvents:WaitForChild("NPCDied")
local combatHitEvent = remoteEvents:WaitForChild("CombatHit")

local activeNPCs: { [string]: ActiveNPC } = {}
local idCounter = 0

-- 生成區域設定：{ npcId, position, count }
local SPAWN_ZONES: { { npcId: string, position: Vector3, count: number } } = {
	{ npcId = "dollEasy",        position = Vector3.new(10, 0, 10),   count = 3 },
	{ npcId = "dollMedium",      position = Vector3.new(30, 0, 10),   count = 2 },
	{ npcId = "dollHard",        position = Vector3.new(60, 0, 10),   count = 1 },
	{ npcId = "wildCatEasy",     position = Vector3.new(10, 0, 40),   count = 3 },
	{ npcId = "wildCatMedium",   position = Vector3.new(30, 0, 40),   count = 2 },
	{ npcId = "wildCatHard",     position = Vector3.new(60, 0, 40),   count = 1 },
	{ npcId = "wildHumanEasy",   position = Vector3.new(10, 0, 70),   count = 3 },
	{ npcId = "wildHumanMedium", position = Vector3.new(30, 0, 70),   count = 2 },
	{ npcId = "wildHumanHard",   position = Vector3.new(60, 0, 70),   count = 1 },
}

local function generateId(): string
	idCounter += 1
	return "npc_" .. idCounter .. "_" .. os.time()
end

function NPCManager.spawnNPC(npcId: string, position: Vector3): ActiveNPC?
	local def = NPCData.getNPCById(npcId)
	if not def then return nil end

	local instanceId = generateId()
	local spread = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	local spawnPos = position + spread

	local npc: ActiveNPC = {
		definition = def,
		currentHp = def.maxHp,
		position = spawnPos,
		instanceId = instanceId,
	}
	activeNPCs[instanceId] = npc
	spawnNPCEvent:FireAllClients(instanceId, npcId, spawnPos)
	return npc
end

function NPCManager.startSpawnLoop()
	for _, zone in ipairs(SPAWN_ZONES) do
		for _ = 1, zone.count do
			task.delay(math.random(0, 3), function()
				NPCManager.spawnNPC(zone.npcId, zone.position)
			end)
		end
	end
end

function NPCManager.handleAttack(
	attacker: Player,
	instanceId: string,
	damage: number,
	statusEffect: any?
)
	local npc = activeNPCs[instanceId]
	if not npc then return end

	-- 防禦減傷
	local finalDamage = math.max(1, damage - npc.definition.defense)
	npc.currentHp -= finalDamage

	-- 通知所有客戶端顯示傷害數字
	combatHitEvent:FireAllClients(instanceId, npc.position, finalDamage, false)

	if npc.currentHp <= 0 then
		NPCManager.handleDeath(instanceId, attacker)
	end
end

function NPCManager.handleDeath(instanceId: string, killer: Player)
	local npc = activeNPCs[instanceId]
	if not npc then return end

	local def = npc.definition
	activeNPCs[instanceId] = nil
	npcDiedEvent:FireAllClients(instanceId)

	-- 計算經驗值（含種類倍率）
	local xpMultiplier = GameConfig.XP_MULTIPLIERS[def.kind] or 1.0
	local xpGained = math.floor(def.xpReward * xpMultiplier)

	-- 計算金幣（含 LuckyCharm 加成）
	local killerData = require(script.Parent.DataStore).getData(killer)
	local coinBonus = (killerData and (killerData :: any)._luckyCharmCoinBonus) or 0
	local coinsGained = math.floor(def.coinReward * (1 + coinBonus))

	if killerData then
		killerData.coins += coinsGained
	end

	if NPCManager._experienceManager then
		NPCManager._experienceManager.addXP(killer, xpGained)
	end

	-- 更新金幣 UI
	local remotes = game.ReplicatedStorage:WaitForChild("RemoteEvents")
	remotes:WaitForChild("UpdateUI"):FireClient(killer, "coins", coinsGained)

	-- 排程重生
	task.delay(def.respawnTime + GameConfig.NPC_RESPAWN_BUFFER, function()
		NPCManager.spawnNPC(def.id, npc.position)
	end)
end

function NPCManager.getNPCByInstance(instanceId: string): ActiveNPC?
	return activeNPCs[instanceId]
end

function NPCManager.getNPCsInRadius(center: Vector3, radius: number): { string }
	local result: { string } = {}
	for id, npc in pairs(activeNPCs) do
		if (npc.position - center).Magnitude <= radius then
			table.insert(result, id)
		end
	end
	return result
end

function NPCManager.getNearbyNPCs(originInstanceId: string, radius: number, maxCount: number): { string }
	local origin = activeNPCs[originInstanceId]
	if not origin then return {} end
	local result: { string } = {}
	for id, npc in pairs(activeNPCs) do
		if id ~= originInstanceId and (npc.position - origin.position).Magnitude <= radius then
			table.insert(result, id)
			if #result >= maxCount then break end
		end
	end
	return result
end

return NPCManager
