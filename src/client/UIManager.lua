local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillData = require(ReplicatedStorage.Shared.SkillData)
local EquipmentData = require(ReplicatedStorage.Shared.EquipmentData)
local CatData = require(ReplicatedStorage.Shared.CatData)

local UIManager = {}

local screenGui: ScreenGui
local xpBar: Frame
local xpFill: Frame
local levelLabel: TextLabel
local coinLabel: TextLabel
local catLabel: TextLabel
local skillButtons: { [string]: ImageButton } = {}
local toastLabel: TextLabel
local shopPanel: Frame?
local equipPanel: Frame?
local cachedFragments: { [string]: number } = {}
local cachedEquipment: { [string]: string? } = {}

-- ── 基礎建構函數 ─────────────────────────────────────────────────

local function getRemote(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild(name) :: RemoteEvent
end
local function getFunction(name: string): RemoteFunction
	return ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild(name) :: RemoteFunction
end

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

local function createButton(parent: Instance, text: string, pos: UDim2, size: UDim2,
	color: Color3?, textColor: Color3?): TextButton
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Text = text
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = color or Color3.fromRGB(60, 120, 200)
	btn.TextColor3 = textColor or Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	return btn
end

-- ── 主初始化 ─────────────────────────────────────────────────────

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

	coinLabel = createLabel(screenGui, "金幣: 0",
		UDim2.new(0.01, 0, 0.01, 0),
		UDim2.new(0.2, 0, 0.04, 0), 18)

	catLabel = createLabel(screenGui, "白貓 — 幼貓",
		UDim2.new(0.01, 0, 0.06, 0),
		UDim2.new(0.25, 0, 0.04, 0), 16)

	-- 浮動通知
	toastLabel = createLabel(screenGui, "",
		UDim2.new(0.3, 0, 0.4, 0),
		UDim2.new(0.4, 0, 0.08, 0), 24)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	toastLabel.TextTransparency = 1

	-- 技能列
	UIManager.buildSkillBar(playerData and playerData.unlockedSkills or {})

	-- 底部功能按鈕
	UIManager.buildMenuButtons()

	if playerData then
		cachedEquipment = playerData.equipment or {}
		cachedFragments = playerData.catFragments or {}
		local required = require(ReplicatedStorage.Shared.GameConfig).XP_TABLE[playerData.level]
		UIManager.updateXPBar(playerData.xp, required, playerData.level)
		UIManager.updateCoinDisplay(playerData.coins)
	end
end

-- ── 底部選單按鈕 ─────────────────────────────────────────────────

function UIManager.buildMenuButtons()
	-- 商城按鈕（右下）
	local shopBtn = createButton(screenGui, "🛒 商城",
		UDim2.new(0.85, 0, 0.88, 0),
		UDim2.new(0.13, 0, 0.055, 0),
		Color3.fromRGB(180, 100, 20))
	shopBtn.MouseButton1Click:Connect(function()
		UIManager.openShopPanel()
	end)

	-- 裝備按鈕（左下）
	local equipBtn = createButton(screenGui, "⚔ 裝備",
		UDim2.new(0.01, 0, 0.88, 0),
		UDim2.new(0.13, 0, 0.055, 0),
		Color3.fromRGB(60, 80, 160))
	equipBtn.MouseButton1Click:Connect(function()
		UIManager.openEquipPanel()
	end)
end

-- ── 商城面板 ─────────────────────────────────────────────────────

local function closePanel(panel: Frame?)
	if panel then panel:Destroy() end
end

local function buildPanelBase(title: string): (Frame, Frame, () -> ())
	-- 半透明遮罩
	local overlay = createFrame(screenGui,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
		Color3.new(0, 0, 0), 0.5)
	overlay.ZIndex = 20

	-- 主面板
	local panel = createFrame(overlay,
		UDim2.new(0.05, 0, 0.05, 0), UDim2.new(0.9, 0, 0.9, 0),
		Color3.fromRGB(20, 20, 35), 0.05)
	panel.ZIndex = 21

	-- 標題
	local titleLbl = createLabel(panel, title,
		UDim2.new(0.03, 0, 0.01, 0), UDim2.new(0.7, 0, 0.08, 0), 24)
	titleLbl.ZIndex = 22

	-- 關閉按鈕
	local closeBtn = createButton(panel, "✕ 關閉",
		UDim2.new(0.78, 0, 0.01, 0), UDim2.new(0.2, 0, 0.08, 0),
		Color3.fromRGB(180, 40, 40))
	closeBtn.ZIndex = 22
	local function doClose()
		overlay:Destroy()
	end
	closeBtn.MouseButton1Click:Connect(doClose)

	-- 捲動內容區
	local scroll = Instance.new("ScrollingFrame")
	scroll.Parent = panel
	scroll.Position = UDim2.new(0, 0, 0.11, 0)
	scroll.Size = UDim2.new(1, 0, 0.89, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 8
	scroll.BorderSizePixel = 0
	scroll.ZIndex = 22

	local layout = Instance.new("UIListLayout")
	layout.Parent = scroll
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local padding = Instance.new("UIPadding")
	padding.Parent = scroll
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 6)

	-- 內容更新後自動調整 CanvasSize
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
	end)

	return overlay, scroll, doClose
end

-- 建立一張物品卡片（行容器）
local function buildCard(parent: Frame, name: string, desc: string, rightText: string,
	btnText: string, btnColor: Color3, onBuy: (() -> ())?): Frame
	local card = createFrame(parent,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 70),
		Color3.fromRGB(35, 35, 55), 0.1)
	card.ZIndex = 23

	local nameLbl = createLabel(card, name,
		UDim2.new(0.02, 0, 0.05, 0), UDim2.new(0.55, 0, 0.45, 0), 16)
	nameLbl.ZIndex = 24

	local descLbl = createLabel(card, desc,
		UDim2.new(0.02, 0, 0.52, 0), UDim2.new(0.55, 0, 0.4, 0), 12)
	descLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLbl.Font = Enum.Font.Gotham
	descLbl.ZIndex = 24

	local rightLbl = createLabel(card, rightText,
		UDim2.new(0.58, 0, 0.05, 0), UDim2.new(0.2, 0, 0.9, 0), 13)
	rightLbl.TextXAlignment = Enum.TextXAlignment.Center
	rightLbl.ZIndex = 24

	if onBuy then
		local btn = createButton(card, btnText,
			UDim2.new(0.8, 0, 0.12, 0), UDim2.new(0.18, 0, 0.76, 0),
			btnColor)
		btn.TextSize = 13
		btn.ZIndex = 24
		btn.MouseButton1Click:Connect(onBuy)
	else
		local statusLbl = createLabel(card, btnText,
			UDim2.new(0.8, 0, 0.12, 0), UDim2.new(0.18, 0, 0.76, 0), 13)
		statusLbl.TextXAlignment = Enum.TextXAlignment.Center
		statusLbl.TextColor3 = Color3.fromRGB(100, 220, 100)
		statusLbl.ZIndex = 24
	end

	return card
end

function UIManager.openShopPanel()
	if shopPanel then shopPanel:Destroy() end
	local playerData = getFunction("GetPlayerData"):InvokeServer()
	if not playerData then return end
	cachedEquipment = playerData.equipment or {}
	cachedFragments = playerData.catFragments or {}

	local overlay, scroll, _ = buildPanelBase("🛒 商城")
	shopPanel = overlay

	-- Tab 按鈕列
	local panel = overlay:FindFirstChildOfClass("Frame")
	local tabBar = createFrame(panel,
		UDim2.new(0, 0, 0.09, 0), UDim2.new(1, 0, 0.1, 0),
		Color3.new(0, 0, 0), 1)
	tabBar.ZIndex = 22

	local function clearScroll()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
	end

	local function showCatsTab()
		clearScroll()
		local catalog = getFunction("GetShopCatalog"):InvokeServer()
		for i, cat in ipairs(catalog or {}) do
			local owned = playerData.ownedCats and playerData.ownedCats[cat.id]
			local rightText = cat.price .. " RB"
			if owned then
				buildCard(scroll, cat.displayName, cat.description, rightText, "✓ 已擁有", Color3.new(0,0,0))
			else
				buildCard(scroll, cat.displayName, cat.description, rightText, "購買",
					Color3.fromRGB(180, 100, 20), function()
						getRemote("PurchaseCat"):FireServer(cat.id)
					end)
			end
			local card = scroll:GetChildren()[i]
			if card then (card :: Frame).LayoutOrder = i end
		end
	end

	local function showEquipTab()
		clearScroll()
		local slots = { collar = "項圈", hat = "帽子", weapon = "武器" }
		local order = 0
		for slotId, slotName in pairs(slots) do
			local items = EquipmentData.getItemsBySlot(slotId)
			table.sort(items, function(a, b) return a.price < b.price end)
			for _, item in ipairs(items) do
				order += 1
				local equipped = cachedEquipment[slotId] == item.id
				local stats = string.format("+ATK%d +DEF%d +HP%d",
					item.statBonus.attack, item.statBonus.defense, item.statBonus.maxHp)
				local rightText = slotName .. "\n" .. stats
				local card
				if equipped then
					card = buildCard(scroll, item.displayName, item.description, rightText, "✓ 已裝備", Color3.new(0,0,0))
					-- 卸下按鈕
					local unequipBtn = createButton(card, "卸下",
						UDim2.new(0.8, 0, 0.55, 0), UDim2.new(0.18, 0, 0.38, 0),
						Color3.fromRGB(120, 40, 40))
					unequipBtn.TextSize = 12
					unequipBtn.ZIndex = 24
					unequipBtn.MouseButton1Click:Connect(function()
						getRemote("UnequipItem"):FireServer(slotId)
						cachedEquipment[slotId] = nil
						UIManager.openShopPanel()  -- 重開刷新
					end)
				else
					card = buildCard(scroll, item.displayName,
						item.description,
						rightText,
						item.price .. "金",
						Color3.fromRGB(60, 140, 60), function()
							getRemote("BuyEquipment"):FireServer(item.id)
							task.delay(0.3, function() UIManager.openShopPanel() end)
						end)
				end
				if card then card.LayoutOrder = order end
			end
		end
	end

	local function showSynthesisTab()
		clearScroll()
		local specialCats = {
			"shadowCat", "flameCat", "frostCat", "thunderCat",
			"sakuraCat", "orangeCat", "calicoCat", "tuxedoCat",
		}
		for i, catId in ipairs(specialCats) do
			local cat = CatData.getCatById(catId)
			if not cat then continue end
			local frags = cachedFragments[catId] or 0
			local owned = playerData.ownedCats and playerData.ownedCats[catId]
			local fragText = string.format("碎片 %d / 10", frags)
			local card
			if owned then
				card = buildCard(scroll, cat.displayName, cat.description, fragText, "✓ 已擁有", Color3.new(0,0,0))
			elseif frags >= 10 then
				card = buildCard(scroll, cat.displayName, cat.description, fragText, "合成！",
					Color3.fromRGB(150, 60, 200), function()
						getRemote("SynthesizeCat"):FireServer(catId)
						task.delay(0.5, function() UIManager.openShopPanel() end)
					end)
			else
				card = buildCard(scroll, cat.displayName, cat.description, fragText, "待收集", Color3.new(0,0,0))
			end
			if card then card.LayoutOrder = i end
		end
	end

	-- Tab 建立
	local tabs = {
		{ name = "貓咪", fn = showCatsTab },
		{ name = "裝備", fn = showEquipTab },
		{ name = "合成", fn = showSynthesisTab },
	}
	scroll.Position = UDim2.new(0, 0, 0.21, 0)
	scroll.Size = UDim2.new(1, 0, 0.79, 0)

	for i, tab in ipairs(tabs) do
		local btn = createButton(tabBar, tab.name,
			UDim2.new((i - 1) / 3, 0, 0, 0), UDim2.new(1 / 3, 0, 1, 0),
			Color3.fromRGB(40, 40, 70))
		btn.ZIndex = 23
		btn.MouseButton1Click:Connect(tab.fn)
	end

	showCatsTab()  -- 預設開貓咪 tab
end

-- ── 裝備面板（獨立快速查看） ──────────────────────────────────────

function UIManager.openEquipPanel()
	if equipPanel then equipPanel:Destroy() end
	local playerData = getFunction("GetPlayerData"):InvokeServer()
	if not playerData then return end
	cachedEquipment = playerData.equipment or {}

	local overlay, scroll, _ = buildPanelBase("⚔ 目前裝備")
	equipPanel = overlay

	local SLOTS = {
		{ id = "collar", name = "項圈" },
		{ id = "hat",    name = "帽子" },
		{ id = "weapon", name = "武器" },
	}
	for i, slot in ipairs(SLOTS) do
		local equippedId = cachedEquipment[slot.id]
		local item = equippedId and EquipmentData.getItemById(equippedId)
		local name = slot.name .. "：" .. (item and item.displayName or "（空）")
		local desc = item and item.description or "尚未裝備任何物品"
		local stats = item and string.format("ATK+%d DEF+%d HP+%d SPD+%d",
			item.statBonus.attack, item.statBonus.defense,
			item.statBonus.maxHp, item.statBonus.speed) or ""

		if item then
			local card = buildCard(scroll, name, desc, stats, "卸下",
				Color3.fromRGB(120, 40, 40), function()
					getRemote("UnequipItem"):FireServer(slot.id)
					task.delay(0.3, function() UIManager.openEquipPanel() end)
				end)
			card.LayoutOrder = i
		else
			local card = buildCard(scroll, name, desc, "", "→ 商城",
				Color3.fromRGB(60, 120, 200), function()
					if equipPanel then equipPanel:Destroy() end
					UIManager.openShopPanel()
				end)
			card.LayoutOrder = i
		end
	end
end

-- ── XP / 等級 / 貓咪資訊 ─────────────────────────────────────────

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
		local cat = CatData.getCatById(catId)
		local name = cat and cat.displayName or catId
		catLabel.Text = name .. " — " .. tierDesc
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

-- 收到碎片掉落通知
function UIManager.updateFragments(catId: string, count: number)
	cachedFragments[catId] = count
	local cat = CatData.getCatById(catId)
	local name = cat and cat.displayName or catId
	UIManager.showToast("✨ 獲得「" .. name .. "」碎片！（" .. count .. "/10）",
		Color3.fromRGB(200, 150, 255))
end

-- 合成結果
function UIManager.showSynthesisResult(success: boolean, message: string)
	local color = success and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(220, 80, 80)
	UIManager.showToast(message, color)
end

-- 裝備變更時快取更新
function UIManager.onEquipmentChanged(loadout: any)
	if loadout then
		cachedEquipment = loadout
	end
end

-- ── 技能列 ───────────────────────────────────────────────────────

function UIManager.showSkillUnlockedNotice(skillId: string, skillDef: any)
	local name = skillDef and skillDef.displayName or skillId
	UIManager.showToast("✨ 解鎖技能：" .. name, Color3.fromRGB(150, 200, 255))
	UIManager.buildSkillBar(nil)
end

function UIManager.buildSkillBar(unlockedSkills: { [string]: boolean }?)
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
			UDim2.new(0.15 + xOffset, 0, 0.82, 0),
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

-- ── 死亡畫面 ─────────────────────────────────────────────────────

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
	local overlay = screenGui and screenGui:FindFirstChild("DeathOverlay")
	if overlay then overlay:Destroy() end
end

-- ── 浮動通知 ─────────────────────────────────────────────────────

function UIManager.showToast(message: string, color: Color3?)
	if not toastLabel then return end
	toastLabel.Text = message
	toastLabel.TextColor3 = color or Color3.new(1, 1, 1)
	toastLabel.TextTransparency = 0

	local fadeOut = TweenService:Create(toastLabel,
		TweenInfo.new(0.5), { TextTransparency = 1 })
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
