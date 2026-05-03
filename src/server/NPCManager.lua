local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCData = require(ReplicatedStorage.Shared.NPCData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)
type ActiveNPC = Types.ActiveNPC

local NPCManager = {}

NPCManager._experienceManager = nil :: any
NPCManager._skillManager = nil :: any

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local npcDiedEvent = remoteEvents:WaitForChild("NPCDied")
local combatHitEvent = remoteEvents:WaitForChild("CombatHit")

local activeNPCs: { [string]: ActiveNPC } = {}
local npcModels: { [string]: Model } = {}
local idCounter = 0

-- 各 NPC 的視覺外觀設定
local NPC_VISUALS: { [string]: { size: Vector3, color: BrickColor } } = {
	dollEasy       = { size = Vector3.new(2, 2, 2),     color = BrickColor.new("Bright yellow") },
	dollMedium     = { size = Vector3.new(3, 3, 3),     color = BrickColor.new("Bright yellow") },
	dollHard       = { size = Vector3.new(4, 4, 4),     color = BrickColor.new("Bright yellow") },
	wildCatEasy    = { size = Vector3.new(4, 2.5, 3),   color = BrickColor.new("Bright orange") },
	wildCatMedium  = { size = Vector3.new(5, 3, 4),     color = BrickColor.new("Bright orange") },
	wildCatHard    = { size = Vector3.new(6, 3.5, 5),   color = BrickColor.new("Dark orange") },
	wildHumanEasy  = { size = Vector3.new(2, 5, 2),     color = BrickColor.new("Brown") },
	wildHumanMedium = { size = Vector3.new(2.5, 6, 2.5), color = BrickColor.new("Brown") },
	wildHumanHard  = { size = Vector3.new(3, 7, 3),     color = BrickColor.new("Maroon") },
}

-- 生成區域：與 WorldSetup 的三大區域對應
local SPAWN_ZONES: { { npcId: string, position: Vector3, count: number } } = {
	-- 玩偶區（北方 Z≈280）
	{ npcId = "dollEasy",        position = Vector3.new(-60, 1, 240), count = 4 },
	{ npcId = "dollEasy",        position = Vector3.new(60,  1, 260), count = 3 },
	{ npcId = "dollMedium",      position = Vector3.new(0,   1, 310), count = 3 },
	{ npcId = "dollHard",        position = Vector3.new(-30, 1, 355), count = 2 },
	-- 野貓區（東北 X≈320, Z≈480）
	{ npcId = "wildCatEasy",     position = Vector3.new(270, 1, 440), count = 4 },
	{ npcId = "wildCatMedium",   position = Vector3.new(340, 1, 490), count = 3 },
	{ npcId = "wildCatHard",     position = Vector3.new(390, 1, 530), count = 2 },
	-- 野人區（西北 X≈-80, Z≈750）
	{ npcId = "wildHumanEasy",   position = Vector3.new(-120, 1, 700), count = 4 },
	{ npcId = "wildHumanMedium", position = Vector3.new(-60,  1, 770), count = 3 },
	{ npcId = "wildHumanHard",   position = Vector3.new(-90,  1, 845), count = 2 },
}

local function generateId(): string
	idCounter += 1
	return "npc_" .. idCounter .. "_" .. os.time()
end

local function createNPCModel(def: any, instanceId: string, spawnPos: Vector3): Model
	local visual = NPC_VISUALS[def.id] or { size = Vector3.new(3, 3, 3), color = BrickColor.new("Medium grey") }
	local halfH = visual.size.Y / 2

	local model = Instance.new("Model")
	model.Name = def.displayName

	-- 主體 Part（射線會命中這個）
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.Size = visual.size
	body.CFrame = CFrame.new(spawnPos + Vector3.new(0, halfH, 0))
	body.BrickColor = visual.color
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	model.PrimaryPart = body

	-- InstanceId（供 CombatClient 射線偵測用）
	local idValue = Instance.new("StringValue")
	idValue.Name = "InstanceId"
	idValue.Value = instanceId
	idValue.Parent = model

	-- 名稱 + HP 顯示
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoGui"
	billboard.Size = UDim2.new(0, 160, 0, 55)
	billboard.StudsOffset = Vector3.new(0, halfH + 2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.displayName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.Parent = billboard

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HpLabel"
	hpLabel.Size = UDim2.new(1, 0, 0.5, 0)
	hpLabel.Position = UDim2.new(0, 0, 0.5, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "❤ " .. def.maxHp .. " / " .. def.maxHp
	hpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	hpLabel.TextStrokeTransparency = 0.3
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextSize = 13
	hpLabel.Parent = billboard

	model.Parent = workspace
	return model
end

local function updateHPLabel(model: Model, current: number, max: number)
	local body = model:FindFirstChild("Body")
	if not body then return end
	local gui = body:FindFirstChild("InfoGui")
	if not gui then return end
	local hpLabel = gui:FindFirstChild("HpLabel") :: TextLabel?
	if not hpLabel then return end
	local ratio = math.clamp(current / max, 0, 1)
	local r = math.floor(255 * (1 - ratio))
	local g = math.floor(255 * ratio)
	hpLabel.TextColor3 = Color3.fromRGB(r, g, 0)
	hpLabel.Text = "❤ " .. math.max(0, current) .. " / " .. max
end

function NPCManager.spawnNPC(npcId: string, position: Vector3): ActiveNPC?
	local def = NPCData.getNPCById(npcId)
	if not def then return nil end

	local instanceId = generateId()
	local spread = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
	local spawnPos = position + spread

	local npc: ActiveNPC = {
		definition = def,
		currentHp = def.maxHp,
		position = spawnPos,
		instanceId = instanceId,
	}
	activeNPCs[instanceId] = npc
	npcModels[instanceId] = createNPCModel(def, instanceId, spawnPos)
	return npc
end

function NPCManager.startSpawnLoop()
	for _, zone in ipairs(SPAWN_ZONES) do
		for i = 1, zone.count do
			task.delay(i * 0.3, function()
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

	local finalDamage = math.max(1, damage - npc.definition.defense)
	npc.currentHp -= finalDamage

	-- 更新 HP 顯示
	local model = npcModels[instanceId]
	if model then
		updateHPLabel(model, npc.currentHp, npc.definition.maxHp)
		combatHitEvent:FireAllClients(instanceId, model:GetPivot().Position, finalDamage, false)
	else
		combatHitEvent:FireAllClients(instanceId, npc.position, finalDamage, false)
	end

	if npc.currentHp <= 0 then
		NPCManager.handleDeath(instanceId, attacker)
	end
end

function NPCManager.handleDeath(instanceId: string, killer: Player)
	local npc = activeNPCs[instanceId]
	if not npc then return end

	local def = npc.definition
	activeNPCs[instanceId] = nil

	-- 移除 Workspace 中的模型
	local model = npcModels[instanceId]
	if model then
		model:Destroy()
		npcModels[instanceId] = nil
	end

	npcDiedEvent:FireAllClients(instanceId)

	local xpMultiplier = GameConfig.XP_MULTIPLIERS[def.kind] or 1.0
	local xpGained = math.floor(def.xpReward * xpMultiplier)

	local killerData = require(script.Parent.DataStore).getData(killer)
	local coinBonus = (killerData and (killerData :: any)._luckyCharmCoinBonus) or 0
	local coinsGained = math.floor(def.coinReward * (1 + coinBonus))

	if killerData then
		killerData.coins += coinsGained
	end

	if NPCManager._experienceManager then
		NPCManager._experienceManager.addXP(killer, xpGained)
	end

	local remotes = game.ReplicatedStorage:WaitForChild("RemoteEvents")
	remotes:WaitForChild("UpdateUI"):FireClient(killer, "coins", coinsGained)

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
