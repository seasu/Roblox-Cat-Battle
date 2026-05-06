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
		return InsertService:LoadAsset(assetIdNum)
	end)

	if success and model then
		-- 遞迴尋找 Accessory
		local accessory = model:FindFirstChildOfClass("Accessory") or model:FindFirstChildOfClass("Accessory", true)
		if accessory then
			accessory.Name = accessoryName
			humanoid:AddAccessory(accessory:Clone())
			print("[CatAppearance] 成功套用配件：", accessoryName, "ID:", assetIdNum)
			model:Destroy()
			return true
		end
		
		-- 如果資產包內沒有 Accessory，嘗試找 MeshPart 或 SpecialMesh 並轉換為配件備案
		local meshPart = model:FindFirstChildOfClass("MeshPart", true)
		local specialMesh = model:FindFirstChildOfClass("SpecialMesh", true)
		
		if meshPart or specialMesh then
			warn("[CatAppearance] 資產 ID " .. assetIdNum .. " 不是 Accessory，嘗試建立虛擬配件備案")
			local newAcc = Instance.new("Accessory")
			newAcc.Name = accessoryName
			
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(1, 1, 1)
			handle.Transparency = 0
			handle.CanCollide = false
			handle.Parent = newAcc
			
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			if meshPart then
				mesh.MeshId = meshPart.MeshId
				mesh.TextureId = meshPart.TextureID
			else
				mesh.MeshId = specialMesh.MeshId
				mesh.TextureId = specialMesh.TextureId
				mesh.Scale = specialMesh.Scale
			end
			mesh.Parent = handle
			
			-- 建立預設 Attachment (假設是頭部)
			local att = Instance.new("Attachment")
			att.Name = (accessoryName == "CatHood") and "HatAttachment" or "BodyFrontAttachment"
			att.Parent = handle
			
			humanoid:AddAccessory(newAcc)
			model:Destroy()
			return true
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

	print(string.format("[CatAppearance] 開始套用外觀：玩家=%s, 貓咪=%s", player.Name, catId))

	local visualInfo = CatVisualData.cats[catId] or CatVisualData.cats.whiteCat
	local appliedAnything = false

	-- 1. 清理舊視覺
	clearOldVisuals(character)

	-- 2. 套用身體連身衣 (Layered Clothing / Accessory)
	if visualInfo.baseSuitAssetId and visualInfo.baseSuitAssetId ~= "rbxassetid://0" then
		print("[CatAppearance] 嘗試套用連身衣 ID:", visualInfo.baseSuitAssetId)
		if applyAccessory(character, visualInfo.baseSuitAssetId, "CatSuit") then
			appliedAnything = true
		end
	end

	-- 3. 套用頭部 (判斷是 Accessory 還是純 Mesh)
	local head = character:FindFirstChild("Head")
	if head and visualInfo.headMeshId ~= "rbxassetid://0" then
		local headSuccess = false
		local idStr = string.match(visualInfo.headMeshId, "%d+")
		if idStr and #idStr >= 13 then 
			print("[CatAppearance] 嘗試套用頭部配件 ID:", visualInfo.headMeshId)
			if applyAccessory(character, visualInfo.headMeshId, "CatHood") then
				headSuccess = true
				appliedAnything = true
			end
		end
		
		if not headSuccess then
			print("[CatAppearance] 套用頭部 Mesh 備案 ID:", visualInfo.headMeshId)
			local catHead = createMeshPart("HeadShape", visualInfo.headMeshId, visualInfo.headTextureId)
			catHead.Parent = character
			local w = Instance.new("Weld")
			w.Part0 = head
			w.Part1 = catHead
			w.C0 = CFrame.new(0, -0.1, 0)
			w.Parent = catHead
			
			local face = Instance.new("Decal")
			face.Name = "DynamicFace"
			face.Texture = visualInfo.faces.idle
			face.Parent = catHead
			appliedAnything = true
		end
	end

	-- 4. 套用尾巴 (MeshPart)
	local tailBase = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if tailBase and visualInfo.tailMeshId ~= "rbxassetid://0" then
		print("[CatAppearance] 套用尾巴 ID:", visualInfo.tailMeshId)
		local catTail = createMeshPart("Tail", visualInfo.tailMeshId, visualInfo.headTextureId)
		catTail.Parent = character
		local w = Instance.new("Weld")
		w.Part0 = tailBase
		w.Part1 = catTail
		local offset = (tailBase.Name == "Torso") and CFrame.new(0, -0.8, 0.4) or CFrame.new(0, -0.2, 0.4)
		w.C0 = offset * CFrame.Angles(math.rad(-10), 0, 0)
		w.Parent = catTail
		appliedAnything = true
	end

	-- 5. 根據是否成功套用新外觀，決定是否隱藏原始身體
	if appliedAnything then
		print("[CatAppearance] 成功套用部分自訂外觀，隱藏原始身體 (Debug Alpha=0.7)")
		setBodyTransparency(character, 0.7) -- 改為 0.7 方便除錯
	else
		print("[CatAppearance] 未能套用任何自訂外觀，保持原始身體可見")
		setBodyTransparency(character, 0)
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
