local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local NPCData = require(ReplicatedStorage.Shared.NPCData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local NPCManager = {}

NPCManager._experienceManager = nil
NPCManager._skillManager = nil

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local npcDiedEvent = remoteEvents:WaitForChild("NPCDied")
local combatHitEvent = remoteEvents:WaitForChild("CombatHit")

local activeNPCs = {}
local npcModels = {}
local idCounter = 0
local npcHomePositions = {}
local npcNextAttackAt = {}
local npcWanderTargets = {}

-- 各 NPC 的視覺設定（難度 → 縮放比例 + 主色 + 配色）
local NPC_CONFIG = {
	dollEasy    = { kind="doll",      scale=1.0, main=BrickColor.new("Bright yellow"),  accent=BrickColor.new("Carnation pink")  },
	dollMedium  = { kind="doll",      scale=1.3, main=BrickColor.new("Bright yellow"),  accent=BrickColor.new("Carnation pink")  },
	dollHard    = { kind="doll",      scale=1.6, main=BrickColor.new("Bright yellow"),  accent=BrickColor.new("Carnation pink")  },
	wildCatEasy   = { kind="wildCat", scale=1.0, main=BrickColor.new("Bright orange"),  accent=BrickColor.new("Brown")           },
	wildCatMedium = { kind="wildCat", scale=1.3, main=BrickColor.new("Bright orange"),  accent=BrickColor.new("Dark orange")     },
	wildCatHard   = { kind="wildCat", scale=1.6, main=BrickColor.new("Dark orange"),    accent=BrickColor.new("Maroon")          },
	wildHumanEasy   = { kind="wildHuman", scale=1.0, main=BrickColor.new("Brown"),         accent=BrickColor.new("Reddish brown") },
	wildHumanMedium = { kind="wildHuman", scale=1.3, main=BrickColor.new("Reddish brown"), accent=BrickColor.new("Dark orange")   },
	wildHumanHard   = { kind="wildHuman", scale=1.6, main=BrickColor.new("Maroon"),        accent=BrickColor.new("Really black")  },
}

-- NPC 移動速度（玩偶靜止，野貓和野人會追逐玩家）
local MOVE_SPEED_BY_KIND = {
	doll      = 0,
	wildCat   = 14,
	wildHuman = 11,
}

-- 生成區域
local SPAWN_ZONES = {
	{ npcId = "dollEasy",        position = Vector3.new(-60, 1, 240), count = 4 },
	{ npcId = "dollEasy",        position = Vector3.new(60,  1, 260), count = 3 },
	{ npcId = "dollMedium",      position = Vector3.new(0,   1, 310), count = 3 },
	{ npcId = "dollHard",        position = Vector3.new(-30, 1, 355), count = 2 },
	{ npcId = "wildCatEasy",     position = Vector3.new(270, 1, 440), count = 4 },
	{ npcId = "wildCatMedium",   position = Vector3.new(340, 1, 490), count = 3 },
	{ npcId = "wildCatHard",     position = Vector3.new(390, 1, 530), count = 2 },
	{ npcId = "wildHumanEasy",   position = Vector3.new(-120, 1, 700), count = 4 },
	{ npcId = "wildHumanMedium", position = Vector3.new(-60,  1, 770), count = 3 },
	{ npcId = "wildHumanHard",   position = Vector3.new(-90,  1, 845), count = 2 },
}

local function generateId()
	idCounter += 1
	return "npc_" .. idCounter .. "_" .. os.time()
end

-- 建立一個 Part 並加入 model
local function ap(model, name, size, pos, color, canCollide, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = canCollide == true
	p.Size = size
	p.Position = pos
	p.BrickColor = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = model
	return p
end

-- 建立 HP / 名稱浮動標籤（topOffset = body 中心到模型頂端的距離）
local function addInfoGui(body, def, topOffset)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoGui"
	billboard.Size = UDim2.new(0, 160, 0, 55)
	billboard.StudsOffset = Vector3.new(0, topOffset + 2, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
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
end

-- ── 玩偶（圓胖毛絨布偶） ────────────────────────────────────────────
local function buildDollModel(def, instanceId, spawnPos, s, colors)
	local model = Instance.new("Model")
	model.Name = def.displayName
	local X, Y, Z = spawnPos.X, spawnPos.Y, spawnPos.Z

	-- 身體（圓胖主體）
	local body = ap(model, "Body",
		Vector3.new(2.5*s, 3*s, 2*s),
		Vector3.new(X, Y + 1.5*s, Z),
		colors.main, true)
	model.PrimaryPart = body

	-- 頭部（球形）
	ap(model, "Head",
		Vector3.new(2.2*s, 2.2*s, 2.2*s),
		Vector3.new(X, Y + 3.9*s, Z),
		colors.main, false, Enum.PartType.Ball)

	-- 貓耳
	ap(model, "EarL",
		Vector3.new(0.55*s, 0.6*s, 0.4*s),
		Vector3.new(X - 0.7*s, Y + 5.25*s, Z - 0.15*s),
		colors.accent, false)
	ap(model, "EarR",
		Vector3.new(0.55*s, 0.6*s, 0.4*s),
		Vector3.new(X + 0.7*s, Y + 5.25*s, Z - 0.15*s),
		colors.accent, false)

	-- 眼睛（黑球）
	ap(model, "EyeL",
		Vector3.new(0.32*s, 0.32*s, 0.32*s),
		Vector3.new(X - 0.55*s, Y + 3.9*s, Z - 1.08*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)
	ap(model, "EyeR",
		Vector3.new(0.32*s, 0.32*s, 0.32*s),
		Vector3.new(X + 0.55*s, Y + 3.9*s, Z - 1.08*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)

	-- 腮紅
	ap(model, "CheekL",
		Vector3.new(0.5*s, 0.35*s, 0.3*s),
		Vector3.new(X - 0.76*s, Y + 3.65*s, Z - 1.05*s),
		BrickColor.new("Carnation pink"), false, Enum.PartType.Ball)
	ap(model, "CheekR",
		Vector3.new(0.5*s, 0.35*s, 0.3*s),
		Vector3.new(X + 0.76*s, Y + 3.65*s, Z - 1.05*s),
		BrickColor.new("Carnation pink"), false, Enum.PartType.Ball)

	-- 手臂
	ap(model, "ArmL",
		Vector3.new(0.7*s, 2*s, 0.7*s),
		Vector3.new(X - 1.65*s, Y + 1.5*s, Z),
		colors.main, false)
	ap(model, "ArmR",
		Vector3.new(0.7*s, 2*s, 0.7*s),
		Vector3.new(X + 1.65*s, Y + 1.5*s, Z),
		colors.main, false)

	local idVal = Instance.new("StringValue")
	idVal.Name = "InstanceId"
	idVal.Value = instanceId
	idVal.Parent = model

	-- 頂端 ≈ Y+5.55*s，body 中心 Y+1.5*s → topOffset = 4.05*s
	addInfoGui(body, def, 4.05*s)
	model.Parent = workspace
	return model
end

-- ── 野貓（低趴攻擊姿勢） ────────────────────────────────────────────
local function buildWildCatModel(def, instanceId, spawnPos, s, colors)
	local model = Instance.new("Model")
	model.Name = def.displayName
	local X, Y, Z = spawnPos.X, spawnPos.Y, spawnPos.Z

	-- 四條腿
	local legSz = Vector3.new(0.7*s, 1.4*s, 0.7*s)
	ap(model, "LegFL", legSz, Vector3.new(X - 1.2*s, Y + 0.7*s, Z - 0.9*s), colors.main, false)
	ap(model, "LegFR", legSz, Vector3.new(X + 1.2*s, Y + 0.7*s, Z - 0.9*s), colors.main, false)
	ap(model, "LegBL", legSz, Vector3.new(X - 1.2*s, Y + 0.7*s, Z + 0.9*s), colors.main, false)
	ap(model, "LegBR", legSz, Vector3.new(X + 1.2*s, Y + 0.7*s, Z + 0.9*s), colors.main, false)

	-- 身體（低趴寬扁）
	local body = ap(model, "Body",
		Vector3.new(3.5*s, 2*s, 3*s),
		Vector3.new(X, Y + 2.2*s, Z),
		colors.main, true)
	model.PrimaryPart = body

	-- 頭部（前方偏上，球形）
	ap(model, "Head",
		Vector3.new(1.9*s, 1.9*s, 1.9*s),
		Vector3.new(X, Y + 3.65*s, Z - 1.4*s),
		colors.main, false, Enum.PartType.Ball)

	-- 尖立貓耳
	ap(model, "EarL",
		Vector3.new(0.4*s, 0.75*s, 0.3*s),
		Vector3.new(X - 0.58*s, Y + 4.7*s, Z - 1.4*s),
		colors.accent, false)
	ap(model, "EarR",
		Vector3.new(0.4*s, 0.75*s, 0.3*s),
		Vector3.new(X + 0.58*s, Y + 4.7*s, Z - 1.4*s),
		colors.accent, false)
	-- 耳朵內層（粉紅）
	ap(model, "EarLInner",
		Vector3.new(0.22*s, 0.45*s, 0.2*s),
		Vector3.new(X - 0.58*s, Y + 4.68*s, Z - 1.45*s),
		BrickColor.new("Carnation pink"), false)
	ap(model, "EarRInner",
		Vector3.new(0.22*s, 0.45*s, 0.2*s),
		Vector3.new(X + 0.58*s, Y + 4.68*s, Z - 1.45*s),
		BrickColor.new("Carnation pink"), false)

	-- 眼睛
	ap(model, "EyeL",
		Vector3.new(0.28*s, 0.28*s, 0.28*s),
		Vector3.new(X - 0.52*s, Y + 3.65*s, Z - 2.35*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)
	ap(model, "EyeR",
		Vector3.new(0.28*s, 0.28*s, 0.28*s),
		Vector3.new(X + 0.52*s, Y + 3.65*s, Z - 2.35*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)

	-- 尾巴（三段，S 形往上翹）
	ap(model, "TailBase",
		Vector3.new(0.5*s, 0.5*s, 1.8*s),
		Vector3.new(X, Y + 2.2*s, Z + 2.15*s),
		colors.accent, false)
	ap(model, "TailMid",
		Vector3.new(0.42*s, 2.1*s, 0.42*s),
		Vector3.new(X, Y + 3.55*s, Z + 2.75*s),
		colors.accent, false)
	ap(model, "TailTip",
		Vector3.new(0.6*s, 0.6*s, 0.6*s),
		Vector3.new(X, Y + 4.7*s, Z + 2.75*s),
		BrickColor.new("White"), false, Enum.PartType.Ball)

	local idVal = Instance.new("StringValue")
	idVal.Name = "InstanceId"
	idVal.Value = instanceId
	idVal.Parent = model

	-- 頂端 ≈ Y+5.08*s，body 中心 Y+2.2*s → topOffset = 2.88*s
	addInfoGui(body, def, 2.88*s)
	model.Parent = workspace
	return model
end

-- ── 野人（直立粗壯蠻人） ────────────────────────────────────────────
local function buildWildHumanModel(def, instanceId, spawnPos, s, colors)
	local model = Instance.new("Model")
	model.Name = def.displayName
	local X, Y, Z = spawnPos.X, spawnPos.Y, spawnPos.Z

	-- 雙腿
	ap(model, "LegL",
		Vector3.new(0.9*s, 2.5*s, 0.9*s),
		Vector3.new(X - 0.55*s, Y + 1.25*s, Z),
		colors.main, false)
	ap(model, "LegR",
		Vector3.new(0.9*s, 2.5*s, 0.9*s),
		Vector3.new(X + 0.55*s, Y + 1.25*s, Z),
		colors.main, false)

	-- 軀幹（主 Part）
	local body = ap(model, "Body",
		Vector3.new(2.2*s, 3*s, 1.5*s),
		Vector3.new(X, Y + 4*s, Z),
		colors.main, true)
	model.PrimaryPart = body

	-- 手臂（向外微張）
	ap(model, "ArmL",
		Vector3.new(0.85*s, 2.8*s, 0.85*s),
		Vector3.new(X - 1.58*s, Y + 4*s, Z),
		colors.main, false)
	ap(model, "ArmR",
		Vector3.new(0.85*s, 2.8*s, 0.85*s),
		Vector3.new(X + 1.58*s, Y + 4*s, Z),
		colors.main, false)

	-- 頭部（球形）
	ap(model, "Head",
		Vector3.new(2*s, 2*s, 2*s),
		Vector3.new(X, Y + 6.5*s, Z),
		colors.accent, false, Enum.PartType.Ball)

	-- 眼睛
	ap(model, "EyeL",
		Vector3.new(0.32*s, 0.32*s, 0.32*s),
		Vector3.new(X - 0.5*s, Y + 6.5*s, Z - 0.95*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)
	ap(model, "EyeR",
		Vector3.new(0.32*s, 0.32*s, 0.32*s),
		Vector3.new(X + 0.5*s, Y + 6.5*s, Z - 0.95*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)

	-- 亂蓬蓬的野髮
	ap(model, "HairMain",
		Vector3.new(1.8*s, 0.6*s, 1.6*s),
		Vector3.new(X, Y + 7.65*s, Z - 0.1*s),
		colors.accent, false)
	ap(model, "HairL",
		Vector3.new(0.5*s, 0.9*s, 0.4*s),
		Vector3.new(X - 0.85*s, Y + 7.45*s, Z),
		colors.accent, false)
	ap(model, "HairR",
		Vector3.new(0.5*s, 0.9*s, 0.4*s),
		Vector3.new(X + 0.85*s, Y + 7.45*s, Z),
		colors.accent, false)

	local idVal = Instance.new("StringValue")
	idVal.Name = "InstanceId"
	idVal.Value = instanceId
	idVal.Parent = model

	-- 頂端 ≈ Y+7.9*s，body 中心 Y+4*s → topOffset = 3.9*s
	addInfoGui(body, def, 3.9*s)
	model.Parent = workspace
	return model
end

local BUILDERS = {
	doll      = buildDollModel,
	wildCat   = buildWildCatModel,
	wildHuman = buildWildHumanModel,
}

local function createNPCModel(def, instanceId, spawnPos)
	local cfg = NPC_CONFIG[def.id]
	if not cfg then
		warn("[NPCManager] 找不到 NPC_CONFIG：", def.id)
		return nil
	end
	local builder = BUILDERS[cfg.kind]
	if not builder then
		warn("[NPCManager] 找不到模型建構函數：", cfg.kind)
		return nil
	end
	return builder(def, instanceId, spawnPos, cfg.scale, { main = cfg.main, accent = cfg.accent })
end

-- 更新 HP 標籤顏色與文字
local function updateHPLabel(model, current, max)
	local body = model:FindFirstChild("Body")
	if not body then return end
	local gui = body:FindFirstChild("InfoGui")
	if not gui then return end
	local hpLabel = gui:FindFirstChild("HpLabel")
	if not hpLabel then return end
	local ratio = math.clamp(current / max, 0, 1)
	hpLabel.TextColor3 = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
	hpLabel.Text = "❤ " .. math.max(0, current) .. " / " .. max
end

function NPCManager.spawnNPC(npcId, position)
	local def = NPCData.getNPCById(npcId)
	if not def then
		warn("[NPCManager] 找不到 NPC 定義：", npcId)
		return nil
	end

	local instanceId = generateId()
	local spawnPos = Vector3.new(
		position.X + math.random(-5, 5),
		position.Y,
		position.Z + math.random(-5, 5)
	)

	local ok, result = pcall(createNPCModel, def, instanceId, spawnPos)
	if not ok then
		warn("[NPCManager] 建立 NPC 模型失敗：", result)
		return nil
	end
	if not result then
		warn("[NPCManager] 模型為 nil：", npcId)
		return nil
	end

	-- 使用模型的實際 Pivot 位置作為追蹤位置（Body 中心）
	local pivotPos = result:GetPivot().Position

	activeNPCs[instanceId] = {
		definition = def,
		currentHp  = def.maxHp,
		position   = pivotPos,
		instanceId = instanceId,
	}
	npcModels[instanceId] = result
	npcHomePositions[instanceId] = pivotPos
	npcNextAttackAt[instanceId] = 0

	print("[NPCManager] 生成 NPC：", def.displayName, "at", spawnPos)
	return activeNPCs[instanceId]
end

function NPCManager.startSpawnLoop()
	print("[NPCManager] 開始生成 NPC 迴圈，共", #SPAWN_ZONES, "個區域")
	local totalSpawned = 0
	for _, zone in ipairs(SPAWN_ZONES) do
		for i = 1, zone.count do
			local capturedZone = zone
			task.delay(totalSpawned * 0.2, function()
				NPCManager.spawnNPC(capturedZone.npcId, capturedZone.position)
			end)
			totalSpawned += 1
		end
	end
	print("[NPCManager] 已排程", totalSpawned, "隻 NPC 生成")
end

function NPCManager.handleAttack(attacker, instanceId, damage, statusEffect)
	local npc = activeNPCs[instanceId]
	if not npc then return end

	local finalDamage = math.max(1, damage - npc.definition.defense)
	npc.currentHp -= finalDamage

	local model = npcModels[instanceId]
	if model then
		updateHPLabel(model, npc.currentHp, npc.definition.maxHp)
		combatHitEvent:FireAllClients(instanceId, model:GetPivot().Position, finalDamage, false)
	end

	if npc.currentHp <= 0 then
		NPCManager.handleDeath(instanceId, attacker)
	end
end

function NPCManager.handleDeath(instanceId, killer)
	local npc = activeNPCs[instanceId]
	if not npc then return end

	local def = npc.definition
	local savedPosition = npc.position
	activeNPCs[instanceId] = nil
	npcHomePositions[instanceId] = nil
	npcWanderTargets[instanceId] = nil
	npcNextAttackAt[instanceId] = nil

	local model = npcModels[instanceId]
	if model then
		model:Destroy()
		npcModels[instanceId] = nil
	end

	npcDiedEvent:FireAllClients(instanceId)

	local xpGained = math.floor(def.xpReward * (GameConfig.XP_MULTIPLIERS[def.kind] or 1.0))

	local DataStore = require(script.Parent.DataStore)
	local killerData = DataStore.getData(killer)
	local coinBonus = (killerData and killerData._luckyCharmCoinBonus) or 0
	local coinsGained = math.floor(def.coinReward * (1 + coinBonus))

	if killerData then
		killerData.coins += coinsGained
	end

	if NPCManager._experienceManager then
		NPCManager._experienceManager.addXP(killer, xpGained)
	end

	remoteEvents:WaitForChild("UpdateUI"):FireClient(killer, "coins", coinsGained)

	task.delay(def.respawnTime + GameConfig.NPC_RESPAWN_BUFFER, function()
		NPCManager.spawnNPC(def.id, savedPosition)
	end)
end

function NPCManager.getNPCByInstance(instanceId)
	return activeNPCs[instanceId]
end

function NPCManager.getNPCsInRadius(center, radius)
	local result = {}
	for id, npc in pairs(activeNPCs) do
		if (npc.position - center).Magnitude <= radius then
			table.insert(result, id)
		end
	end
	return result
end

function NPCManager.getActiveNPCCount()
	local count = 0
	for _ in pairs(activeNPCs) do
		count += 1
	end
	return count
end

function NPCManager.getNearbyNPCs(originInstanceId, radius, maxCount)
	local origin = activeNPCs[originInstanceId]
	if not origin then return {} end
	local result = {}
	for id, npc in pairs(activeNPCs) do
		if id ~= originInstanceId and (npc.position - origin.position).Magnitude <= radius then
			table.insert(result, id)
			if #result >= maxCount then break end
		end
	end
	return result
end

-- 找距離 position 最近且在 maxDistance 內的存活玩家
local function getNearestPlayer(position, maxDistance)
	local nearest, nearestDist = nil, maxDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local dist = (hrp.Position - position).Magnitude
			if dist < nearestDist then
				nearest, nearestDist = player, dist
			end
		end
	end
	return nearest, nearestDist
end

-- 每幀更新 NPC 移動 / 攻擊行為（玩偶靜止，野貓/野人主動追人）
local function updateNPCBehavior(deltaTime)
	for id, npc in pairs(activeNPCs) do
		local model = npcModels[id]
		if not model then continue end

		local cfg = NPC_CONFIG[npc.definition.id]
		local speed = cfg and MOVE_SPEED_BY_KIND[cfg.kind] or 0
		local home = npcHomePositions[id] or npc.position
		local targetPos = home

		local player, dist = getNearestPlayer(npc.position, 45)

		if player and dist <= 45 then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				targetPos = hrp.Position
				if dist <= 5 then
					local now = os.clock()
					if now >= (npcNextAttackAt[id] or 0) then
						npcNextAttackAt[id] = now + 1.2
						local hum = player.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:TakeDamage(npc.definition.attack) end
					end
				end
			end
		elseif speed > 0 then
			local wander = npcWanderTargets[id]
			if not wander or (wander - npc.position).Magnitude < 3 then
				wander = home + Vector3.new(math.random(-18, 18), 0, math.random(-18, 18))
				npcWanderTargets[id] = wander
			end
			targetPos = wander
		end

		if speed > 0 then
			local toTarget = Vector3.new(targetPos.X - npc.position.X, 0, targetPos.Z - npc.position.Z)
			if toTarget.Magnitude > 0.1 then
				local step = math.min(toTarget.Magnitude, speed * deltaTime)
				local dir = toTarget.Unit
				npc.position = npc.position + dir * step
				model:PivotTo(CFrame.lookAt(npc.position, npc.position + dir))
			end
		end
	end
end

RunService.Heartbeat:Connect(updateNPCBehavior)

return NPCManager
