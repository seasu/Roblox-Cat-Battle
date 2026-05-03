local Types = require(script.Parent.Types)
type CatDefinition = Types.CatDefinition
type GrowthTier = Types.GrowthTier
type CatStats = Types.CatStats

local CatData = {}

local function makeTiers(names: { string }): { GrowthTier }
	local tiers: { GrowthTier } = {}
	for i, name in ipairs(names) do
		tiers[i] = {
			minLevel = (i - 1) * 10 + 1,
			appearance = name,
			description = name,
		}
	end
	return tiers
end

local defaultStats: CatStats = {
	maxHp = 100,
	attack = 10,
	defense = 5,
	speed = 16,
	critChance = 0.05,
}

CatData.cats: { [string]: CatDefinition } = {

	whiteCat = {
		id = "whiteCat",
		displayName = "白貓",
		description = "最初的貓咪，純潔而堅韌，隨等級成長蛻變。",
		price = 0,
		productId = nil,
		innateSkills = { "BasicSwipe" },
		growthTiers = makeTiers({
			"WhiteCat_Kitten", "WhiteCat_Junior", "WhiteCat_Adult",
			"WhiteCat_Veteran", "WhiteCat_Elder", "WhiteCat_Sage",
			"WhiteCat_Champion", "WhiteCat_Legend", "WhiteCat_Mythic", "WhiteCat_Celestial",
		}),
		baseStats = defaultStats,
	},

	shadowCat = {
		id = "shadowCat",
		displayName = "暗影貓",
		description = "潛伏於黑暗的刺客，一擊致命，轉瞬消失。",
		price = 200,
		productId = 1001,
		innateSkills = { "BasicSwipe", "ShadowStrike", "Vanish" },
		growthTiers = makeTiers({
			"Shadow_Shade", "Shadow_Stalker", "Shadow_Phantom",
			"Shadow_Wraith", "Shadow_Specter", "Shadow_Haunt",
			"Shadow_Nightmare", "Shadow_Abyss", "Shadow_Void", "Shadow_Oblivion",
		}),
		baseStats = { maxHp = 90, attack = 15, defense = 4, speed = 18, critChance = 0.15 },
	},

	flameCat = {
		id = "flameCat",
		displayName = "烈焰貓",
		description = "燃燒著怒火的狂戰士，傷害極高，讓敵人化為灰燼。",
		price = 350,
		productId = 1002,
		innateSkills = { "BasicSwipe", "FireClaw", "EmberAura" },
		growthTiers = makeTiers({
			"Flame_Spark", "Flame_Ember", "Flame_Blaze",
			"Flame_Inferno", "Flame_Volcano", "Flame_Eruption",
			"Flame_Purgatory", "Flame_Hellfire", "Flame_Phoenix", "Flame_SolarFlare",
		}),
		baseStats = { maxHp = 95, attack = 18, defense = 3, speed = 16, critChance = 0.10 },
	},

	frostCat = {
		id = "frostCat",
		displayName = "冰霜貓",
		description = "以冰封住敵人行動的控場大師，緩速與冰凍讓對手無從應對。",
		price = 350,
		productId = 1003,
		innateSkills = { "BasicSwipe", "IceShard", "FrostAura" },
		growthTiers = makeTiers({
			"Frost_Flake", "Frost_Chill", "Frost_Freeze",
			"Frost_Glacier", "Frost_Blizzard", "Frost_Permafrost",
			"Frost_Avalanche", "Frost_Arctic", "Frost_AbsoluteZero", "Frost_Cryogenic",
		}),
		baseStats = { maxHp = 100, attack = 12, defense = 8, speed = 14, critChance = 0.07 },
	},

	thunderCat = {
		id = "thunderCat",
		displayName = "雷霆貓",
		description = "閃電橫掃一切的 AoE 之王，連鎖閃電讓多個敵人同時受苦。",
		price = 500,
		productId = 1004,
		innateSkills = { "BasicSwipe", "ThunderPounce", "ChainLightning" },
		growthTiers = makeTiers({
			"Thunder_Static", "Thunder_Spark", "Thunder_Bolt",
			"Thunder_Storm", "Thunder_Tempest", "Thunder_Cyclone",
			"Thunder_Maelstrom", "Thunder_Hurricane", "Thunder_Mjolnir", "Thunder_Zeus",
		}),
		baseStats = { maxHp = 95, attack = 16, defense = 5, speed = 17, critChance = 0.10 },
	},

	sakuraCat = {
		id = "sakuraCat",
		displayName = "櫻花貓",
		description = "攻守兼備的均衡型貓咪，帶有治癒能力，適合持久戰。",
		price = 450,
		productId = 1005,
		innateSkills = { "BasicSwipe", "PetalSlash", "HealingBloom" },
		growthTiers = makeTiers({
			"Sakura_Bud", "Sakura_Petal", "Sakura_Blossom",
			"Sakura_Bloom", "Sakura_Hanami", "Sakura_Zen",
			"Sakura_Celestial", "Sakura_Eternal", "Sakura_Divine", "Sakura_Transcendent",
		}),
		baseStats = { maxHp = 110, attack = 12, defense = 7, speed = 15, critChance = 0.08 },
	},

	orangeCat = {
		id = "orangeCat",
		displayName = "橘貓",
		description = "貪吃懶散卻爆發力驚人——越餓越猛，血量越低攻擊越強！",
		price = 300,
		productId = 1006,
		innateSkills = { "BasicSwipe", "OrangeFury", "FoodRage" },
		growthTiers = makeTiers({
			"Orange_Kitten", "Orange_Chubby", "Orange_Fat",
			"Orange_BigBoy", "Orange_Emperor", "Orange_Divine",
			"Orange_Legend", "Orange_Titan", "Orange_Mythic", "Orange_CosmicChonk",
		}),
		baseStats = { maxHp = 130, attack = 13, defense = 6, speed = 14, critChance = 0.06 },
	},

	calicoCat = {
		id = "calicoCat",
		displayName = "三花貓",
		description = "神秘的魔法師，能切換火、冰、雷三種元素形態，並帶來好運加持。",
		price = 400,
		productId = 1007,
		innateSkills = { "BasicSwipe", "LuckyCharm", "ColorShift" },
		growthTiers = makeTiers({
			"Calico_Kitten", "Calico_ColorGirl", "Calico_Mage",
			"Calico_Sorcerer", "Calico_ElementMaster", "Calico_Prismatic",
			"Calico_Legend", "Calico_DivineSoul", "Calico_Mythic", "Calico_RainbowGod",
		}),
		baseStats = { maxHp = 100, attack = 13, defense = 6, speed = 16, critChance = 0.09 },
	},

	tuxedoCat = {
		id = "tuxedoCat",
		displayName = "賓士貓",
		description = "優雅的紳士刺客，必殺技保證暴擊，燕尾護盾可完全格擋一擊。",
		price = 500,
		productId = 1008,
		innateSkills = { "BasicSwipe", "GentlemanStrike", "TailcoatShield" },
		growthTiers = makeTiers({
			"Tuxedo_Kitten", "Tuxedo_Junior", "Tuxedo_Warrior",
			"Tuxedo_Knight", "Tuxedo_Swordsman", "Tuxedo_Agent",
			"Tuxedo_Legend", "Tuxedo_God", "Tuxedo_Mythic", "Tuxedo_CosmicKing",
		}),
		baseStats = { maxHp = 95, attack = 14, defense = 6, speed = 17, critChance = 0.20 },
	},
}

function CatData.getCatById(catId: string): CatDefinition?
	return CatData.cats[catId]
end

function CatData.getGrowthTier(catId: string, level: number): GrowthTier
	local cat = CatData.cats[catId]
	if not cat then
		return { minLevel = 1, appearance = "Default", description = "預設" }
	end
	local result = cat.growthTiers[1]
	for _, tier in ipairs(cat.growthTiers) do
		if level >= tier.minLevel then
			result = tier
		end
	end
	return result
end

function CatData.getDefaultCatId(): string
	return "whiteCat"
end

return CatData
