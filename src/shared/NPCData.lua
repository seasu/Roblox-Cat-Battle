local Types = require(script.Parent.Types)
type NPCDefinition = Types.NPCDefinition

local NPCData = {}

local npcs: { [string]: NPCDefinition } = {

	-- 玩偶（Doll）——靜止訓練假人
	dollEasy = {
		id = "dollEasy",
		kind = "Doll",
		displayName = "軟綿綿布偶（簡單）",
		tier = 1,
		maxHp = 80,
		attack = 5,
		defense = 2,
		xpReward = 20,
		coinReward = 5,
		respawnTime = 8,
		modelKey = "Doll_Easy",
	},
	dollMedium = {
		id = "dollMedium",
		kind = "Doll",
		displayName = "胖嘟嘟布偶（中等）",
		tier = 2,
		maxHp = 200,
		attack = 10,
		defense = 5,
		xpReward = 55,
		coinReward = 15,
		respawnTime = 12,
		modelKey = "Doll_Medium",
	},
	dollHard = {
		id = "dollHard",
		kind = "Doll",
		displayName = "巨無霸布偶（困難）",
		tier = 3,
		maxHp = 450,
		attack = 18,
		defense = 10,
		xpReward = 130,
		coinReward = 35,
		respawnTime = 20,
		modelKey = "Doll_Hard",
	},

	-- 野貓（WildCat）——四處遊蕩的近戰貓
	wildCatEasy = {
		id = "wildCatEasy",
		kind = "WildCat",
		displayName = "傲嬌野貓（簡單）",
		tier = 1,
		maxHp = 120,
		attack = 12,
		defense = 3,
		xpReward = 30,
		coinReward = 10,
		respawnTime = 10,
		modelKey = "WildCat_Easy",
	},
	wildCatMedium = {
		id = "wildCatMedium",
		kind = "WildCat",
		displayName = "貪吃野貓（中等）",
		tier = 2,
		maxHp = 300,
		attack = 22,
		defense = 8,
		xpReward = 75,
		coinReward = 25,
		respawnTime = 15,
		modelKey = "WildCat_Medium",
	},
	wildCatHard = {
		id = "wildCatHard",
		kind = "WildCat",
		displayName = "野外大王貓（困難）",
		tier = 3,
		maxHp = 650,
		attack = 38,
		defense = 15,
		xpReward = 180,
		coinReward = 60,
		respawnTime = 25,
		modelKey = "WildCat_Hard",
	},

	-- 野人（WildHuman）——主動進攻的遠程野人
	wildHumanEasy = {
		id = "wildHumanEasy",
		kind = "WildHuman",
		displayName = "圓滾滾野人（簡單）",
		tier = 1,
		maxHp = 100,
		attack = 15,
		defense = 2,
		xpReward = 35,
		coinReward = 12,
		respawnTime = 10,
		modelKey = "WildHuman_Easy",
	},
	wildHumanMedium = {
		id = "wildHumanMedium",
		kind = "WildHuman",
		displayName = "搗蛋小野人（中等）",
		tier = 2,
		maxHp = 260,
		attack = 28,
		defense = 6,
		xpReward = 90,
		coinReward = 30,
		respawnTime = 18,
		modelKey = "WildHuman_Medium",
	},
	wildHumanHard = {
		id = "wildHumanHard",
		kind = "WildHuman",
		displayName = "野人部落酋長（困難）",
		tier = 3,
		maxHp = 580,
		attack = 48,
		defense = 12,
		xpReward = 210,
		coinReward = 70,
		respawnTime = 30,
		modelKey = "WildHuman_Hard",
	},
}

NPCData.npcs = npcs

function NPCData.getNPCById(npcId: string): NPCDefinition?
	return NPCData.npcs[npcId]
end

function NPCData.getNPCsByKind(kind: string): { NPCDefinition }
	local result: { NPCDefinition } = {}
	for _, npc in pairs(NPCData.npcs) do
		if npc.kind == kind then
			table.insert(result, npc)
		end
	end
	return result
end

function NPCData.getNPCsByTier(tier: number): { NPCDefinition }
	local result: { NPCDefinition } = {}
	for _, npc in pairs(NPCData.npcs) do
		if npc.tier == tier then
			table.insert(result, npc)
		end
	end
	return result
end

return NPCData
