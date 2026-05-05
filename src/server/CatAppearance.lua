-- CatAppearance.lua
-- 核心外觀管理器：實作 R15 透明素體 + 高模 MeshPart 配件系統

local CatAppearance = {}
local CatVisualData = require(game:GetService("ReplicatedStorage").shared.CatVisualData)

-- ──────────────────────────────────────────────────────────────────────
-- 輔助工具
-- ──────────────────────────────────────────────────────────────────────

local function clearOldVisuals(character: Model)
	-- 清除舊有的自訂 Part (以 Cat 開頭的)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 3) == "Cat" then
			child:Destroy()
		end
		-- 清除舊有的 Layered Clothing 或配件
		if child:IsA("Accessory") and (child:FindFirstChild("CatHead") or child:FindFirstChild("CatTail")) then
			child:Destroy()
		end
	end
end

local function setBodyTransparency(character: Model, transparency: number)
	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") then
			-- 排除 HumanoidRootPart 以免影響物理或相機
			if child.Name ~= "HumanoidRootPart" then
				child.Transparency = transparency
			end
		end
		if child:IsA("Decal") then -- 隱藏預設臉部
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

-- ──────────────────────────────────────────────────────────────────────
-- 核心外觀套用邏輯
-- ──────────────────────────────────────────────────────────────────────

function CatAppearance.apply(player: Player, catId: string)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local visualInfo = CatVisualData.cats[catId] or CatVisualData.cats.whiteCat

	-- 1. 清理與重設
	clearOldVisuals(character)
	setBodyTransparency(character, 1) -- 隱藏預設 R15 素體，只留骨架動作

	-- 2. 套用高模頭部 (MeshPart)
	local head = character:FindFirstChild("Head")
	if head and visualInfo.headMeshId ~= "rbxassetid://0" then
		local catHead = createMeshPart("HeadShape", visualInfo.headMeshId, visualInfo.headTextureId)
		catHead.Parent = character

		local w = Instance.new("Weld")
		w.Part0 = head
		w.Part1 = catHead
		w.C0 = CFrame.new(0, 0, 0) -- 根據實際 Mesh 調整偏移
		w.Parent = catHead
		
		-- 添加動態臉部貼圖元件 (供客戶端控制)
		local face = Instance.new("Decal")
		face.Name = "DynamicFace"
		face.Texture = visualInfo.faces.idle
		face.Parent = catHead
	end

	-- 3. 套用高模尾巴 (MeshPart)
	local lowerTorso = character:FindFirstChild("LowerTorso")
	if lowerTorso and visualInfo.tailMeshId ~= "rbxassetid://0" then
		local catTail = createMeshPart("Tail", visualInfo.tailMeshId, visualInfo.headTextureId)
		catTail.Parent = character

		local w = Instance.new("Weld")
		w.Part0 = lowerTorso
		w.Part1 = catTail
		w.C0 = CFrame.new(0, -0.5, 0.6) * CFrame.Angles(math.rad(-20), 0, 0)
		w.Parent = catTail
	end

	-- 4. 套用基礎毛皮 (Layered Clothing - 預留實作)
	-- 如果有 baseSuitAssetId，則使用 humanoid:AddAccessory() 套用
	-- 目前以 BrickColor 著色不可見的 Part 作為備案 (影響粒子等效果)
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Color = visualInfo.baseColor
		end
	end
end

return CatAppearance
