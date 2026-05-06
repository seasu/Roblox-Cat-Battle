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
		-- 只針對原始身體部位進行透明度設定
		-- 排除 HumanoidRootPart、排除我們剛加入的 Cat 字頭部位、排除配件中的 Handle
		if child:IsA("BasePart") then
			local isOriginalBody = true
			if child.Name == "HumanoidRootPart" then
				isOriginalBody = false
			elseif string.sub(child.Name, 1, 3) == "Cat" then
				isOriginalBody = false
			elseif child:FindFirstAncestorOfClass("Accessory") then
				isOriginalBody = false
			end
			
			if isOriginalBody then
				child.Transparency = transparency
			end
		end
		
		if child:IsA("Decal") then
			-- 排除自訂頭部上的表情 Decal
			if child.Name ~= "DynamicFace" then
				child.Transparency = transparency
			end
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

local function applyAccessory(character: Model, assetId: string, accessoryName: string): boolean
	if not assetId or assetId == "rbxassetid://0" then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local assetIdNum = tonumber(string.match(assetId, "%d+"))
	if not assetIdNum then return false end

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
			model:Destroy()
			return true
		else
			warn("[CatAppearance] 資產內找不到 Accessory 物件：", assetIdNum)
		end
		model:Destroy()
	else
		warn("[CatAppearance] 配件載入失敗 ID:", assetIdNum, "錯誤:", tostring(model))
	end
	return false
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
	local appliedAnything = false

	-- 1. 清理舊視覺
	clearOldVisuals(character)

	-- 2. 套用身體連身衣 (Layered Clothing / Accessory)
	if visualInfo.baseSuitAssetId then
		if applyAccessory(character, visualInfo.baseSuitAssetId, "CatSuit") then
			appliedAnything = true
		end
	end

	-- 3. 套用頭部 (判斷是 Accessory 還是純 Mesh)
	local head = character:FindFirstChild("Head")
	if head and visualInfo.headMeshId ~= "rbxassetid://0" then
		-- 如果 ID 長度超過 12 位，通常是較新的 Accessory 資產 (針對白貓 Pro 版)
		local idStr = string.match(visualInfo.headMeshId, "%d+")
		if idStr and #idStr >= 13 then 
			if applyAccessory(character, visualInfo.headMeshId, "CatHood") then
				appliedAnything = true
			end
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
			appliedAnything = true
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
		appliedAnything = true
	end

	-- 5. 根據是否成功套用新外觀，決定是否隱藏原始身體
	if appliedAnything then
		setBodyTransparency(character, 1)
	else
		-- 如果什麼都沒套用成功，則確保身體是可見的（防止變成隱形人）
		setBodyTransparency(character, 0)
	end

	-- 6. 顏色同步 (確保原始部位也有顏色，即使是備案顯示)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			-- 不要染黑 HumanoidRootPart
			if part.Name ~= "HumanoidRootPart" then
				part.Color = visualInfo.baseColor
			end
		end
	end
end

return CatAppearance
