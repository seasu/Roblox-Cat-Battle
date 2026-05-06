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

local function createMeshPart(name: string, meshId: string, textureId: string): BasePart
	-- 使用 Part + SpecialMesh，因為在執行階段透過腳本建立 MeshPart 並設定 MeshId 有時會失效或不渲染
	local p = Instance.new("Part")
	p.Name = "Cat" .. name
	p.CanCollide = false
	p.CastShadow = true
	p.Anchored = false
	p.Transparency = 0
	p.Size = Vector3.new(1, 1, 1) -- 初始大小，視覺由 Mesh 縮放決定
	
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.FileMesh
	sm.MeshId = meshId
	sm.TextureId = textureId
	sm.Parent = p
	
	return p
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
		-- 優先尋找 Accessory
		local accessory = model:FindFirstChildOfClass("Accessory")
		if accessory then
			accessory.Name = accessoryName
			humanoid:AddAccessory(accessory:Clone())
			print("[CatAppearance] 成功套用配件：", accessoryName, "ID:", assetIdNum)
			model:Destroy()
			return true
		end
		
		-- 如果資產包內沒有 Accessory，嘗試直接找 MeshPart (有些資產可能是 Model 包裹的 Mesh)
		local meshPart = model:FindFirstChildOfClass("MeshPart")
		if meshPart then
			warn("[CatAppearance] 資產 ID " .. assetIdNum .. " 不是 Accessory，嘗試作為 MeshPart 處理")
			-- 此處暫不實作複雜的 MeshPart 手動焊接，因為 Suit 需要 WrapLayer
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
	if visualInfo.baseSuitAssetId and visualInfo.baseSuitAssetId ~= "rbxassetid://0" then
		if applyAccessory(character, visualInfo.baseSuitAssetId, "CatSuit") then
			appliedAnything = true
		end
	end

	-- 3. 套用頭部 (判斷是 Accessory 還是純 Mesh)
	local head = character:FindFirstChild("Head")
	if head and visualInfo.headMeshId ~= "rbxassetid://0" then
		local headSuccess = false
		-- 如果 ID 長度超過 12 位，嘗試作為 Accessory 載入
		local idStr = string.match(visualInfo.headMeshId, "%d+")
		if idStr and #idStr >= 13 then 
			if applyAccessory(character, visualInfo.headMeshId, "CatHood") then
				headSuccess = true
				appliedAnything = true
			end
		end
		
		-- 如果 Accessory 載入失敗或原本就是短 ID，則使用 MeshPart 備案
		if not headSuccess then
			local catHead = createMeshPart("HeadShape", visualInfo.headMeshId, visualInfo.headTextureId)
			catHead.Parent = character
			local w = Instance.new("Weld")
			w.Part0 = head
			w.Part1 = catHead
			w.C0 = CFrame.new(0, -0.1, 0) -- 稍微向下修正位置
			w.Parent = catHead
			
			local face = Instance.new("Decal")
			face.Name = "DynamicFace"
			face.Texture = visualInfo.faces.idle
			face.Parent = catHead
			appliedAnything = true
			print("[CatAppearance] 使用 MeshPart 備案套用頭部")
		end
	end

	-- 4. 套用尾巴 (MeshPart)
	-- 支援 R15 (LowerTorso) 與 R6 (Torso)
	local tailBase = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if tailBase and visualInfo.tailMeshId ~= "rbxassetid://0" then
		local catTail = createMeshPart("Tail", visualInfo.tailMeshId, visualInfo.headTextureId)
		catTail.Parent = character
		local w = Instance.new("Weld")
		w.Part0 = tailBase
		w.Part1 = catTail
		-- 針對 R6/R15 稍微調整位置
		local offset = (tailBase.Name == "Torso") and CFrame.new(0, -0.8, 0.4) or CFrame.new(0, -0.2, 0.4)
		w.C0 = offset * CFrame.Angles(math.rad(-10), 0, 0)
		w.Parent = catTail
		appliedAnything = true
	end

	-- 5. 根據是否成功套用新外觀，決定是否隱藏原始身體
	if appliedAnything then
		setBodyTransparency(character, 1)
	else
		-- 如果什麼都沒套用成功，則確保身體是可見的
		setBodyTransparency(character, 0)
		warn("[CatAppearance] 警告：未能套用任何自訂外觀組件，已恢復原始身體顯示")
	end

	-- 6. 顏色同步
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name ~= "HumanoidRootPart" then
				part.Color = visualInfo.baseColor
			end
		end
	end
end

return CatAppearance
