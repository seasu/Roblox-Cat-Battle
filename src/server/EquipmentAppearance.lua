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
		
		-- 2. 備案：若資產包內是 MeshPart 或 SpecialMesh，將其配件化
		local foundMesh = model:FindFirstChildOfClass("MeshPart", true) or model:FindFirstChildOfClass("SpecialMesh", true)
		if foundMesh then
			warn("[EquipmentAppearance] 裝備 ID " .. assetId .. " 內部無 Accessory，執行自動轉換...")
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
			if foundMesh:IsA("MeshPart") then
				mesh.MeshId = foundMesh.MeshId
				mesh.TextureId = foundMesh.TextureID
				mesh.Scale = foundMesh.Size -- 核心修復：使用 MeshPart.Size 作為 SpecialMesh 的 Scale，保留原始縮放
			else
				mesh.MeshId = foundMesh.MeshId
				mesh.TextureId = foundMesh.TextureId
				mesh.Scale = foundMesh.Scale
			end
			mesh.Parent = handle
			
			-- 核心修復：嘗試遞迴尋找來源資產中的 Attachment，保留原本對齊 CFrame 偏移量
			local existingAtt = foundMesh:FindFirstChildOfClass("Attachment")
			if not existingAtt and foundMesh.Parent then
				existingAtt = foundMesh.Parent:FindFirstChildOfClass("Attachment")
				if not existingAtt then
					existingAtt = model:FindFirstChildOfClass("Attachment", true)
				end
			end

			local att
			if existingAtt then
				att = existingAtt:Clone()
				print("[EquipmentAppearance] 成功複製並沿用來源裝備原有 Attachment:", att.Name, "CFrame:", att.CFrame)
			else
				att = Instance.new("Attachment")
				-- 依據槽位決定預設掛載點
				if slot == "hat" then
					att.Name = "HatAttachment"
				elseif slot == "collar" then
					att.Name = "NeckAttachment"
				elseif slot == "weapon" then
					att.Name = "RightGripAttachment"
				else
					att.Name = "BodyFrontAttachment"
				end
			end
			att.Parent = handle
			
			humanoid:AddAccessory(newAcc)
			print("[EquipmentAppearance] 成功將裝備內容轉換為配件：", itemName)
		end
		model:Destroy()
	else
		-- 3. 終極備案：如果 LoadAsset 失敗，且該 ID 可能是原始 Mesh ID
		-- 我們在此可以建立一個使用該 ID 的配件
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
