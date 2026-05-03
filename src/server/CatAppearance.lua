local CatAppearance = {}

-- 各貓咪對應的身體主色與配色
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

local function weld(base, attachment)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = attachment
	w.Parent = attachment
end

local function makePart(name, size, color, shape)
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

-- 移除所有 Cat 前綴的附件
local function clearCatParts(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 3) == "Cat" then
			child:Destroy()
		end
	end
end

-- 所有需要被隱藏/還原的原始身體零件
local BODY_PART_NAMES = {
	"Head",
	"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
	"UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

-- 重新套用前先還原透明度，避免殘留透明
local function restoreBodyParts(character)
	for _, name in ipairs(BODY_PART_NAMES) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Transparency = 0
		end
	end
end

-- ── 主體形狀替換 ───────────────────────────────────────────────────
-- 隱藏原始方形身體，以貓咪比例的 Part 替換
local function buildCatBodyShape(character, colors)

	-- 隱藏 origName，並附加一個 catName 的貓咪形狀 Part
	local function hideAndWeld(origName, catName, catSize, catColor, localCF)
		local orig = character:FindFirstChild(origName)
		if not orig or not orig:IsA("BasePart") then return end
		orig.Transparency = 1
		local cat = makePart(catName, catSize, catColor)
		cat.CFrame = orig.CFrame * (localCF or CFrame.new())
		cat.Parent = character
		weld(orig, cat)
	end

	-- ── 頭部：改成球形貓臉 ──────────────────────────────────────
	local head = character:FindFirstChild("Head")
	if head then
		head.Transparency = 1
		-- 刪除 avatar 臉部貼圖（貓不需要人臉）
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then d:Destroy() end
		end

		-- 圓形貓頭（球）
		local catHead = makePart("CatHeadShape", Vector3.new(1.7, 1.7, 1.7), colors.accent, Enum.PartType.Ball)
		catHead.CFrame = head.CFrame
		catHead.Parent = character
		weld(head, catHead)

		-- 眼睛
		local eyeL = makePart("CatFaceEyeL", Vector3.new(0.22, 0.22, 0.22), BrickColor.new("Really black"), Enum.PartType.Ball)
		eyeL.CFrame = head.CFrame * CFrame.new(-0.38, 0.12, -0.82)
		eyeL.Parent = character
		weld(head, eyeL)

		local eyeR = makePart("CatFaceEyeR", Vector3.new(0.22, 0.22, 0.22), BrickColor.new("Really black"), Enum.PartType.Ball)
		eyeR.CFrame = head.CFrame * CFrame.new(0.38, 0.12, -0.82)
		eyeR.Parent = character
		weld(head, eyeR)

		-- 鼻子（粉紅小球）
		local nose = makePart("CatFaceNose", Vector3.new(0.2, 0.15, 0.15), BrickColor.new("Carnation pink"), Enum.PartType.Ball)
		nose.CFrame = head.CFrame * CFrame.new(0, -0.14, -0.84)
		nose.Parent = character
		weld(head, nose)
	end

	-- ── 軀幹（R6）─────────────────────────────────────────────────
	-- 圓胖貓肚子，比人體軀幹更寬更深
	hideAndWeld("Torso", "CatTorso", Vector3.new(2.8, 2.2, 1.8), colors.main)

	-- ── 軀幹（R15）────────────────────────────────────────────────
	hideAndWeld("UpperTorso", "CatUpperTorso", Vector3.new(2.6, 1.5, 1.6), colors.main)
	hideAndWeld("LowerTorso", "CatLowerTorso", Vector3.new(2.4, 1.2, 1.5), colors.main)

	-- ── 手臂（R6）─────────────────────────────────────────────────
	hideAndWeld("Left Arm",  "CatArmL", Vector3.new(0.55, 1.7, 0.55), colors.main)
	hideAndWeld("Right Arm", "CatArmR", Vector3.new(0.55, 1.7, 0.55), colors.main)

	-- ── 手臂（R15）────────────────────────────────────────────────
	hideAndWeld("LeftUpperArm",  "CatArmUpperL", Vector3.new(0.5, 0.9, 0.5), colors.main)
	hideAndWeld("LeftLowerArm",  "CatArmLowerL", Vector3.new(0.45, 0.85, 0.45), colors.main)
	hideAndWeld("LeftHand",      "CatPawL",      Vector3.new(0.55, 0.4, 0.6), colors.main)
	hideAndWeld("RightUpperArm", "CatArmUpperR", Vector3.new(0.5, 0.9, 0.5), colors.main)
	hideAndWeld("RightLowerArm", "CatArmLowerR", Vector3.new(0.45, 0.85, 0.45), colors.main)
	hideAndWeld("RightHand",     "CatPawR",      Vector3.new(0.55, 0.4, 0.6), colors.main)

	-- ── 腿（R6）───────────────────────────────────────────────────
	hideAndWeld("Left Leg",  "CatLegL", Vector3.new(0.65, 1.8, 0.65), colors.main)
	hideAndWeld("Right Leg", "CatLegR", Vector3.new(0.65, 1.8, 0.65), colors.main)

	-- ── 腿（R15）──────────────────────────────────────────────────
	hideAndWeld("LeftUpperLeg",  "CatLegUpperL", Vector3.new(0.6, 1.0, 0.6),   colors.main)
	hideAndWeld("LeftLowerLeg",  "CatLegLowerL", Vector3.new(0.55, 0.9, 0.55), colors.main)
	hideAndWeld("LeftFoot",      "CatFootL",     Vector3.new(0.6, 0.35, 0.8),  colors.main)
	hideAndWeld("RightUpperLeg", "CatLegUpperR", Vector3.new(0.6, 1.0, 0.6),   colors.main)
	hideAndWeld("RightLowerLeg", "CatLegLowerR", Vector3.new(0.55, 0.9, 0.55), colors.main)
	hideAndWeld("RightFoot",     "CatFootR",     Vector3.new(0.6, 0.35, 0.8),  colors.main)
end

-- ── 貓耳（含粉紅內耳，根據頭部實際高度定位） ──────────────────────
local function addCatEars(character, colors)
	local head = character:FindFirstChild("Head")
	if not head then return end

	local earSize = Vector3.new(0.28, 0.45, 0.22)
	local headHalfY = head.Size.Y / 2
	local earHalfY  = earSize.Y / 2
	local tiltL = CFrame.Angles(0, 0, -0.12)
	local tiltR = CFrame.Angles(0, 0,  0.12)

	local earL = makePart("CatEarLeft", earSize, colors.accent)
	earL.CFrame = head.CFrame * CFrame.new(-0.27, headHalfY + earHalfY - 0.04, -0.04) * tiltL
	earL.Parent = character
	weld(head, earL)

	local earLInner = makePart("CatEarLeftInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earLInner.CFrame = head.CFrame * CFrame.new(-0.27, headHalfY + earHalfY - 0.04, -0.07) * tiltL
	earLInner.Parent = character
	weld(head, earLInner)

	local earR = makePart("CatEarRight", earSize, colors.accent)
	earR.CFrame = head.CFrame * CFrame.new(0.27, headHalfY + earHalfY - 0.04, -0.04) * tiltR
	earR.Parent = character
	weld(head, earR)

	local earRInner = makePart("CatEarRightInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earRInner.CFrame = head.CFrame * CFrame.new(0.27, headHalfY + earHalfY - 0.04, -0.07) * tiltR
	earRInner.Parent = character
	weld(head, earRInner)
end

-- ── 貓尾巴（主段 + 末端白球，球焊接在尾巴上） ─────────────────────
local function addCatTail(character, colors)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local tailSize = Vector3.new(0.2, 1.5, 0.2)
	local tail = makePart("CatTailMain", tailSize, colors.main)
	tail.CFrame = hrp.CFrame * CFrame.new(0, -0.5, 0.65) * CFrame.Angles(0.7, 0, 0)
	tail.Parent = character
	weld(hrp, tail)

	local tip = makePart("CatTailTip", Vector3.new(0.3, 0.3, 0.3), BrickColor.new("White"), Enum.PartType.Ball)
	tip.CFrame = tail.CFrame * CFrame.new(0, tailSize.Y / 2 + 0.15, 0)
	tip.Parent = character
	weld(tail, tip)
end

-- ── 主入口 ─────────────────────────────────────────────────────────
function CatAppearance.apply(player, catId)
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
