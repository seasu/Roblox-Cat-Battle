-- CatAppearance.lua
-- 核心外觀管理器：實作 R15 透明素體 + 高模 MeshPart 配件系統

local CatAppearance = {}
local CatVisualData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").CatVisualData)
local InsertService = game:GetService("InsertService")

-- ──────────────────────────────────────────────────────────────────────
-- 輔助工具
-- ──────────────────────────────────────────────────────────────────────

local function clearOldVisuals(character: Model)
	-- 清除舊有的自訂 Part (以 Cat 開頭的)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 3) == "Cat" then
			child:Destroy()
		end
		-- 清除自訂配件 (包含 Hood 與 Suit)
		if child:IsA("Accessory") and (child.Name == "CatHood" or child.Name == "CatSuit") then
			child:Destroy()
		end
	end
end

local function setBodyTransparency(character: Model, transparency: number)
	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") then
			if child.Name ~= "HumanoidRootPart" then
				child.Transparency = transparency
			end
		end
		if child:IsA("Decal") then
			child.Transparency = transparency
		end
	end
end

local function createMeshPart(name: string, meshId: string, textureId: string): MeshPart
	local mp = Instance.new("MeshPart")
	mp.Name = "Cat" .. name
	mp.MeshId = meshId
	mp.TextureID = textureId
	mp.CanCollide = false
	mp.CastShadow = true
	mp.Anchored = false
	return mp
end

local function applyAccessory(character: Model, assetId: string, accessoryName: string)
	if not assetId or assetId == "rbxassetid://0" then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local assetIdNum = tonumber(string.match(assetId, "%d+"))
	if not assetIdNum then return end

	local success, model = pcall(function()
		-- 注意：InsertService 需要資產擁有權或資產為公開
		return InsertService:LoadAsset(assetIdNum)
	end)

	if success and model then
		local accessory = model:FindFirstChildOfClass("Accessory")
		if accessory then
			accessory.Name = accessoryName
			humanoid:AddAccessory(accessory:Clone())
			print("[CatAppearance] 成功套用配件：", accessoryName, "ID:", assetIdNum)
		else
			warn("[CatAppearance] 資產內找不到 Accessory 物件：", assetIdNum)
		end
		model:Destroy()
	else
		warn("[CatAppearance] 配件載入失敗 ID:", assetIdNum, "錯誤:", tostring(model))
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- 核心外觀套用邏輯
-- ──────────────────────────────────────────────────────────────────────

function CatAppearance.apply(player: Player, catId: string)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local visualInfo = CatVisualData.cats[catId] or CatVisualData.cats.whiteCat

	-- 1. 清理與隱藏素體
	clearOldVisuals(character)
	setBodyTransparency(character, 1)

	-- 2. 套用身體連身衣 (Layered Clothing / Accessory)
	if visualInfo.baseSuitAssetId then
		applyAccessory(character, visualInfo.baseSuitAssetId, "CatSuit")
	end

	-- 3. 套用頭部 (判斷是 Accessory 還是純 Mesh)
	local head = character:FindFirstChild("Head")
	if head and visualInfo.headMeshId ~= "rbxassetid://0" then
		-- 如果 ID 長度超過 12 位，通常是較新的 Accessory 資產 (針對白貓 Pro 版)
		local idStr = string.match(visualInfo.headMeshId, "%d+")
		if idStr and #idStr >= 13 then 
			applyAccessory(character, visualInfo.headMeshId, "CatHood")
		else
			-- 如果是短 ID，視為純 MeshPart (舊版或通用版)
			local catHead = createMeshPart("HeadShape", visualInfo.headMeshId, visualInfo.headTextureId)
			catHead.Parent = character
			local w = Instance.new("Weld")
			w.Part0 = head
			w.Part1 = catHead
			w.C0 = CFrame.new(0, 0, 0)
			w.Parent = catHead
			
			local face = Instance.new("Decal")
			face.Name = "DynamicFace"
			face.Texture = visualInfo.faces.idle
			face.Parent = catHead
		end
	end

	-- 4. 套用尾巴 (MeshPart)
	local lowerTorso = character:FindFirstChild("LowerTorso")
	if lowerTorso and visualInfo.tailMeshId ~= "rbxassetid://0" then
		local catTail = createMeshPart("Tail", visualInfo.tailMeshId, visualInfo.headTextureId)
		catTail.Parent = character
		local w = Instance.new("Weld")
		w.Part0 = lowerTorso
		w.Part1 = catTail
		w.C0 = CFrame.new(0, -0.2, 0.4) * CFrame.Angles(math.rad(-10), 0, 0)
		w.Parent = catTail
	end

	-- 5. 顏色同步 (針對粒子與 UI 背景)
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Color = visualInfo.baseColor
		end
	end
end

return CatAppearance
