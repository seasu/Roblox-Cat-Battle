-- EquipmentAppearance.lua
-- 負責在高質感角色上套用裝備視覺資產 (MeshPart / Layered Clothing)

local EquipmentAppearance = {}
local EquipmentData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").EquipmentData)
local InsertService = game:GetService("InsertService")

-- 標記前綴，用於識別並清除舊裝備
local PREFIX = "EqVis_"

-- ──────────────────────────────────────────────────────────────────────
-- 輔助工具
-- ──────────────────────────────────────────────────────────────────────

local function clearEquipVisuals(character: Model)
	-- 清除舊有的配件物件
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and string.sub(child.Name, 1, #PREFIX) == PREFIX then
			child:Destroy()
		end
	end
end

local function applyAccessory(character: Model, assetId: string, itemName: string, slot: string)
	if assetId == "rbxassetid://0" then return end -- 忽略佔位符

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- ──────────────────────────────────────────────────────────────────
	-- A. 本地快取機制：優先在 ReplicatedStorage 中尋找本地預存的裝備資產
	-- ──────────────────────────────────────────────────────────────────
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local localAsset = nil
	local assetsFolder = replicatedStorage:FindFirstChild("Assets")
	
	-- 嘗試從 "Assets" 資料夾或 ReplicatedStorage 根目錄尋找
	local possibleNames = {
		itemName,
		PREFIX .. itemName,
		string.gsub(itemName, "^EqVis_", ""),
		string.gsub(itemName, "^Eq_", "")
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
		print(string.format("[EquipmentAppearance] 找到本地預存 %s 裝備資產, 直接 Clone 套用: %s", itemName, localAsset.Name))
		local newAcc
		if localAsset:IsA("Accessory") then
			newAcc = localAsset:Clone()
			newAcc.Name = PREFIX .. itemName
		else
			-- 如果是 Model 或 MeshPart，將其自動配件化
			newAcc = Instance.new("Accessory")
			newAcc.Name = PREFIX .. itemName
			
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
				if slot == "hat" then
					att.Name = "HatAttachment"
				elseif slot == "collar" then
					att.Name = "NeckAttachment"
				elseif slot == "weapon" then
					att.Name = "RightGripAttachment"
				else
					att.Name = "BodyFrontAttachment"
				end
				att.Parent = handle
			end
		end
		humanoid:AddAccessory(newAcc)
		return
	end

	-- ──────────────────────────────────────────────────────────────────
	-- B. 遠端資產載入機制
	-- ──────────────────────────────────────────────────────────────────
	-- 嘗試從 ID 載入資產
	local success, model = pcall(function()
		return InsertService:LoadAsset(tonumber(string.match(assetId, "%d+")))
	end)

	if success and model then
		-- 1. 優先尋找資產包內的 Accessory
		local accessory = model:FindFirstChildOfClass("Accessory") or model:FindFirstChildOfClass("Accessory", true)
		if accessory then
			accessory.Name = PREFIX .. itemName
			humanoid:AddAccessory(accessory:Clone())
			model:Destroy()
			return
		end
		
		-- 2. 備案：若資產包內是 MeshPart，直接 Clone 物件，完整保留原始尺寸與 PBR
		local foundMesh = model:FindFirstChildOfClass("MeshPart", true) or model:FindFirstChildOfClass("SpecialMesh", true)
		if foundMesh then
			warn("[EquipmentAppearance] 裝備 ID " .. assetId .. " 內部無 Accessory，直接 Clone 轉配件...")
			local newAcc = Instance.new("Accessory")
			newAcc.Name = PREFIX .. itemName
			
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
				if slot == "hat" then
					att.Name = "HatAttachment"
				elseif slot == "collar" then
					att.Name = "NeckAttachment"
				elseif slot == "weapon" then
					att.Name = "RightGripAttachment"
				else
					att.Name = "BodyFrontAttachment"
				end
				att.Parent = handle
			end
			
			humanoid:AddAccessory(newAcc)
			print("[EquipmentAppearance] 成功將裝備網格轉換為配件：", itemName)
		end
		model:Destroy()
	else
		-- 3. 終極備案：如果 LoadAsset 失敗，且該 ID 可能是原始 Mesh ID
		warn("[EquipmentAppearance] LoadAsset 失敗，嘗試以原始 Mesh ID 模式建立配件: ", assetId)
		
		local newAcc = Instance.new("Accessory")
		newAcc.Name = PREFIX .. itemName
		
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 1)
		handle.Transparency = 0
		handle.CanCollide = false
		handle.Parent = newAcc
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = assetId
		mesh.Parent = handle
		
		local att = Instance.new("Attachment")
		if slot == "hat" then
			att.Name = "HatAttachment"
		elseif slot == "collar" then
			att.Name = "NeckAttachment"
		elseif slot == "weapon" then
			att.Name = "RightGripAttachment"
		else
			att.Name = "BodyFrontAttachment"
		end
		att.Parent = handle
		
		humanoid:AddAccessory(newAcc)
		print("[EquipmentAppearance] 已透過原始 Mesh ID 強制建立配件：", itemName)
	end
end

-- ──────────────────────────────────────────────────────────────────────
-- 核心套用邏輯
-- ──────────────────────────────────────────────────────────────────────

function EquipmentAppearance.apply(player: Player, loadout: { [string]: string? })
	local character = player.Character
	if not character then return end

	-- 1. 先清除舊視覺
	clearEquipVisuals(character)

	-- 2. 遍歷並套用各槽位裝備
	-- 延遲執行以確保 CatAppearance 的透明度與 MeshPart 已經就位
	task.defer(function()
		local char = player.Character
		if not char then return end

		for slot, itemId in pairs(loadout) do
			if itemId then
				local itemInfo = EquipmentData.getItemById(itemId)
				if itemInfo and itemInfo.assetId ~= "rbxassetid://0" then
					applyAccessory(char, itemInfo.assetId, itemInfo.id, itemInfo.slot)
				end
			end
		end
	end)
end

return EquipmentAppearance
