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
	end
	
	-- 清除自訂配件 (包含 Hood 與 Suit)
	-- 同時清除原本角色自帶的頭髮與帽子等 Accessory，實現「全身只露人臉」的效果
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			local isCustom = string.match(child.Name, "^Cat") or string.match(child.Name, "^EqVis_")
			if not isCustom then
				child:Destroy() -- 直接清除頭髮、原本的帽子等，防止穿模
			elseif child.Name == "CatHood" or child.Name == "CatSuit" then
				child:Destroy()
			end
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
			-- 只隱藏標準身體部位，且排除所有 Accessory 內部的 Handle，且 Head 保持完全不透明 (保留臉部)
			if partMap[child.Name] and not child:FindFirstAncestorOfClass("Accessory") then
				if child.Name == "Head" then
					child.Transparency = 0 -- 臉部保持正常不透明！
				else
					child.Transparency = transparency
				end
			end
		end
		
		-- 臉部 Decal 絕對不設為透明
		if child:IsA("Decal") and child.Name ~= "DynamicFace" and child.Parent and child.Parent.Name ~= "Head" then
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

-- ──────────────────────────────────────────────────────────────────────
-- 程序化可愛 3D 貓咪建模系統 (100% 顯示回退機制)
-- ──────────────────────────────────────────────────────────────────────

-- 輔助工具：建立 Weld 連接
local function weldParts(part0: BasePart, part1: BasePart, c0: CFrame): Weld
	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.Parent = part1
	return w
end

-- 1. 建立貼合全身 R15 關節的貓連身套裝 (Suit)
local function createProceduralSuit(character: Model, baseColor: Color3)
	local SUIT_PARTS = {
		"UpperTorso", "LowerTorso",
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot"
	}
	
	for _, partName in ipairs(SUIT_PARTS) do
		local origPart = character:FindFirstChild(partName)
		if origPart and origPart:IsA("BasePart") then
			local suitPart = Instance.new("Part")
			suitPart.Name = "CatSuitPart_" .. partName
			-- 稍微膨脹 0.04 格，完全包裹原始關節肢體，形成全身衣服
			suitPart.Size = origPart.Size + Vector3.new(0.04, 0.04, 0.04)
			suitPart.Color = baseColor
			suitPart.Material = Enum.Material.SmoothPlastic
			suitPart.CanCollide = false
			suitPart.Massless = true
			suitPart.Parent = character
			
			weldParts(origPart, suitPart, CFrame.new(0, 0, 0))
		end
	end
end

-- 2. 建立立體粉嫩雙色貓耳
local function createProceduralEars(hood: BasePart, baseColor: Color3, character: Model)
	local function createEar(name: string, isLeft: boolean)
		-- 外耳
		local outer = Instance.new("WedgePart")
		outer.Name = "CatOuterEar" .. name
		outer.Size = Vector3.new(0.35, 0.45, 0.25)
		outer.Color = baseColor
		outer.CanCollide = false
		outer.CastShadow = true
		outer.Material = Enum.Material.SmoothPlastic
		outer.Parent = character

		-- 內耳 (粉紅色，貼在外耳前斜面)
		local inner = Instance.new("WedgePart")
		inner.Name = "CatInnerEar" .. name
		inner.Size = Vector3.new(0.22, 0.32, 0.05)
		inner.Color = Color3.fromRGB(255, 192, 203) -- 可愛粉紅
		inner.CanCollide = false
		inner.CastShadow = false
		inner.Material = Enum.Material.SmoothPlastic
		inner.Parent = character

		weldParts(outer, inner, CFrame.new(0, 0.02, -0.11))

		-- 外耳相對於兜帽的對齊偏移與偏轉角 (因兜帽變大而向外/上調整)
		local yaw = isLeft and math.rad(15) or math.rad(-15)
		local roll = isLeft and math.rad(12) or math.rad(-12)
		local posX = isLeft and -0.38 or 0.38
		
		local offset = CFrame.new(posX, 0.52, -0.05) 
			* CFrame.Angles(math.rad(10), yaw, roll)
			* CFrame.Angles(0, math.rad(180), 0) -- 旋轉朝前
		
		weldParts(hood, outer, offset)
	end

	createEar("Left", true)
	createEar("Right", false)
end

-- 3. 建立立體口鼻與害羞 Neon 霓虹腮紅
local function createProceduralFace(head: BasePart, baseColor: Color3, character: Model)
	-- 腮紅 (Cheeks)
	local function createBlush(name: string, isLeft: boolean)
		local blush = Instance.new("Part")
		blush.Name = "CatBlush" .. name
		blush.Shape = Enum.PartType.Ball
		blush.Size = Vector3.new(0.22, 0.12, 0.05)
		blush.Color = Color3.fromRGB(255, 105, 180) -- 亮桃紅
		blush.Material = Enum.Material.Neon
		blush.Transparency = 0.45 -- 營造輕微光暈
		blush.CanCollide = false
		blush.CastShadow = false
		blush.Parent = character

		local posX = isLeft and -0.34 or 0.34
		local rotY = isLeft and math.rad(-15) or math.rad(15)
		local offset = CFrame.new(posX, -0.1, -0.46) * CFrame.Angles(0, rotY, 0)
		weldParts(head, blush, offset)
	end
	createBlush("Left", true)
	createBlush("Right", false)

	-- 貓嘴包 (Snout - W 形嘟嘟嘴)
	local snoutColor = baseColor:Lerp(Color3.new(1,1,1), 0.75) -- 比身體顏色淡的柔和色
	local function createMuzzle(name: string, posX: number)
		local muz = Instance.new("Part")
		muz.Name = "CatMuzzle" .. name
		muz.Shape = Enum.PartType.Ball
		muz.Size = Vector3.new(0.18, 0.14, 0.08)
		muz.Color = snoutColor
		muz.Material = Enum.Material.SmoothPlastic
		muz.CanCollide = false
		muz.Parent = character
		weldParts(head, muz, CFrame.new(posX, -0.16, -0.48))
	end
	createMuzzle("Left", -0.07)
	createMuzzle("Right", 0.07)

	-- 貓咪小粉鼻
	local nose = Instance.new("Part")
	nose.Name = "CatNose"
	nose.Shape = Enum.PartType.Ball
	nose.Size = Vector3.new(0.08, 0.06, 0.06)
	nose.Color = Color3.fromRGB(255, 80, 110) -- 可愛深粉紅
	nose.Material = Enum.Material.SmoothPlastic
	nose.CanCollide = false
	nose.Parent = character
	weldParts(head, nose, CFrame.new(0, -0.09, -0.51))
end

-- 4. 建立貓兜帽頭套 (Hood)，包覆後腦勺與兩側，向後偏移露出前方臉部
local function createProceduralHood(head: BasePart, baseColor: Color3, character: Model)
	local hood = Instance.new("Part")
	hood.Name = "CatSuitHood"
	hood.Shape = Enum.PartType.Ball
	-- 尺寸從 1.32 放大至 1.48，以完全包覆頭部防止禿頭
	hood.Size = Vector3.new(1.48, 1.48, 1.48)
	hood.Color = baseColor
	hood.Material = Enum.Material.SmoothPlastic
	hood.CanCollide = false
	hood.Parent = character
	
	-- 向上偏移 0.08，向後偏移減小到 0.05，使兜帽邊緣往前延伸包住前額
	weldParts(head, hood, CFrame.new(0, 0.08, 0.05))
	
	-- 在兜帽頭套上長出貓耳，並在頭部本體長出口鼻與腮紅
	createProceduralEars(hood, baseColor, character)
	createProceduralFace(head, baseColor, character)
end

-- 5. 建立環繞脖子的蓬鬆毛茸茸領環
local function createProceduralCollar(upperTorso: BasePart, character: Model)
	local collarColor = Color3.fromRGB(255, 255, 255) -- 白色蓬鬆毛領
	local numPuffs = 8
	local radius = 0.52
	
	for i = 1, numPuffs do
		local angle = (i / numPuffs) * math.pi * 2
		local posX = math.cos(angle) * radius
		local posZ = math.sin(angle) * radius
		
		local puff = Instance.new("Part")
		puff.Name = "CatCollarPuff" .. i
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.new(0.24, 0.24, 0.24)
		puff.Color = collarColor
		puff.Material = Enum.Material.SmoothPlastic
		puff.CanCollide = false
		puff.CastShadow = false
		puff.Parent = character
		
		weldParts(upperTorso, puff, CFrame.new(posX, 0.38, posZ))
	end
end

-- 6. 建立多段向上微翹的軟Q貓尾巴
local function createProceduralTail(lowerTorso: BasePart, baseColor: Color3, character: Model)
	local numSegments = 3
	local segLength = 0.36
	local radius = 0.12
	local lastPart = lowerTorso
	
	-- 尾巴末梢的小白球顏色
	local tipColor = Color3.fromRGB(255, 250, 240)

	for i = 1, numSegments do
		local seg = Instance.new("Part")
		seg.Name = "CatTailSeg" .. i
		seg.Size = Vector3.new(radius, segLength, radius)
		seg.Color = baseColor
		seg.Material = Enum.Material.SmoothPlastic
		seg.CanCollide = false
		seg.Parent = character
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Parent = seg
		
		-- 每一段尾巴產生一定的向上傾角，形成優美弧度
		local offset
		if i == 1 then
			offset = CFrame.new(0, -0.15, 0.4) 
				* CFrame.Angles(math.rad(-45), 0, 0)
				* CFrame.new(0, segLength/2, 0)
		else
			offset = CFrame.new(0, segLength/2, 0) 
				* CFrame.Angles(math.rad(25), 0, 0)
				* CFrame.new(0, segLength/2, 0)
		end
		
		weldParts(lastPart, seg, offset)
		lastPart = seg
	end
	
	-- 尾巴最末梢的可愛球球
	local tip = Instance.new("Part")
	tip.Name = "CatTailTip"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.new(0.2, 0.2, 0.2)
	tip.Color = tipColor
	tip.Material = Enum.Material.SmoothPlastic
	tip.CanCollide = false
	tip.Parent = character
	weldParts(lastPart, tip, CFrame.new(0, segLength/2, 0))
end

-- ──────────────────────────────────────────────────────────────────────
-- 遠端資產載入輔助函數
-- ──────────────────────────────────────────────────────────────────────

local function applyAccessory(character: Model, assetId: string, accessoryName: string, textureId: string?): boolean
	if not assetId or assetId == "rbxassetid://0" or assetId == "" then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	-- ──────────────────────────────────────────────────────────────────
	-- A. 本地快取機制：優先在 ReplicatedStorage 中尋找本地預存的資產
	-- ──────────────────────────────────────────────────────────────────
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local localAsset = nil
	local assetsFolder = replicatedStorage:FindFirstChild("Assets")
	
	-- 嘗試從 "Assets" 資料夾或 ReplicatedStorage 根目錄尋找
	local possibleNames = {
		accessoryName,
		string.gsub(accessoryName, "^Cat", ""), -- 去除 "Cat" 前綴，例如 "Suit", "Hood"
		"whiteCat" .. string.gsub(accessoryName, "^Cat", ""), -- 配合具體貓咪名稱，例如 "whiteCatSuit"
		"white" .. string.gsub(accessoryName, "^Cat", "")
	}

	for _, name in ipairs(possibleNames) do
		if assetsFolder then
			localAsset = assetsFolder:FindFirstChild(name) or assetsFolder:FindFirstChild(string.lower(name))
		end
		if not localAsset then
			localAsset = replicatedStorage:FindFirstChild(name) or replicatedStorage:FindFirstChild(string.lower(name))
		end
		if localAsset then break end
	end

	if localAsset then
		print(string.format("[CatAppearance] 找到本地預存 %s 資產, 直接 Clone 套用: %s", accessoryName, localAsset.Name))
		local newAcc
		if localAsset:IsA("Accessory") then
			newAcc = localAsset:Clone()
			newAcc.Name = accessoryName
		else
			-- 如果是 Model 或 MeshPart，將其自動配件化
			newAcc = Instance.new("Accessory")
			newAcc.Name = accessoryName
			
			local handle = localAsset:Clone()
			handle.Name = "Handle"
			if handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.Transparency = 0
			end
			handle.Parent = newAcc
			
			local existingAtt = handle:FindFirstChildOfClass("Attachment")
			if not existingAtt then
				local att = Instance.new("Attachment")
				att.Name = (accessoryName == "CatHood") and "HatAttachment" or "BodyFrontAttachment"
				att.Parent = handle
			end
		end
		humanoid:AddAccessory(newAcc)
		return true
	end

	-- ──────────────────────────────────────────────────────────────────
	-- B. 遠端資產載入機制
	-- ──────────────────────────────────────────────────────────────────
	local assetIdNum = tonumber(string.match(assetId, "%d+"))
	if not assetIdNum then return false end

	print("[CatAppearance] 嘗試載入遠端資產 ID:", assetIdNum, "型態:", accessoryName)

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
		
		-- 2. 備案：若資產包內是 MeshPart，直接 Clone 物件，完整保留原始尺寸、材質、顏色與 PBR
		local foundMesh = model:FindFirstChildOfClass("MeshPart", true) or model:FindFirstChildOfClass("SpecialMesh", true)
		if foundMesh then
			warn("[CatAppearance] 資產 ID " .. assetIdNum .. " 內部無 Accessory，直接 Clone 轉配件...")
			local newAcc = Instance.new("Accessory")
			newAcc.Name = accessoryName
			
			-- 直接 Clone，保留其材質、PBR、Size
			local handle = foundMesh:Clone()
			handle.Name = "Handle"
			if handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.Transparency = 0
			end
			handle.Parent = newAcc
			
			-- 如果有原有 Attachment，保留它；否則建立預設
			local existingAtt = handle:FindFirstChildOfClass("Attachment")
			if not existingAtt then
				local att = Instance.new("Attachment")
				att.Name = (accessoryName == "CatHood") and "HatAttachment" or "BodyFrontAttachment"
				att.Parent = handle
			end
			
			humanoid:AddAccessory(newAcc)
			print("[CatAppearance] 成功將克隆網格轉換為配件：", accessoryName)
			model:Destroy()
			return true
		end
		model:Destroy()
	else
		-- 3. 終極備案：如果 LoadAsset 失敗
		-- 如果是頭套，在此回傳 false，讓其回到穩定的 Weld 貼合模式
		if accessoryName == "CatHood" then
			warn("[CatAppearance] LoadAsset 失敗且為頭套，回傳 false 以觸發舊有 Weld 貼合模式: " .. assetId)
			return false
		end

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
		mesh.TextureId = textureId or ""
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

	-- 1. 清理與隱藏原生頭髮帽子
	clearOldVisuals(character)

	-- 2. 套用 Suit (連身衣)
	local hasSuit = false
	if visualInfo.baseSuitAssetId and visualInfo.baseSuitAssetId ~= "rbxassetid://0" then
		hasSuit = applyAccessory(character, visualInfo.baseSuitAssetId, "CatSuit", visualInfo.headTextureId)
	end
	
	if hasSuit then
		appliedAnything = true
	else
		-- 💖 視覺補強：若無 Suit/載入失敗，為角色生成一套全身貼合的貓咪連身衣，並加上毛茸茸頸領！
		createProceduralSuit(character, visualInfo.baseColor)
		local upperTorso = character:FindFirstChild("UpperTorso")
		if upperTorso then
			createProceduralCollar(upperTorso, character)
		end
		appliedAnything = true
	end

	-- 3. 套用 Head / Hood (頭部)
	local head = character:FindFirstChild("Head")
	if head then
		local hasHood = false
		if visualInfo.headMeshId ~= "rbxassetid://0" then
			hasHood = applyAccessory(character, visualInfo.headMeshId, "CatHood", visualInfo.headTextureId)
		end
		
		if hasHood then
			appliedAnything = true
		else
			-- 💖 視覺補強與回退：若無 Hood/載入失敗，在頭部生成一個偏後的貓兜帽頭套，並加上貓耳與臉部口鼻、腮紅組！
			createProceduralHood(head, visualInfo.baseColor, character)
			appliedAnything = true
		end
	end

	-- 4. 套用 Tail (尾巴)
	local tailBase = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if tailBase then
		local hasTail = false
		if visualInfo.tailMeshId ~= "rbxassetid://0" then
			print("[CatAppearance] 嘗試套用高模尾巴配件...")
			local catTail = createVisualPart("Tail", visualInfo.tailMeshId, visualInfo.headTextureId)
			catTail.Parent = character
			local w = Instance.new("Weld")
			w.Part0 = tailBase
			w.Part1 = catTail
			local offset = (tailBase.Name == "Torso") and CFrame.new(0, -0.8, 0.4) or CFrame.new(0, -0.2, 0.4)
			w.C0 = offset * CFrame.Angles(math.rad(-10), 0, 0)
			w.Parent = catTail
			hasTail = true
			appliedAnything = true
		end
		
		if not hasTail then
			-- 💖 視覺補強：若高模尾巴載入失敗，生成程序化多段微捲貓尾巴！
			createProceduralTail(tailBase, visualInfo.baseColor, character)
			appliedAnything = true
		end
	end

	-- 5. 透明度設定 (全身隱形 = 1，套用失敗則恢復 0，臉部 Head 永遠保持 0)
	if appliedAnything then
		print("[CatAppearance] 套用成功，隱藏原始身體，只留臉部 (Alpha 1)")
		setBodyTransparency(character, 1) -- 這裡把身體設為完全透明 1，因為有我們的 Suit 代替了它！
	else
		warn("[CatAppearance] 未能套用任何自訂組件，保持原始身體顯示 (Alpha 0)")
		setBodyTransparency(character, 0)
	end

	-- 6. 顏色同步
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local name = part.Name
			local isSpecialPart = string.match(name, "InnerEar") or string.match(name, "Blush") or string.match(name, "Nose") or string.match(name, "CollarPuff") or string.match(name, "TailTip")
			if name ~= "HumanoidRootPart" and name ~= "Head" and not isSpecialPart then
				part.Color = visualInfo.baseColor
			end
		end
	end
	
	print("[CatAppearance] === 外觀套用完成 ===")
end

return CatAppearance
