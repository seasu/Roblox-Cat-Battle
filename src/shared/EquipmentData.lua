local Types = require(script.Parent.Types)
type EquipmentItem = Types.EquipmentItem
type EquipmentLoadout = Types.EquipmentLoadout
type CatStats = Types.CatStats

local EquipmentData = {}

local function zeroStats(): CatStats
	return { maxHp = 0, attack = 0, defense = 0, speed = 0, critChance = 0 }
end

local items: { [string]: EquipmentItem } = {

	-- 項圈槽
	collarBasic = {
		id = "collarBasic",
		displayName = "基礎項圈",
		slot = "collar",
		description = "普通的項圈，略微提升防禦與血量。",
		statBonus = { maxHp = 10, attack = 0, defense = 2, speed = 0, critChance = 0 },
		price = 50,
	},
	collarSpike = {
		id = "collarSpike",
		displayName = "尖刺項圈",
		slot = "collar",
		description = "帶有尖刺的項圈，提升攻擊與防禦。",
		statBonus = { maxHp = 0, attack = 5, defense = 3, speed = 0, critChance = 0 },
		price = 150,
	},
	collarHeal = {
		id = "collarHeal",
		displayName = "治癒項圈",
		slot = "collar",
		description = "散發治癒能量，大幅提升最大 HP。",
		statBonus = { maxHp = 30, attack = 0, defense = 0, speed = 0, critChance = 0 },
		price = 200,
	},
	collarSpeed = {
		id = "collarSpeed",
		displayName = "迅捷項圈",
		slot = "collar",
		description = "輕盈的項圈，讓你動作更加敏捷。",
		statBonus = { maxHp = 0, attack = 0, defense = 0, speed = 2, critChance = 0 },
		price = 250,
	},

	-- 帽子槽
	hatWizard = {
		id = "hatWizard",
		displayName = "巫師帽",
		slot = "hat",
		description = "蘊含魔力的帽子，提升攻擊力。",
		statBonus = { maxHp = 0, attack = 8, defense = 0, speed = 0, critChance = 0 },
		price = 180,
	},
	hatKnight = {
		id = "hatKnight",
		displayName = "騎士頭盔",
		slot = "hat",
		description = "堅固的金屬頭盔，大幅提升防禦與血量。",
		statBonus = { maxHp = 20, attack = 0, defense = 10, speed = 0, critChance = 0 },
		price = 220,
	},
	hatBandana = {
		id = "hatBandana",
		displayName = "戰鬥頭巾",
		slot = "hat",
		description = "勇士的頭巾，均衡提升攻守。",
		statBonus = { maxHp = 0, attack = 5, defense = 5, speed = 0, critChance = 0 },
		price = 160,
	},
	hatCrown = {
		id = "hatCrown",
		displayName = "金色皇冠",
		slot = "hat",
		description = "彰顯尊貴的皇冠，全面提升各項數值。",
		statBonus = { maxHp = 10, attack = 3, defense = 3, speed = 1, critChance = 0 },
		price = 300,
	},

	-- 武器槽
	weaponClaws = {
		id = "weaponClaws",
		displayName = "鐵爪",
		slot = "weapon",
		description = "鋒利的鐵製爪套，大幅提升攻擊力。",
		statBonus = { maxHp = 0, attack = 10, defense = 0, speed = 0, critChance = 0 },
		price = 200,
	},
	weaponSword = {
		id = "weaponSword",
		displayName = "迷你劍",
		slot = "weapon",
		description = "輕巧的小劍，攻擊極高但防禦稍弱。",
		statBonus = { maxHp = 0, attack = 15, defense = -2, speed = 0, critChance = 0 },
		price = 280,
	},
	weaponShield = {
		id = "weaponShield",
		displayName = "貓盾",
		slot = "weapon",
		description = "厚重的盾牌，犧牲攻擊換取強力防禦。",
		statBonus = { maxHp = 0, attack = -2, defense = 18, speed = 0, critChance = 0 },
		price = 260,
	},
	weaponStaff = {
		id = "weaponStaff",
		displayName = "魔法杖",
		slot = "weapon",
		description = "輕盈的魔法杖，提升攻擊與移動速度。",
		statBonus = { maxHp = 0, attack = 12, defense = 0, speed = 2, critChance = 0 },
		price = 320,
	},
}

EquipmentData.items = items

function EquipmentData.getItemById(itemId: string): EquipmentItem?
	return EquipmentData.items[itemId]
end

function EquipmentData.getItemsBySlot(slot: string): { EquipmentItem }
	local result: { EquipmentItem } = {}
	for _, item in pairs(EquipmentData.items) do
		if item.slot == slot then
			table.insert(result, item)
		end
	end
	return result
end

function EquipmentData.sumBonuses(loadout: EquipmentLoadout): CatStats
	local total = zeroStats()
	local slots = { loadout.collar, loadout.hat, loadout.weapon }
	for _, itemId in ipairs(slots) do
		if itemId then
			local item = EquipmentData.items[itemId]
			if item then
				total.maxHp += item.statBonus.maxHp
				total.attack += item.statBonus.attack
				total.defense += item.statBonus.defense
				total.speed += item.statBonus.speed
				total.critChance += item.statBonus.critChance
			end
		end
	end
	return total
end

return EquipmentData
