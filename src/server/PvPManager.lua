local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataStore = require(script.Parent.DataStore)

local PvPManager = {}

PvPManager._equipmentManager = nil :: any

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local pvpInviteEvent = remoteEvents:WaitForChild("PvPInvite")
local pvpResultEvent = remoteEvents:WaitForChild("PvPResult")
local combatHitEvent = remoteEvents:WaitForChild("CombatHit")

-- 待處理的挑戰：pendingChallenges[targetUserId] = challengerPlayer
local pendingChallenges: { [number]: Player } = {}

-- 進行中的對戰：activePvP[userId] = opponentUserId
local activePvP: { [number]: number } = {}

function PvPManager.handleChallenge(challenger: Player, targetUserId: number)
	if activePvP[challenger.UserId] then
		warn("[PvPManager] 玩家", challenger.Name, "已在對戰中")
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return end
	if activePvP[targetUserId] then return end

	pendingChallenges[targetUserId] = challenger
	pvpInviteEvent:FireClient(target, challenger.UserId, challenger.Name)

	-- 15 秒後若未接受則取消
	task.delay(15, function()
		if pendingChallenges[targetUserId] == challenger then
			pendingChallenges[targetUserId] = nil
		end
	end)
end

function PvPManager.handleAccept(target: Player, challengerUserId: number)
	local challenger = pendingChallenges[target.UserId]
	if not challenger or challenger.UserId ~= challengerUserId then return end
	pendingChallenges[target.UserId] = nil

	if activePvP[target.UserId] or activePvP[challenger.UserId] then return end

	activePvP[target.UserId] = challenger.UserId
	activePvP[challenger.UserId] = target.UserId

	PvPManager.runCombat(challenger, target)
end

function PvPManager.runCombat(playerA: Player, playerB: Player)
	if not PvPManager._equipmentManager then return end

	local statsA = PvPManager._equipmentManager.getTotalStats(playerA)
	local statsB = PvPManager._equipmentManager.getTotalStats(playerB)

	local hpA = statsA.maxHp
	local hpB = statsB.maxHp
	local maxRounds = 30

	task.spawn(function()
		for _ = 1, maxRounds do
			if not Players:GetPlayerByUserId(playerA.UserId) or not Players:GetPlayerByUserId(playerB.UserId) then
				break
			end

			-- A 攻擊 B
			local dmgA = math.max(1, statsA.attack - statsB.defense)
			local critA = math.random() < statsA.critChance
			if critA then dmgA = math.floor(dmgA * GameConfig.CRIT_MULTIPLIER) end
			hpB -= dmgA
			combatHitEvent:FireClient(playerB, "pvp", Vector3.new(0, 5, 0), dmgA, critA)

			if hpB <= 0 then
				PvPManager.endPvP(playerA, playerB)
				return
			end

			-- B 攻擊 A
			local dmgB = math.max(1, statsB.attack - statsA.defense)
			local critB = math.random() < statsB.critChance
			if critB then dmgB = math.floor(dmgB * GameConfig.CRIT_MULTIPLIER) end
			hpA -= dmgB
			combatHitEvent:FireClient(playerA, "pvp", Vector3.new(0, 5, 0), dmgB, critB)

			if hpA <= 0 then
				PvPManager.endPvP(playerB, playerA)
				return
			end

			task.wait(GameConfig.PVP_TICK_INTERVAL)
		end

		-- 超過回合限制：HP 較高者勝
		if hpA >= hpB then
			PvPManager.endPvP(playerA, playerB)
		else
			PvPManager.endPvP(playerB, playerA)
		end
	end)
end

function PvPManager.endPvP(winner: Player, loser: Player)
	activePvP[winner.UserId] = nil
	activePvP[loser.UserId] = nil

	local winnerData = DataStore.getData(winner)
	if winnerData then
		winnerData.xp += GameConfig.PVP_XP_BONUS
		winnerData.coins += GameConfig.PVP_COIN_BONUS
	end

	pvpResultEvent:FireClient(winner, true, winner.Name, GameConfig.PVP_XP_BONUS, GameConfig.PVP_COIN_BONUS)
	pvpResultEvent:FireClient(loser, false, winner.Name, 0, 0)
end

function PvPManager.isInPvP(player: Player): boolean
	return activePvP[player.UserId] ~= nil
end

function PvPManager.cleanupPlayer(player: Player)
	pendingChallenges[player.UserId] = nil
	local opponentId = activePvP[player.UserId]
	if opponentId then
		activePvP[player.UserId] = nil
		activePvP[opponentId] = nil
		local opponent = Players:GetPlayerByUserId(opponentId)
		if opponent then
			pvpResultEvent:FireClient(opponent, true, opponent.Name, GameConfig.PVP_XP_BONUS, GameConfig.PVP_COIN_BONUS)
		end
	end
end

return PvPManager
