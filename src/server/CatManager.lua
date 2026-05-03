local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatData = require(ReplicatedStorage.Shared.CatData)
local DataStore = require(script.Parent.DataStore)

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

	-- 重新初始化固有技能
	local SkillManager = require(script.Parent.SkillManager)
	SkillManager.initInnateSkills(player)
end

function CatManager.getActiveCat(player: Player)
	local data = DataStore.getData(player)
	if not data then return CatData.getCatById("whiteCat") end
	return CatData.getCatById(data.activeCatId)
end

return CatManager
