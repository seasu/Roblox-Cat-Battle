local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillData = require(ReplicatedStorage.Shared.SkillData)
local EquipmentData = require(ReplicatedStorage.Shared.EquipmentData)

local UIManager = {}

local screenGui: ScreenGui
local xpBar: Frame
local xpFill: Frame
local levelLabel: TextLabel
local coinLabel: TextLabel
local catLabel: TextLabel
local skillButtons: { [string]: ImageButton } = {}
local toastLabel: TextLabel

local function createLabel(parent: Instance, text: string, pos: UDim2, size: UDim2, fontSize: number?): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Parent = parent
	lbl.Text = text
	lbl.Position = pos
	lbl.Size = size
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.5
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = fontSize or 18
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function createFrame(parent: Instance, pos: UDim2, size: UDim2, color: Color3?, alpha: number?): Frame
	local f = Instance.new("Frame")
	f.Parent = parent
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = color or Color3.new(0, 0, 0)
	f.BackgroundTransparency = alpha or 0.5
	f.BorderSizePixel = 0
	return f
end

function UIManager.init(playerData: any)
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CatBattleUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	-- XP 條底框
	local xpBg = createFrame(screenGui,
		UDim2.new(0.3, 0, 0.93, 0),
		UDim2.new(0.4, 0, 0.04, 0),
		Color3.fromRGB(30, 30, 30), 0.3)

	xpFill = createFrame(xpBg,
		UDim2.new(0, 0, 0, 0),
		UDim2.new(0, 0, 1, 0),
		Color3.fromRGB(80, 200, 100), 0)

	xpBar = xpBg

	levelLabel = createLabel(screenGui, "Lv.1",
		UDim2.new(0.3, 0, 0.88, 0),
		UDim2.new(0.1, 0, 0.04, 0), 22)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Center

	coinLabel = createLabel(screenGui, "🪙 0",
		UDim2.new(0.01, 0, 0.01, 0),
		UDim2.new(0.15, 0, 0.04, 0), 18)

	catLabel = createLabel(screenGui, "白貓 — 幼貓",
		UDim2.new(0.01, 0, 0.06, 0),
		UDim2.new(0.25, 0, 0.04, 0), 16)

	-- 浮動通知
	toastLabel = createLabel(screenGui, "",
		UDim2.new(0.3, 0, 0.4, 0),
		UDim2.new(0.4, 0, 0.08, 0), 24)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	toastLabel.TextTransparency = 1

	-- 技能列（底部）
	UIManager.buildSkillBar(playerData and playerData.unlockedSkills or {})

	-- 初始更新
	if playerData then
		local required = require(ReplicatedStorage.Shared.GameConfig).XP_TABLE[playerData.level]
		UIManager.updateXPBar(playerData.xp, required, playerData.level)
		UIManager.updateCoinDisplay(playerData.coins)
	end
end

function UIManager.updateXPBar(current: number, max: number, level: number)
	if not xpFill then return end
	levelLabel.Text = "Lv." .. level
	local ratio = max > 0 and math.clamp(current / max, 0, 1) or 0
	local tween = TweenService:Create(xpFill,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(ratio, 0, 1, 0) })
	tween:Play()
end

function UIManager.showLevelUpEffect(newLevel: number)
	UIManager.showToast("⬆ 升級！現在是 Lv." .. newLevel, Color3.fromRGB(255, 220, 50))
end

function UIManager.refreshCatDisplay(catId: string, appearance: string, level: number, tierDesc: string)
	if catLabel then
		local CatData = require(ReplicatedStorage.Shared.CatData)
		local cat = CatData.getCatById(catId)
		local name = cat and cat.displayName or catId
		catLabel.Text = name .. " — " .. tierDesc .. "（" .. appearance .. "）"
	end
end

function UIManager.updateCoinDisplay(coins: number)
	if coinLabel then
		coinLabel.Text = "金幣: " .. coins
	end
end

function UIManager.showPurchaseResult(success: boolean, message: string)
	local color = success and Color3.fromRGB(100, 220, 100) or Color3.fromRGB(220, 80, 80)
	UIManager.showToast(message, color)
end

function UIManager.showSkillUnlockedNotice(skillId: string, skillDef: any)
	local name = skillDef and skillDef.displayName or skillId
	UIManager.showToast("✨ 解鎖技能：" .. name, Color3.fromRGB(150, 200, 255))
	UIManager.buildSkillBar(nil)  -- 重建技能列（傳 nil 讓其從 RemoteFunction 重抓）
end

function UIManager.buildSkillBar(unlockedSkills: { [string]: boolean }?)
	-- 清除舊技能按鈕
	for _, btn in pairs(skillButtons) do
		btn:Destroy()
	end
	skillButtons = {}

	if not unlockedSkills then return end

	local slotIndex = 0
	local keys = { "滑鼠", "Q", "E", "R", "F", "T" }

	for skillId in pairs(unlockedSkills) do
		local skill = SkillData.getSkillById(skillId)
		if not skill or skill.isPassive then continue end

		slotIndex += 1
		local xOffset = (slotIndex - 1) * 0.08

		local bg = createFrame(screenGui,
			UDim2.new(0.1 + xOffset, 0, 0.82, 0),
			UDim2.new(0.07, 0, 0.07, 0),
			Color3.fromRGB(40, 40, 60), 0.2)

		local nameLabel = createLabel(bg, skill.displayName,
			UDim2.new(0, 0, 0, 0),
			UDim2.new(1, 0, 0.5, 0), 11)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center

		local keyLabel = createLabel(bg, (keys[slotIndex] or tostring(slotIndex)),
			UDim2.new(0, 0, 0.5, 0),
			UDim2.new(1, 0, 0.5, 0), 14)
		keyLabel.TextXAlignment = Enum.TextXAlignment.Center
		keyLabel.TextColor3 = Color3.fromRGB(200, 200, 100)

		skillButtons[skillId] = bg :: any

		if slotIndex >= 6 then break end
	end
end

function UIManager.updateSkillCooldown(skillId: string, remaining: number)
	local btn = skillButtons[skillId]
	if not btn then return end
	local overlay = btn:FindFirstChild("CooldownOverlay")
	if remaining > 0 then
		if not overlay then
			overlay = createFrame(btn, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
				Color3.fromRGB(0, 0, 0), 0.5)
			overlay.Name = "CooldownOverlay"
			local cdLabel = createLabel(overlay, "", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), 16)
			cdLabel.Name = "CDLabel"
			cdLabel.TextXAlignment = Enum.TextXAlignment.Center
		end
		local cdLabel = overlay:FindFirstChild("CDLabel")
		if cdLabel then
			(cdLabel :: TextLabel).Text = string.format("%.1f", remaining)
		end
	else
		if overlay then overlay:Destroy() end
	end
end

function UIManager.showDeathScreen()
	local overlay = createFrame(screenGui,
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 1, 0),
		Color3.fromRGB(0, 0, 0), 0.6)
	overlay.Name = "DeathOverlay"
	overlay.ZIndex = 10

	createLabel(overlay, "你已陣亡...",
		UDim2.new(0.3, 0, 0.4, 0),
		UDim2.new(0.4, 0, 0.1, 0), 36).ZIndex = 11
end

function UIManager.hideDeathScreen()
	local overlay = screenGui:FindFirstChild("DeathOverlay")
	if overlay then overlay:Destroy() end
end

function UIManager.showToast(message: string, color: Color3?)
	if not toastLabel then return end
	toastLabel.Text = message
	toastLabel.TextColor3 = color or Color3.new(1, 1, 1)
	toastLabel.TextTransparency = 0

	local fadeIn = TweenService:Create(toastLabel,
		TweenInfo.new(0.2), { TextTransparency = 0 })
	local fadeOut = TweenService:Create(toastLabel,
		TweenInfo.new(0.5), { TextTransparency = 1 })

	fadeIn:Play()
	task.delay(2, function()
		fadeOut:Play()
	end)
end

function UIManager.showPvPResult(won: boolean, opponentName: string, xpGained: number, coinsGained: number)
	local msg: string
	if won then
		msg = "勝利！擊敗 " .. opponentName .. "，獲得 +" .. xpGained .. " XP, +" .. coinsGained .. " 金幣"
	else
		msg = "敗北！輸給了 " .. opponentName
	end
	UIManager.showToast(msg, won and Color3.fromRGB(100, 220, 100) or Color3.fromRGB(220, 100, 100))
end

return UIManager
