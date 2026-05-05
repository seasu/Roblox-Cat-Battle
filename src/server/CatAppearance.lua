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

local function applyBodyPalette(character: Model, colors: { main: BrickColor, accent: BrickColor })
	for _, name in ipairs(BODY_PART_NAMES) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.BrickColor = colors.main
		end
	end
end

-- 貓耳採配件式附加在預設 Head 上，避免替換整顆頭骨架
local function addCatEars(character: Model, colors: { main: BrickColor, accent: BrickColor })
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local earSize = Vector3.new(0.3, 0.45, 0.25)
	local tiltL = CFrame.Angles(0, 0, -0.2)
	local tiltR = CFrame.Angles(0, 0, 0.2)

	local earL = makePart("CatEarLeft", earSize, colors.main)
	earL.Parent = character
	weldOffset(head, earL, CFrame.new(-0.35, 0.55, -0.05) * tiltL)

	local earR = makePart("CatEarRight", earSize, colors.main)
	earR.Parent = character
	weldOffset(head, earR, CFrame.new(0.35, 0.55, -0.05) * tiltR)
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
	applyBodyPalette(character, colors)
	addCatEars(character, colors)
	addCatTail(character, colors)
end

return CatAppearance
