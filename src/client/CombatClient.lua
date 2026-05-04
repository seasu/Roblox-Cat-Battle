local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CombatClient = {}

local localPlayer = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local useSkillEvent = remoteEvents:WaitForChild("UseSkill") :: RemoteEvent

-- 目前技能列映射：slot -> skillId（由 GameClient 在初始化後設置）
CombatClient.skillSlots = {} :: { string }

-- 目前裝備的武器 ID（由 GameClient 透過 EquipmentChanged 更新）
CombatClient.currentWeapon = nil :: string?

-- ── VFX 輔助函數 ──────────────────────────────────────────────────

-- 建立一個錨定、不碰撞、短暫存在的 Part
local function vfxPart(pos: Vector3, size: Vector3, color: Color3,
	material: Enum.Material?, transparency: number?, lifetime: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = workspace
	Debris:AddItem(p, lifetime or 0.6)
	return p
end

-- 球形爆炸（向外擴散後淡出）
local function vfxBurst(pos: Vector3, color: Color3, startSize: number, endSize: number, duration: number)
	local p = vfxPart(pos, Vector3.new(startSize, startSize, startSize),
		color, Enum.Material.Neon, 0.1, duration + 0.1)
	p.Shape = Enum.PartType.Ball
	TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(endSize, endSize, endSize),
		Transparency = 1,
	}):Play()
end

-- 環形波（扁平圓柱，向外展開）
local function vfxRing(pos: Vector3, color: Color3, startR: number, endR: number, duration: number)
	local p = vfxPart(pos, Vector3.new(startR, 0.3, startR),
		color, Enum.Material.Neon, 0.15, duration + 0.1)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(endR, 0.3, endR),
		Transparency = 1,
	}):Play()
end

-- 爪痕（三條平行條紋，從 pos 斜向出現後淡出）
local function vfxClawSlash(pos: Vector3, color: Color3, count: number?, length: number?)
	local n = count or 3
	local len = length or 3
	for i = 1, n do
		local offset = Vector3.new((i - (n + 1) / 2) * 0.5, (i - 1) * 0.3, 0)
		local p = vfxPart(pos + offset,
			Vector3.new(0.18, len, 0.18),
			color, Enum.Material.Neon, 0, 0.35)
		p.CFrame = CFrame.new(pos + offset) * CFrame.Angles(0, 0, math.pi / 5)
		TweenService:Create(p, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Transparency = 1,
			Size = Vector3.new(0.06, len * 1.4, 0.06),
		}):Play()
	end
end

-- 向上噴射粒子（治癒/魔法用）
local function vfxRise(pos: Vector3, color: Color3, count: number)
	for i = 1, count do
		local offset = Vector3.new(math.random(-20, 20) / 10, 0, math.random(-20, 20) / 10)
		local p = vfxPart(pos + offset, Vector3.new(0.3, 0.3, 0.3),
			color, Enum.Material.Neon, 0.1, 0.9)
		p.Shape = Enum.PartType.Ball
		TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = pos + offset + Vector3.new(0, 5, 0),
			Transparency = 1,
			Size = Vector3.new(0.05, 0.05, 0.05),
		}):Play()
	end
end

-- 閃電條（隨機鋸齒線段）
local function vfxLightning(pos: Vector3, color: Color3, segments: number)
	local cur = pos
	for _ = 1, segments do
		local next = cur + Vector3.new(
			math.random(-15, 15) / 10,
			math.random(-8, 8) / 10,
			math.random(-15, 15) / 10
		) + Vector3.new(0, -0.3, 0)
		local mid = (cur + next) / 2
		local len = (next - cur).Magnitude
		local p = vfxPart(mid, Vector3.new(0.12, len, 0.12),
			color, Enum.Material.Neon, 0, 0.25)
		p.CFrame = CFrame.lookAt(mid, next) * CFrame.Angles(math.pi / 2, 0, 0)
		TweenService:Create(p, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		cur = next
	end
end

-- ── 武器特效定義 ──────────────────────────────────────────────────
-- 每種武器對應一個 function(hitPos: Vector3)

local WEAPON_VFX: { [string]: (pos: Vector3) -> () } = {

	-- 鐵爪：銀灰色三條爪痕 + 小衝擊球
	weaponClaws = function(pos)
		vfxClawSlash(pos, Color3.fromRGB(200, 210, 220), 3, 3.5)
		vfxBurst(pos, Color3.fromRGB(180, 190, 200), 0.5, 2.5, 0.25)
	end,

	-- 迷你劍：藍白劍氣弧 + 橫向環
	weaponSword = function(pos)
		vfxClawSlash(pos, Color3.fromRGB(160, 220, 255), 2, 4.5)
		vfxRing(pos, Color3.fromRGB(120, 200, 255), 0.5, 5, 0.3)
		vfxBurst(pos, Color3.fromRGB(200, 240, 255), 0.3, 1.8, 0.2)
	end,

	-- 貓盾：金色衝擊環 + 大球擴散（盾反感）
	weaponShield = function(pos)
		vfxRing(pos, Color3.fromRGB(255, 210, 60), 0.8, 7, 0.4)
		vfxRing(pos, Color3.fromRGB(255, 240, 140), 0.4, 4, 0.25)
		vfxBurst(pos, Color3.fromRGB(255, 220, 80), 1, 3, 0.3)
	end,

	-- 魔法杖：紫色星爆 + 多顆上升粒子
	weaponStaff = function(pos)
		vfxBurst(pos, Color3.fromRGB(180, 80, 255), 0.6, 4, 0.35)
		vfxRing(pos, Color3.fromRGB(140, 60, 220), 0.3, 3.5, 0.3)
		vfxRise(pos, Color3.fromRGB(200, 140, 255), 6)
	end,
}

-- 無武器（基礎爪）
local function defaultWeaponVFX(pos: Vector3)
	vfxClawSlash(pos, Color3.fromRGB(255, 240, 200), 3, 3)
	vfxBurst(pos, Color3.fromRGB(255, 220, 150), 0.3, 2, 0.2)
end

-- ── 技能額外特效（疊加在武器特效之上） ──────────────────────────
local SKILL_VFX: { [string]: (pos: Vector3) -> () } = {

	BasicSwipe = function(pos)
		-- 只靠武器特效，無額外
	end,

	PowerClaw = function(pos)
		vfxClawSlash(pos, Color3.fromRGB(220, 60, 60), 4, 4)
		vfxBurst(pos, Color3.fromRGB(180, 30, 30), 0.5, 3, 0.3)
	end,

	ShadowStrike = function(pos)
		vfxBurst(pos, Color3.fromRGB(60, 0, 80), 0.8, 5, 0.4)
		vfxRise(pos, Color3.fromRGB(100, 20, 140), 5)
		-- 黑紫殘影環
		vfxRing(pos, Color3.fromRGB(80, 0, 100), 1, 6, 0.35)
	end,

	Vanish = function(pos)
		-- 自身位置白色閃光
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		vfxBurst(p2, Color3.fromRGB(200, 200, 200), 2, 8, 0.5)
		vfxRing(p2, Color3.fromRGB(180, 180, 180), 1, 7, 0.45)
	end,

	FireClaw = function(pos)
		vfxBurst(pos, Color3.fromRGB(255, 100, 20), 0.8, 5, 0.4)
		vfxRing(pos, Color3.fromRGB(255, 60, 10), 0.5, 4, 0.35)
		vfxRise(pos, Color3.fromRGB(255, 140, 30), 8)
	end,

	EmberAura = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		vfxRing(p2, Color3.fromRGB(255, 80, 10), 1, 10, 0.5)
		vfxBurst(p2, Color3.fromRGB(255, 120, 20), 2, 9, 0.5)
		vfxRise(p2, Color3.fromRGB(255, 160, 40), 12)
	end,

	IceShard = function(pos)
		vfxBurst(pos, Color3.fromRGB(140, 220, 255), 0.5, 4, 0.35)
		-- 四向冰錐（小長條）
		for i = 0, 3 do
			local angle = i * math.pi / 2
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local p = vfxPart(pos + dir * 1.5,
				Vector3.new(0.25, 2, 0.25),
				Color3.fromRGB(180, 240, 255), Enum.Material.Neon, 0, 0.4)
			p.CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(math.pi / 2, 0, 0)
			TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = pos + dir * 4,
				Transparency = 1,
			}):Play()
		end
	end,

	FrostAura = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		vfxRing(p2, Color3.fromRGB(180, 230, 255), 1, 9, 0.5)
		vfxBurst(p2, Color3.fromRGB(200, 240, 255), 2, 8, 0.45)
	end,

	ThunderPounce = function(pos)
		vfxLightning(pos + Vector3.new(0, 4, 0), Color3.fromRGB(255, 255, 60), 8)
		vfxBurst(pos, Color3.fromRGB(255, 240, 50), 1, 7, 0.4)
		vfxRing(pos, Color3.fromRGB(220, 220, 30), 1, 8, 0.4)
	end,

	ChainLightning = function(pos)
		vfxLightning(pos + Vector3.new(0, 3, 0), Color3.fromRGB(160, 200, 255), 10)
		vfxBurst(pos, Color3.fromRGB(140, 180, 255), 0.8, 5, 0.35)
	end,

	PetalSlash = function(pos)
		-- 粉紅花瓣環
		vfxRing(pos, Color3.fromRGB(255, 160, 200), 0.5, 5, 0.4)
		vfxRise(pos, Color3.fromRGB(255, 180, 220), 8)
		vfxBurst(pos, Color3.fromRGB(255, 200, 230), 0.6, 4, 0.35)
	end,

	HealingBloom = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		vfxBurst(p2, Color3.fromRGB(80, 220, 100), 1, 6, 0.5)
		vfxRing(p2, Color3.fromRGB(60, 200, 80), 1, 5, 0.45)
		vfxRise(p2, Color3.fromRGB(120, 255, 140), 12)
	end,

	FoodRage = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		vfxBurst(p2, Color3.fromRGB(230, 140, 30), 1.5, 7, 0.45)
		vfxRing(p2, Color3.fromRGB(200, 100, 20), 1, 6, 0.4)
	end,

	GentlemanStrike = function(pos)
		-- 黑白暴擊閃光
		vfxBurst(pos, Color3.fromRGB(255, 255, 255), 1, 6, 0.3)
		vfxRing(pos, Color3.fromRGB(200, 200, 200), 0.5, 7, 0.35)
		vfxClawSlash(pos, Color3.fromRGB(240, 240, 240), 2, 5)
	end,

	TailcoatShield = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		-- 黑白護盾球
		vfxBurst(p2, Color3.fromRGB(40, 40, 40), 2, 7, 0.5)
		vfxRing(p2, Color3.fromRGB(220, 220, 220), 1, 6, 0.45)
	end,

	LuckyCharm = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		vfxBurst(p2, Color3.fromRGB(255, 215, 0), 1, 5, 0.5)
		vfxRing(p2, Color3.fromRGB(255, 200, 50), 1, 6, 0.45)
		vfxRise(p2, Color3.fromRGB(255, 240, 100), 10)
	end,

	ColorShift = function(pos)
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local p2 = root and root.Position or pos
		-- 三色環
		vfxRing(p2, Color3.fromRGB(255, 80, 20), 0.5, 5, 0.4)
		task.delay(0.08, function()
			vfxRing(p2, Color3.fromRGB(80, 180, 255), 0.5, 5, 0.4)
		end)
		task.delay(0.16, function()
			vfxRing(p2, Color3.fromRGB(255, 255, 60), 0.5, 5, 0.4)
		end)
	end,
}

-- ── 主特效入口 ────────────────────────────────────────────────────

local function spawnAttackVFX(skillId: string, hitPos: Vector3)
	local weaponId = CombatClient.currentWeapon
	-- 武器底層特效
	local weaponFn = (weaponId and WEAPON_VFX[weaponId]) or defaultWeaponVFX
	weaponFn(hitPos)
	-- 技能疊加特效
	local skillFn = SKILL_VFX[skillId]
	if skillFn then
		skillFn(hitPos)
	end
end

-- 快捷鍵對應（第 2–6 槽）

local function playOneShotSound(soundId: string, position: Vector3?, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.8
	sound.RollOffMaxDistance = 80
	if position then
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.Position = position
		part.Parent = workspace
		sound.Parent = part
		sound:Play()
		game:GetService("Debris"):AddItem(part, 2)
	else
		sound.Parent = workspace
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end
end

local KEY_BINDINGS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.Q] = 2,
	[Enum.KeyCode.E] = 3,
	[Enum.KeyCode.R] = 4,
	[Enum.KeyCode.F] = 5,
	[Enum.KeyCode.T] = 6,
}

local function getMouseTarget(): (string?, Vector3?)
	local camera = workspace.CurrentCamera
	local mouse = localPlayer:GetMouse()
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100)
	if not result then return nil, nil end

	local hit = result.Instance
	local npcModel = hit:FindFirstAncestorWhichIsA("Model")
	if npcModel then
		local idValue = npcModel:FindFirstChild("InstanceId")
		if idValue then
			return (idValue :: StringValue).Value, result.Position
		end
	end
	return nil, result.Position
end

function CombatClient.attemptBasicAttack()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local instanceId, hitPos = getMouseTarget()
	if instanceId then
		useSkillEvent:FireServer("BasicSwipe", instanceId)
		local vfxPos = hitPos or (root.Position + Vector3.new(0, 0, -3))
		spawnAttackVFX("BasicSwipe", vfxPos)
		playOneShotSound("rbxassetid://12222225", vfxPos, 0.6)
	end
end

function CombatClient.activateSkill(slotIndex: number)
	local skillId = CombatClient.skillSlots[slotIndex]
	if not skillId then return end

	local instanceId, hitPos = getMouseTarget()
	useSkillEvent:FireServer(skillId, instanceId)

	-- 立即顯示技能特效（不等伺服器回應，讓手感更即時）
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local vfxPos = hitPos or (root and root.Position + Vector3.new(0, 0, -4)) or Vector3.new(0, 1, 0)
	spawnAttackVFX(skillId, vfxPos)
end

function CombatClient.showDamageNumber(position: Vector3, damage: number | string, isCrit: boolean)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Parent = workspace
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Parent = billboard
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(damage)
	label.Font = Enum.Font.GothamBold
	label.TextSize = isCrit and 28 or 20
	label.TextColor3 = isCrit and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 80)
	label.TextStrokeTransparency = 0.3
	playOneShotSound("rbxassetid://5419098675", position, isCrit and 1 or 0.8)

	-- 向上飄移並淡出
	local tweenPart = TweenService:Create(part,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = position + Vector3.new(0, 4, 0) })
	local tweenLabel = TweenService:Create(label,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 })

	tweenPart:Play()
	tweenLabel:Play()

	game:GetService("Debris"):AddItem(part, 1.6)
end

function CombatClient.onSkillResult(
	skillId: string,
	targets: { string },
	damage: number,
	cooldown: number,
	extra: string?
)
	local UIManager = require(script.Parent.UIManager)
	UIManager.updateSkillCooldown(skillId, cooldown)
end

function CombatClient.onNPCDied(instanceId: string)
	-- 清除場景上對應的 NPC BillboardGui
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("StringValue") and obj.Name == "InstanceId" and obj.Value == instanceId then
			local model = obj.Parent
			if model then
				model:Destroy()
			end
			break
		end
	end
end

function CombatClient.init()
	-- 滑鼠左鍵攻擊
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			CombatClient.attemptBasicAttack()
			return
		end

		local slotIndex = KEY_BINDINGS[input.KeyCode]
		if slotIndex then
			CombatClient.activateSkill(slotIndex)
		end
	end)

	-- 手機觸控
	UserInputService.TouchTap:Connect(function(touchPositions: { Vector2 }, gameProcessed: boolean)
		if gameProcessed then return end
		CombatClient.attemptBasicAttack()
	end)
end

return CombatClient
