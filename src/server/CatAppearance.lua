local CatAppearance = {}

-- 各貓咪對應的身體主色與配色
-- whiteCat：白色身體 + 粉紅頭/耳（main=白，accent=粉紅）
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

-- 頭球直徑與半徑
local CAT_HEAD_DIAMETER = 1.7
local CAT_HEAD_RADIUS   = CAT_HEAD_DIAMETER / 2   -- 0.85

-- 頭球相對 Head Part 中心的 Y 偏移：
-- Roblox R6 Head.Size.Y = 1.2，頭部 Part 中心在頸椎上方 0.6 格
-- 球半徑 0.85 → 球底端 = head center - 0.85
-- 要讓球底端貼齊 Torso 頂端，需要把球下移至 head center 以下
-- 實測：偏移 -0.5 可讓 R6/R15 球頭緊貼身體不留縫隙
local CAT_HEAD_Y_OFFSET = -0.5

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
	-- 還原所有配件（頭髮、帽子等）的 Handle
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.Transparency = 0
			end
		end
	end
end

-- ── 主體形狀替換 ───────────────────────────────────────────────────
local function buildCatBodyShape(character, colors)

	local function hideAndWeld(origName, catName, catSize, catColor, localCF)
		local orig = character:FindFirstChild(origName)
		if not orig or not orig:IsA("BasePart") then return end
		orig.Transparency = 1
		local cat = makePart(catName, catSize, catColor)
		cat.CFrame = orig.CFrame * (localCF or CFrame.new())
		cat.Parent = character
		weld(orig, cat)
	end

	-- 隱藏所有配件的 Handle（頭髮、帽子等），否則會穿出貓頭
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.Transparency = 1
			end
		end
	end

	-- ── 頭部：改成球形貓臉 ──────────────────────────────────────
	local head = character:FindFirstChild("Head")
	if head then
		head.Transparency = 1
		-- 刪除 avatar 臉部貼圖
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then d:Destroy() end
		end

		-- 計算球頭應在的位置：
		-- 取 Head 實際中心，再往下移 CAT_HEAD_Y_OFFSET，
		-- 讓球底端貼近 Torso/UpperTorso 頂端，消除脖子縫隙
		local headCF = head.CFrame
		local ballCF = headCF * CFrame.new(0, CAT_HEAD_Y_OFFSET, 0)

		local catHead = makePart("CatHeadShape",
			Vector3.new(CAT_HEAD_DIAMETER, CAT_HEAD_DIAMETER, CAT_HEAD_DIAMETER),
			colors.main, Enum.PartType.Ball)
		catHead.CFrame = ballCF
		catHead.Parent = character
		weld(head, catHead)

		-- 眼睛（相對球頭中心定位，不再用 head.CFrame 疊加偏移）
		local eyeL = makePart("CatFaceEyeL",
			Vector3.new(0.22, 0.22, 0.22), BrickColor.new("Really black"), Enum.PartType.Ball)
		eyeL.CFrame = ballCF * CFrame.new(-0.38, 0.12, -0.80)
		eyeL.Parent = character
		weld(catHead, eyeL)

		local eyeR = makePart("CatFaceEyeR",
			Vector3.new(0.22, 0.22, 0.22), BrickColor.new("Really black"), Enum.PartType.Ball)
		eyeR.CFrame = ballCF * CFrame.new(0.38, 0.12, -0.80)
		eyeR.Parent = character
		weld(catHead, eyeR)

		-- 鼻子（相對球頭中心）
		local nose = makePart("CatFaceNose",
			Vector3.new(0.2, 0.15, 0.15), BrickColor.new("Carnation pink"), Enum.PartType.Ball)
		nose.CFrame = ballCF * CFrame.new(0, -0.14, -0.83)
		nose.Parent = character
		weld(catHead, nose)
	end

	-- ── 軀幹（R6）─────────────────────────────────────────────────
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

-- ── 貓耳（相對球頭本體 CatHeadShape 定位） ─────────────────────────
local function addCatEars(character, colors)
	-- 找到剛才建立的球頭 Part（比 head 更可靠）
	local catHead = character:FindFirstChild("CatHeadShape")
	local head = character:FindFirstChild("Head")
	local anchor = catHead or head
	if not anchor then return end

	local earSize  = Vector3.new(0.28, 0.45, 0.22)
	local earHalfY = earSize.Y / 2
	-- 球頭頂端在球頭中心上方 CAT_HEAD_RADIUS 格
	-- 耳朵中心在頂端再上方 earHalfY - 0.05 格（稍微嵌入頂部，不懸空）
	local earTopY = CAT_HEAD_RADIUS + earHalfY - 0.05
	local tiltL = CFrame.Angles(0, 0, -0.12)
	local tiltR = CFrame.Angles(0, 0,  0.12)

	local earL = makePart("CatEarLeft", earSize, colors.main)
	earL.CFrame = anchor.CFrame * CFrame.new(-0.27, earTopY, -0.04) * tiltL
	earL.Parent = character
	weld(anchor, earL)

	local earLInner = makePart("CatEarLeftInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earLInner.CFrame = anchor.CFrame * CFrame.new(-0.27, earTopY, -0.07) * tiltL
	earLInner.Parent = character
	weld(anchor, earLInner)

	local earR = makePart("CatEarRight", earSize, colors.main)
	earR.CFrame = anchor.CFrame * CFrame.new(0.27, earTopY, -0.04) * tiltR
	earR.Parent = character
	weld(anchor, earR)

	local earRInner = makePart("CatEarRightInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earRInner.CFrame = anchor.CFrame * CFrame.new(0.27, earTopY, -0.07) * tiltR
	earRInner.Parent = character
	weld(anchor, earRInner)
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

	local tip = makePart("CatTailTip", Vector3.new(0.3, 0.3, 0.3), colors.accent, Enum.PartType.Ball)
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
