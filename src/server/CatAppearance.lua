local CatAppearance = {}

-- 各貓咪對應的身體主色與配色（耳朵 / 頭部）
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

-- WeldConstraint 將附件 Part 固定在基礎 Part 上
local function weld(base, attachment)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = attachment
	w.Parent = attachment
end

-- 建立附件 Part（不碰撞、不投影陰影）
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

-- 移除舊有的貓咪附件（切換貓咪或重生時呼叫）
local function clearCatParts(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 3) == "Cat" then
			child:Destroy()
		end
	end
end

-- 替換角色身體顏色（R6 + R15 均處理）
local function applyBodyColors(character, colors)
	local bodyParts = { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
	for _, name in ipairs(bodyParts) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.BrickColor = colors.main
		end
	end
	local r15Parts = {
		"UpperTorso", "LowerTorso",
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot",
	}
	for _, name in ipairs(r15Parts) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.BrickColor = colors.main
		end
	end
	local head = character:FindFirstChild("Head")
	if head then
		head.BrickColor = colors.accent
	end
end

-- 在頭部加上貓耳（含粉紅內耳）
local function addCatEars(character, colors)
	local head = character:FindFirstChild("Head")
	if not head then return end

	local earSize = Vector3.new(0.28, 0.45, 0.22)
	-- 動態計算頭頂位置，避免不同角色頭部大小造成貼歪
	local headHalfY = head.Size.Y / 2
	local earHalfY  = earSize.Y / 2
	-- 耳朵往頭頂中線略微內傾（±0.12 rad）讓它看起來更自然
	local tiltL = CFrame.Angles(0, 0, -0.12)
	local tiltR = CFrame.Angles(0, 0,  0.12)

	-- 左耳
	local earL = makePart("CatEarLeft", earSize, colors.accent)
	earL.CFrame = head.CFrame * CFrame.new(-0.27, headHalfY + earHalfY - 0.04, -0.04) * tiltL
	earL.Parent = character
	weld(head, earL)

	local earLInner = makePart("CatEarLeftInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earLInner.CFrame = head.CFrame * CFrame.new(-0.27, headHalfY + earHalfY - 0.04, -0.07) * tiltL
	earLInner.Parent = character
	weld(head, earLInner)

	-- 右耳
	local earR = makePart("CatEarRight", earSize, colors.accent)
	earR.CFrame = head.CFrame * CFrame.new(0.27, headHalfY + earHalfY - 0.04, -0.04) * tiltR
	earR.Parent = character
	weld(head, earR)

	local earRInner = makePart("CatEarRightInner", Vector3.new(0.16, 0.27, 0.14), BrickColor.new("Carnation pink"))
	earRInner.CFrame = head.CFrame * CFrame.new(0.27, headHalfY + earHalfY - 0.04, -0.07) * tiltR
	earRInner.Parent = character
	weld(head, earRInner)
end

-- 在背後加上翹起的貓尾巴（主段 + 末端白球，球焊接在尾巴上）
local function addCatTail(character, colors)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local tailSize = Vector3.new(0.2, 1.5, 0.2)
	local tail = makePart("CatTailMain", tailSize, colors.main)
	-- 從臀部後方斜向翹起（0.7 rad ≈ 40°，看起來像貓尾巴翹起姿態）
	tail.CFrame = hrp.CFrame * CFrame.new(0, -0.5, 0.65) * CFrame.Angles(0.7, 0, 0)
	tail.Parent = character
	weld(hrp, tail)

	-- 尾尖白球：焊接到尾巴本身，位於尾巴頂端正上方，不會跑位
	local tip = makePart("CatTailTip", Vector3.new(0.3, 0.3, 0.3), BrickColor.new("White"), Enum.PartType.Ball)
	tip.CFrame = tail.CFrame * CFrame.new(0, tailSize.Y / 2 + 0.15, 0)
	tip.Parent = character
	weld(tail, tip)
end

-- 主入口：將指定貓咪的外觀套用到玩家角色
function CatAppearance.apply(player, catId)
	local character = player.Character
	if not character then return end
	if not character:FindFirstChildOfClass("Humanoid") then return end

	local colors = CAT_COLORS[catId] or CAT_COLORS.whiteCat
	clearCatParts(character)
	applyBodyColors(character, colors)
	addCatEars(character, colors)
	addCatTail(character, colors)
end

return CatAppearance
