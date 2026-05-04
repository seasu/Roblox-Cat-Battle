-- CatAppearance.lua  v0.2.0
-- 策略：完全隱藏 Roblox 人形骨架，改用 HumanoidRootPart 為根，
-- 從零建構圓潤 chibi 貓型（球形身體、大頭、短胖四肢、尖耳、捲尾）
-- 所有 Cat* 零件以 Weld (C0/C1) 焊接，確保跟隨角色動畫

local CatAppearance = {}

-- ── 各貓咪配色 ────────────────────────────────────────────────────
local CAT_COLORS = {
	whiteCat  = { body=BrickColor.new("White"),             ear=BrickColor.new("Carnation pink"), eye=BrickColor.new("Bright blue"),        tail=BrickColor.new("White"),           belly=BrickColor.new("White")     },
	shadowCat = { body=BrickColor.new("Dark stone grey"),   ear=BrickColor.new("Royal purple"),   eye=BrickColor.new("Royal purple"),        tail=BrickColor.new("Dark stone grey"), belly=nil                         },
	flameCat  = { body=BrickColor.new("Bright red"),        ear=BrickColor.new("Bright yellow"),  eye=BrickColor.new("Bright orange"),       tail=BrickColor.new("Bright yellow"),   belly=BrickColor.new("Bright yellow") },
	frostCat  = { body=BrickColor.new("Pastel blue"),       ear=BrickColor.new("White"),          eye=BrickColor.new("Cyan"),                tail=BrickColor.new("White"),           belly=BrickColor.new("White")     },
	thunderCat= { body=BrickColor.new("Bright yellow"),     ear=BrickColor.new("Bright orange"),  eye=BrickColor.new("Bright yellow"),       tail=BrickColor.new("Bright orange"),   belly=nil                         },
	sakuraCat = { body=BrickColor.new("Pink"),              ear=BrickColor.new("White"),          eye=BrickColor.new("Bright bluish green"), tail=BrickColor.new("White"),           belly=BrickColor.new("White")     },
	orangeCat = { body=BrickColor.new("Bright orange"),     ear=BrickColor.new("Carnation pink"), eye=BrickColor.new("Bright orange"),       tail=BrickColor.new("Dark orange"),     belly=BrickColor.new("Bright yellow") },
	calicoCat = { body=BrickColor.new("White"),             ear=BrickColor.new("Carnation pink"), eye=BrickColor.new("Bright bluish green"), tail=BrickColor.new("Bright orange"),   belly=BrickColor.new("White")     },
	tuxedoCat = { body=BrickColor.new("Really black"),      ear=BrickColor.new("Carnation pink"), eye=BrickColor.new("Bright green"),        tail=BrickColor.new("Really black"),    belly=BrickColor.new("White")     },
}

-- ── 工具函數 ─────────────────────────────────────────────────────

local function weld(base: BasePart, part: BasePart, c0: CFrame)
	local w    = Instance.new("Weld")
	w.Part0    = base
	w.Part1    = part
	w.C0       = c0
	w.C1       = CFrame.new()
	w.Parent   = part
end

local function ball(name: string, diameter: number, color: BrickColor): Part
	local p         = Instance.new("Part")
	p.Name          = name
	p.Shape         = Enum.PartType.Ball
	p.Size          = Vector3.new(diameter, diameter, diameter)
	p.BrickColor    = color
	p.Material      = Enum.Material.SmoothPlastic
	p.Anchored      = false
	p.CanCollide    = false
	p.CastShadow    = false
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function block(name: string, sz: Vector3, color: BrickColor): Part
	local p         = Instance.new("Part")
	p.Name          = name
	p.Size          = sz
	p.BrickColor    = color
	p.Material      = Enum.Material.SmoothPlastic
	p.Anchored      = false
	p.CanCollide    = false
	p.CastShadow    = false
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- ── 隱藏所有人形零件 ─────────────────────────────────────────────

local HUMAN_PARTS = {
	"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg",
	"UpperTorso","LowerTorso",
	"LeftUpperArm","LeftLowerArm","LeftHand",
	"RightUpperArm","RightLowerArm","RightHand",
	"LeftUpperLeg","LeftLowerLeg","LeftFoot",
	"RightUpperLeg","RightLowerLeg","RightFoot",
}

local function hideAll(character: Model)
	for _, name in ipairs(HUMAN_PARTS) do
		local p = character:FindFirstChild(name)
		if p and p:IsA("BasePart") then p.Transparency = 1 end
	end
	-- 移除 face decal
	local head = character:FindFirstChild("Head")
	if head then
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then d:Destroy() end
		end
	end
	-- 隱藏配件
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local h = obj:FindFirstChild("Handle")
			if h and h:IsA("BasePart") then h.Transparency = 1 end
		end
	end
end

local function showAll(character: Model)
	for _, name in ipairs(HUMAN_PARTS) do
		local p = character:FindFirstChild(name)
		if p and p:IsA("BasePart") then p.Transparency = 0 end
	end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local h = obj:FindFirstChild("Handle")
			if h and h:IsA("BasePart") then h.Transparency = 0 end
		end
	end
end

local function clearCat(character: Model)
	for _, c in ipairs(character:GetChildren()) do
		if c:IsA("BasePart") and string.sub(c.Name, 1, 3) == "Cat" then
			c:Destroy()
		end
	end
end

-- ── 貓咪模型建構 ─────────────────────────────────────────────────
-- 所有零件的焊接基準：
--   R6  → 使用 Torso 作為上半身錨點，Head 作為頭部錨點
--   R15 → 使用 UpperTorso, LowerTorso
-- 優先讓關鍵 Part（Torso/Head）驅動，這樣 Roblox 動畫系統可以帶動它們

local function buildCat(character: Model, colors: typeof(CAT_COLORS.whiteCat))
	local char = character

	-- 偵測骨架類型
	local isR6   = char:FindFirstChild("Torso") ~= nil
	local torso  = (isR6 and char:FindFirstChild("Torso"))
		or char:FindFirstChild("UpperTorso") :: BasePart?
	local head   = char:FindFirstChild("Head") :: BasePart?
	local armR   = (isR6 and char:FindFirstChild("Right Arm"))
		or char:FindFirstChild("RightUpperArm") :: BasePart?
	local armL   = (isR6 and char:FindFirstChild("Left Arm"))
		or char:FindFirstChild("LeftUpperArm") :: BasePart?
	local legR   = (isR6 and char:FindFirstChild("Right Leg"))
		or char:FindFirstChild("RightUpperLeg") :: BasePart?
	local legL   = (isR6 and char:FindFirstChild("Left Leg"))
		or char:FindFirstChild("LeftUpperLeg") :: BasePart?

	if not torso then return end

	-- ── 身體（擬人化站姿：更接近人形比例） ──────────────────────────────
	local catBody = block("CatBody", Vector3.new(1.85, 2.65, 1.45), colors.body)
	catBody.Parent = char
	weld(torso, catBody, CFrame.new(0, 0.24, -0.02) * CFrame.Angles(math.rad(2), 0, 0))

	-- 白色肚腹（前方稍突出）
	if colors.belly then
		local belly = block("CatBelly", Vector3.new(1.20, 1.72, 0.88), colors.belly)
		belly.Parent = char
		-- 擬人肚腹位於胸軀前方中央
		weld(torso, belly, CFrame.new(0, -0.04, -0.38) * CFrame.Angles(math.rad(3), 0, 0))
	end

	-- ── 頭部（大球，焊在 Head Part） ─────────────────────────────
	if head then
		local headD = 2.02  -- 擬人比例：維持可愛但更精緻
		local catHead = ball("CatHeadShape", headD, colors.body)
		catHead.Parent = char
		-- 頭部回到擬人站姿高度，只保留輕微前探
		weld(head, catHead, CFrame.new(0, -0.30, -0.06))

		-- ── 眼睛（三層：眼白 → 虹膜(Neon) → 瞳孔 → 光點）
		local HR = headD / 2  -- 1.2
		for _, side in ipairs({ {-1, "L"}, {1, "R"} }) do
			local sx, sn = side[1], side[2]
			local ex = sx * 0.46
			local ey = 0.15
			local ez = -HR * 0.85

			local ew = ball("CatEyeWhite"..sn, 0.56, BrickColor.new("White"))
			ew.Parent = char
			weld(catHead, ew, CFrame.new(ex, ey, ez + 0.05))

			local ei = ball("CatEyeIris"..sn, 0.44, colors.eye)
			ei.Material = Enum.Material.Neon
			ei.Parent = char
			weld(catHead, ei, CFrame.new(ex, ey, ez))

			local ep = ball("CatEyePupil"..sn, 0.24, BrickColor.new("Really black"))
			ep.Parent = char
			weld(catHead, ep, CFrame.new(ex, ey, ez - 0.05))

			local es = ball("CatEyeShine"..sn, 0.13, BrickColor.new("White"))
			es.Material = Enum.Material.Neon
			es.Parent = char
			weld(catHead, es, CFrame.new(ex + sx * 0.08, ey + 0.12, ez - 0.08))
		end

		-- ── 口鼻突出區（白色橢圓球）
		local muzzle = ball("CatMuzzle", 0.64, BrickColor.new("White"))
		muzzle.Parent = char
		weld(catHead, muzzle, CFrame.new(0, -0.24, -HR * 0.82))

		-- 鼻頭（粉紅小球）
		local nose = ball("CatNose", 0.23, BrickColor.new("Carnation pink"))
		nose.Parent = char
		weld(catHead, nose, CFrame.new(0, -0.08, -HR * 0.98))

		-- 腮紅
		for _, sx in ipairs({ -1, 1 }) do
			local blush = ball("CatBlush"..sx, 0.34, BrickColor.new("Carnation pink"))
			blush.Transparency = 0.40
			blush.Parent = char
			weld(catHead, blush, CFrame.new(sx * 0.62, -0.28, -HR * 0.77))
		end

		-- 嘴巴（W 形，兩段細線）
		for _, sx in ipairs({ -1, 1 }) do
			local mouth = block("CatMouth"..sx, Vector3.new(0.12, 0.05, 0.05), BrickColor.new("Really black"))
			mouth.Parent = char
			weld(catHead, mouth, CFrame.new(sx * 0.08, -0.33, -HR * 0.98) * CFrame.Angles(0, 0, math.rad(20 * sx)))
		end

		-- ── 貓耳（三角形近似：用傾斜的細長塊）
		local earW, earH, earD = 0.50, 0.66, 0.22
		for _, side in ipairs({ {-1, "L", -0.20}, {1, "R", 0.20} }) do
			local sx, sn, tiltZ = side[1], side[2], side[3]
			-- 耳朵外殼
			local ear = block("CatEar"..sn, Vector3.new(earW, earH, earD), colors.body)
			ear.Parent = char
			weld(catHead, ear, CFrame.new(sx * 0.60, HR + earH/2 - 0.10, -0.05)
				* CFrame.Angles(0, 0, tiltZ))
			-- 耳內粉紅
			local earIn = block("CatEarInner"..sn,
				Vector3.new(earW * 0.55, earH * 0.60, earD * 0.5),
				colors.ear)
			earIn.Parent = char
			weld(catHead, earIn, CFrame.new(sx * 0.60, HR + earH/2 - 0.12, -0.07)
				* CFrame.Angles(0, 0, tiltZ))
		end
	end

	-- ── 前肢（擬人手臂：拉長成更接近人形比例）─────────────────────────
	local armD, armH = 0.55, 1.36
	for _, info in ipairs({
		{ armR, "CatFrontLegR" },
		{ armL, "CatFrontLegL" },
	}) do
		local anchor, name = info[1], info[2]
		if anchor then
			local limb = ball(name, armD, colors.body)
			limb.Size  = Vector3.new(armD, armH, armD)
			limb.Shape = Enum.PartType.Block
			limb.Parent = char
			weld(anchor, limb, CFrame.new(0, -0.36, -0.06))

			-- 擬人手掌：小肉球，不貼地
			local paw = ball(name.."Paw", 0.44, colors.body)
			paw.Parent = char
			weld(anchor, paw, CFrame.new(0, -armH/2 - 0.19, -0.02))
		end
	end

	-- ── 後肢（擬人腿：加長，降低「玩偶短腿」感）───────────────────────
	local legD, legH = 0.60, 1.52
	for _, info in ipairs({
		{ legR, "CatBackLegR" },
		{ legL, "CatBackLegL" },
	}) do
		local anchor, name = info[1], info[2]
		if anchor then
			local limb = ball(name, legD, colors.body)
			limb.Size  = Vector3.new(legD, legH, legD)
			limb.Shape = Enum.PartType.Block
			limb.Parent = char
			weld(anchor, limb, CFrame.new(0, -0.32, 0.04))

			local paw = block(name.."Paw", Vector3.new(0.56, 0.24, 0.66), colors.body)
			paw.Parent = char
			weld(anchor, paw, CFrame.new(0, -legH/2 - 0.18, 0.10))
		end
	end

	-- ── 尾巴（焊在 Torso，S 形彎曲三段）
	local tailColor = colors.tail or colors.body
	local t1 = block("CatTail1", Vector3.new(0.30, 0.30, 1.30), tailColor)
	t1.Parent = char
	weld(torso, t1, CFrame.new(0, -0.35, 0.95) * CFrame.Angles(-0.22, 0, 0))

	local t2 = block("CatTail2", Vector3.new(0.26, 1.50, 0.26), tailColor)
	t2.Parent = char
	weld(torso, t2, CFrame.new(0, 0.18, 1.52) * CFrame.Angles(0.45, 0, 0))

	local tailTip = ball("CatTailTip", 0.52, colors.body)
	tailTip.Parent = char
	weld(torso, tailTip, CFrame.new(0, 1.10, 1.35))
end

-- ── 主入口 ─────────────────────────────────────────────────────────

function CatAppearance.apply(player: Player, catId: string)
	local character = player.Character
	if not character then return end
	if not character:FindFirstChildOfClass("Humanoid") then return end

	local colors = CAT_COLORS[catId] or CAT_COLORS.whiteCat

	showAll(character)
	clearCat(character)
	hideAll(character)
	buildCat(character, colors)
end

return CatAppearance
