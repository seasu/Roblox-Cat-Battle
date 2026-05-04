local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local Types = require(game.ReplicatedStorage.Shared.Types)
type PlayerData = Types.PlayerData

local DataStore = {}

local store = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
local cache: { [number]: PlayerData } = {}

local function retryAsync(fn: () -> any, maxRetries: number): (boolean, any)
	local tries = 0
	repeat
		tries += 1
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn("[DataStore] 重試第", tries, "次，錯誤：", result)
		if tries < maxRetries then
			task.wait(2 ^ tries)
		end
	until tries >= maxRetries
	return false, nil
end

function DataStore.getDefaultData(player: Player): PlayerData
	return {
		playerId = player.UserId,
		level = 1,
		xp = 0,
		coins = 0,
		ownedCats = { whiteCat = true },
		activeCatId = "whiteCat",
		equipment = { collar = nil, hat = nil, weapon = nil },
		unlockedSkills = { BasicSwipe = true },
		catFragments = {},
		activeColorShiftMode = nil,
		createdAt = os.time(),
		lastSeen = os.time(),
	}
end

function DataStore.loadPlayer(player: Player): PlayerData
	local key = "player_" .. player.UserId
	local ok, saved = retryAsync(function()
		return store:GetAsync(key)
	end, 4)

	local data: PlayerData
	if ok and saved then
		data = saved :: PlayerData
		data.lastSeen = os.time()
	else
		data = DataStore.getDefaultData(player)
	end

	cache[player.UserId] = data
	return data
end

function DataStore.savePlayer(player: Player): boolean
	local data = cache[player.UserId]
	if not data then
		return false
	end
	data.lastSeen = os.time()
	local key = "player_" .. player.UserId
	local ok, _ = retryAsync(function()
		store:SetAsync(key, data)
	end, 4)
	return ok
end

function DataStore.getData(player: Player): PlayerData?
	return cache[player.UserId]
end

function DataStore.setData(player: Player, data: PlayerData)
	cache[player.UserId] = data
end

function DataStore.clearCache(player: Player)
	cache[player.UserId] = nil
end

return DataStore
