-- CatAppearance.lua
-- 核心外觀管理器：實作 R15/R6 透明素體 + 高模 SpecialMesh 配件系統

local CatAppearance = {}
local CatVisualData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").CatVisualData)
local InsertService = game:GetService("InsertService")

-- ──────────────────────────────────────────────────────────────────────
-- 輔助工具
-- ──────────────────────────────────────────────────────────────────────

local BODY_PART_NAMES = {
	"Head", "UpperTorso", "LowerTorso", "Torso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm",
	"RightUpperArm", "RightLowerArm", "RightHand", "Right Arm",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg",
	"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"
}

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
	local partMap = {}
	for _, name in ipairs(BODY_PART_NAMES) do
		partMap[name] = true
	end

	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") then
			-- 只隱藏標準身體部位，且排除所有 Accessory 內部的 Handle
			if partMap[child.Name] and not child:FindFirstAncestorOfClass("Accessory") then
				child.Transparency = transparency
			end
		end
		
		if child:IsA("Decal") and child.Name ~= "DynamicFace" then
			local parent = child.Parent
			if parent and partMap[parent.Name] then
				child.Transparency = transparency
			end
		end
	end
end

local function createVisualPart(name: string, meshId: string, textureId: string): BasePart
	local p = Instance.new("Part")
	p.Name = "Cat" .. name
	p.CanCollide = false
	p.CastShadow = true
	p.Anchored = false
	p.Transparency = 0
	p.Size = Vector3.new(1, 1, 1)
	
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.FileMesh
	sm.MeshId = meshId
	sm.TextureId = textureId
	sm.Parent = p
	
	return p
end

local function applyAccessory(character: Model, assetId: string, accessoryName: string): boolean
	if not assetId or assetId == "rbxassetid://0" or assetId == "" then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local assetIdNum = tonumber(string.match(assetId, "%d+"))
	if not assetIdNum then return false end

	print("[CatAppearance] 嘗試載入資產 ID:", assetIdNum, "型態:", accessoryName)

	local success, model = pcall(function()
		return InsertService:LoadAsset(assetIdNum)
	end)

	if success and model then
		-- 1. 優先尋找資產包內的 Accessory
		local accessory = model:FindFirstChildOfClass("Accessory") or model:FindFirstChildOfClass("Accessory", true)
		if accessory then
			accessory.Name = accessoryName
			humanoid:AddAccessory(accessory:Clone())
			print("[CatAppearance] 成功從資產包套用 Accessory：", accessoryName)
			model:Destroy()
			return true
		end
		
		-- 2. 備案：若資產包內是 MeshPart 或 SpecialMesh，將其配件化
		local foundMesh = model:FindFirstChildOfClass("MeshPart", true) or model:FindFirstChildOfClass("SpecialMesh", true)
		if foundMesh then
			warn("[CatAppearance] 資產 ID " .. assetIdNum .. " 內部無 Accessory，執行自動轉換...")
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
			if foundMesh:IsA("MeshPart") then
				mesh.MeshId = foundMesh.MeshId
				mesh.TextureId = foundMesh.TextureID
			else
				mesh.MeshId = foundMesh.MeshId
				mesh.TextureId = foundMesh.TextureId
				mesh.Scale = foundMesh.Scale
			end
			mesh.Parent = handle
			
			-- 依據名稱設定掛載點
			local att = Instance.new("Attachment")
			att.Name = (accessoryName == "CatHood") and "HatAttachment" or "BodyFrontAttachment"
			att.Parent = handle
			
			humanoid:AddAccessory(newAcc)
			print("[CatAppearance] 成功將資產包內容轉換為配件：", accessoryName)
			model:Destroy()
			return true
		end
		model:Destroy()
	else
		-- 3. 終極備案：如果 LoadAsset 失敗（通常是因為這是原始 Mesh ID 而非 Model ID）
		-- 直接嘗試建立一個使用該 ID 的配件
		warn("[CatAppearance] LoadAsset 失敗，嘗試以原始 Mesh ID 模式建立配件: ", assetId)
		
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
		mesh.MeshId = assetId
		-- 嘗試抓取同配置中的 TextureId (如果是 Hood)
		mesh.Parent = handle
		
		local att = Instance.new("Attachment")
		att.Name = (accessoryName == "CatHood") and "HatAttachment" or "BodyFrontAttachment"
		att.Parent = handle
		
		humanoid:AddAccessory(newAcc)
		print("[CatAppearance] 已透過原始 Mesh ID 強制建立配件：", accessoryName)
		return true
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

	print(string.format("[CatAppearance] === 開始套用外觀：玩家=%s, 貓咪=%s ===", player.Name, catId))

	local visualInfo = CatVisualData.cats[catId] or CatVisualData.cats.whiteCat
	local appliedAnything = false

	-- 1. 清理
	clearOldVisuals(character)

	-- 2. 套用 Suit (連身衣)
	if visualInfo.baseSuitAssetId and visualInfo.baseSuitAssetId ~= "rbxassetid://0" then
		if applyAccessory(character, visualInfo.baseSuitAssetId, "CatSuit") then
			appliedAnything = true
		else
			warn("[CatAppearance] Suit 套用失敗")
		end
	end

	-- 3. 套用 Head / Hood (頭部)
	local head = character:FindFirstChild("Head")
	if head and visualInfo.headMeshId ~= "rbxassetid://0" then
		if applyAccessory(character, visualInfo.headMeshId, "CatHood") then
			appliedAnything = true
		else
			-- 回退到舊有的 Mesh 模式
			print("[CatAppearance] 配件模式失敗，使用 Mesh 模式套用頭部...")
			local catHead = createVisualPart("HeadShape", visualInfo.headMeshId, visualInfo.headTextureId)
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

	-- 4. 套用 Tail (尾巴)
	local tailBase = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if tailBase and visualInfo.tailMeshId ~= "rbxassetid://0" then
		print("[CatAppearance] 套用尾巴視覺...")
		local catTail = createVisualPart("Tail", visualInfo.tailMeshId, visualInfo.headTextureId)
		catTail.Parent = character
		local w = Instance.new("Weld")
		w.Part0 = tailBase
		w.Part1 = catTail
		local offset = (tailBase.Name == "Torso") and CFrame.new(0, -0.8, 0.4) or CFrame.new(0, -0.2, 0.4)
		w.C0 = offset * CFrame.Angles(math.rad(-10), 0, 0)
		w.Parent = catTail
		appliedAnything = true
	end

	-- 5. 透明度設定 (偵錯用 0.7)
	if appliedAnything then
		print("[CatAppearance] 套用成功，隱藏原始身體 (Alpha 0.7)")
		setBodyTransparency(character, 0.7)
	else
		warn("[CatAppearance] 未能套用任何自訂組件，保持原始身體顯示")
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
	
	print("[CatAppearance] === 外觀套用完成 ===")
end

return CatAppearance
