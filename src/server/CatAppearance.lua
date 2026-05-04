local CatAppearance = {}

local CAT_COLORS = {
	whiteCat  = { main = BrickColor.new("White"),           accent = BrickColor.new("Carnation pink")  },
	shadowCat = { main = BrickColor.new("Dark stone grey"), accent = BrickColor.new("Royal purple")    },
	flameCat  = { main = BrickColor.new("Bright red"),      accent = BrickColor.new("Bright yellow")   },
	frostCat  = { main = BrickColor.new("Pastel blue"),     accent = BrickColor.new("White")            },
	thunderCat= { main = BrickColor.new("Bright yellow"),   accent = BrickColor.new("Cyan")             },
	sakuraCat = { main = BrickColor.new("Pink"),            accent = BrickColor.new("White")            },
	orangeCat = { main = BrickColor.new("Bright orange"),   accent = BrickColor.new("Dark orange")      },
	calicoCat = { main = BrickColor.new("White"),           accent = BrickColor.new("Bright orange")    },
	tuxedoCat = { main = BrickColor.new("Really black"),    accent = BrickColor.new("White")            },
}

local CAT_HEAD_DIAMETER = 1.7
local CAT_HEAD_RADIUS   = CAT_HEAD_DIAMETER / 2  -- 0.85

-- 實測：偏移 -0.5 可讓 R6/R15 球頭緊貼身體不留縫隙
local CAT_HEAD_Y_OFFSET = -0.5

-- 使用 legacy Weld + C0，不依賴建立瞬間的物理狀態，比 WeldConstraint 更穩定
local function weldOffset(base: BasePart, attachment: BasePart, offsetCF: CFrame?)
	local w = Instance.new("Weld")
	w.Part0 = base
	w.Part1 = attachment
	w.C0 = offsetCF or CFrame.new()
	w.C1 = CFrame.new()
	w.Parent = attachment  -- 隨 attachment 被 clearCatParts 一起清除
end

local function makePart(name: string, size: Vector3, color: BrickColor, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = false
	p.CanCollide = false
	p.CastShadow = false
	p.Size = size
	p.BrickColor = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	return p
end

local function clearCatParts(character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 3) == "Cat" then
			child:Destroy()
		end
	end
end

local BODY_PART_NAMES = {
	"Head",
	"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
	"UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function restoreBodyParts(character: Model)
	for _, name in ipairs(BODY_PART_NAMES) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Transparency = 0
		end
	end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.Transparency = 0
			end
		end
	end
end

local function buildCatBodyShape(character: Model, colors: { main: BrickColor, accent: BrickColor })
	local function hideAndWeld(origName: string, catName: string, catSize: Vector3, catColor: BrickColor, localCF: CFrame?)
		local orig = character:FindFirstChild(origName)
		if not orig or not orig:IsA("BasePart") then return end
		orig.Transparency = 1
		local cat = makePart(catName, catSize, catColor)
		cat.Parent = character
		weldOffset(orig :: BasePart, cat, localCF)
	end

	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.Transparency = 1
			end
		end
	end

	-- ── 頭部：球形貓臉，向下偏移填補脖子間隙 ──────────────────────
	local head = character:FindFirstChild("Head") :: BasePart?
	if head then
		head.Transparency = 1
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then d:Destroy() end
		end

		-- catHead 焊到 head，偏移量由 C0 決定
		local catHead = makePart("CatHeadShape",
			Vector3.new(CAT_HEAD_DIAMETER, CAT_HEAD_DIAMETER, CAT_HEAD_DIAMETER),
			colors.main, Enum.PartType.Ball)
		catHead.Parent = character
		weldOffset(head, catHead, CFrame.new(0, CAT_HEAD_Y_OFFSET, 0))

		-- 眼睛、鼻子相對 catHead 中心定位（不再疊加 head 偏移量）
		local eyeL = makePart("CatFaceEyeL",
			Vector3.new(0.22, 0.22, 0.22), BrickColor.new("Really black"), Enum.PartType.Ball)
		eyeL.Parent = character
		weldOffset(catHead, eyeL, CFrame.new(-0.38, 0.12, -0.80))

		local eyeR = makePart("CatFaceEyeR",
			Vector3.new(0.22, 0.22, 0.22), BrickColor.new("Really black"), Enum.PartType.Ball)
		eyeR.Parent = character
		weldOffset(catHead, eyeR, CFrame.new(0.38, 0.12, -0.80))

		local nose = makePart("CatFaceNose",
			Vector3.new(0.2, 0.15, 0.15), BrickColor.new("Carnation pink"), Enum.PartType.Ball)
		nose.Parent = character
		weldOffset(catHead, nose, CFrame.new(0, -0.14, -0.83))
	end

	-- ── 軀幹 ───────────────────────────────────────────────────────
	hideAndWeld("Torso",      "CatTorso",      Vector3.new(2.8, 2.2, 1.8), colors.main)
	hideAndWeld("UpperTorso", "CatUpperTorso", Vector3.new(2.6, 1.5, 1.6), colors.main)
	hideAndWeld("LowerTorso", "CatLowerTorso", Vector3.new(2.4, 1.2, 1.5), colors.main)

	-- ── 手臂 ───────────────────────────────────────────────────────
	hideAndWeld("Left Arm",      "CatArmL",      Vector3.new(0.55, 1.7, 0.55),  colors.main)
	hideAndWeld("Right Arm",     "CatArmR",      Vector3.new(0.55, 1.7, 0.55),  colors.main)
	hideAndWeld("LeftUpperArm",  "CatArmUpperL", Vector3.new(0.5, 0.9, 0.5),    colors.main)
	hideAndWeld("LeftLowerArm",  "CatArmLowerL", Vector3.new(0.45, 0.85, 0.45), colors.main)
	hideAndWeld("LeftHand",      "CatPawL",      Vector3.new(0.55, 0.4, 0.6),   colors.main)
	hideAndWeld("RightUpperArm", "CatArmUpperR", Vector3.new(0.5, 0.9, 0.5),    colors.main)
	hideAndWeld("RightLowerArm", "CatArmLowerR", Vector3.new(0.45, 0.85, 0.45), colors.main)
	hideAndWeld("RightHand",     "CatPawR",      Vector3.new(0.55, 0.4, 0.6),   colors.main)

	-- ── 腿 ────────────────────────────────────────────────────────
	hideAndWeld("Left Leg",      "CatLegL",      Vector3.new(0.65, 1.8, 0.65),  colors.main)
	hideAndWeld("Right Leg",     "CatLegR",      Vector3.new(0.65, 1.8, 0.65),  colors.main)
	hideAndWeld("LeftUpperLeg",  "CatLegUpperL", Vector3.new(0.6, 1.0, 0.6),    colors.main)
	hideAndWeld("LeftLowerLeg",  "CatLegLowerL", Vector3.new(0.55, 0.9, 0.55),  colors.main)
	hideAndWeld("LeftFoot",      "CatFootL",     Vector3.new(0.6, 0.35, 0.8),   colors.main)
	hideAndWeld("RightUpperLeg", "CatLegUpperR", Vector3.new(0.6, 1.0, 0.6),    colors.main)
	hideAndWeld("RightLowerLeg", "CatLegLowerR", Vector3.new(0.55, 0.9, 0.55),  colors.main)
	hideAndWeld("RightFoot",     "CatFootR",     Vector3.new(0.6, 0.35, 0.8),   colors.main)
end

-- 耳朵錨點改為 CatHeadShape（球頭 Part），讓耳朵精確跟著球頭位移
local function addCatEars(character: Model, colors: { main: BrickColor, accent: BrickColor })
	local catHead = character:FindFirstChild("CatHeadShape") :: BasePart?
	if not catHead then return end

	local earSize  = Vector3.new(0.28, 0.45, 0.22)
	local earHalfY = earSize.Y / 2
	-- 耳朵中心：球頭頂端再往上 earHalfY，微調 -0.05 讓底部嵌入球頭
	local earTopY  = CAT_HEAD_RADIUS + earHalfY - 0.05
	local tiltL = CFrame.Angles(0, 0, -0.12)
	local tiltR = CFrame.Angles(0, 0,  0.12)

	local earL = makePart("CatEarLeft", earSize, colors.main)
	earL.Parent = character
	weldOffset(catHead, earL, CFrame.new(-0.27, earTopY, -0.04) * tiltL)

	local earLInner = makePart("CatEarLeftInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earLInner.Parent = character
	weldOffset(catHead, earLInner, CFrame.new(-0.27, earTopY, -0.07) * tiltL)

	local earR = makePart("CatEarRight", earSize, colors.main)
	earR.Parent = character
	weldOffset(catHead, earR, CFrame.new(0.27, earTopY, -0.04) * tiltR)

	local earRInner = makePart("CatEarRightInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earRInner.Parent = character
	weldOffset(catHead, earRInner, CFrame.new(0.27, earTopY, -0.07) * tiltR)
end

local function addCatTail(character: Model, colors: { main: BrickColor, accent: BrickColor })
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local tailSize = Vector3.new(0.2, 1.5, 0.2)
	local tail = makePart("CatTailMain", tailSize, colors.main)
	tail.Parent = character
	weldOffset(hrp, tail, CFrame.new(0, -0.5, 0.65) * CFrame.Angles(0.7, 0, 0))

	local tip = makePart("CatTailTip", Vector3.new(0.3, 0.3, 0.3), colors.accent, Enum.PartType.Ball)
	tip.Parent = character
	weldOffset(tail, tip, CFrame.new(0, tailSize.Y / 2 + 0.15, 0))
end

function CatAppearance.apply(player: Player, catId: string)
	local character = player.Character
	if not character then return end
	if not character:FindFirstChildOfClass("Humanoid") then return end

	local colors = CAT_COLORS[catId] or CAT_COLORS.whiteCat
	restoreBodyParts(character)
	clearCatParts(character)
	buildCatBodyShape(character, colors)
	addCatEars(character, colors)
	addCatTail(character, colors)
end

return CatAppearance
