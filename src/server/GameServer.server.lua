local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

local DataStore = require(script.Parent.DataStore)
local ExperienceManager = require(script.Parent.ExperienceManager)
local CatManager = require(script.Parent.CatManager)
local NPCManager = require(script.Parent.NPCManager)
local ShopManager = require(script.Parent.ShopManager)
local EquipmentManager = require(script.Parent.EquipmentManager)
local SkillManager = require(script.Parent.SkillManager)
local PvPManager = require(script.Parent.PvPManager)

-- 跨模組依賴注入
ExperienceManager._catManager = CatManager
ExperienceManager._skillManager = SkillManager
NPCManager._experienceManager = ExperienceManager
NPCManager._skillManager = SkillManager
PvPManager._equipmentManager = EquipmentManager

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- 取得各個 RemoteEvent
local function getEvent(name: string)
	return remoteEvents:WaitForChild(name) :: RemoteEvent
end
local function getFunction(name: string)
	return remoteFunctions:WaitForChild(name) :: RemoteFunction
end

-- 監聽伺服器腳本錯誤（方便定位實際報錯檔案與內容）
ScriptContext.Error:Connect(function(message: string, stackTrace: string, scriptInstance: Instance?)
	local scriptName = scriptInstance and scriptInstance:GetFullName() or "UnknownScript"
	warn(string.format("[ServerError] %s | %s", scriptName, message))
	if stackTrace ~= "" then
		warn("[ServerErrorStack] " .. stackTrace)
	end
end)

-- 初始化商店
local okShop, shopErr = pcall(function()
	ShopManager.init()
end)
if not okShop then
	warn("[ServerBootstrap] ShopManager.init 失敗：" .. tostring(shopErr))
end

-- 啟動 NPC 生成迴圈
local okSpawn, spawnErr = pcall(function()
	NPCManager.startSpawnLoop()
end)
if not okSpawn then
	warn("[ServerBootstrap] NPCManager.startSpawnLoop 失敗：" .. tostring(spawnErr))
end

-- 啟動自檢：確認 NPC 是否成功生成
task.delay(3, function()
	local okCount, npcCountOrErr = pcall(function()
		return NPCManager.getActiveNPCCount()
	end)
	if not okCount then
		warn("[ServerBootstrap] 讀取 NPC 數量失敗：" .. tostring(npcCountOrErr))
		return
	end

	local npcCount = npcCountOrErr :: number
	if npcCount <= 0 then
		warn("[ServerBootstrap] NPC 生成失敗：3 秒後仍為 0。請確認 Play 模式、Rojo 同步、Server Output 中的 [ServerError]。")
	else
		print(string.format("[ServerBootstrap] NPC 生成成功，目前數量：%d", npcCount))
	end
end)

-- ── 玩家加入 / 離開 ──────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player: Player)
	local data = DataStore.loadPlayer(player)

	SkillManager.initPlayer(player)
	SkillManager.initInnateSkills(player)
	CatManager.initPlayer(player)

	-- 通知客戶端資料已就緒
	getEvent("LoadDataResponse"):FireClient(player, data)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	PvPManager.cleanupPlayer(player)
	DataStore.savePlayer(player)
	DataStore.clearCache(player)
	SkillManager.initPlayer(player)  -- 清空冷卻記憶
end)

-- ── 自動存檔 ────────────────────────────────────────────────────
task.spawn(function()
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	while true do
		task.wait(GameConfig.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			DataStore.savePlayer(player)
		end
	end
end)

-- ── RemoteEvent 路由 ────────────────────────────────────────────
getEvent("RequestLoadData").OnServerEvent:Connect(function(player: Player)
	local data = DataStore.getData(player)
	if data then
		getEvent("LoadDataResponse"):FireClient(player, data)
	end
end)

getEvent("SelectCat").OnServerEvent:Connect(function(player: Player, catId: string)
	CatManager.handleSelectCat(player, catId)
end)

getEvent("EquipItem").OnServerEvent:Connect(function(player: Player, itemId: string)
	EquipmentManager.handleEquip(player, itemId)
end)

getEvent("UnequipItem").OnServerEvent:Connect(function(player: Player, slot: string)
	EquipmentManager.handleUnequip(player, slot)
end)

getEvent("UseSkill").OnServerEvent:Connect(function(player: Player, skillId: string, targetInstanceId: string?)
	SkillManager.handleUseSkill(player, skillId, targetInstanceId, NPCManager, EquipmentManager)
end)

getEvent("PurchaseCat").OnServerEvent:Connect(function(player: Player, catId: string)
	ShopManager.handlePurchaseRequest(player, catId)
end)

getEvent("RequestPvP").OnServerEvent:Connect(function(player: Player, targetUserId: number)
	PvPManager.handleChallenge(player, targetUserId)
end)

getEvent("PvPAccepted").OnServerEvent:Connect(function(player: Player, challengerUserId: number)
	PvPManager.handleAccept(player, challengerUserId)
end)

-- ── RemoteFunction 路由 ─────────────────────────────────────────
getFunction("GetPlayerData").OnServerInvoke = function(player: Player)
	return DataStore.getData(player)
end

getFunction("GetShopCatalog").OnServerInvoke = function(_player: Player)
	return ShopManager.getCatalog()
end
