local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local UIManager = require(script.Parent:WaitForChild("UIManager"))
local CombatClient = require(script.Parent:WaitForChild("CombatClient"))

local localPlayer = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local function getEvent(name: string): RemoteEvent
	return remoteEvents:WaitForChild(name) :: RemoteEvent
end

-- ── 等待角色生成 ─────────────────────────────────────────────────
local function onCharacterAdded(character: Model)
	character:WaitForChild("HumanoidRootPart")
	UIManager.hideDeathScreen()
	getEvent("RequestLoadData"):FireServer()
end

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ── 接收玩家資料並初始化 ─────────────────────────────────────────
getEvent("LoadDataResponse").OnClientEvent:Connect(function(playerData: any)
	UIManager.init(playerData)
	CombatClient.init()
	-- 初始化武器狀態
	if playerData and playerData.equipment then
		CombatClient.currentWeapon = playerData.equipment.weapon or nil
	end

	-- 建立技能列順序對應
	local slots: { string } = {}
	local skillDefs = require(ReplicatedStorage.Shared.SkillData).skills
	for skillId in pairs(playerData.unlockedSkills or {}) do
		local skill = skillDefs[skillId]
		if skill and not skill.isPassive then
			table.insert(slots, skillId)
		end
	end
	CombatClient.skillSlots = slots
end)

-- ── XP / 升級 ────────────────────────────────────────────────────
getEvent("AddXP").OnClientEvent:Connect(function(amount: number, newTotal: number, threshold: number, level: number)
	UIManager.updateXPBar(newTotal, threshold, level)
end)

getEvent("LevelUp").OnClientEvent:Connect(function(newLevel: number)
	UIManager.showLevelUpEffect(newLevel)
end)

-- ── 貓咪外觀更新 ─────────────────────────────────────────────────
getEvent("UpdateCatAppearance").OnClientEvent:Connect(function(
	catId: string, appearance: string, level: number, tierDesc: string
)
	UIManager.refreshCatDisplay(catId, appearance, level, tierDesc)
end)

-- ── 裝備變更 ─────────────────────────────────────────────────────
getEvent("EquipmentChanged").OnClientEvent:Connect(function(loadout: any)
	UIManager.onEquipmentChanged(loadout)
	-- 同步武器到 CombatClient，用於決定攻擊特效
	CombatClient.currentWeapon = loadout and loadout.weapon or nil
end)

-- ── 碎片掉落 ─────────────────────────────────────────────────────
getEvent("UpdateFragments").OnClientEvent:Connect(function(catId: string, count: number)
	UIManager.updateFragments(catId, count)
end)

-- ── 合成結果 ─────────────────────────────────────────────────────
getEvent("SynthesisResult").OnClientEvent:Connect(function(success: boolean, message: string)
	UIManager.showSynthesisResult(success, message)
end)

-- ── 技能系統 ─────────────────────────────────────────────────────
getEvent("SkillResult").OnClientEvent:Connect(function(
	skillId: string, targets: { string }, damage: number, cooldown: number, extra: string?
)
	CombatClient.onSkillResult(skillId, targets, damage, cooldown, extra)
end)

getEvent("SkillUnlocked").OnClientEvent:Connect(function(skillId: string, skillDef: any)
	UIManager.showSkillUnlockedNotice(skillId, skillDef)

	-- 更新技能列
	if skillDef and not skillDef.isPassive then
		table.insert(CombatClient.skillSlots, skillId)
		UIManager.buildSkillBar(
			(function()
				local result: { [string]: boolean } = {}
				for _, sid in ipairs(CombatClient.skillSlots) do
					result[sid] = true
				end
				return result
			end)()
		)
	end
end)

-- ── 戰鬥命中特效 ─────────────────────────────────────────────────
getEvent("CombatHit").OnClientEvent:Connect(function(
	instanceId: string, position: Vector3, damage: number, isCrit: boolean
)
	CombatClient.showDamageNumber(position, damage, isCrit)
end)

-- ── NPC 死亡 ─────────────────────────────────────────────────────
getEvent("NPCDied").OnClientEvent:Connect(function(instanceId: string)
	CombatClient.onNPCDied(instanceId)
end)

-- ── 玩家死亡 ─────────────────────────────────────────────────────
getEvent("PlayerDied").OnClientEvent:Connect(function()
	UIManager.showDeathScreen()
end)

-- ── 商店結果 ─────────────────────────────────────────────────────
getEvent("PurchaseResult").OnClientEvent:Connect(function(success: boolean, message: string)
	UIManager.showPurchaseResult(success, message)
end)

-- ── 通用 UI 更新（金幣等） ───────────────────────────────────────
getEvent("UpdateUI").OnClientEvent:Connect(function(key: string, value: any)
	if key == "coins" then
		local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
		local playerData = (remoteFunctions:WaitForChild("GetPlayerData") :: RemoteFunction):InvokeServer()
		if playerData then
			UIManager.updateCoinDisplay(playerData.coins)
		end
	end
end)

-- ── 3D 商店攤位 ProximityPrompt ───────────────────────────────────
local function bindShopPrompts()
	local function tryBind(instance: Instance)
		if instance:IsA("ProximityPrompt") and instance.Name == "ShopPrompt" then
			local action = instance:GetAttribute("ShopAction")
			instance.Triggered:Connect(function()
				if action == "OpenShop" then
					UIManager.openShopPanel("cats")
				elseif action == "OpenEquip" then
					UIManager.openShopPanel("equip")
				elseif action == "OpenSynth" then
					UIManager.openShopPanel("synth")
				end
			end)
		end
	end

	-- 掃描已存在的 Prompt
	for _, desc in ipairs(workspace:GetDescendants()) do
		tryBind(desc)
	end
	-- 監聽後續新增（WorldSetup 是 server script，可能稍晚載入）
	workspace.DescendantAdded:Connect(tryBind)
end

bindShopPrompts()

-- ── PvP 相關 ─────────────────────────────────────────────────────
getEvent("PvPInvite").OnClientEvent:Connect(function(challengerUserId: number, challengerName: string)
	UIManager.showToast(challengerName .. " 向你發起挑戰！（自動接受）", Color3.fromRGB(255, 180, 50))
	-- 自動接受（實際遊戲中可改為彈出確認對話框）
	task.delay(2, function()
		getEvent("PvPAccepted"):FireServer(challengerUserId)
	end)
end)

getEvent("PvPResult").OnClientEvent:Connect(function(
	won: boolean, opponentName: string, xpGained: number, coinsGained: number
)
	UIManager.showPvPResult(won, opponentName, xpGained, coinsGained)
end)
