-- 全域 Luau 型別定義，所有模組透過 require 此檔案取得型別

export type EquipmentLoadout = {
	collar: string?,
	hat: string?,
	weapon: string?,
}

export type CatStats = {
	maxHp: number,
	attack: number,
	defense: number,
	speed: number,
	critChance: number,
}

export type GrowthTier = {
	minLevel: number,
	appearance: string,
	description: string,
}

export type CatDefinition = {
	id: string,
	displayName: string,
	description: string,
	price: number,
	productId: number?,
	innateSkills: { string },
	growthTiers: { GrowthTier },
	baseStats: CatStats,
}

export type StatusEffect = {
	kind: "Bleed" | "Slow" | "Stun" | "Burn" | "Blind",
	duration: number,
	magnitude: number,
}

export type SkillDefinition = {
	id: string,
	displayName: string,
	description: string,
	damage: number,
	cooldown: number,
	range: number,
	aoeRadius: number,
	unlockLevel: number?,
	isPassive: boolean,
	statusEffect: StatusEffect?,
}

export type EquipmentItem = {
	id: string,
	displayName: string,
	slot: "collar" | "hat" | "weapon",
	description: string,
	statBonus: CatStats,
	price: number,
}

export type NPCDefinition = {
	id: string,
	kind: "Doll" | "WildCat" | "WildHuman",
	displayName: string,
	tier: number,
	maxHp: number,
	attack: number,
	defense: number,
	xpReward: number,
	coinReward: number,
	respawnTime: number,
	modelKey: string,
}

export type ActiveNPC = {
	definition: NPCDefinition,
	currentHp: number,
	position: Vector3,
	instanceId: string,
}

export type PlayerData = {
	playerId: number,
	level: number,
	xp: number,
	coins: number,
	ownedCats: { [string]: boolean },
	activeCatId: string,
	equipment: EquipmentLoadout,
	unlockedSkills: { [string]: boolean },
	catFragments: { [string]: number },  -- 各特殊貓的碎片數量，10 片可合成
	activeColorShiftMode: string?,
	createdAt: number,
	lastSeen: number,
}

return {}
