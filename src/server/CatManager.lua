local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatData = require(ReplicatedStorage.Shared.CatData)
local DataStore = require(script.Parent.DataStore)
local CatVisualData = require(ReplicatedStorage.Shared.CatVisualData)

local CatManager = {}

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateCatEvent = remoteEvents:WaitForChild("UpdateCatAppearance")

function CatManager.initPlayer(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	if not CatData.getCatById(data.activeCatId) then
		data.activeCatId = CatData.getDefaultCatId()
	end
	CatManager.pushAppearanceUpdate(player)
	-- 註：視覺更新現在由 GameServer 監聽 CharacterAppearanceLoaded 並調用 CatAppearance.apply 處理
end

function CatManager.pushAppearanceUpdate(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	local tier = CatData.getGrowthTier(data.activeCatId, data.level)
	updateCatEvent:FireClient(player, data.activeCatId, tier.appearance, data.level, tier.description)
end

function CatManager.checkAppearanceUpgrade(player: Player)
	local data = DataStore.getData(player)
	if not data then return end
	-- 取得前一等級的分階與現在等級的分階，不同時才更新
	local prevTier = CatData.getGrowthTier(data.activeCatId, data.level - 1)
	local currTier = CatData.getGrowthTier(data.activeCatId, data.level)
	if prevTier.appearance ~= currTier.appearance then
		CatManager.pushAppearanceUpdate(player)
	end
end

function CatManager.handleSelectCat(player: Player, catId: string)
	local data = DataStore.getData(player)
	if not data then return end
	if not data.ownedCats[catId] then
		warn("[CatManager] 玩家", player.Name, "未擁有貓咪：", catId)
		return
	end
	if not CatData.getCatById(catId) then
		warn("[CatManager] 無效的 catId：", catId)
		return
	end
	data.activeCatId = catId
	CatManager.pushAppearanceUpdate(player)
	applyBasicCatVisual(player, catId)

	-- 重新初始化固有技能
	local SkillManager = require(script.Parent.SkillManager)
	SkillManager.initInnateSkills(player)
end

local SYNTHESIS_COST = 10  -- 合成所需碎片數

function CatManager.synthesizeCat(player: Player, catId: string)
	local data = DataStore.getData(player)
	if not data then return false, "資料讀取失敗。" end
	if not CatData.getCatById(catId) then return false, "無效的貓咪 ID。" end
	if data.ownedCats[catId] then return false, "你已擁有這隻貓咪了！" end

	data.catFragments = data.catFragments or {}
	local frags = data.catFragments[catId] or 0
	if frags < SYNTHESIS_COST then
		return false, string.format("碎片不足！需要 %d 片，目前只有 %d 片。", SYNTHESIS_COST, frags)
	end

	data.catFragments[catId] = frags - SYNTHESIS_COST
	data.ownedCats[catId] = true
	DataStore.savePlayer(player)

	local cat = CatData.getCatById(catId)
	return true, "恭喜合成「" .. (cat and cat.displayName or catId) .. "」！"
end

function CatManager.getActiveCat(player: Player)
	local data = DataStore.getData(player)
	if not data then return CatData.getCatById("whiteCat") end
	return CatData.getCatById(data.activeCatId)
end

return CatManager
