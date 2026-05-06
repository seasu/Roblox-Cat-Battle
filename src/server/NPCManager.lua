local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local NPCData = require(ReplicatedStorage:WaitForChild("Shared").NPCData)
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared").GameConfig)

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
-- "idle"（漫步）/ "chase"（追逐）/ "return"（返回原位）
local npcState = {}

-- ── 安全區定義 ─────────────────────────────────────────────────────
-- 圓形：{type="circle", center=Vector3, radius=number}
-- 矩形：{type="rect", minX, maxX, minZ, maxZ}
-- 注意：需與 WorldSetup.server.lua 的地板視覺保持一致
local SAFE_ZONES = {
	-- 出生點廣場（半徑 55，覆蓋廣場與路徑起點）
	{ type = "circle", center = Vector3.new(0, 0, 0), radius = 55 },
	-- 商城攤位區（X=-42~42, Z=10~72，完整包含三棟建築）
	{ type = "rect", minX = -42, maxX = 42, minZ = 10, maxZ = 72 },
}

-- 追逐參數
local AGGRO_RANGE     = 28   -- NPC 發現玩家的距離（格）
local MAX_CHASE_DIST  = 65   -- 離 home 最大追逐距離，超過即放棄
local ATTACK_RANGE    = 5    -- 攻擊距離
local RETURN_SPEED_MULT = 1.5 -- 返回原位時的速度倍率

local function isInSafeZone(position: Vector3): boolean
	for _, zone in ipairs(SAFE_ZONES) do
		if zone.type == "circle" then
			local dx = position.X - zone.center.X
			local dz = position.Z - zone.center.Z
			if math.sqrt(dx*dx + dz*dz) <= zone.radius then
				return true
			end
		elseif zone.type == "rect" then
			if position.X >= zone.minX and position.X <= zone.maxX
				and position.Z >= zone.minZ and position.Z <= zone.maxZ then
				return true
			end
		end
	end
	return false
end

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

-- 碎片掉落機率（依 NPC 類型）
local FRAGMENT_DROP_RATE = { Doll = 0.08, WildCat = 0.15, WildHuman = 0.22 }
-- 可合成的特殊貓列表
local SPECIAL_CAT_IDS = {
	"shadowCat", "flameCat", "frostCat", "thunderCat",
	"sakuraCat", "orangeCat", "calicoCat", "tuxedoCat",
}

-- NPC 移動速度（玩偶靜止，野貓和野人會追逐玩家）
local MOVE_SPEED_BY_KIND = {
	doll      = 0,
	wildCat   = 14,
	wildHuman = 11,
}

-- 生成區域（對應新地圖：玩偶區左X=-150，野貓區前Z=-150，野人區右X=+150）
local SPAWN_ZONES = {
	{ npcId = "dollEasy",        position = Vector3.new(-165, 1,  15), count = 4 },
	{ npcId = "dollEasy",        position = Vector3.new(-140, 1, -20), count = 3 },
	{ npcId = "dollMedium",      position = Vector3.new(-155, 1,  30), count = 3 },
	{ npcId = "dollHard",        position = Vector3.new(-145, 1, -35), count = 2 },
	{ npcId = "wildCatEasy",     position = Vector3.new( -18, 1, -165), count = 4 },
	{ npcId = "wildCatMedium",   position = Vector3.new(  18, 1, -145), count = 3 },
	{ npcId = "wildCatHard",     position = Vector3.new(   0, 1, -130), count = 2 },
	{ npcId = "wildHumanEasy",   position = Vector3.new( 155, 1,  20), count = 4 },
	{ npcId = "wildHumanMedium", position = Vector3.new( 140, 1, -15), count = 3 },
	{ npcId = "wildHumanHard",   position = Vector3.new( 165, 1,  -5), count = 2 },
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

-- 建立一個 MeshPart (透過 FileMesh) 並加入 model
local function am(model, name, meshId, size, pos, color, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = canCollide == true
	p.Size = size
	p.Position = pos
	p.BrickColor = color
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = model

	local m = Instance.new("SpecialMesh")
	m.MeshId = meshId
	m.Scale = Vector3.new(1, 1, 1) -- 預設比例，由 Part Size 控制
	m.Parent = p

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

-- ── 玩偶（超級圓潤、軟萌配色） ──────────────────────────────────────────
local function buildDollModel(def, instanceId, spawnPos, s, colors)
	local model = Instance.new("Model")
	model.Name = def.displayName
	local X, Y, Z = spawnPos.X, spawnPos.Y, spawnPos.Z

	-- 身體（圓潤大球體）
	local body = ap(model, "Body",
		Vector3.new(2.8*s, 2.8*s, 2.8*s),
		Vector3.new(X, Y + 1.4*s, Z),
		colors.main, true, Enum.PartType.Ball)
	model.PrimaryPart = body

	-- 頭部（更圓的球）
	ap(model, "Head",
		Vector3.new(2.4*s, 2.4*s, 2.4*s),
		Vector3.new(X, Y + 3.4*s, Z),
		colors.main, false, Enum.PartType.Ball)

	-- 圓耳朵
	ap(model, "EarL",
		Vector3.new(0.6*s, 0.6*s, 0.6*s),
		Vector3.new(X - 0.7*s, Y + 4.5*s, Z),
		colors.accent, false, Enum.PartType.Ball)
	ap(model, "EarR",
		Vector3.new(0.6*s, 0.6*s, 0.6*s),
		Vector3.new(X + 0.7*s, Y + 4.5*s, Z),
		colors.accent, false, Enum.PartType.Ball)

	-- 大大的黑眼睛（呆萌感）
	ap(model, "EyeL",
		Vector3.new(0.4*s, 0.4*s, 0.4*s),
		Vector3.new(X - 0.6*s, Y + 3.4*s, Z - 1.1*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)
	ap(model, "EyeR",
		Vector3.new(0.4*s, 0.4*s, 0.4*s),
		Vector3.new(X + 0.6*s, Y + 3.4*s, Z - 1.1*s),
		BrickColor.new("Really black"), false, Enum.PartType.Ball)

	-- 腮紅（必備）
	ap(model, "CheekL",
		Vector3.new(0.6*s, 0.4*s, 0.3*s),
		Vector3.new(X - 0.9*s, Y + 3.1*s, Z - 1.0*s),
		BrickColor.new("Carnation pink"), false, Enum.PartType.Ball)
	ap(model, "CheekR",
		Vector3.new(0.6*s, 0.4*s, 0.3*s),
		Vector3.new(X + 0.9*s, Y + 3.1*s, Z - 1.0*s),
		BrickColor.new("Carnation pink"), false, Enum.PartType.Ball)

	local idVal = Instance.new("StringValue")
	idVal.Name = "InstanceId"
	idVal.Value = instanceId
	idVal.Parent = model

	addInfoGui(body, def, 3.5*s)
	model.Parent = workspace
	return model
end

-- ── 野貓（使用 3D Mesh，更有靈動感） ──────────────────────────────────────────
local function buildWildCatModel(def, instanceId, spawnPos, s, colors)
	local model = Instance.new("Model")
	model.Name = def.displayName
	local X, Y, Z = spawnPos.X, spawnPos.Y, spawnPos.Z

	-- 四條短胖腿
	local legSz = Vector3.new(0.6*s, 1.0*s, 0.6*s)
	ap(model, "LegFL", legSz, Vector3.new(X - 1.0*s, Y + 0.5*s, Z - 0.8*s), colors.main, false)
	ap(model, "LegFR", legSz, Vector3.new(X + 1.0*s, Y + 0.5*s, Z - 0.8*s), colors.main, false)
	ap(model, "LegBL", legSz, Vector3.new(X - 1.0*s, Y + 0.5*s, Z + 0.8*s), colors.main, false)
	ap(model, "LegBR", legSz, Vector3.new(X + 1.0*s, Y + 0.5*s, Z + 0.8*s), colors.main, false)

	-- 身體（像吐司一樣的方圓形）
	local body = ap(model, "Body",
		Vector3.new(3.0*s, 1.8*s, 2.8*s),
		Vector3.new(X, Y + 1.6*s, Z),
		colors.main, true)
	model.PrimaryPart = body

	-- 3D 頭部（使用 Generic Cat Head Mesh）
	am(model, "Head",
		"rbxassetid://74852812713110",
		Vector3.new(2.2*s, 2.2*s, 2.2*s),
		Vector3.new(X, Y + 2.8*s, Z - 1.2*s),
		colors.main, false)

	-- 3D 尾巴（使用 Curved Tail Mesh）
	am(model, "Tail",
		"rbxassetid://96597653505917",
		Vector3.new(1.5*s, 1.5*s, 1.5*s),
		Vector3.new(X, Y + 2.2*s, Z + 2.0*s),
		colors.accent, false)

	local idVal = Instance.new("StringValue")
	idVal.Name = "InstanceId"
	idVal.Value = instanceId
	idVal.Parent = model

	addInfoGui(body, def, 2.5*s)
	model.Parent = workspace
	return model
end

-- ── 野人（Chibi 風格，帶貓耳帽的可愛部落民） ────────────────────────────────────────────
local function buildWildHumanModel(def, instanceId, spawnPos, s, colors)
	local model = Instance.new("Model")
	model.Name = def.displayName
	local X, Y, Z = spawnPos.X, spawnPos.Y, spawnPos.Z

	-- 短短的雙腿
	ap(model, "LegL",
		Vector3.new(0.8*s, 1.2*s, 0.8*s),
		Vector3.new(X - 0.5*s, Y + 0.6*s, Z),
		colors.main, false)
	ap(model, "LegR",
		Vector3.new(0.8*s, 1.2*s, 0.8*s),
		Vector3.new(X + 0.5*s, Y + 0.6*s, Z),
		colors.main, false)

	-- 圓滾滾的軀幹
	local body = ap(model, "Body",
		Vector3.new(1.8*s, 2.2*s, 1.4*s),
		Vector3.new(X, Y + 2.3*s, Z),
		colors.main, true)
	model.PrimaryPart = body

	-- 3D 頭部帽（帶貓耳的頭部）
	am(model, "Head",
		"rbxassetid://74852812713110",
		Vector3.new(2.4*s, 2.4*s, 2.4*s),
		Vector3.new(X, Y + 4.2*s, Z),
		colors.accent, false)

	-- 手臂（握拳姿勢）
	ap(model, "ArmL",
		Vector3.new(0.7*s, 1.5*s, 0.7*s),
		Vector3.new(X - 1.3*s, Y + 2.5*s, Z),
		colors.main, false)
	ap(model, "ArmR",
		Vector3.new(0.7*s, 1.5*s, 0.7*s),
		Vector3.new(X + 1.3*s, Y + 2.5*s, Z),
		colors.main, false)

	local idVal = Instance.new("StringValue")
	idVal.Name = "InstanceId"
	idVal.Value = instanceId
	idVal.Parent = model

	addInfoGui(body, def, 3.8*s)
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
	local rawX = position.X + math.random(-5, 5)
	local rawZ = position.Z + math.random(-5, 5)

	-- ── 地面偵測 (Raycast) ──────────────────────────────────────────
	-- 從上方 20 格向下射線，找尋最近的地面，避免 NPC 因為碰撞飄在半空
	local rayOrigin = Vector3.new(rawX, position.Y + 20, rawZ)
	local rayDirection = Vector3.new(0, -40, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	-- 排除目前已有的 NPC 模型
	local excludeList = {}
	for _, model in pairs(npcModels) do table.insert(excludeList, model) end
	raycastParams.FilterDescendantsInstances = excludeList

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	local spawnY = position.Y
	if result then
		spawnY = result.Position.Y
	end

	local spawnPos = Vector3.new(rawX, spawnY, rawZ)

	local ok, npcModel = pcall(createNPCModel, def, instanceId, spawnPos)
	if not ok then
		warn("[NPCManager] 建立 NPC 模型失敗：", npcModel)
		return nil
	end
	if not npcModel then
		warn("[NPCManager] 模型為 nil：", npcId)
		return nil
	end

	-- 使用模型的實際 Pivot 位置作為追蹤位置（Body 中心）
	local pivotPos = npcModel:GetPivot().Position

	activeNPCs[instanceId] = {
		definition = def,
		currentHp  = def.maxHp,
		position   = pivotPos,
		instanceId = instanceId,
	}
	npcModels[instanceId] = npcModel
	npcHomePositions[instanceId] = pivotPos
	npcNextAttackAt[instanceId] = 0
	npcState[instanceId] = "idle"

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
	npcState[instanceId] = nil

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

	-- 碎片掉落（隨機特殊貓碎片）
	local droppedFragment: string? = nil
	local dropRate = FRAGMENT_DROP_RATE[def.kind] or 0.08
	if math.random() < dropRate then
		local fragmentCatId = SPECIAL_CAT_IDS[math.random(#SPECIAL_CAT_IDS)]
		droppedFragment = fragmentCatId
		if killerData then
			killerData.catFragments = killerData.catFragments or {}
			killerData.catFragments[fragmentCatId] = (killerData.catFragments[fragmentCatId] or 0) + 1
			local fragCount = killerData.catFragments[fragmentCatId]
			remoteEvents:WaitForChild("UpdateFragments"):FireClient(killer, fragmentCatId, fragCount)
		end
	end

	-- 掉落特效通知（金幣 + 可能有碎片）
	remoteEvents:WaitForChild("NPCDrops"):FireClient(killer,
		Vector3.new(savedPosition.X, savedPosition.Y + 1, savedPosition.Z),
		coinsGained,
		droppedFragment
	)

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

-- ── NPC 三狀態 AI ─────────────────────────────────────────────────
--
--  idle   → 在 home 附近隨機漫步，感知到玩家後切換 chase
--  chase  → 追逐最近玩家；以下情況放棄並切 return：
--             1. 玩家進入安全區
--             2. 玩家跑得太遠（> AGGRO_RANGE × 1.8）
--             3. NPC 離 home 超過 MAX_CHASE_DIST
--  return → 快速回到 home；到達後切 idle
--
local function updateNPCBehavior(deltaTime)
	for id, npc in pairs(activeNPCs) do
		local model = npcModels[id]
		if not model then continue end

		local cfg = NPC_CONFIG[npc.definition.id]
		local baseSpeed = cfg and MOVE_SPEED_BY_KIND[cfg.kind] or 0
		local home = npcHomePositions[id] or npc.position
		local state = npcState[id] or "idle"

		-- 玩偶靜止，只做攻擊判定（不移動也不追）
		if baseSpeed == 0 then
			local player, dist = getNearestPlayer(npc.position, ATTACK_RANGE)
			if player and dist <= ATTACK_RANGE then
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if hrp and not isInSafeZone(hrp.Position) then
					local now = os.clock()
					if now >= (npcNextAttackAt[id] or 0) then
						npcNextAttackAt[id] = now + 1.5
						local hum = player.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:TakeDamage(npc.definition.attack) end
					end
				end
			end
			continue
		end

		local targetPos: Vector3
		local moveSpeed = baseSpeed

		if state == "return" then
			-- 返回原位
			local distHome = (home - npc.position).Magnitude
			if distHome < 2 then
				npc.position = Vector3.new(home.X, npc.position.Y, home.Z)
				npcState[id] = "idle"
				npcWanderTargets[id] = nil
				targetPos = home
			else
				targetPos = home
				moveSpeed = baseSpeed * RETURN_SPEED_MULT
			end

		elseif state == "chase" then
			local player, dist = getNearestPlayer(npc.position, AGGRO_RANGE * 1.8)
			local hrp = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")

			-- 判斷是否應放棄追逐
			local shouldAbandon = false
			if not player or not hrp then
				shouldAbandon = true
			else
				local playerInSafe = isInSafeZone(hrp.Position)
				local npcTooFarFromHome = (npc.position - home).Magnitude > MAX_CHASE_DIST
				if playerInSafe or npcTooFarFromHome then
					shouldAbandon = true
				end
			end

			if shouldAbandon then
				npcState[id] = "return"
				targetPos = home
				moveSpeed = baseSpeed * RETURN_SPEED_MULT
			else
				-- 繼續追逐
				targetPos = hrp.Position
				-- 攻擊判定
				if dist and dist <= ATTACK_RANGE then
					local now = os.clock()
					if now >= (npcNextAttackAt[id] or 0) then
						npcNextAttackAt[id] = now + 1.2
						local hum = player.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:TakeDamage(npc.definition.attack) end
					end
				end
			end

		else
			-- idle：漫步
			local player, dist = getNearestPlayer(npc.position, AGGRO_RANGE)
			local hrp = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")

			if player and hrp and dist and dist <= AGGRO_RANGE
				and not isInSafeZone(hrp.Position) then
				-- 玩家在感知範圍內且不在安全區 → 切換追逐
				npcState[id] = "chase"
				targetPos = hrp.Position
			else
				-- 繼續漫步
				local wander = npcWanderTargets[id]
				if not wander or (wander - npc.position).Magnitude < 2.5 then
					-- 隨機新漫步點（在 home 附近 18 格內）
					wander = home + Vector3.new(math.random(-18, 18), 0, math.random(-18, 18))
					npcWanderTargets[id] = wander
				end
				targetPos = wander
				moveSpeed = baseSpeed * 0.5  -- 漫步時速度減半，看起來更自然
			end
		end

		-- 移動
		if targetPos then
			local toTarget = Vector3.new(
				targetPos.X - npc.position.X,
				0,
				targetPos.Z - npc.position.Z
			)
			if toTarget.Magnitude > 0.1 then
				local step = math.min(toTarget.Magnitude, moveSpeed * deltaTime)
				local dir = toTarget.Unit
				npc.position = npc.position + dir * step
				model:PivotTo(CFrame.lookAt(npc.position, npc.position + dir))
			end
		end
	end
end

RunService.Heartbeat:Connect(updateNPCBehavior)

return NPCManager
