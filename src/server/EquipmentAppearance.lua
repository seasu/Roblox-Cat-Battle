-- EquipmentAppearance.lua
-- 負責在角色 3D 模型上附加裝備視覺配件（純外觀，不影響數值）
-- 每次裝備變更時呼叫 apply(player, loadout)

local EquipmentAppearance = {}

-- 標記前綴，用於清除舊配件
local PREFIX = "EqVis_"

-- ── 輔助函數 ──────────────────────────────────────────────────────

local function weld(base: BasePart, target: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = target
	w.Parent = target
end

local function makePart(name: string, size: Vector3, color: BrickColor,
	material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = PREFIX .. name
	p.Anchored = false
	p.CanCollide = false
	p.CastShadow = false
	p.Size = size
	p.BrickColor = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	return p
end

-- 清除角色上所有 EqVis_ 前綴的配件
local function clearEquipVisuals(character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, #PREFIX) == PREFIX then
			child:Destroy()
		end
	end
end

-- 取得焊接基準部位（優先用 CatHeadShape/CatTorso，其次 Roblox 原始 Part）
local function getPart(character: Model, catName: string, fallback: string): BasePart?
	local cat = character:FindFirstChild(catName)
	if cat and cat:IsA("BasePart") then return cat :: BasePart end
	local orig = character:FindFirstChild(fallback)
	if orig and orig:IsA("BasePart") then return orig :: BasePart end
	return nil
end

-- ── 各槽位視覺建構函數 ──────────────────────────────────────────────

-- 項圈：掛在頸部（Torso 頂端 / UpperTorso 頂端）
local COLLAR_BUILDERS: { [string]: (character: Model) -> () } = {

	collarBasic = function(character)
		local torso = getPart(character, "CatTorso", "Torso")
			or getPart(character, "CatUpperTorso", "UpperTorso")
		if not torso then return end
		local band = makePart("Collar", Vector3.new(1.4, 0.28, 1.4),
			BrickColor.new("Brown"), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		band.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 - 0.05, 0)
			* CFrame.Angles(0, 0, math.pi / 2)
		band.Parent = character
		weld(torso, band)
	end,

	collarSpike = function(character)
		local torso = getPart(character, "CatTorso", "Torso")
			or getPart(character, "CatUpperTorso", "UpperTorso")
		if not torso then return end
		-- 主帶
		local band = makePart("CollarBand", Vector3.new(1.45, 0.28, 1.45),
			BrickColor.new("Really black"), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		band.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 - 0.05, 0)
			* CFrame.Angles(0, 0, math.pi / 2)
		band.Parent = character
		weld(torso, band)
		-- 前方尖刺（三顆）
		for i = -1, 1 do
			local spike = makePart("CollarSpike" .. i, Vector3.new(0.12, 0.35, 0.12),
				BrickColor.new("Medium stone grey"), Enum.Material.Metal)
			spike.CFrame = torso.CFrame
				* CFrame.new(i * 0.38, torso.Size.Y / 2 + 0.12, -0.65)
			spike.Parent = character
			weld(torso, spike)
		end
	end,

	collarHeal = function(character)
		local torso = getPart(character, "CatTorso", "Torso")
			or getPart(character, "CatUpperTorso", "UpperTorso")
		if not torso then return end
		-- 翠綠療癒項圈
		local band = makePart("CollarHeal", Vector3.new(1.4, 0.32, 1.4),
			BrickColor.new("Bright green"), Enum.Material.Neon, Enum.PartType.Cylinder)
		band.Transparency = 0.25
		band.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 - 0.05, 0)
			* CFrame.Angles(0, 0, math.pi / 2)
		band.Parent = character
		weld(torso, band)
		-- 小愛心寶石
		local gem = makePart("CollarGem", Vector3.new(0.22, 0.22, 0.22),
			BrickColor.new("Lime green"), Enum.Material.Neon, Enum.PartType.Ball)
		gem.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 + 0.02, -0.68)
		gem.Parent = character
		weld(torso, gem)
	end,

	collarSpeed = function(character)
		local torso = getPart(character, "CatTorso", "Torso")
			or getPart(character, "CatUpperTorso", "UpperTorso")
		if not torso then return end
		-- 細白光速項圈
		local band = makePart("CollarSpeed", Vector3.new(1.4, 0.18, 1.4),
			BrickColor.new("White"), Enum.Material.Neon, Enum.PartType.Cylinder)
		band.Transparency = 0.15
		band.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 - 0.02, 0)
			* CFrame.Angles(0, 0, math.pi / 2)
		band.Parent = character
		weld(torso, band)
		-- 兩側小翼（代表速度）
		for side = -1, 1, 2 do
			local wing = makePart("CollarWing" .. side, Vector3.new(0.35, 0.18, 0.08),
				BrickColor.new("White"), Enum.Material.Neon)
			wing.CFrame = torso.CFrame
				* CFrame.new(side * 0.72, torso.Size.Y / 2, 0)
			wing.Parent = character
			weld(torso, wing)
		end
	end,
}

-- 帽子：掛在頭部上方（CatHeadShape 頂端）
local HAT_BUILDERS: { [string]: (character: Model) -> () } = {

	hatWizard = function(character)
		local head = getPart(character, "CatHeadShape", "Head")
		if not head then return end
		-- 帽簷（寬扁圓柱）
		local brim = makePart("HatBrim", Vector3.new(1.6, 0.18, 1.6),
			BrickColor.new("Dark indigo"), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		brim.CFrame = head.CFrame * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.pi / 2)
		brim.Parent = character
		weld(head, brim)
		-- 帽身（細高錐形近似：高圓柱）
		local crown = makePart("HatCrown", Vector3.new(0.9, 1.2, 0.9),
			BrickColor.new("Dark indigo"), Enum.Material.SmoothPlastic)
		crown.CFrame = head.CFrame * CFrame.new(0, 1.55, 0)
		crown.Parent = character
		weld(head, crown)
		-- 帽尖（小球）
		local tip = makePart("HatTip", Vector3.new(0.28, 0.28, 0.28),
			BrickColor.new("Royal purple"), Enum.Material.Neon, Enum.PartType.Ball)
		tip.CFrame = head.CFrame * CFrame.new(0, 2.22, 0)
		tip.Parent = character
		weld(head, tip)
	end,

	hatKnight = function(character)
		local head = getPart(character, "CatHeadShape", "Head")
		if not head then return end
		-- 頭盔主體（覆蓋頭部）
		local helmet = makePart("HatHelmet", Vector3.new(1.85, 1.1, 1.85),
			BrickColor.new("Medium stone grey"), Enum.Material.Metal, Enum.PartType.Ball)
		helmet.Transparency = 0.1
		helmet.CFrame = head.CFrame * CFrame.new(0, 0.15, 0)
		helmet.Parent = character
		weld(head, helmet)
		-- 頭冠裝飾
		local crest = makePart("HatCrest", Vector3.new(0.25, 0.55, 0.9),
			BrickColor.new("Bright red"), Enum.Material.SmoothPlastic)
		crest.CFrame = head.CFrame * CFrame.new(0, 0.85, 0)
		crest.Parent = character
		weld(head, crest)
	end,

	hatBandana = function(character)
		local head = getPart(character, "CatHeadShape", "Head")
		if not head then return end
		-- 頭巾帶（包覆頭部的扁圓柱）
		local wrap = makePart("HatBandana", Vector3.new(1.82, 0.55, 1.82),
			BrickColor.new("Bright red"), Enum.Material.Fabric, Enum.PartType.Cylinder)
		wrap.CFrame = head.CFrame * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.pi / 2)
		wrap.Parent = character
		weld(head, wrap)
		-- 正面結（小方塊）
		local knot = makePart("HatKnot", Vector3.new(0.32, 0.32, 0.18),
			BrickColor.new("Bright red"), Enum.Material.Fabric)
		knot.CFrame = head.CFrame * CFrame.new(0, 0.05, -0.92)
		knot.Parent = character
		weld(head, knot)
	end,

	hatCrown = function(character)
		local head = getPart(character, "CatHeadShape", "Head")
		if not head then return end
		-- 皇冠底環
		local base = makePart("CrownBase", Vector3.new(1.55, 0.3, 1.55),
			BrickColor.new("Bright yellow"), Enum.Material.Metal, Enum.PartType.Cylinder)
		base.CFrame = head.CFrame * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.pi / 2)
		base.Parent = character
		weld(head, base)
		-- 三顆寶石
		local gemColors = { BrickColor.new("Bright red"), BrickColor.new("Bright blue"), BrickColor.new("Bright green") }
		for i, gc in ipairs(gemColors) do
			local angle = (i - 1) * (math.pi * 2 / 3)
			local gem = makePart("CrownGem" .. i, Vector3.new(0.22, 0.32, 0.22),
				gc, Enum.Material.Neon, Enum.PartType.Ball)
			gem.CFrame = head.CFrame * CFrame.new(
				math.sin(angle) * 0.65, 1.08, -math.cos(angle) * 0.65)
			gem.Parent = character
			weld(head, gem)
		end
	end,
}

-- 武器：掛在右手（CatPawR / Right Arm / RightHand）
local WEAPON_BUILDERS: { [string]: (character: Model) -> () } = {

	weaponClaws = function(character)
		local hand = getPart(character, "CatPawR", "Right Arm")
			or getPart(character, "CatPawR", "RightHand")
		if not hand then return end
		-- 三根鐵爪
		for i = -1, 1 do
			local claw = makePart("WeaponClaw" .. i, Vector3.new(0.1, 0.55, 0.1),
				BrickColor.new("Medium stone grey"), Enum.Material.Metal)
			claw.CFrame = hand.CFrame
				* CFrame.new(i * 0.14, -hand.Size.Y / 2 - 0.22, -0.1)
				* CFrame.Angles(-0.35, 0, 0)
			claw.Parent = character
			weld(hand, claw)
		end
	end,

	weaponSword = function(character)
		local hand = getPart(character, "CatPawR", "Right Arm")
			or getPart(character, "CatPawR", "RightHand")
		if not hand then return end
		-- 握柄
		local grip = makePart("WeaponGrip", Vector3.new(0.18, 0.55, 0.18),
			BrickColor.new("Reddish brown"), Enum.Material.Wood)
		grip.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.35, 0)
		grip.Parent = character
		weld(hand, grip)
		-- 護手
		local guard = makePart("WeaponGuard", Vector3.new(0.55, 0.12, 0.18),
			BrickColor.new("Dark stone grey"), Enum.Material.Metal)
		guard.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 0.65, 0)
		guard.Parent = character
		weld(hand, guard)
		-- 刀身
		local blade = makePart("WeaponBlade", Vector3.new(0.1, 0.9, 0.08),
			BrickColor.new("Light stone grey"), Enum.Material.Metal)
		blade.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 1.15, 0)
		blade.Parent = character
		weld(hand, blade)
	end,

	weaponShield = function(character)
		-- 盾牌掛在左手
		local hand = getPart(character, "CatPawL", "Left Arm")
			or getPart(character, "CatPawL", "LeftHand")
		if not hand then return end
		-- 盾面
		local shield = makePart("WeaponShield", Vector3.new(1.1, 1.2, 0.18),
			BrickColor.new("Dark stone grey"), Enum.Material.Metal)
		shield.CFrame = hand.CFrame * CFrame.new(-0.4, -hand.Size.Y / 2 - 0.5, 0)
		shield.Parent = character
		weld(hand, shield)
		-- 盾牌中央圖案（金色球）
		local emblem = makePart("WeaponEmblem", Vector3.new(0.32, 0.32, 0.22),
			BrickColor.new("Bright yellow"), Enum.Material.Neon, Enum.PartType.Ball)
		emblem.CFrame = hand.CFrame * CFrame.new(-0.4, -hand.Size.Y / 2 - 0.5, -0.12)
		emblem.Parent = character
		weld(hand, emblem)
	end,

	weaponStaff = function(character)
		local hand = getPart(character, "CatPawR", "Right Arm")
			or getPart(character, "CatPawR", "RightHand")
		if not hand then return end
		-- 杖身
		local pole = makePart("WeaponPole", Vector3.new(0.14, 1.8, 0.14),
			BrickColor.new("Reddish brown"), Enum.Material.Wood)
		pole.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 1.0, 0)
		pole.Parent = character
		weld(hand, pole)
		-- 頂部魔法球
		local orb = makePart("WeaponOrb", Vector3.new(0.42, 0.42, 0.42),
			BrickColor.new("Royal purple"), Enum.Material.Neon, Enum.PartType.Ball)
		orb.CFrame = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 2.05, 0)
		orb.Parent = character
		weld(hand, orb)
		-- 頂環（光環）
		local ring = makePart("WeaponRing", Vector3.new(0.65, 0.08, 0.65),
			BrickColor.new("Bright violet"), Enum.Material.Neon, Enum.PartType.Cylinder)
		ring.CFrame = (hand.CFrame * CFrame.new(0, -hand.Size.Y / 2 - 2.05, 0))
			* CFrame.Angles(0, 0, math.pi / 2)
		ring.Parent = character
		weld(hand, ring)
	end,
}

-- ── 主入口 ──────────────────────────────────────────────────────────

function EquipmentAppearance.apply(player: Player, loadout: { [string]: string? })
	local character = player.Character
	if not character then return end

	clearEquipVisuals(character)

	-- 等待貓咪 Part 建立完成（CatAppearance 可能剛執行完）
	task.defer(function()
		local char = player.Character
		if not char then return end

		-- 項圈
		local collarId = loadout.collar
		if collarId and COLLAR_BUILDERS[collarId] then
			local ok, err = pcall(COLLAR_BUILDERS[collarId], char)
			if not ok then warn("[EquipmentAppearance] 項圈套用失敗：", err) end
		end

		-- 帽子
		local hatId = loadout.hat
		if hatId and HAT_BUILDERS[hatId] then
			local ok, err = pcall(HAT_BUILDERS[hatId], char)
			if not ok then warn("[EquipmentAppearance] 帽子套用失敗：", err) end
		end

		-- 武器
		local weaponId = loadout.weapon
		if weaponId and WEAPON_BUILDERS[weaponId] then
			local ok, err = pcall(WEAPON_BUILDERS[weaponId], char)
			if not ok then warn("[EquipmentAppearance] 武器套用失敗：", err) end
		end
	end)
end

return EquipmentAppearance
