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

	-- 左耳
	local earL = makePart("CatEarLeft", Vector3.new(0.28, 0.46, 0.22), colors.accent)
	earL.CFrame = head.CFrame * CFrame.new(-0.34, 0.52, -0.08) * CFrame.Angles(0, 0, -0.25)
	earL.Parent = character
	weld(head, earL)

	local earLInner = makePart("CatEarLeftInner", Vector3.new(0.16, 0.28, 0.15), BrickColor.new("Carnation pink"))
	earLInner.CFrame = head.CFrame * CFrame.new(-0.34, 0.51, -0.11) * CFrame.Angles(0, 0, -0.25)
	earLInner.Parent = character
	weld(head, earLInner)

	-- 右耳
	local earR = makePart("CatEarRight", Vector3.new(0.28, 0.46, 0.22), colors.accent)
	earR.CFrame = head.CFrame * CFrame.new(0.34, 0.52, -0.08) * CFrame.Angles(0, 0, 0.25)
	earR.Parent = character
	weld(head, earR)

	local earRInner = makePart("CatEarRightInner", Vector3.new(0.16, 0.28, 0.15), BrickColor.new("Carnation pink"))
	earRInner.CFrame = head.CFrame * CFrame.new(0.34, 0.51, -0.11) * CFrame.Angles(0, 0, 0.25)
	earRInner.Parent = character
	weld(head, earRInner)
end

-- 在背後加上翹起的貓尾巴（兩段，末端白球）
local function addCatTail(character, colors)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- 尾巴主段
	local tail = makePart("CatTailMain", Vector3.new(0.2, 1.4, 0.2), colors.main)
	tail.CFrame = hrp.CFrame * CFrame.new(0, -0.25, 0.72) * CFrame.Angles(0.65, 0, 0)
	tail.Parent = character
	weld(hrp, tail)

	-- 尾巴尖端（白色小球）
	local tip = makePart("CatTailTip", Vector3.new(0.32, 0.32, 0.32), BrickColor.new("White"), Enum.PartType.Ball)
	tip.CFrame = hrp.CFrame * CFrame.new(0, 0.28, 1.2) * CFrame.Angles(0.65, 0, 0)
	tip.Parent = character
	weld(hrp, tip)
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
