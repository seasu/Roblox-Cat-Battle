local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatData = require(ReplicatedStorage.Shared.CatData)
local DataStore = require(script.Parent.DataStore)

local CatManager = {}

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateCatEvent = remoteEvents:WaitForChild("UpdateCatAppearance")

local CAT_COLORS: { [string]: Color3 } = {
	whiteCat = Color3.fromRGB(245, 245, 245),
	shadowCat = Color3.fromRGB(55, 55, 70),
	flameCat = Color3.fromRGB(255, 120, 60),
	frostCat = Color3.fromRGB(170, 225, 255),
	thunderCat = Color3.fromRGB(255, 235, 120),
	sakuraCat = Color3.fromRGB(255, 185, 220),
	orangeCat = Color3.fromRGB(255, 170, 80),
	calicoCat = Color3.fromRGB(230, 200, 170),
	tuxedoCat = Color3.fromRGB(40, 40, 40),
}


local function clearCatParts(character: Model)
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("BasePart") and (obj.Name == "CatEar_L" or obj.Name == "CatEar_R" or obj.Name == "CatTail") then
			obj:Destroy()
		end
	end
end

local function attachCatParts(character: Model, color: Color3)
	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end

	local function makePart(name: string, size: Vector3, cf: CFrame): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.Massless = true
		p.CFrame = cf
		p.Parent = character
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = (name == "CatTail") and (hrp :: BasePart) or (head :: BasePart)
		weld.Parent = p
		return p
	end

	makePart("CatEar_L", Vector3.new(0.35, 0.45, 0.25), head.CFrame * CFrame.new(-0.3, 0.5, -0.1))
	makePart("CatEar_R", Vector3.new(0.35, 0.45, 0.25), head.CFrame * CFrame.new(0.3, 0.5, -0.1))
	makePart("CatTail", Vector3.new(0.25, 0.25, 1.4), hrp.CFrame * CFrame.new(0, -0.4, 0.9))
end

local function applyBasicCatVisual(player: Player, catId: string)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local desc = humanoid:GetAppliedDescription()
	local color = CAT_COLORS[catId] or Color3.fromRGB(220, 220, 220)
	desc.HeadColor = color
	desc.LeftArmColor = color
	desc.RightArmColor = color
	desc.LeftLegColor = color
	desc.RightLegColor = color
	desc.TorsoColor = color
	humanoid:ApplyDescription(desc)
	clearCatParts(character)
	attachCatParts(character, color)
end


function CatManager.initPlayer(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	if not CatData.getCatById(data.activeCatId) then
		data.activeCatId = CatData.getDefaultCatId()
	end
	CatManager.pushAppearanceUpdate(player)
	applyBasicCatVisual(player, data.activeCatId)
	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		applyBasicCatVisual(player, data.activeCatId)
	end)
end

function CatManager.pushAppearanceUpdate(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	local tier = CatData.getGrowthTier(data.activeCatId, data.level)
	updateCatEvent:FireClient(player, data.activeCatId, tier.appearance, data.level, tier.description)
end

function CatManager.checkAppearanceUpgrade(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	-- 取得前一等級的分階與現在等級的分階，不同時才更新
	local prevTier = CatData.getGrowthTier(data.activeCatId, data.level - 1)
	local currTier = CatData.getGrowthTier(data.activeCatId, data.level)
	if prevTier.appearance ~= currTier.appearance then
		CatManager.pushAppearanceUpdate(player)
	end
end

function CatManager.handleSelectCat(player: Player, catId: string)
	local data = DataStore.getData(player)
	if not data then return end
	if not data.ownedCats[catId] then
		warn("[CatManager] 玩家", player.Name, "未擁有貓咪：", catId)
		return
	end
	if not CatData.getCatById(catId) then
		warn("[CatManager] 無效的 catId：", catId)
		return
	end
	data.activeCatId = catId
	CatManager.pushAppearanceUpdate(player)
	applyBasicCatVisual(player, catId)

	-- 重新初始化固有技能
	local SkillManager = require(script.Parent.SkillManager)
	SkillManager.initInnateSkills(player)
end

function CatManager.getActiveCat(player: Player)
	local data = DataStore.getData(player)
	if not data then return CatData.getCatById("whiteCat") end
	return CatData.getCatById(data.activeCatId)
end

return CatManager
