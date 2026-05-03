local Types = require(script.Parent.Types)
type SkillDefinition = Types.SkillDefinition

local SkillData = {}

local skills: { [string]: SkillDefinition } = {

	BasicSwipe = {
		id = "BasicSwipe",
		displayName = "基礎爪擊",
		description = "最基礎的攻擊，無冷卻時間。",
		damage = 15,
		cooldown = 0,
		range = 6,
		aoeRadius = 0,
		unlockLevel = 1,
		isPassive = false,
		statusEffect = nil,
	},

	PowerClaw = {
		id = "PowerClaw",
		displayName = "強力貓爪",
		description = "猛力一擊，使敵人流血 3 秒。",
		damage = 45,
		cooldown = 8,
		range = 6,
		aoeRadius = 0,
		unlockLevel = 10,
		isPassive = false,
		statusEffect = { kind = "Bleed", duration = 3, magnitude = 5 },
	},

	ShadowStrike = {
		id = "ShadowStrike",
		displayName = "暗影突刺",
		description = "從黑暗中突刺，使敵人失明 2 秒。",
		damage = 60,
		cooldown = 12,
		range = 7,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = { kind = "Blind", duration = 2, magnitude = 1 },
	},

	Vanish = {
		id = "Vanish",
		displayName = "消失術",
		description = "瞬間隱身，讓敵人無法鎖定你。",
		damage = 0,
		cooldown = 20,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	FireClaw = {
		id = "FireClaw",
		displayName = "烈焰貓爪",
		description = "燃燒的爪擊，使敵人持續燃燒 4 秒。",
		damage = 55,
		cooldown = 10,
		range = 6,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = { kind = "Burn", duration = 4, magnitude = 8 },
	},

	EmberAura = {
		id = "EmberAura",
		displayName = "火焰氣場",
		description = "釋放火焰波動，對周圍敵人造成範圍燃燒傷害。",
		damage = 20,
		cooldown = 15,
		range = 0,
		aoeRadius = 8,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = { kind = "Burn", duration = 2, magnitude = 5 },
	},

	IceShard = {
		id = "IceShard",
		displayName = "冰錐射擊",
		description = "發射冰錐，使敵人緩速 4 秒。",
		damage = 40,
		cooldown = 9,
		range = 15,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = { kind = "Slow", duration = 4, magnitude = 0.5 },
	},

	FrostAura = {
		id = "FrostAura",
		displayName = "冰霜氣場",
		description = "持續散發寒氣，對附近敵人造成緩速效果。",
		damage = 10,
		cooldown = 18,
		range = 0,
		aoeRadius = 6,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = { kind = "Slow", duration = 3, magnitude = 0.4 },
	},

	ThunderPounce = {
		id = "ThunderPounce",
		displayName = "雷霆猛撲",
		description = "雷電衝撲，對範圍內敵人造成傷害並暈眩 1.5 秒。",
		damage = 70,
		cooldown = 14,
		range = 8,
		aoeRadius = 5,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = { kind = "Stun", duration = 1.5, magnitude = 1 },
	},

	ChainLightning = {
		id = "ChainLightning",
		displayName = "連鎖閃電",
		description = "閃電在最多 3 個敵人之間跳躍傳導。",
		damage = 50,
		cooldown = 18,
		range = 12,
		aoeRadius = 0,
		unlockLevel = 20,
		isPassive = false,
		statusEffect = nil,
	},

	PetalSlash = {
		id = "PetalSlash",
		displayName = "花瓣斬",
		description = "旋轉花瓣對周圍小範圍敵人造成傷害。",
		damage = 35,
		cooldown = 7,
		range = 0,
		aoeRadius = 4,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	HealingBloom = {
		id = "HealingBloom",
		displayName = "治癒花開",
		description = "綻放花朵，恢復自身 40 點 HP。",
		damage = -40,
		cooldown = 25,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	OrangeFury = {
		id = "OrangeFury",
		displayName = "橘貓狂怒",
		description = "【被動】HP 低於 30% 時，攻擊力提升 80%。",
		damage = 0,
		cooldown = 0,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = true,
		statusEffect = nil,
	},

	FoodRage = {
		id = "FoodRage",
		displayName = "飢餓暴走",
		description = "消耗自身 10% 最大 HP，使下次攻擊造成 2.5 倍傷害。",
		damage = 0,
		cooldown = 15,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	LuckyCharm = {
		id = "LuckyCharm",
		displayName = "幸運符咒",
		description = "施放後 30 秒內，XP 獲取 +50%，金幣掉落 +30%。",
		damage = 0,
		cooldown = 60,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	ColorShift = {
		id = "ColorShift",
		displayName = "三色切換",
		description = "在火焰（+ATK）、冰霜（+DEF）、雷電（+SPD）三種形態中循環，各加成 +15%。",
		damage = 0,
		cooldown = 8,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	GentlemanStrike = {
		id = "GentlemanStrike",
		displayName = "紳士必殺",
		description = "必定暴擊，造成 ATK × 3.0 傷害。",
		damage = 0,
		cooldown = 20,
		range = 7,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},

	TailcoatShield = {
		id = "TailcoatShield",
		displayName = "燕尾護盾",
		description = "5 秒內完全格擋下一次受到的傷害（100% 吸收）。",
		damage = 0,
		cooldown = 30,
		range = 0,
		aoeRadius = 0,
		unlockLevel = nil,
		isPassive = false,
		statusEffect = nil,
	},
}

SkillData.skills = skills

function SkillData.getSkillById(skillId: string): SkillDefinition?
	return SkillData.skills[skillId]
end

function SkillData.getInnateSkillsForCat(catId: string): { string }
	local CatData = require(script.Parent.CatData)
	local cat = CatData.getCatById(catId)
	if cat then
		return cat.innateSkills
	end
	return { "BasicSwipe" }
end

function SkillData.getLevelUnlockedSkills(level: number): { string }
	local result: { string } = {}
	for _, skill in pairs(SkillData.skills) do
		if skill.unlockLevel == level and not skill.isPassive then
			table.insert(result, skill.id)
		end
	end
	return result
end

return SkillData
