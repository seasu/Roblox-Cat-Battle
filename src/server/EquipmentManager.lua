local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipmentData = require(ReplicatedStorage:WaitForChild("Shared").EquipmentData)
local CatData = require(ReplicatedStorage:WaitForChild("Shared").CatData)
local DataStore = require(script.Parent.DataStore)
local Types = require(ReplicatedStorage:WaitForChild("Shared").Types)
type CatStats = Types.CatStats

local EquipmentManager = {}

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local equipmentChangedEvent = remoteEvents:WaitForChild("EquipmentChanged")

function EquipmentManager.handleEquip(player: Player, itemId: string)
	local data = DataStore.getData(player)
	if not data then return end
	local item = EquipmentData.getItemById(itemId)
	if not item then
		warn("[EquipmentManager] 無效的 itemId：", itemId)
		return
	end
	-- 確保 ownedItems 存在（舊存檔相容）
	if not data.ownedItems then data.ownedItems = {} end
	-- 驗證擁有權
	if not data.ownedItems[itemId] then
		warn("[EquipmentManager] 玩家未擁有此物品：", itemId)
		return
	end
	data.equipment[item.slot] = itemId
	equipmentChangedEvent:FireClient(player, data.equipment)
end

function EquipmentManager.handleUnequip(player: Player, slot: string)
	local data = DataStore.getData(player)
	if not data then return end
	if slot ~= "collar" and slot ~= "hat" and slot ~= "weapon" then return end
	data.equipment[slot] = nil
	equipmentChangedEvent:FireClient(player, data.equipment)
end

function EquipmentManager.getOwnedItems(player: Player): { [string]: boolean }
	local data = DataStore.getData(player)
	if not data then return {} end
	return data.ownedItems or {}
end

function EquipmentManager.getTotalStats(player: Player): CatStats
	local data = DataStore.getData(player)
	if not data then
		return { maxHp = 100, attack = 10, defense = 5, speed = 16, critChance = 0.05 }
	end

	local cat = CatData.getCatById(data.activeCatId)
	local base: CatStats = cat and cat.baseStats
		or { maxHp = 100, attack = 10, defense = 5, speed = 16, critChance = 0.05 }

	-- 等級成長：每 10 等各項基礎數值 +10%
	local growthFactor = 1 + (data.level - 1) * 0.02
	local grown: CatStats = {
		maxHp = math.floor(base.maxHp * growthFactor),
		attack = math.floor(base.attack * growthFactor),
		defense = math.floor(base.defense * growthFactor),
		speed = base.speed,
		critChance = base.critChance,
	}

	local bonus = EquipmentData.sumBonuses(data.equipment)
	return {
		maxHp = grown.maxHp + bonus.maxHp,
		attack = grown.attack + bonus.attack,
		defense = math.max(0, grown.defense + bonus.defense),
		speed = grown.speed + bonus.speed,
		critChance = math.min(0.95, grown.critChance + bonus.critChance),
	}
end

function EquipmentManager.getEquipmentLoadout(player: Player)
	local data = DataStore.getData(player)
	return data and data.equipment or {}
end

return EquipmentManager
