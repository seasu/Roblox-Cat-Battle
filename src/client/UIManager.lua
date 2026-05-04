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

	-- ── 左上角 HUD（固定像素高度，避免 scale 在手機端造成文字溢出重疊）──
	local hudBg = createFrame(screenGui,
		UDim2.new(0, 6, 0, 6),
		UDim2.new(0.27, 0, 0, 66),
		Color3.fromRGB(0, 0, 0), 0.45)
	hudBg.ZIndex = 2
	local hudCorner = Instance.new("UICorner")
	hudCorner.CornerRadius = UDim.new(0, 6)
	hudCorner.Parent = hudBg
	local hudPad = Instance.new("UIPadding")
	hudPad.PaddingLeft   = UDim.new(0, 8)
	hudPad.PaddingRight  = UDim.new(0, 10)
	hudPad.PaddingTop    = UDim.new(0, 6)
	hudPad.PaddingBottom = UDim.new(0, 6)
	hudPad.Parent = hudBg

	-- 金幣：固定 28px 高，文字不會溢出
	coinLabel = Instance.new("TextLabel")
	coinLabel.Text = "金幣: 0"
	coinLabel.Position = UDim2.new(0, 0, 0, 0)
	coinLabel.Size = UDim2.new(1, 0, 0, 28)
	coinLabel.AnchorPoint = Vector2.new(0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.TextColor3 = Color3.new(1, 1, 1)
	coinLabel.TextStrokeTransparency = 0.5
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextSize = 18
	coinLabel.TextScaled = false
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.ZIndex = 3
	coinLabel.Parent = hudBg

	-- 分隔線（讓兩行視覺上有明確間距）
	local divider = createFrame(hudBg,
		UDim2.new(0, 0, 0, 32),
		UDim2.new(1, 0, 0, 2),
		Color3.fromRGB(255, 255, 255), 0.85)
	divider.ZIndex = 3

	-- 貓咪名稱：固定 26px 高，第 36px 起
	catLabel = Instance.new("TextLabel")
	catLabel.Text = "白貓 — 幼貓"
	catLabel.Position = UDim2.new(0, 0, 0, 36)
	catLabel.Size = UDim2.new(1, 0, 0, 26)
	catLabel.AnchorPoint = Vector2.new(0, 0)
	catLabel.BackgroundTransparency = 1
	catLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	catLabel.TextStrokeTransparency = 0.5
	catLabel.Font = Enum.Font.Gotham
	catLabel.TextSize = 14
	catLabel.TextScaled = false
	catLabel.TextXAlignment = Enum.TextXAlignment.Left
	catLabel.ZIndex = 3
	catLabel.Parent = hudBg

	-- ── XP 條與等級（level label 移至 Y=0.905 避開技能列 Y=0.82~0.89）──
	local xpBg = createFrame(screenGui,
		UDim2.new(0.3, 0, 0.945, 0),
		UDim2.new(0.4, 0, 0.038, 0),
		Color3.fromRGB(30, 30, 30), 0.3)

	xpFill = createFrame(xpBg,
		UDim2.new(0, 0, 0, 0),
		UDim2.new(0, 0, 1, 0),
		Color3.fromRGB(80, 200, 100), 0)

	xpBar = xpBg

	-- 等級標籤：X=0.30~0.40，介於裝備和PvP按鈕之間，Y=0.900 在技能列（~0.89）之下
	levelLabel = createLabel(screenGui, "Lv.1",
		UDim2.new(0.3, 0, 0.900, 0),
		UDim2.new(0.1, 0, 0.040, 0), 22)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Center

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
		UIManager.openShopPanel("cats")
	end)

	-- 裝備按鈕（左下）— 直接開商城裝備 tab
	local equipBtn = createButton(screenGui, "⚔ 裝備",
		UDim2.new(0.01, 0, 0.88, 0),
		UDim2.new(0.13, 0, 0.055, 0),
		Color3.fromRGB(60, 80, 160))
	equipBtn.MouseButton1Click:Connect(function()
		UIManager.openShopPanel("equip")
	end)

	-- PvP 按鈕（中下）
	local pvpBtn = createButton(screenGui, "⚔ PvP",
		UDim2.new(0.43, 0, 0.88, 0),
		UDim2.new(0.13, 0, 0.055, 0),
		Color3.fromRGB(160, 40, 40))
	pvpBtn.MouseButton1Click:Connect(function()
		UIManager.openPvPPanel()
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

-- 圖示色塊（左側方形色條，作為視覺識別）
local ICON_COLORS: { [string]: Color3 } = {
	-- 貓咪
	whiteCat    = Color3.fromRGB(230, 230, 230),
	shadowCat   = Color3.fromRGB(60,  40,  90),
	flameCat    = Color3.fromRGB(220, 80,  20),
	frostCat    = Color3.fromRGB(80,  180, 220),
	thunderCat  = Color3.fromRGB(200, 200, 0),
	sakuraCat   = Color3.fromRGB(240, 140, 170),
	orangeCat   = Color3.fromRGB(230, 140, 30),
	calicoCat   = Color3.fromRGB(160, 80,  220),
	tuxedoCat   = Color3.fromRGB(30,  30,  30),
	-- 裝備槽
	collar      = Color3.fromRGB(120, 200, 100),
	hat         = Color3.fromRGB(100, 160, 240),
	weapon      = Color3.fromRGB(220, 120, 60),
}

-- 建立一張物品卡片，含左側圖示色條
-- iconKey: ICON_COLORS 的索引；fragData: {current, max} 用於合成進度條
local function buildCard(parent: Frame, name: string, desc: string, rightText: string,
	btnText: string, btnColor: Color3, onBuy: (() -> ())?,
	iconKey: string?, fragData: { current: number, max: number }?): Frame

	local cardHeight = fragData and 90 or 74
	local card = createFrame(parent,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, cardHeight),
		Color3.fromRGB(28, 28, 45), 0.05)
	card.ZIndex = 23

	-- 左側圖示色條
	local iconColor = (iconKey and ICON_COLORS[iconKey]) or Color3.fromRGB(80, 80, 100)
	local iconBar = createFrame(card,
		UDim2.new(0, 0, 0, 0), UDim2.new(0, 5, 1, 0),
		iconColor, 0)
	iconBar.ZIndex = 24

	-- 圖示色塊（左側大色塊，顯示縮略識別色）
	local iconBox = createFrame(card,
		UDim2.new(0, 8, 0.1, 0), UDim2.new(0, 42, 0.8, 0),
		iconColor, 0.1)
	iconBox.ZIndex = 24
	-- 圓角
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = iconBox

	-- 首字圖示文字
	local abbrev = string.upper(string.sub(name, 1, 1))
	local iconTxt = createLabel(iconBox, abbrev,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), 22)
	iconTxt.TextXAlignment = Enum.TextXAlignment.Center
	iconTxt.TextColor3 = Color3.new(1, 1, 1)
	iconTxt.ZIndex = 25

	-- 名稱
	local nameLbl = createLabel(card, name,
		UDim2.new(0, 58, 0.05, 0), UDim2.new(0.5, 0, 0.4, 0), 15)
	nameLbl.ZIndex = 24

	-- 描述
	local descLbl = createLabel(card, desc,
		UDim2.new(0, 58, 0.48, 0), UDim2.new(0.5, 0, 0.38, 0), 11)
	descLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
	descLbl.Font = Enum.Font.Gotham
	descLbl.ZIndex = 24

	-- 右側資訊文字
	local rightLbl = createLabel(card, rightText,
		UDim2.new(0.6, 0, 0.05, 0), UDim2.new(0.17, 0, 0.85, 0), 12)
	rightLbl.TextXAlignment = Enum.TextXAlignment.Center
	rightLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
	rightLbl.ZIndex = 24

	-- 合成碎片進度條（可選）
	if fragData then
		local barBg = createFrame(card,
			UDim2.new(0, 58, 0, cardHeight - 20), UDim2.new(0.55, 0, 0, 10),
			Color3.fromRGB(40, 40, 60), 0)
		barBg.ZIndex = 24
		local pct = math.clamp(fragData.current / fragData.max, 0, 1)
		local barFill = createFrame(barBg,
			UDim2.new(0, 0, 0, 0), UDim2.new(pct, 0, 1, 0),
			pct >= 1 and Color3.fromRGB(160, 60, 220) or Color3.fromRGB(80, 120, 200), 0)
		barFill.ZIndex = 25
		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(1, 0)
		barCorner.Parent = barBg
		local barCorner2 = Instance.new("UICorner")
		barCorner2.CornerRadius = UDim.new(1, 0)
		barCorner2.Parent = barFill
	end

	-- 按鈕或狀態標籤
	if onBuy then
		local btn = createButton(card, btnText,
			UDim2.new(0.79, 0, 0.12, 0), UDim2.new(0.19, 0, 0.76, 0),
			btnColor)
		btn.TextSize = 13
		btn.ZIndex = 24
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn
		btn.MouseButton1Click:Connect(onBuy)
	else
		local statusLbl = createLabel(card, btnText,
			UDim2.new(0.79, 0, 0.12, 0), UDim2.new(0.19, 0, 0.76, 0), 13)
		statusLbl.TextXAlignment = Enum.TextXAlignment.Center
		if btnColor == Color3.new(0, 0, 0) then
			statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
		else
			statusLbl.TextColor3 = btnColor
		end
		statusLbl.ZIndex = 24
	end

	return card
end

-- startTab: "cats" | "equip" | "synth"（nil = 預設貓咪）
function UIManager.openShopPanel(startTab: string?)
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
		local currentCatId = playerData.currentCat or "whiteCat"
		for i, cat in ipairs(catalog or {}) do
			local owned = playerData.ownedCats and playerData.ownedCats[cat.id]
			local isActive = currentCatId == cat.id
			local rightText = isActive and "▶ 使用中" or (cat.price == 0 and "免費" or (cat.price .. " RB"))
			local card: Frame
			if isActive then
				card = buildCard(scroll, cat.displayName, cat.description, rightText, "使用中",
					Color3.fromRGB(40, 160, 80), nil, cat.id)
			elseif owned then
				card = buildCard(scroll, cat.displayName, cat.description, rightText, "切換使用",
					Color3.fromRGB(60, 120, 200), function()
						getRemote("SelectCat"):FireServer(cat.id)
						currentCatId = cat.id
						UIManager.showToast("切換至 " .. cat.displayName, Color3.fromRGB(100, 200, 255))
						task.delay(0.3, function() UIManager.openShopPanel("cats") end)
					end, cat.id)
			else
				card = buildCard(scroll, cat.displayName, cat.description, rightText, "購買",
					Color3.fromRGB(200, 120, 20), function()
						getRemote("PurchaseCat"):FireServer(cat.id)
					end, cat.id)
			end
			if card then card.LayoutOrder = i end
		end
	end

	local function showEquipTab()
		clearScroll()
		-- 固定排序：項圈 → 帽子 → 武器
		local slotOrder = { { id = "collar", name = "項圈" }, { id = "hat", name = "帽子" }, { id = "weapon", name = "武器" } }
		local order = 0
		for _, slotDef in ipairs(slotOrder) do
			local slotId = slotDef.id
			local slotName = slotDef.name
			local items = EquipmentData.getItemsBySlot(slotId)
			table.sort(items, function(a, b) return a.price < b.price end)
			for _, item in ipairs(items) do
				order += 1
				local equipped = cachedEquipment[slotId] == item.id
				local atkStr = item.statBonus.attack ~= 0 and string.format(" ATK%+d", item.statBonus.attack) or ""
				local defStr = item.statBonus.defense ~= 0 and string.format(" DEF%+d", item.statBonus.defense) or ""
				local hpStr  = item.statBonus.maxHp   ~= 0 and string.format(" HP%+d",  item.statBonus.maxHp)  or ""
				local spdStr = item.statBonus.speed   ~= 0 and string.format(" SPD%+d", item.statBonus.speed)  or ""
				local stats = (atkStr .. defStr .. hpStr .. spdStr):gsub("^ ", "")
				local rightText = "[" .. slotName .. "]\n" .. (stats ~= "" and stats or "—")
				local card
				if equipped then
					card = buildCard(scroll, item.displayName, item.description, rightText,
						"✓ 已裝備", Color3.new(0, 0, 0), nil, slotId)
					-- 卸下按鈕疊加
					local unequipBtn = createButton(card, "卸下",
						UDim2.new(0.79, 0, 0.55, 0), UDim2.new(0.19, 0, 0.35, 0),
						Color3.fromRGB(140, 40, 40))
					unequipBtn.TextSize = 12
					unequipBtn.ZIndex = 25
					local uCorner = Instance.new("UICorner")
					uCorner.CornerRadius = UDim.new(0, 5)
					uCorner.Parent = unequipBtn
					unequipBtn.MouseButton1Click:Connect(function()
						getRemote("UnequipItem"):FireServer(slotId)
						cachedEquipment[slotId] = nil
						UIManager.openShopPanel("equip")
					end)
				else
					card = buildCard(scroll, item.displayName, item.description, rightText,
						item.price .. " 金",
						Color3.fromRGB(50, 150, 60), function()
							getRemote("BuyEquipment"):FireServer(item.id)
							task.delay(0.3, function() UIManager.openShopPanel("equip") end)
						end, slotId)
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
			local fragText = string.format("%d / 10 碎片", frags)
			local fd = { current = frags, max = 10 }
			local card
			if owned then
				card = buildCard(scroll, cat.displayName, cat.description, fragText,
					"✓ 已擁有", Color3.new(0, 0, 0), nil, catId, fd)
			elseif frags >= 10 then
				card = buildCard(scroll, cat.displayName, cat.description, fragText,
					"合成！", Color3.fromRGB(160, 60, 220), function()
						getRemote("SynthesizeCat"):FireServer(catId)
						task.delay(0.5, function() UIManager.openShopPanel("synth") end)
					end, catId, fd)
			else
				card = buildCard(scroll, cat.displayName, cat.description, fragText,
					"待收集", Color3.fromRGB(80, 80, 100), nil, catId, fd)
			end
			if card then card.LayoutOrder = i end
		end
	end

	-- Tab 建立
	local tabs = {
		{ name = "🐱 貓咪", key = "cats", fn = showCatsTab },
		{ name = "⚔ 裝備",  key = "equip", fn = showEquipTab },
		{ name = "✨ 合成", key = "synth", fn = showSynthesisTab },
	}
	scroll.Position = UDim2.new(0, 0, 0.21, 0)
	scroll.Size = UDim2.new(1, 0, 0.79, 0)

	local activeTabColor = Color3.fromRGB(60, 80, 160)
	local inactiveTabColor = Color3.fromRGB(28, 28, 50)
	local tabBtns: { [string]: TextButton } = {}

	local function activateTab(key: string)
		for k, btn in pairs(tabBtns) do
			btn.BackgroundColor3 = k == key and activeTabColor or inactiveTabColor
		end
	end

	for i, tab in ipairs(tabs) do
		local btn = createButton(tabBar, tab.name,
			UDim2.new((i - 1) / 3, 1, 0, 1), UDim2.new(1 / 3, -2, 1, -2),
			inactiveTabColor)
		btn.TextSize = 14
		btn.ZIndex = 23
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(0, 5)
		tc.Parent = btn
		tabBtns[tab.key] = btn
		btn.MouseButton1Click:Connect(function()
			activateTab(tab.key)
			tab.fn()
		end)
	end

	-- 依 startTab 決定預設分頁
	local defaultKey = startTab or "cats"
	local defaultFn = showCatsTab
	for _, tab in ipairs(tabs) do
		if tab.key == defaultKey then
			defaultFn = tab.fn
			break
		end
	end
	activateTab(defaultKey)
	defaultFn()
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
			local card = buildCard(scroll, name, desc, "", "→ 裝備商城",
				Color3.fromRGB(60, 120, 200), function()
					if equipPanel then equipPanel:Destroy() end
					UIManager.openShopPanel("equip")
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

-- ── PvP 發起面板 ─────────────────────────────────────────────────

function UIManager.openPvPPanel()
	local overlay, scroll, _ = buildPanelBase("⚔ PvP 挑戰")

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local panel = overlay:FindFirstChildOfClass("Frame")

	-- 說明文字
	local hintLbl = createLabel(panel,
		"選擇一名線上玩家發起 PvP 對決，勝者獲得額外 XP 與金幣",
		UDim2.new(0.03, 0, 0.09, 0), UDim2.new(0.94, 0, 0.06, 0), 13)
	hintLbl.ZIndex = 22
	hintLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	hintLbl.Font = Enum.Font.Gotham

	-- 移動 scroll 往下避開說明文字
	scroll.Position = UDim2.new(0, 0, 0.16, 0)
	scroll.Size = UDim2.new(1, 0, 0.84, 0)

	local function refreshPlayerList()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end

		local order = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if player == localPlayer then continue end
			order += 1
			local card = createFrame(scroll,
				UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 60),
				Color3.fromRGB(35, 35, 55), 0.1)
			card.ZIndex = 23
			card.LayoutOrder = order

			local nameLbl = createLabel(card, player.DisplayName,
				UDim2.new(0.02, 0, 0.1, 0), UDim2.new(0.55, 0, 0.45, 0), 16)
			nameLbl.ZIndex = 24

			local userLbl = createLabel(card, "@" .. player.Name,
				UDim2.new(0.02, 0, 0.55, 0), UDim2.new(0.55, 0, 0.35, 0), 12)
			userLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
			userLbl.Font = Enum.Font.Gotham
			userLbl.ZIndex = 24

			local challengeBtn = createButton(card, "發起挑戰",
				UDim2.new(0.78, 0, 0.12, 0), UDim2.new(0.2, 0, 0.76, 0),
				Color3.fromRGB(160, 40, 40))
			challengeBtn.TextSize = 13
			challengeBtn.ZIndex = 24
			challengeBtn.MouseButton1Click:Connect(function()
				getRemote("RequestPvP"):FireServer(player.UserId)
				UIManager.showToast("已向 " .. player.DisplayName .. " 發起 PvP 挑戰！", Color3.fromRGB(255, 180, 50))
				overlay:Destroy()
			end)
		end

		-- 若沒有其他玩家
		if order == 0 then
			local noPlayerLbl = createLabel(scroll, "目前沒有其他玩家在線",
				UDim2.new(0.1, 0, 0, 0), UDim2.new(0.8, 0, 0, 40), 16)
			noPlayerLbl.ZIndex = 23
			noPlayerLbl.TextXAlignment = Enum.TextXAlignment.Center
		end
	end

	-- 重新整理按鈕
	local refreshBtn = createButton(panel, "🔄 重新整理",
		UDim2.new(0.55, 0, 0.09, 0), UDim2.new(0.2, 0, 0.06, 0),
		Color3.fromRGB(50, 100, 50))
	refreshBtn.ZIndex = 22
	refreshBtn.TextSize = 13
	refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

	refreshPlayerList()
end

return UIManager
