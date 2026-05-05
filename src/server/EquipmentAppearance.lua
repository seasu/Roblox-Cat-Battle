-- EquipmentAppearance.lua
-- 負責在高質感角色上套用裝備視覺資產 (MeshPart / Layered Clothing)

local EquipmentAppearance = {}
local EquipmentData = require(game:GetService("ReplicatedStorage").shared.EquipmentData)
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

local function applyAccessory(character: Model, assetId: string, itemName: string)
	if assetId == "rbxassetid://0" then return end -- 忽略佔位符

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- 嘗試從 ID 載入資產
	-- 注意：在實際環境中，Asset ID 必須是 Accessory 類別且正確設定 Attachment
	local success, model = pcall(function()
		return InsertService:LoadAsset(tonumber(string.match(assetId, "%d+")))
	end)

	if success and model then
		local accessory = model:FindFirstChildOfClass("Accessory")
		if accessory then
			accessory.Name = PREFIX .. itemName
			humanoid:AddAccessory(accessory:Clone())
		end
		model:Destroy()
	else
		-- warn("[EquipmentAppearance] 無法載入資產 ID: " .. assetId)
		-- 佔位方案：如果無法載入，可以在此處實作基礎視覺作為備案
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
					applyAccessory(char, itemInfo.assetId, itemInfo.id)
				end
			end
		end
	end)
end

return EquipmentAppearance
