-- CatAppearance.lua
-- Chibi 貓咪外觀系統：大頭、大眼、圓潤身體、可愛比例
-- 參考目標：圓潤 chibi 卡通貓，頭身比約 1:1.2

local CatAppearance = {}

-- ── 各貓咪配色 ────────────────────────────────────────────────────

local CAT_COLORS: { [string]: {
	main: BrickColor, accent: BrickColor,
	eye: BrickColor, belly: BrickColor?,
	hasStripes: boolean?,
} } = {
	whiteCat  = { main = BrickColor.new("White"),           accent = BrickColor.new("Light reddish violet"),
	              eye  = BrickColor.new("Bright blue"),      belly = BrickColor.new("White") },
	shadowCat = { main = BrickColor.new("Dark stone grey"), accent = BrickColor.new("Royal purple"),
	              eye  = BrickColor.new("Royal purple"),     belly = nil },
	flameCat  = { main = BrickColor.new("Bright red"),      accent = BrickColor.new("Bright yellow"),
	              eye  = BrickColor.new("Bright orange"),    belly = BrickColor.new("Bright yellow"),  hasStripes = true },
	frostCat  = { main = BrickColor.new("Pastel blue"),     accent = BrickColor.new("White"),
	              eye  = BrickColor.new("Cyan"),             belly = BrickColor.new("White") },
	thunderCat= { main = BrickColor.new("Bright yellow"),   accent = BrickColor.new("Bright orange"),
	              eye  = BrickColor.new("Bright yellow"),    belly = nil, hasStripes = true },
	sakuraCat = { main = BrickColor.new("Pink"),            accent = BrickColor.new("White"),
	              eye  = BrickColor.new("Bright bluish green"), belly = BrickColor.new("White") },
	orangeCat = { main = BrickColor.new("Bright orange"),   accent = BrickColor.new("Dark orange"),
	              eye  = BrickColor.new("Bright orange"),    belly = BrickColor.new("Bright yellow"), hasStripes = true },
	calicoCat = { main = BrickColor.new("White"),           accent = BrickColor.new("Bright orange"),
	              eye  = BrickColor.new("Bright bluish green"), belly = BrickColor.new("White") },
	tuxedoCat = { main = BrickColor.new("Really black"),    accent = BrickColor.new("White"),
	              eye  = BrickColor.new("Bright green"),     belly = BrickColor.new("White") },
}

-- 頭球大小（chibi 大頭：直徑 2.2）
local HEAD_D    = 2.2
local HEAD_R    = HEAD_D / 2   -- 1.1
-- Head Part 向下偏移，讓球底端貼近軀幹
local HEAD_Y_OFFSET = -0.45

-- ── Weld 工具 ─────────────────────────────────────────────────────

local function weldOffset(base: BasePart, part: BasePart, c0: CFrame?)
	local w = Instance.new("Weld")
	w.Part0 = base
	w.Part1 = part
	w.C0 = c0 or CFrame.new()
	w.C1 = CFrame.new()
	w.Parent = part
end

-- ── Part 建構工具 ─────────────────────────────────────────────────

local function p(
	name: string, sz: Vector3, color: BrickColor,
	mat: Enum.Material?, shape: Enum.PartType?, trans: number?
): Part
	local part = Instance.new("Part")
	part.Name  = name
	part.Anchored   = false
	part.CanCollide = false
	part.CastShadow = false
	part.Size      = sz
	part.BrickColor = color
	part.Material  = mat or Enum.Material.SmoothPlastic
	part.TopSurface    = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency  = trans or 0
	if shape then part.Shape = shape end
	return part
end

-- ── 清除舊貓咪 Part ───────────────────────────────────────────────

local CAT_PREFIX = "Cat"
local function clearCatParts(character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 3) == CAT_PREFIX then
			child:Destroy()
		end
	end
end

-- ── 隱藏原始身體零件 ──────────────────────────────────────────────

local BODY_PARTS = {
	"Head",
	"Torso","Left Arm","Right Arm","Left Leg","Right Leg",
	"UpperTorso","LowerTorso",
	"LeftUpperArm","LeftLowerArm","LeftHand",
	"RightUpperArm","RightLowerArm","RightHand",
	"LeftUpperLeg","LeftLowerLeg","LeftFoot",
	"RightUpperLeg","RightLowerLeg","RightFoot",
}
local function hideBodyParts(character: Model)
	for _, name in ipairs(BODY_PARTS) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then part.Transparency = 1 end
	end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then handle.Transparency = 1 end
		end
	end
end

local function restoreBodyParts(character: Model)
	for _, name in ipairs(BODY_PARTS) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then part.Transparency = 0 end
	end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then handle.Transparency = 0 end
		end
	end
end

-- ── 貓臉（大頭 + 大眼 + 口鼻 + 腮紅） ──────────────────────────────

local function buildCatHead(character: Model, colors: typeof(CAT_COLORS.whiteCat))
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then return end

	head.Transparency = 1
	for _, d in ipairs(head:GetChildren()) do
		if d:IsA("Decal") then d:Destroy() end
	end

	-- 主頭球（大，chibi 比例）
	local catHead = p("CatHeadShape", Vector3.new(HEAD_D, HEAD_D, HEAD_D), colors.main,
		Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	catHead.Parent = character
	weldOffset(head, catHead, CFrame.new(0, HEAD_Y_OFFSET, 0))

	-- ── 耳朵（高尖，焊在 catHead 上） ──────────────────────────────
	-- 右耳
	local earRBase = p("CatEarRight", Vector3.new(0.55, 0.70, 0.28), colors.main)
	earRBase.Parent = character
	weldOffset(catHead, earRBase,
		CFrame.new( 0.52, HEAD_R + 0.28, -0.10) * CFrame.Angles(0, 0, 0.22))
	local earRInner = p("CatEarRightInner", Vector3.new(0.30, 0.42, 0.18), BrickColor.new("Carnation pink"))
	earRInner.Parent = character
	weldOffset(catHead, earRInner,
		CFrame.new( 0.52, HEAD_R + 0.28, -0.12) * CFrame.Angles(0, 0, 0.22))

	-- 左耳
	local earLBase = p("CatEarLeft", Vector3.new(0.55, 0.70, 0.28), colors.main)
	earLBase.Parent = character
	weldOffset(catHead, earLBase,
		CFrame.new(-0.52, HEAD_R + 0.28, -0.10) * CFrame.Angles(0, 0, -0.22))
	local earLInner = p("CatEarLeftInner", Vector3.new(0.30, 0.42, 0.18), BrickColor.new("Carnation pink"))
	earLInner.Parent = character
	weldOffset(catHead, earLInner,
		CFrame.new(-0.52, HEAD_R + 0.28, -0.12) * CFrame.Angles(0, 0, -0.22))

	-- ── 眼睛（大、Neon 色、帶光點） ─────────────────────────────────
	local eyeY =  0.10
	local eyeZ = -HEAD_R * 0.88

	for _, side in ipairs({ -1, 1 }) do
		local eyeX = side * 0.42
		-- 眼白（大圓，微亮）
		local eyeWhite = p("CatEyeWhite_" .. side,
			Vector3.new(0.44, 0.44, 0.16), BrickColor.new("White"),
			Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		eyeWhite.Parent = character
		weldOffset(catHead, eyeWhite, CFrame.new(eyeX, eyeY, eyeZ + 0.04))

		-- 虹膜（有色，Neon 發光）
		local iris = p("CatEyeIris_" .. side,
			Vector3.new(0.34, 0.36, 0.18), colors.eye,
			Enum.Material.Neon, Enum.PartType.Ball)
		iris.Parent = character
		weldOffset(catHead, iris, CFrame.new(eyeX, eyeY, eyeZ))

		-- 瞳孔（黑色）
		local pupil = p("CatEyePupil_" .. side,
			Vector3.new(0.18, 0.22, 0.16), BrickColor.new("Really black"),
			Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		pupil.Parent = character
		weldOffset(catHead, pupil, CFrame.new(eyeX, eyeY, eyeZ - 0.04))

		-- 眼睛光點（白色小球，讓眼睛有神）
		local shine = p("CatEyeShine_" .. side,
			Vector3.new(0.10, 0.10, 0.10), BrickColor.new("White"),
			Enum.Material.Neon, Enum.PartType.Ball)
		shine.Parent = character
		weldOffset(catHead, shine, CFrame.new(eyeX + 0.08, eyeY + 0.09, eyeZ - 0.06))
	end

	-- ── 口鼻（突出的小圓嘴鼻區域） ──────────────────────────────────
	local muzzle = p("CatMuzzle",
		Vector3.new(0.50, 0.38, 0.22), BrickColor.new("White"),
		Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	muzzle.Parent = character
	weldOffset(catHead, muzzle, CFrame.new(0, -0.20, -HEAD_R * 0.82))

	-- 鼻子（小橢圓，粉紅）
	local nose = p("CatNose",
		Vector3.new(0.18, 0.13, 0.14), BrickColor.new("Carnation pink"),
		Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	nose.Parent = character
	weldOffset(catHead, nose, CFrame.new(0, -0.12, -HEAD_R * 0.95))

	-- ── 腮紅（兩頰橢圓，半透明粉紅） ─────────────────────────────
	for _, side in ipairs({ -1, 1 }) do
		local blush = p("CatBlush_" .. side,
			Vector3.new(0.38, 0.22, 0.08), BrickColor.new("Carnation pink"),
			Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.35)
		blush.Parent = character
		weldOffset(catHead, blush, CFrame.new(side * 0.62, -0.24, -HEAD_R * 0.78))
	end
end

-- ── 圓潤身體 ─────────────────────────────────────────────────────

local function buildCatBody(character: Model, colors: typeof(CAT_COLORS.whiteCat))
	local torso   = character:FindFirstChild("Torso")   :: BasePart?
	local utorso  = character:FindFirstChild("UpperTorso") :: BasePart?
	local ltorso  = character:FindFirstChild("LowerTorso") :: BasePart?

	if torso then
		-- R6：單一軀幹 + 白肚（覆蓋在前面）
		torso.Transparency = 1
		local body = p("CatTorso", Vector3.new(2.6, 2.0, 1.9), colors.main)
		body.Parent = character
		weldOffset(torso, body)

		-- 白色肚腹（前面稍微突出）
		if colors.belly then
			local belly = p("CatBelly", Vector3.new(1.4, 1.5, 0.30), colors.belly,
				Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0)
			belly.Parent = character
			weldOffset(torso, belly, CFrame.new(0, -0.10, -1.0))
		end
	end

	if utorso then
		utorso.Transparency = 1
		local ubody = p("CatUpperTorso", Vector3.new(2.5, 1.4, 1.8), colors.main)
		ubody.Parent = character
		weldOffset(utorso, ubody)
		if colors.belly then
			local ubelly = p("CatUpperBelly", Vector3.new(1.3, 1.1, 0.28), colors.belly,
				Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0)
			ubelly.Parent = character
			weldOffset(utorso, ubelly, CFrame.new(0, -0.10, -0.95))
		end
	end
	if ltorso then
		ltorso.Transparency = 1
		local lbody = p("CatLowerTorso", Vector3.new(2.2, 1.1, 1.6), colors.main)
		lbody.Parent = character
		weldOffset(ltorso, lbody)
	end
end

-- ── 四肢（短胖，末端有圓爪） ──────────────────────────────────────

local function buildCatLimbs(character: Model, colors: typeof(CAT_COLORS.whiteCat))
	local function hideAndWeld(origName: string, catName: string, sz: Vector3, cf: CFrame?)
		local orig = character:FindFirstChild(origName) :: BasePart?
		if not orig then return end
		orig.Transparency = 1
		local part = p(catName, sz, colors.main)
		part.Parent = character
		weldOffset(orig, part, cf)
	end

	local function addPaw(anchor: BasePart?, pawName: string, offsetCF: CFrame)
		if not anchor then return end
		local paw = p(pawName, Vector3.new(0.65, 0.42, 0.72), colors.main,
			Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		paw.Parent = character
		weldOffset(anchor, paw, offsetCF)
	end

	-- R6 ──────────────────────────────────────────────────────────
	-- 手臂：短胖（比原來短 20%）
	hideAndWeld("Left Arm",  "CatArmL", Vector3.new(0.70, 1.30, 0.70))
	hideAndWeld("Right Arm", "CatArmR", Vector3.new(0.70, 1.30, 0.70))
	-- 腿：短
	hideAndWeld("Left Leg",  "CatLegL", Vector3.new(0.75, 1.40, 0.75))
	hideAndWeld("Right Leg", "CatLegR", Vector3.new(0.75, 1.40, 0.75))

	-- 爪子（R6：焊在手臂/腿 Part 下端）
	local armL = character:FindFirstChild("CatArmL") :: BasePart?
	local armR = character:FindFirstChild("CatArmR") :: BasePart?
	local legL = character:FindFirstChild("CatLegL") :: BasePart?
	local legR = character:FindFirstChild("CatLegR") :: BasePart?
	if armL then addPaw(armL, "CatPawFrontL", CFrame.new(0, -0.65 - 0.21, 0)) end
	if armR then addPaw(armR, "CatPawFrontR", CFrame.new(0, -0.65 - 0.21, 0)) end
	if legL then addPaw(legL, "CatPawBackL",  CFrame.new(0, -0.70 - 0.21, 0)) end
	if legR then addPaw(legR, "CatPawBackR",  CFrame.new(0, -0.70 - 0.21, 0)) end

	-- R15 ─────────────────────────────────────────────────────────
	hideAndWeld("LeftUpperArm",  "CatArmUpperL", Vector3.new(0.60, 0.80, 0.60))
	hideAndWeld("LeftLowerArm",  "CatArmLowerL", Vector3.new(0.55, 0.72, 0.55))
	hideAndWeld("LeftHand",      "CatPawL",      Vector3.new(0.62, 0.40, 0.68), nil)
	hideAndWeld("RightUpperArm", "CatArmUpperR", Vector3.new(0.60, 0.80, 0.60))
	hideAndWeld("RightLowerArm", "CatArmLowerR", Vector3.new(0.55, 0.72, 0.55))
	hideAndWeld("RightHand",     "CatPawR",      Vector3.new(0.62, 0.40, 0.68), nil)
	hideAndWeld("LeftUpperLeg",  "CatLegUpperL", Vector3.new(0.68, 0.88, 0.68))
	hideAndWeld("LeftLowerLeg",  "CatLegLowerL", Vector3.new(0.62, 0.80, 0.62))
	hideAndWeld("LeftFoot",      "CatFootL",     Vector3.new(0.64, 0.34, 0.80))
	hideAndWeld("RightUpperLeg", "CatLegUpperR", Vector3.new(0.68, 0.88, 0.68))
	hideAndWeld("RightLowerLeg", "CatLegLowerR", Vector3.new(0.62, 0.80, 0.62))
	hideAndWeld("RightFoot",     "CatFootR",     Vector3.new(0.64, 0.34, 0.80))
end

-- ── 條紋花紋（橘貓、雷霆貓、烈焰貓） ────────────────────────────────

local function addStripes(character: Model, colors: typeof(CAT_COLORS.whiteCat))
	local torso = character:FindFirstChild("CatTorso")
		or character:FindFirstChild("CatUpperTorso") :: BasePart?
	if not torso then return end

	local stripeColor = colors.accent
	-- 三條橫紋（背部/側面，貓咪條紋感）
	for i = -1, 1 do
		local stripe = p("CatStripe_" .. i,
			Vector3.new(2.8, 0.18, 0.22), stripeColor,
			Enum.Material.SmoothPlastic, nil, 0.1)
		stripe.Parent = character
		weldOffset(torso, stripe, CFrame.new(0, i * 0.55, -0.88))
	end
end

-- ── 尾巴（S 形往上翹，末端大毛球） ──────────────────────────────────

local function buildCatTail(character: Model, colors: typeof(CAT_COLORS.whiteCat))
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- 尾根（從臀部向後斜上）
	local base = p("CatTailBase", Vector3.new(0.32, 0.32, 1.20), colors.main)
	base.Parent = character
	weldOffset(hrp, base, CFrame.new(0, -0.30, 0.90) * CFrame.Angles(-0.55, 0, 0))

	-- 尾中段（向上彎）
	local mid = p("CatTailMid", Vector3.new(0.26, 1.60, 0.26), colors.main)
	mid.Parent = character
	weldOffset(hrp, mid, CFrame.new(0, 0.60, 1.20) * CFrame.Angles(0.30, 0, 0))

	-- 尾尖大毛球（accent 色）
	local tip = p("CatTailTip", Vector3.new(0.58, 0.58, 0.58), colors.accent,
		Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	tip.Parent = character
	weldOffset(hrp, tip, CFrame.new(0, 1.60, 0.90))
end

-- ── 主入口 ─────────────────────────────────────────────────────────

function CatAppearance.apply(player: Player, catId: string)
	local character = player.Character
	if not character then return end
	if not character:FindFirstChildOfClass("Humanoid") then return end

	local colors = CAT_COLORS[catId] or CAT_COLORS.whiteCat

	restoreBodyParts(character)
	clearCatParts(character)
	hideBodyParts(character)

	buildCatHead(character, colors)
	buildCatBody(character, colors)
	buildCatLimbs(character, colors)
	buildCatTail(character, colors)

	if colors.hasStripes then
		addStripes(character, colors)
	end
end

return CatAppearance
