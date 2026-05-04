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

local function getMouseTarget(overridePos: Vector3?): (string?, Vector3?)
	local camera = workspace.CurrentCamera
	local x, y
	if overridePos then
		x, y = overridePos.X, overridePos.Y
	else
		local mouse = localPlayer:GetMouse()
		x, y = mouse.X, mouse.Y
	end
	
	local unitRay = camera:ScreenPointToRay(x, y)
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

function CombatClient.attemptBasicAttack(inputPos: Vector3?)
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local instanceId, hitPos = getMouseTarget(inputPos)
	
	-- 無論是否打中 NPC，都播放揮手動作與聲音，提供操作回饋
	local vfxPos = hitPos or (root.Position + root.CFrame.LookVector * 3)
	
	if instanceId then
		useSkillEvent:FireServer("BasicSwipe", instanceId)
	end
	
	spawnAttackVFX("BasicSwipe", vfxPos)
	playOneShotSound("rbxassetid://12222225", vfxPos, 0.6)
	triggerSwingForSkill("BasicSwipe")
end

function CombatClient.activateSkill(slotIndex: number, inputPos: Vector3?)
	local skillId = CombatClient.skillSlots[slotIndex]
	if not skillId then return end

	local instanceId, hitPos = getMouseTarget(inputPos)
	useSkillEvent:FireServer(skillId, instanceId)

	-- 立即顯示技能特效 + 揮手動畫
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local vfxPos = hitPos or (root and root.Position + Vector3.new(0, 0, -4)) or Vector3.new(0, 1, 0)
	spawnAttackVFX(skillId, vfxPos)
	triggerSwingForSkill(skillId)
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

-- ── 攻擊揮手動畫 ─────────────────────────────────────────────────
-- 找出手臂的 Motor6D (肩部關節)，優先尋找最上層關節以帶動整個手臂
local function getArmMotor(char: Model, side: "Right" | "Left"): Motor6D?
	local sidePattern = (side == "Right") and "Right" or "Left"
	local candidates = {}
	
	for _, m in ipairs(char:GetDescendants()) do
		if m:IsA("Motor6D") and m.Part1 then
			local p1Name = m.Part1.Name
			local mName = m.Name
			if string.find(p1Name, sidePattern) or string.find(mName, sidePattern) then
				table.insert(candidates, m)
			end
		end
	end
	
	-- 優先級 1：名稱包含 Shoulder (R6/R15 常見)
	for _, m in ipairs(candidates) do
		if string.find(m.Name, "Shoulder") then return m end
	end
	
	-- 優先級 2：Part1 包含 Arm/Paw 且排除 Lower/Hand (確保是上臂)
	for _, m in ipairs(candidates) do
		local p1 = m.Part1.Name
		if (string.find(p1, "Arm") or string.find(p1, "Paw")) 
			and not string.find(p1, "Lower") 
			and not string.find(p1, "Hand") then
			return m
		end
	end
	
	return candidates[1]
end

-- ── 貓咪走路姿勢優化 (四足俯衝感) ──────────────────────────────────
-- 透過旋轉 RootJoint 讓貓咪在移動時身體前傾，更像四足動物行走
local function setupCatWalkTilt()
	local currentConnection: RBXScriptConnection? = nil

	local function onCharacter(char: Model)
		if currentConnection then currentConnection:Disconnect() end
		
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		local rootMotor: Motor6D? = nil

		local function findRootMotor()
			for _, m in ipairs(char:GetDescendants()) do
				if m:IsA("Motor6D") and m.Part0 and m.Part0.Name == "HumanoidRootPart" then
					return m
				end
			end
			return nil
		end

		currentConnection = RunService.RenderStepped:Connect(function()
			if not char.Parent or not hum.Parent then
				if currentConnection then currentConnection:Disconnect() end
				return
			end
			
			if not rootMotor or not rootMotor.Parent then
				rootMotor = findRootMotor()
				if not rootMotor then return end
			end

			local moveDir = hum.MoveDirection
			local isMoving = moveDir.Magnitude > 0.1
			
			-- 目標前傾角度：移動時 40 度左右 (math.pi/4.5)，靜止時 0 度
			local targetAngle = isMoving and (math.pi / 4.5) or 0
			local currentCF = rootMotor.Transform
			local targetCF = CFrame.Angles(targetAngle, 0, 0)
			
			rootMotor.Transform = currentCF:Lerp(targetCF, 0.15)
		end)
	end

	if localPlayer.Character then onCharacter(localPlayer.Character) end
	localPlayer.CharacterAdded:Connect(onCharacter)
end

-- 揮手動畫：使用 RenderStepped 並在每一幀強制「覆寫」Transform。
local swingActive = false
local function playSwingAnimation(swingAngle: number, duration: number)
	if swingActive then return end
	local char = localPlayer.Character
	if not char then return end
	local motor = getArmMotor(char, "Right")
	if not motor then return end

	swingActive = true
	local startTime = os.clock()
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local t = elapsed / duration

		if t >= 1 or not char.Parent or not motor.Parent then
			motor.Transform = CFrame.new() -- 回歸原位
			connection:Disconnect()
			swingActive = false
			return
		end

		-- 動作曲線 (更加激進的揮動)
		local alpha = 0
		if t < 0.2 then
			alpha = (t / 0.2) ^ 2 -- 快速揮出
		elseif t < 0.3 then
			alpha = 1 -- 停頓打擊感
		else
			local backT = (t - 0.3) / 0.7
			alpha = math.cos(backT * math.pi / 2) -- 平滑收回
		end

		-- 強制覆寫。注意：若有 setupCatWalkTilt，這會與其競爭 Transform。
		-- 但因為這裡是揮手動畫，通常只影響手臂，而 CatWalkTilt 影響軀幹，所以不衝突。
		motor.Transform = CFrame.Angles(swingAngle * alpha, 0, 0.2 * alpha)
	end)
end

-- 依技能決定揮動參數
local SKILL_SWING: { [string]: { angle: number, duration: number } } = {
	BasicSwipe      = { angle = -1.4, duration = 0.28 },
	PowerClaw       = { angle = -1.7, duration = 0.35 },
	ShadowStrike    = { angle = -1.9, duration = 0.25 },
	FireClaw        = { angle = -1.5, duration = 0.32 },
	GentlemanStrike = { angle = -2.0, duration = 0.30 },
	FoodRage        = { angle = -1.8, duration = 0.30 },
	PetalSlash      = { angle = -1.4, duration = 0.28 },
	ThunderPounce   = { angle = -1.9, duration = 0.30 },
}

-- 雙手揮動（AoE 技能用）
local function playBothArmsSwing(angle: number, duration: number)
	local char = localPlayer.Character
	if not char then return end
	local mR = getArmMotor(char, "Right")
	local mL = getArmMotor(char, "Left")

	local startTime = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - startTime) / duration
		if t >= 1 or not char.Parent then
			if mR then mR.Transform = CFrame.new() end
			if mL then mL.Transform = CFrame.new() end
			connection:Disconnect()
			return
		end

		local alpha = 1
		if t < 0.4 then alpha = (t / 0.4) ^ 2
		else alpha = 1 - ((t - 0.4) / 0.6) ^ 2 end
		
		local cf = CFrame.Angles(angle * alpha, 0, 0)
		if mR then mR.Transform = cf end
		if mL then mL.Transform = cf end
	end)
end

local AOE_SKILLS = {
	EmberAura = true, FrostAura = true, ChainLightning = true,
	PetalSlash = true, ThunderPounce = true,
}

local function triggerSwingForSkill(skillId: string)
	local params = SKILL_SWING[skillId]
	if AOE_SKILLS[skillId] then
		playBothArmsSwing(params and params.angle or -1.5, params and params.duration or 0.32)
	elseif params then
		playSwingAnimation(params.angle, params.duration)
	else
		playSwingAnimation(-1.4, 0.28)
	end
end

-- ── 掉落動畫 ──────────────────────────────────────────────────────

-- 金幣掉落：噴出多顆金幣球，向外弧形飛出後停留再淡出
local function playDropCoins(pos: Vector3, amount: number)
	-- 依金幣數量決定噴出顆數（3~8顆）
	local count = math.clamp(math.floor(amount / 5) + 3, 3, 8)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + math.random(-10, 10) / 10
		local dist  = math.random(15, 30) / 10
		local peakH = math.random(18, 30) / 10

		-- 金幣球（黃色）
		local coin = vfxPart(pos,
			Vector3.new(0.35, 0.35, 0.35),
			Color3.fromRGB(255, 210, 30),
			Enum.Material.Neon,
			0, 2.0)
		coin.Shape = Enum.PartType.Cylinder

		-- 峰值位置
		local landPos = pos + Vector3.new(
			math.cos(angle) * dist,
			0,
			math.sin(angle) * dist
		)
		local peakPos = (pos + landPos) / 2 + Vector3.new(0, peakH, 0)

		-- 拋物線：先飛到峰值
		local delay = (i - 1) * 0.04
		task.delay(delay, function()
			TweenService:Create(coin,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = peakPos }):Play()
			-- 再落到地面
			task.delay(0.28, function()
				TweenService:Create(coin,
					TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = landPos }):Play()
				-- 停留後縮小淡出
				task.delay(0.6, function()
					TweenService:Create(coin,
						TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{
							Transparency = 1,
							Size = Vector3.new(0.05, 0.05, 0.05),
							Position = landPos + Vector3.new(0, 0.5, 0),
						}):Play()
				end)
			end)
		end)
	end

	-- 金光爆散（中央閃光）
	task.delay(0.05, function()
		vfxBurst(pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 230, 60), 0.3, 2.5, 0.3)
		vfxRing(pos + Vector3.new(0, 0.3, 0), Color3.fromRGB(255, 200, 30), 0.2, 2, 0.25)
	end)

	-- 金幣音效（輕盈的叮叮聲）
	playOneShotSound("rbxassetid://4614471819", pos, 0.9)
end

-- 碎片掉落：彩色晶體從中心爆散，帶閃亮光暈
local FRAG_CAT_COLORS: { [string]: Color3 } = {
	shadowCat  = Color3.fromRGB(120, 60, 200),
	flameCat   = Color3.fromRGB(255, 90, 20),
	frostCat   = Color3.fromRGB(100, 200, 255),
	thunderCat = Color3.fromRGB(230, 230, 0),
	sakuraCat  = Color3.fromRGB(255, 160, 200),
	orangeCat  = Color3.fromRGB(255, 140, 30),
	calicoCat  = Color3.fromRGB(180, 80, 255),
	tuxedoCat  = Color3.fromRGB(200, 200, 200),
}

local function playDropFragment(pos: Vector3, catId: string)
	local color = FRAG_CAT_COLORS[catId] or Color3.fromRGB(200, 100, 255)
	local landPos = pos + Vector3.new(0, 0.4, 0)

	-- 大光球爆散
	vfxBurst(pos + Vector3.new(0, 1, 0), color, 0.5, 4, 0.5)
	vfxRing(pos + Vector3.new(0, 0.5, 0), color, 0.3, 3, 0.4)

	-- 主晶體（菱形近似：Cylinder 橫放）
	local gem = vfxPart(pos + Vector3.new(0, 1.8, 0),
		Vector3.new(0.5, 0.8, 0.5),
		color,
		Enum.Material.Neon,
		0, 3.0)

	-- 緩緩落下
	TweenService:Create(gem,
		TweenInfo.new(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{ Position = landPos }):Play()

	-- 停留後閃爍並消失
	task.delay(1.5, function()
		TweenService:Create(gem,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1) }):Play()
	end)

	-- 四周小晶片
	for i = 1, 6 do
		local a = i * math.pi / 3 + math.random(-5, 5) / 10
		local r = math.random(8, 18) / 10
		local chip = vfxPart(pos + Vector3.new(0, 1.2, 0),
			Vector3.new(0.18, 0.18, 0.18),
			color, Enum.Material.Neon, 0, 2.0)
		chip.Shape = Enum.PartType.Ball
		local chipDest = pos + Vector3.new(math.cos(a) * r, 0.3, math.sin(a) * r)
		TweenService:Create(chip,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = chipDest, Transparency = 0.2 }):Play()
		task.delay(0.5, function()
			TweenService:Create(chip,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Transparency = 1, Size = Vector3.new(0.02, 0.02, 0.02) }):Play()
		end)
	end

	-- BillboardGui 掉落提示文字
	local anchor = vfxPart(landPos + Vector3.new(0, 1.5, 0),
		Vector3.new(0.1, 0.1, 0.1),
		Color3.new(0,0,0), Enum.Material.SmoothPlastic, 1, 2.5)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 40)
	bb.StudsOffset = Vector3.new(0, 0.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 0.3
	lbl.BackgroundColor3 = Color3.fromRGB(30, 0, 50)
	lbl.Text = "✨ 碎片掉落！"
	lbl.TextColor3 = color
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16
	lbl.TextStrokeTransparency = 0.2
	lbl.Parent = bb
	local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0,6); lc.Parent = lbl

	-- 文字向上飄並淡出
	TweenService:Create(anchor,
		TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = landPos + Vector3.new(0, 3.5, 0) }):Play()
	task.delay(1.4, function()
		TweenService:Create(lbl,
			TweenInfo.new(0.6), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	end)

	-- 碎片音效（神秘晶體聲）
	playOneShotSound("rbxassetid://4612355301", pos, 1.0)
end

-- 處理 NPCDrops 事件
function CombatClient.onNPCDrops(pos: Vector3, coins: number, fragmentCatId: string?)
	playDropCoins(pos, coins)
	if fragmentCatId then
		task.delay(0.15, function()
			playDropFragment(pos, fragmentCatId)
		end)
	end
end

-- ── 武器外觀道具 ──────────────────────────────────────────────────

local function makeProp(char: Model, size: Vector3, color: Color3,
	material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = "WeaponProp"
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.Anchored = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = char
	return p
end

local function weldProp(base: BasePart, prop: Part, cf: CFrame)
	local w = Instance.new("Weld")
	w.Part0 = base
	w.Part1 = prop
	w.C0 = cf
	w.C1 = CFrame.new()
	w.Parent = prop
end

local WEAPON_BUILDERS: { [string]: (hand: BasePart, char: Model, isR6: boolean) -> () } = {
	weaponClaws = function(hand, char, isR6)
		local yBase = isR6 and -0.85 or -0.25
		for i = -1, 1 do
			local claw = makeProp(char, Vector3.new(0.08, 0.48, 0.08),
				Color3.fromRGB(110, 115, 130), Enum.Material.Metal)
			weldProp(hand, claw, CFrame.new(i * 0.14, yBase, -0.2) * CFrame.Angles(0.25, 0, 0))
		end
	end,
	weaponSword = function(hand, char, isR6)
		local yBase = isR6 and -0.8 or -0.2
		local blade = makeProp(char, Vector3.new(0.1, 1.3, 0.06),
			Color3.fromRGB(200, 215, 225), Enum.Material.Metal)
		weldProp(hand, blade, CFrame.new(0, yBase, -0.08))
		local guard = makeProp(char, Vector3.new(0.42, 0.07, 0.1),
			Color3.fromRGB(180, 150, 55), Enum.Material.Metal)
		weldProp(hand, guard, CFrame.new(0, yBase + 0.7, -0.08))
	end,
	weaponShield = function(hand, char, isR6)
		local yBase = isR6 and -0.3 or -0.1
		local shield = makeProp(char, Vector3.new(0.75, 0.85, 0.1),
			Color3.fromRGB(170, 130, 55), Enum.Material.SmoothPlastic)
		weldProp(hand, shield, CFrame.new(0, yBase, -0.3))
		local boss = makeProp(char, Vector3.new(0.2, 0.2, 0.1),
			Color3.fromRGB(220, 200, 100), Enum.Material.Metal, Enum.PartType.Ball)
		weldProp(hand, boss, CFrame.new(0, yBase, -0.37))
	end,
	weaponStaff = function(hand, char, isR6)
		local yBase = isR6 and -1.0 or -0.3
		local shaft = makeProp(char, Vector3.new(0.08, 1.8, 0.08),
			Color3.fromRGB(140, 90, 40), Enum.Material.Wood)
		weldProp(hand, shaft, CFrame.new(0, yBase, 0))
		local orb = makeProp(char, Vector3.new(0.23, 0.23, 0.23),
			Color3.fromRGB(180, 80, 255), Enum.Material.Neon, Enum.PartType.Ball)
		weldProp(hand, orb, CFrame.new(0, yBase + 0.9, 0))
	end,
}

function CombatClient.updateWeaponProp(weaponId: string?)
	local char = localPlayer.Character
	if not char then return end
	for _, obj in ipairs(char:GetDescendants()) do
		if obj.Name == "WeaponProp" then obj:Destroy() end
	end
	if not weaponId then return end
	local builder = WEAPON_BUILDERS[weaponId]
	if not builder then return end
	local handR15 = char:FindFirstChild("RightHand") :: BasePart?
	local armR6   = char:FindFirstChild("Right Arm") :: BasePart?
	local hand = handR15 or armR6
	if not hand then return end
	builder(hand :: BasePart, char, armR6 ~= nil)
end

function CombatClient.playDeathAnimation()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	local pos = root.Position

	-- 紅色爆發光球
	vfxBurst(pos, Color3.fromRGB(220, 30, 30), 1.5, 9, 0.5)
	vfxBurst(pos, Color3.fromRGB(255, 120, 50), 0.8, 5, 0.35)
	vfxRing(pos, Color3.fromRGB(200, 0, 0), 1, 8, 0.45)

	-- 碎裂方塊：隨機飛散的身體碎片
	local FRAGMENT_COLORS = {
		Color3.fromRGB(230, 230, 230),
		Color3.fromRGB(180, 180, 180),
		Color3.fromRGB(255, 200, 180),
		Color3.fromRGB(200, 160, 140),
	}
	for i = 1, 20 do
		local sz = math.random(15, 40) / 100
		local frag = vfxPart(
			pos + Vector3.new(math.random(-8, 8) / 10, math.random(0, 15) / 10, math.random(-8, 8) / 10),
			Vector3.new(sz, sz, sz),
			FRAGMENT_COLORS[math.random(1, #FRAGMENT_COLORS)],
			Enum.Material.SmoothPlastic,
			0,
			1.2
		)
		local targetPos = pos + Vector3.new(
			math.random(-40, 40) / 10,
			math.random(5, 30) / 10,
			math.random(-40, 40) / 10
		)
		TweenService:Create(frag, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos,
			Transparency = 1,
			Size = Vector3.new(sz * 0.2, sz * 0.2, sz * 0.2),
			CFrame = CFrame.new(targetPos) * CFrame.Angles(
				math.random(0, 314) / 100,
				math.random(0, 314) / 100,
				math.random(0, 314) / 100
			),
		}):Play()
	end
end

function CombatClient.init()
	-- 啟動貓咪走路姿勢優化
	task.spawn(setupCatWalkTilt)

	-- 監聽 NPC 掉落（金幣 + 碎片動畫）
	local npcDropsEvent = remoteEvents:WaitForChild("NPCDrops") :: RemoteEvent
	npcDropsEvent.OnClientEvent:Connect(function(
		pos: Vector3, coins: number, fragmentCatId: string?
	)
		CombatClient.onNPCDrops(pos, coins, fragmentCatId)
	end)

	-- 處理攻擊輸入 (支援 PC 滑鼠與 iOS 觸控)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end

		-- 合併滑鼠點擊與手機點擊
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			CombatClient.attemptBasicAttack(input.Position)
			return
		end

		local slotIndex = KEY_BINDINGS[input.KeyCode]
		if slotIndex then
			CombatClient.activateSkill(slotIndex)
		end
	end)
end

return CombatClient
