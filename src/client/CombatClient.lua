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
-- VFX cooldown：BasicSwipe 最小間隔 0.12 秒，避免連打時粒子堆疊暈開
local lastVfxTime: { [string]: number } = {}
local VFX_COOLDOWN: { [string]: number } = {
	BasicSwipe = 0.12,
}

local function spawnAttackVFX(skillId: string, hitPos: Vector3)
	local now = os.clock()
	local cd = VFX_COOLDOWN[skillId]
	if cd then
		local last = lastVfxTime[skillId] or 0
		if now - last < cd then return end
		lastVfxTime[skillId] = now
	end

	local weaponId = CombatClient.currentWeapon
	local weaponFn = (weaponId and WEAPON_VFX[weaponId]) or defaultWeaponVFX
	weaponFn(hitPos)
	local skillFn = SKILL_VFX[skillId]
	if skillFn then
		skillFn(hitPos)
	end
end

-- 快捷鍵對應（第 2–6 槽）

-- ── 音效系統 ─────────────────────────────────────────────────────
-- 所有音效放在 SoundService（2D，全域播放），避免 3D 定位的載入延遲問題
-- 使用 ContentProvider:PreloadAsync 確保音效下載完成再播放

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")

-- ── 音效系統 ────────────────────────────────────────────────────
-- 使用 Roblox 官方內建 Gear 音效 ID（來自官方裝備系統，永久有效）

local function makeSound(id: string, vol: number): Sound
	local s   = Instance.new("Sound")
	s.SoundId = id
	s.Volume  = vol
	s.Parent  = SoundService
	return s
end

local SFX = {
	-- 揮擊（Sword Slash）：Roblox Gear 內建，ID 62337944
	attack = makeSound("rbxassetid://62337944", 0.8),
	-- 命中（Hit）：Roblox Gear 內建，ID 93016098
	hit    = makeSound("rbxassetid://93016098", 1.0),
	-- 受傷（同命中，音量較低）
	hurt   = makeSound("rbxassetid://93016098", 0.6),
	-- 金幣（Sparkle）：ID 4612355301
	coin   = makeSound("rbxassetid://4612355301", 0.9),
	-- 魔法（同金幣）
	magic  = makeSound("rbxassetid://4612355301", 0.8),
}

-- 預載確保首次使用時無延遲
task.spawn(function()
	pcall(ContentProvider.PreloadAsync, ContentProvider, {
		"rbxassetid://62337944",
		"rbxassetid://93016098",
		"rbxassetid://4612355301",
	})
end)

-- 播放：Stop + Play 確保連打時每次都有聲音
local function playSound(sfx: Sound, _pos: Vector3?)
	sfx:Stop()
	sfx:Play()
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

-- Forward declaration：triggerSwingForSkill 定義在後段，需先宣告避免 nil 呼叫
local triggerSwingForSkill: (skillId: string) -> ()

-- 攻擊整體 cooldown（0.35s），防止連點 VFX 堆疊 / 音效疊加
local lastAttackTime = 0
local ATTACK_CD = 0.35

-- VFX 最近一次播放時間
local lastVfxTime = 0
-- 命中確認音效節流（避免 AoE 多目標瞬間重疊爆音）
local lastConfirmedAttackSoundTime = 0
local CONFIRMED_ATTACK_SOUND_CD = 0.08

function CombatClient.attemptBasicAttack(inputPos: Vector3?)
	local now = os.clock()
	if now - lastAttackTime < ATTACK_CD then return end
	lastAttackTime = now

	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local instanceId, hitPos = getMouseTarget(inputPos)
	local vfxPos = hitPos or (root.Position + root.CFrame.LookVector * 3)

	if instanceId then
		useSkillEvent:FireServer("BasicSwipe", instanceId)
	end

	-- VFX 也受 cooldown 保護，不會堆疊
	if now - lastVfxTime >= ATTACK_CD then
		lastVfxTime = now
		spawnAttackVFX("BasicSwipe", vfxPos)
	end

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
	local now = os.clock()
	if now - lastConfirmedAttackSoundTime >= CONFIRMED_ATTACK_SOUND_CD then
		lastConfirmedAttackSoundTime = now
		-- 只在伺服器確認命中時播放攻擊音效，避免空點畫面一直出聲
		playSound(SFX.attack, position)
	end

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
-- 找出肩部 Motor6D，優先命中肩關節，避免誤抓到髖部導致「手不動」
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
	
	-- 優先級 2：Part1 為 UpperArm / Arm（確保是上臂）
	for _, m in ipairs(candidates) do
		local p1 = m.Part1.Name
		if (string.find(p1, "UpperArm") or p1 == (sidePattern .. " Arm")) then
			return m
		end
	end
	
	return candidates[1]
end

-- 取得前臂關節（R15 常見為 RightElbow / LeftElbow）
local function getElbowMotor(char: Model, side: "Right" | "Left"): Motor6D?
	local sidePattern = (side == "Right") and "Right" or "Left"
	for _, m in ipairs(char:GetDescendants()) do
		if not m:IsA("Motor6D") then continue end
		local mName = m.Name
		local p1Name = m.Part1 and m.Part1.Name or ""
		if (string.find(mName, sidePattern) or string.find(p1Name, sidePattern))
			and (string.find(mName, "Elbow") or string.find(p1Name, "LowerArm")) then
			return m
		end
	end
	return nil
end

-- 揮手動畫狀態（必須在步態系統前宣告，供步態判斷攻擊中讓出前肢控制）
local swingActive = false
local swingConnection: RBXScriptConnection? = nil

-- ── 貓咪走路姿勢優化 (擬人步態) ──────────────────────────────────────
-- 透過旋轉 RootJoint 與四肢擺動，維持擬人化貓咪的站姿移動節奏
local function setupCatWalkTilt()
	local currentConnection: RBXScriptConnection? = nil
	local phase = 0

	local function onCharacter(char: Model)
		if currentConnection then currentConnection:Disconnect() end

		local hum = char:WaitForChild("Humanoid") :: Humanoid
		local rootMotor: Motor6D? = nil
		local armR: Motor6D? = nil
		local armL: Motor6D? = nil
		local legR: Motor6D? = nil
		local legL: Motor6D? = nil

		local function findMotors()
			rootMotor = nil; armR = nil; armL = nil; legR = nil; legL = nil
			for _, m in ipairs(char:GetDescendants()) do
				if not m:IsA("Motor6D") then continue end
				local mn  = m.Name
				local p0n = m.Part0 and m.Part0.Name or ""
				local p1n = m.Part1 and m.Part1.Name or ""
				-- 軀幹根關節
				if p0n == "HumanoidRootPart" then
					rootMotor = m
				end
				-- 右肩（前右腿）
				if not armR and string.find(mn, "Right") and string.find(mn, "Shoulder") then
					armR = m
				elseif not armR and string.find(p1n, "Right") and
					(string.find(p1n, "UpperArm") or p1n == "Right Arm") then
					armR = m
				end
				-- 左肩（前左腿）
				if not armL and string.find(mn, "Left") and string.find(mn, "Shoulder") then
					armL = m
				elseif not armL and string.find(p1n, "Left") and
					(string.find(p1n, "UpperArm") or p1n == "Left Arm") then
					armL = m
				end
				-- 右髖（後右腿）
				if not legR and string.find(mn, "Right") and string.find(mn, "Hip") then
					legR = m
				elseif not legR and string.find(p1n, "Right") and
					(string.find(p1n, "UpperLeg") or p1n == "Right Leg") then
					legR = m
				end
				-- 左髖（後左腿）
				if not legL and string.find(mn, "Left") and string.find(mn, "Hip") then
					legL = m
				elseif not legL and string.find(p1n, "Left") and
					(string.find(p1n, "UpperLeg") or p1n == "Left Leg") then
					legL = m
				end
			end
		end

		findMotors()
		local lastTime = os.clock()
		-- 蹲伏角度目前值（用於平滑過渡）
		local currentTilt = 0

		currentConnection = RunService.RenderStepped:Connect(function()
			if not char.Parent or not hum.Parent then
				if currentConnection then currentConnection:Disconnect() end
				return
			end
			-- 若 motor 消失（換貓/重生）重新尋找
			if not rootMotor or not rootMotor.Parent then
				findMotors()
			end

			local now = os.clock()
			local dt  = math.min(now - lastTime, 0.05)
			lastTime   = now

			local isMoving = hum.MoveDirection.Magnitude > 0.1
			local speed    = Vector3.new(
				char:FindFirstChild("HumanoidRootPart") and
				(char:FindFirstChild("HumanoidRootPart") :: BasePart).AssemblyLinearVelocity.X or 0,
				0,
				char:FindFirstChild("HumanoidRootPart") and
				(char:FindFirstChild("HumanoidRootPart") :: BasePart).AssemblyLinearVelocity.Z or 0
			).Magnitude

			-- 步態頻率：速度越快步頻越高
			if isMoving then
				local freq = 5.5 + speed * 0.18  -- 靜走 ~5.5Hz，全速跑約 7-8Hz
				phase = (phase + dt * freq) % (math.pi * 2)
			else
				-- 靜止時相位緩慢歸零（讓四肢回到蹲伏待機位）
				phase = phase * (1 - math.min(dt * 6, 1))
			end

			-- ── 軀幹姿態（擬人貓）───────────────────────────────────
			-- 回到直立擬人姿勢：移動時微微前傾，待機近直立
			local targetTilt = isMoving and math.rad(6) or math.rad(2)
			-- 快速平滑收斂（Lerp 係數 0.25，約 4 幀到位）
			currentTilt = currentTilt + (targetTilt - currentTilt) * math.min(dt * 18, 1)
			if rootMotor then
				rootMotor.Transform = CFrame.Angles(currentTilt, 0, 0)
			end

			-- ── 四肢對角步態 ──────────────────────────────────────────
			-- 移動時全幅擺動；靜止時平滑歸零（前肢微前傾待機）
			local moveBlend  = math.min(speed / 5, 1)  -- 0(靜)→1(全速)
			local limbLerp   = isMoving and 0.35 or 0.12  -- 移動時快速跟上，靜止慢速歸位

			local sR  = math.sin(phase) * moveBlend         -- 右前相位
			local sL  = math.sin(phase + math.pi) * moveBlend  -- 左前反相

			-- 前肢（手臂）：擬人走路擺手，攻擊時讓出
			if not swingActive then
				if armR then
					local targetR = isMoving and CFrame.Angles(-sR * 0.95, 0, 0)
						or CFrame.Angles(0.06, 0, 0)
					armR.Transform = armR.Transform:Lerp(targetR, limbLerp)
				end
				if armL then
					local targetL = isMoving and CFrame.Angles(-sL * 0.95, 0, 0)
						or CFrame.Angles(0.06, 0, 0)
					armL.Transform = armL.Transform:Lerp(targetL, limbLerp)
				end
			end

			-- 後肢（腿）：直立步態
			if legR then
				local targetLR = isMoving and CFrame.Angles(sL * 0.90, 0, 0)
					or CFrame.Angles(0.04, 0, 0)
				legR.Transform = legR.Transform:Lerp(targetLR, limbLerp)
			end
			if legL then
				local targetLL = isMoving and CFrame.Angles(sR * 0.90, 0, 0)
					or CFrame.Angles(0.04, 0, 0)
				legL.Transform = legL.Transform:Lerp(targetLL, limbLerp)
			end
		end)
	end

	if localPlayer.Character then onCharacter(localPlayer.Character) end
	localPlayer.CharacterAdded:Connect(onCharacter)
end

-- 揮手動畫：連打時強制重置，不累積 RenderStepped 連接
local function playSwingAnimation(swingAngle: number, duration: number)
	local char = localPlayer.Character
	if not char then return end
	local shoulderR = getArmMotor(char, "Right")
	if not shoulderR then return end
	local shoulderL = getArmMotor(char, "Left")
	local elbowR = getElbowMotor(char, "Right")
	local elbowL = getElbowMotor(char, "Left")

	-- 若有舊的揮手動畫還在跑，強制中斷再重新開始
	if swingConnection then
		swingConnection:Disconnect()
		swingConnection = nil
	end

	swingActive = true
	local startTime = os.clock()

	swingConnection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local t = elapsed / duration

		if t >= 1 or not char.Parent or not shoulderR.Parent then
			shoulderR.Transform = CFrame.new()
			if shoulderL then
				shoulderL.Transform = CFrame.new()
			end
			if elbowR then elbowR.Transform = CFrame.new() end
			if elbowL then elbowL.Transform = CFrame.new() end
			if swingConnection then swingConnection:Disconnect(); swingConnection = nil end
			swingActive = false
			return
		end

		-- 劍客式三段動作：
		-- 1) 蓄力收手（前 26%） 2) 爆發突刺斬（26-58%） 3) 俐落收招（58-100%）
		local pitch = 0
		local yaw = 0
		local roll = 0
		local elbowPitch = 0
		if t < 0.26 then
			local p = t / 0.26
			local ease = p * p
			pitch = 0.52 * ease
			yaw = -0.30 * ease
			roll = -0.20 * ease
			elbowPitch = -0.88 * ease
		elseif t < 0.58 then
			local p = (t - 0.26) / 0.32
			local ease = 1 - (1 - p) * (1 - p)
			pitch = 0.52 + (swingAngle - 0.52) * ease
			yaw = -0.30 + 0.52 * ease
			roll = -0.20 + 0.62 * ease
			elbowPitch = -0.88 + 1.38 * ease
		else
			local p = (t - 0.58) / 0.42
			local ease = math.sin(math.clamp(p, 0, 1) * math.pi * 0.5)
			pitch = swingAngle * (1 - ease)
			yaw = 0.22 * (1 - ease)
			roll = 0.40 * (1 - ease)
			elbowPitch = 0.50 * (1 - ease)
		end

		-- 右手主攻擊，左手反向平衡，讓揮擊更容易被看見
		shoulderR.Transform = CFrame.Angles(pitch, yaw, roll)
		if shoulderL then
			shoulderL.Transform = CFrame.Angles(-pitch * 0.24, -yaw * 0.45, -roll * 0.35)
		end
		if elbowR then
			elbowR.Transform = CFrame.Angles(elbowPitch, 0, 0)
		end
		if elbowL then
			elbowL.Transform = CFrame.Angles(-elbowPitch * 0.25, 0, 0)
		end
	end)
end

-- 依技能決定揮動參數
local SKILL_SWING: { [string]: { angle: number, duration: number } } = {
	BasicSwipe      = { angle = -1.25, duration = 0.34 },
	PowerClaw       = { angle = -1.55, duration = 0.38 },
	ShadowStrike    = { angle = -1.70, duration = 0.30 },
	FireClaw        = { angle = -1.38, duration = 0.36 },
	GentlemanStrike = { angle = -1.82, duration = 0.32 },
	FoodRage        = { angle = -1.62, duration = 0.33 },
	PetalSlash      = { angle = -1.30, duration = 0.34 },
	ThunderPounce   = { angle = -1.72, duration = 0.33 },
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

triggerSwingForSkill = function(skillId: string)
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
	playSound(SFX.coin, pos)
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
	playSound(SFX.magic, pos)
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
	if CombatClient._initialized then
		return
	end
	CombatClient._initialized = true

	-- 啟動貓咪走路姿勢優化
	task.spawn(setupCatWalkTilt)

	-- 監聽 NPC 掉落（金幣 + 碎片動畫）
	local npcDropsEvent = remoteEvents:WaitForChild("NPCDrops") :: RemoteEvent
	npcDropsEvent.OnClientEvent:Connect(function(
		pos: Vector3, coins: number, fragmentCatId: string?
	)
		CombatClient.onNPCDrops(pos, coins, fragmentCatId)
	end)

	-- ── NPC 攻擊音效：監聽角色 HP 下降播受傷聲 ─────────────────────
	local lastHurtTime = 0
	local function bindHurtSound(character: Model)
		local hum = character:WaitForChild("Humanoid") :: Humanoid
		local lastHp = hum.Health
		hum.HealthChanged:Connect(function(newHp: number)
			-- 僅在 HP 相對上一幀下降時播音，避免回血期間反覆觸發
			local now = os.clock()
			if newHp < lastHp and now - lastHurtTime > 0.25 then
				lastHurtTime = now
				local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				playSound(SFX.hurt, hrp and hrp.Position)
			end
			lastHp = newHp
		end)
	end

	if localPlayer.Character then
		task.spawn(bindHurtSound, localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(function(char)
		task.spawn(bindHurtSound, char)
	end)

	-- 處理攻擊輸入 (支援 PC 滑鼠與 iOS 觸控)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch then
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
