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

local THEME = {
	textPrimary = Color3.fromRGB(248, 250, 255),
	textSecondary = Color3.fromRGB(190, 198, 230),
	panel = Color3.fromRGB(20, 24, 42),
	panelAlt = Color3.fromRGB(30, 36, 58),
	panelStroke = Color3.fromRGB(84, 95, 145),
	button = Color3.fromRGB(70, 102, 190),
	buttonHover = Color3.fromRGB(92, 125, 215),
	buttonDanger = Color3.fromRGB(180, 62, 78),
	buttonSuccess = Color3.fromRGB(70, 150, 108),
	accent = Color3.fromRGB(120, 170, 255),
}

-- ── 基礎建構函數 ─────────────────────────────────────────────────

local function getRemote(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild(name) :: RemoteEvent
end
local function getFunction(name: string): RemoteFunction
	return ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild(name) :: RemoteFunction
end

local function applyCorner(gui: GuiObject, radiusPx: number)
	if gui:FindFirstChild("AutoCorner") then return end
	local c = Instance.new("UICorner")
	c.Name = "AutoCorner"
	c.CornerRadius = UDim.new(0, radiusPx)
	c.Parent = gui
end

local function applyStroke(gui: GuiObject, color: Color3, thickness: number, transparency: number)
	if gui:FindFirstChild("AutoStroke") then return end
	local s = Instance.new("UIStroke")
	s.Name = "AutoStroke"
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = gui
end

local function applyGradient(gui: GuiObject, topColor: Color3, bottomColor: Color3, rotation: number?)
	if gui:FindFirstChild("AutoGradient") then return end
	local g = Instance.new("UIGradient")
	g.Name = "AutoGradient"
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	g.Rotation = rotation or 90
	g.Parent = gui
end

local function createLabel(parent: Instance, text: string, pos: UDim2, size: UDim2, fontSize: number?): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Parent = parent
	lbl.Text = text
	lbl.Position = pos
	lbl.Size = size
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = THEME.textPrimary
	lbl.TextStrokeTransparency = 0.6
	lbl.TextStrokeColor3 = Color3.fromRGB(20, 24, 38)
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = fontSize or 18
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function createFrame(parent: Instance, pos: UDim2, size: UDim2, color: Color3?, alpha: number?): Frame
	local f = Instance.new("Frame")
	f.Parent = parent
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = color or THEME.panel
	f.BackgroundTransparency = alpha or 0.5
	f.BorderSizePixel = 0
	local isFullscreen = size.X.Scale >= 1 and size.Y.Scale >= 1 and size.X.Offset == 0 and size.Y.Offset == 0
	if not isFullscreen then
		applyCorner(f, 12)
		applyStroke(f, THEME.panelStroke, 1.2, 0.42)
	end
	return f
end

local function createButton(parent: Instance, text: string, pos: UDim2, size: UDim2,
	color: Color3?, textColor: Color3?): TextButton
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Text = text
	btn.Position = pos
	btn.Size = size
	local baseColor = color or THEME.button
	btn.BackgroundColor3 = baseColor
	btn.TextColor3 = textColor or THEME.textPrimary
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	local hoverColor = Color3.fromRGB(
		math.clamp(baseColor.R * 255 + 22, 0, 255),
		math.clamp(baseColor.G * 255 + 22, 0, 255),
		math.clamp(baseColor.B * 255 + 22, 0, 255)
	)
	applyCorner(btn, 10)
	applyStroke(btn, Color3.fromRGB(
		math.clamp(baseColor.R * 255 + 25, 0, 255),
		math.clamp(baseColor.G * 255 + 25, 0, 255),
		math.clamp(baseColor.B * 255 + 25, 0, 255)
	), 1.1, 0.35)
	applyGradient(btn,
		Color3.fromRGB(
			math.clamp(baseColor.R * 255 + 18, 0, 255),
			math.clamp(baseColor.G * 255 + 18, 0, 255),
			math.clamp(baseColor.B * 255 + 18, 0, 255)
		),
		Color3.fromRGB(
			math.clamp(baseColor.R * 255 - 18, 0, 255),
			math.clamp(baseColor.G * 255 - 18, 0, 255),
			math.clamp(baseColor.B * 255 - 18, 0, 255)
		),
		90
	)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = hoverColor,
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = baseColor,
		}):Play()
	end)
	return btn
end

local function styleCardFrame(frame: Frame, baseColor: Color3)
	frame.BorderSizePixel = 0
	applyCorner(frame, 14)
	applyStroke(frame, Color3.fromRGB(
		math.clamp(baseColor.R * 255 + 22, 0, 255),
		math.clamp(baseColor.G * 255 + 22, 0, 255),
		math.clamp(baseColor.B * 255 + 22, 0, 255)
	), 1.2, 0.35)
	applyGradient(
		frame,
		Color3.fromRGB(
			math.clamp(baseColor.R * 255 + 16, 0, 255),
			math.clamp(baseColor.G * 255 + 16, 0, 255),
			math.clamp(baseColor.B * 255 + 16, 0, 255)
		),
		Color3.fromRGB(
			math.clamp(baseColor.R * 255 - 16, 0, 255),
			math.clamp(baseColor.G * 255 - 16, 0, 255),
			math.clamp(baseColor.B * 255 - 16, 0, 255)
		),
		90
	)
end

local function applyGlassPanel(panel: Frame)
	panel.BackgroundColor3 = THEME.panel
	panel.BackgroundTransparency = 0.12
	applyCorner(panel, 16)
	applyStroke(panel, THEME.panelStroke, 1.4, 0.25)
	applyGradient(panel, Color3.fromRGB(36, 44, 72), Color3.fromRGB(16, 20, 36), 90)
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

	-- 版本號：固定在畫面左下角，清楚可見
	local gameVersion = require(ReplicatedStorage.Shared.GameConfig).VERSION
	local versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "VersionLabel"
	versionLabel.Text = "🐾 " .. gameVersion
	versionLabel.Position = UDim2.new(0, 6, 1, -22)  -- 左下角固定位置
	versionLabel.Size = UDim2.new(0, 90, 0, 18)
	versionLabel.AnchorPoint = Vector2.new(0, 0)
	versionLabel.BackgroundTransparency = 0.45
	versionLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	versionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	versionLabel.TextStrokeTransparency = 0.5
	versionLabel.Font = Enum.Font.GothamBold
	versionLabel.TextSize = 12
	versionLabel.TextXAlignment = Enum.TextXAlignment.Center
	versionLabel.ZIndex = 3
	versionLabel.Parent = screenGui
	local vc = Instance.new("UICorner")
	vc.CornerRadius = UDim.new(0, 5)
	vc.Parent = versionLabel

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

-- ── 右上角選單按鈕（直排，不擋方向鍵/跳躍） ─────────────────────

function UIManager.buildMenuButtons()
	-- 按鈕規格：右上角直排，每個按鈕 11% 寬、5% 高，間距 1%
	-- X 起點 0.88（距右邊 1%），Y 從 0.01 往下排列
	local BTN_X    = 0.88
	local BTN_W    = 0.115
	local BTN_H    = 0.052
	local BTN_GAP  = 0.008
	local startY   = 0.01

	local function makeBtn(label, yPos, color, fn)
		local btn = createButton(screenGui, label,
			UDim2.new(BTN_X, 0, yPos, 0),
			UDim2.new(BTN_W, 0, BTN_H, 0),
			color)
		btn.TextSize = 13
		btn.ZIndex = 5
		-- 輕微半透明背景讓按鈕不過於搶眼
		btn.BackgroundTransparency = 0.15
		btn.MouseButton1Click:Connect(fn)
		return btn
	end

	local y = startY
	makeBtn("🛒 商城", y, Color3.fromRGB(170, 90, 15), function()
		UIManager.openShopPanel("cats")
	end)

	y = y + BTN_H + BTN_GAP
	makeBtn("🎒 背包", y, Color3.fromRGB(50, 75, 155), function()
		UIManager.openInventoryPanel()
	end)

	y = y + BTN_H + BTN_GAP
	makeBtn("⚔ PvP", y, Color3.fromRGB(150, 35, 35), function()
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
		THEME.panel, 0.05)
	panel.ZIndex = 21
	applyCorner(panel, 18)
	applyStroke(panel, THEME.panelStroke, 1.4, 0.18)
	applyGradient(panel, Color3.fromRGB(34, 42, 70), Color3.fromRGB(16, 20, 36), 90)

	-- 標題
	local titleLbl = createLabel(panel, title,
		UDim2.new(0.03, 0, 0.01, 0), UDim2.new(0.7, 0, 0.08, 0), 24)
	titleLbl.ZIndex = 22

	-- 關閉按鈕
	local closeBtn = createButton(panel, "✕ 關閉",
		UDim2.new(0.78, 0, 0.01, 0), UDim2.new(0.2, 0, 0.08, 0),
		THEME.buttonDanger)
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

-- 舊式列表卡片（給裝備快捷面板沿用）
local function buildCard(
	parent: Frame,
	title: string,
	desc: string,
	stats: string,
	buttonText: string,
	buttonColor: Color3,
	onClick: () -> ()
): Frame
	local card = createFrame(parent,
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 0, 112),
		THEME.panelAlt, 0.08)
	card.ZIndex = 23
	applyCorner(card, 12)
	applyStroke(card, THEME.panelStroke, 1.1, 0.35)
	applyGradient(card, Color3.fromRGB(52, 60, 92), Color3.fromRGB(30, 36, 56), 90)

	local titleLbl = createLabel(card, title,
		UDim2.new(0.03, 0, 0.06, 0), UDim2.new(0.65, 0, 0.24, 0), 16)
	titleLbl.ZIndex = 24
	titleLbl.TextColor3 = THEME.textPrimary

	local descLbl = createLabel(card, desc,
		UDim2.new(0.03, 0, 0.30, 0), UDim2.new(0.65, 0, 0.30, 0), 13)
	descLbl.ZIndex = 24
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextWrapped = true
	descLbl.TextColor3 = THEME.textSecondary

	if stats ~= "" then
		local statsLbl = createLabel(card, stats,
			UDim2.new(0.03, 0, 0.64, 0), UDim2.new(0.65, 0, 0.22, 0), 12)
		statsLbl.ZIndex = 24
		statsLbl.Font = Enum.Font.GothamBold
		statsLbl.TextColor3 = Color3.fromRGB(136, 232, 170)
	end

	local actionBtn = createButton(card, buttonText,
		UDim2.new(0.72, 0, 0.20, 0), UDim2.new(0.25, 0, 0.58, 0),
		buttonColor)
	actionBtn.ZIndex = 25
	actionBtn.TextScaled = true
	actionBtn.MouseButton1Click:Connect(onClick)

	return card
end

-- 圖示顏色（格狀卡片背景色）
local ICON_COLORS: { [string]: Color3 } = {
	whiteCat    = Color3.fromRGB(210, 210, 210),
	shadowCat   = Color3.fromRGB(55,  30,  80),
	flameCat    = Color3.fromRGB(210, 70,  15),
	frostCat    = Color3.fromRGB(60,  160, 210),
	thunderCat  = Color3.fromRGB(190, 185, 0),
	sakuraCat   = Color3.fromRGB(230, 120, 160),
	orangeCat   = Color3.fromRGB(220, 130, 20),
	calicoCat   = Color3.fromRGB(140, 60,  210),
	tuxedoCat   = Color3.fromRGB(25,  25,  25),
	collar      = Color3.fromRGB(100, 180, 85),
	hat         = Color3.fromRGB(80,  140, 220),
	weapon      = Color3.fromRGB(200, 100, 40),
}

-- 圖示 Emoji（格狀卡片大圖示）
local ICON_EMOJI: { [string]: string } = {
	whiteCat    = "🐱",
	shadowCat   = "🌑",
	flameCat    = "🔥",
	frostCat    = "❄️",
	thunderCat  = "⚡",
	sakuraCat   = "🌸",
	orangeCat   = "🍊",
	calicoCat   = "🌈",
	tuxedoCat   = "🎩",
	collarBasic = "🔗",
	collarSpike = "⚙️",
	collarHeal  = "💚",
	collarSpeed = "💨",
	hatWizard   = "🧙",
	hatKnight   = "⚔️",
	hatBandana  = "🎗️",
	hatCrown    = "👑",
	weaponClaws = "🗡️",
	weaponSword = "🔪",
	weaponShield= "🛡️",
	weaponStaff = "🪄",
}

-- ── 格狀商城輔助 ─────────────────────────────────────────────────

-- 建立 UIGridLayout 格狀容器（取代 UIListLayout）
local function makeGridScroll(parent: Frame, cellSize: UDim2): (ScrollingFrame, UIGridLayout)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Parent = parent
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.BorderSizePixel = 0
	scroll.ZIndex = 22

	local grid = Instance.new("UIGridLayout")
	grid.Parent = scroll
	grid.CellSize = cellSize
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = 3

	local padding = Instance.new("UIPadding")
	padding.Parent = scroll
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)

	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
	end)

	return scroll, grid
end

-- 建立一個格狀圖示卡片（正方形，大 Emoji + 名稱 + 狀態徽章）
local function buildIconCard(parent: Frame, order: number, opts: {
	id: string,
	emoji: string,
	name: string,
	badgeText: string,
	badgeColor: Color3,
	bgColor: Color3,
	dimmed: boolean?,       -- 未擁有/不可用時變暗
	onClick: (() -> ())?,
}): Frame

	local card = Instance.new("Frame")
	card.Name = "IconCard_" .. opts.id
	card.BackgroundColor3 = opts.dimmed and Color3.fromRGB(18, 18, 28)
		or opts.bgColor
	card.BackgroundTransparency = opts.dimmed and 0.15 or 0.2
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.ZIndex = 23
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	-- 大 Emoji（佔上方 55%）
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size = UDim2.new(1, 0, 0.52, 0)
	emojiLbl.Position = UDim2.new(0, 0, 0.03, 0)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text = opts.emoji
	emojiLbl.TextScaled = true
	emojiLbl.Font = Enum.Font.GothamBold
	emojiLbl.TextColor3 = Color3.new(1, 1, 1)
	emojiLbl.TextTransparency = opts.dimmed and 0.45 or 0
	emojiLbl.ZIndex = 24
	emojiLbl.Parent = card

	-- 名稱（中段）
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -8, 0.22, 0)
	nameLbl.Position = UDim2.new(0, 4, 0.54, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = opts.name
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextColor3 = opts.dimmed and Color3.fromRGB(140, 140, 160)
		or Color3.new(1, 1, 1)
	nameLbl.TextStrokeTransparency = 0.5
	nameLbl.ZIndex = 24
	nameLbl.Parent = card

	-- 狀態徽章（底部）
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(1, 0, 0.22, 0)
	badge.Position = UDim2.new(0, 0, 0.78, 0)
	badge.BackgroundColor3 = opts.badgeColor
	badge.BackgroundTransparency = 0.1
	badge.BorderSizePixel = 0
	badge.ZIndex = 24
	badge.Parent = card
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 10)
	badgeCorner.Parent = badge

	local badgeLbl = Instance.new("TextLabel")
	badgeLbl.Size = UDim2.new(1, 0, 1, 0)
	badgeLbl.BackgroundTransparency = 1
	badgeLbl.Text = opts.badgeText
	badgeLbl.TextScaled = true
	badgeLbl.Font = Enum.Font.GothamBold
	badgeLbl.TextColor3 = Color3.new(1, 1, 1)
	badgeLbl.ZIndex = 25
	badgeLbl.Parent = badge

	-- 點擊效果
	if opts.onClick then
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 26
		btn.Parent = card
		btn.MouseButton1Click:Connect(opts.onClick)
		-- 懸停高亮
		btn.MouseEnter:Connect(function()
			card.BackgroundTransparency = opts.dimmed and 0.05 or 0.05
		end)
		btn.MouseLeave:Connect(function()
			card.BackgroundTransparency = opts.dimmed and 0.15 or 0.2
		end)
	end

	return card
end

-- 詳情彈出視窗（點擊圖示卡後出現）
local function showDetailPopup(opts: {
	title: string,
	emoji: string,
	desc: string,
	stats: string?,
	priceText: string,
	btnText: string,
	btnColor: Color3,
	onConfirm: (() -> ())?,
	fragData: { current: number, max: number }?,
})
	-- 遮罩
	local mask = createFrame(screenGui,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
		Color3.new(0, 0, 0), 0.55)
	mask.ZIndex = 40

	-- 彈窗主體
	local popup = createFrame(mask,
		UDim2.new(0.2, 0, 0.2, 0), UDim2.new(0.6, 0, 0.6, 0),
		Color3.fromRGB(18, 18, 32), 0.05)
	popup.ZIndex = 41
	local popCorner = Instance.new("UICorner")
	popCorner.CornerRadius = UDim.new(0, 16)
	popCorner.Parent = popup

	-- 大 Emoji
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size = UDim2.new(1, 0, 0.28, 0)
	emojiLbl.Position = UDim2.new(0, 0, 0.02, 0)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text = opts.emoji
	emojiLbl.TextScaled = true
	emojiLbl.Font = Enum.Font.GothamBold
	emojiLbl.TextColor3 = Color3.new(1, 1, 1)
	emojiLbl.ZIndex = 42
	emojiLbl.Parent = popup

	-- 標題
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(0.9, 0, 0.1, 0)
	titleLbl.Position = UDim2.new(0.05, 0, 0.3, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = opts.title
	titleLbl.TextScaled = true
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextColor3 = Color3.new(1, 1, 1)
	titleLbl.TextStrokeTransparency = 0.3
	titleLbl.ZIndex = 42
	titleLbl.Parent = popup

	-- 描述
	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(0.88, 0, 0.15, 0)
	descLbl.Position = UDim2.new(0.06, 0, 0.41, 0)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = opts.desc
	descLbl.TextScaled = true
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
	descLbl.TextWrapped = true
	descLbl.ZIndex = 42
	descLbl.Parent = popup

	-- 數值加成（若有）
	if opts.stats and opts.stats ~= "" then
		local statsLbl = Instance.new("TextLabel")
		statsLbl.Size = UDim2.new(0.88, 0, 0.1, 0)
		statsLbl.Position = UDim2.new(0.06, 0, 0.55, 0)
		statsLbl.BackgroundTransparency = 1
		statsLbl.Text = opts.stats
		statsLbl.TextScaled = true
		statsLbl.Font = Enum.Font.GothamBold
		statsLbl.TextColor3 = Color3.fromRGB(120, 220, 140)
		statsLbl.ZIndex = 42
		statsLbl.Parent = popup
	end

	-- 碎片進度條（合成用）
	if opts.fragData then
		local fd = opts.fragData
		local barY = (opts.stats and opts.stats ~= "") and 0.65 or 0.57
		local barBg = createFrame(popup,
			UDim2.new(0.06, 0, barY, 0), UDim2.new(0.88, 0, 0.06, 0),
			Color3.fromRGB(30, 30, 50), 0)
		barBg.ZIndex = 42
		local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(1,0); c1.Parent = barBg
		local pct = math.clamp(fd.current / fd.max, 0, 1)
		local fill = createFrame(barBg, UDim2.new(0,0,0,0), UDim2.new(pct,0,1,0),
			pct >= 1 and Color3.fromRGB(160,60,220) or Color3.fromRGB(80,140,220), 0)
		fill.ZIndex = 43
		local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(1,0); c2.Parent = fill

		local fragLbl = Instance.new("TextLabel")
		fragLbl.Size = UDim2.new(1, 0, 0.06, 0)
		fragLbl.Position = UDim2.new(0, 0, barY + 0.065, 0)
		fragLbl.BackgroundTransparency = 1
		fragLbl.Text = string.format("碎片 %d / %d", fd.current, fd.max)
		fragLbl.TextScaled = true
		fragLbl.Font = Enum.Font.Gotham
		fragLbl.TextColor3 = Color3.fromRGB(160, 180, 220)
		fragLbl.ZIndex = 42
		fragLbl.Parent = popup
	end

	-- 價格標示
	local priceLbl = Instance.new("TextLabel")
	priceLbl.Size = UDim2.new(0.88, 0, 0.08, 0)
	priceLbl.Position = UDim2.new(0.06, 0, 0.75, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Text = opts.priceText
	priceLbl.TextScaled = true
	priceLbl.Font = Enum.Font.GothamBold
	priceLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
	priceLbl.ZIndex = 42
	priceLbl.Parent = popup

	-- 確認按鈕
	if opts.onConfirm then
		local confirmBtn = createButton(popup, opts.btnText,
			UDim2.new(0.1, 0, 0.85, 0), UDim2.new(0.5, 0, 0.12, 0),
			opts.btnColor)
		confirmBtn.TextScaled = true
		confirmBtn.ZIndex = 42
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,10); cc.Parent = confirmBtn
		confirmBtn.MouseButton1Click:Connect(function()
			mask:Destroy()
			opts.onConfirm()
		end)
	end

	-- 關閉按鈕
	local closeBtn = createButton(popup, "✕",
		UDim2.new(0.65, 0, 0.85, 0), UDim2.new(0.25, 0, 0.12, 0),
		Color3.fromRGB(100, 40, 40))
	closeBtn.TextScaled = true
	closeBtn.ZIndex = 42
	local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0,10); clc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		mask:Destroy()
	end)
	mask.MouseButton1Click:Connect(function()
		mask:Destroy()
	end)
end

-- startTab: "cats" | "equip" | "synth"（nil = 預設貓咪）
function UIManager.openShopPanel(startTab: string?)
	if shopPanel then shopPanel:Destroy() end
	local playerData = getFunction("GetPlayerData"):InvokeServer()
	if not playerData then return end
	cachedEquipment = playerData.equipment or {}
	cachedFragments = playerData.catFragments or {}

	-- 面板底框
	local overlay = createFrame(screenGui,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
		Color3.new(0, 0, 0), 0.5)
	overlay.ZIndex = 20
	shopPanel = overlay

	local panel = createFrame(overlay,
		UDim2.new(0.04, 0, 0.04, 0), UDim2.new(0.92, 0, 0.92, 0),
		Color3.fromRGB(14, 14, 26), 0.04)
	panel.ZIndex = 21
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 18)
	panelCorner.Parent = panel

	-- 標題列
	local titleLbl = createLabel(panel, "🛒 商城",
		UDim2.new(0.03, 0, 0.01, 0), UDim2.new(0.6, 0, 0.07, 0), 24)
	titleLbl.ZIndex = 22
	titleLbl.TextColor3 = THEME.textPrimary

	local closeBtn = createButton(panel, "✕",
		UDim2.new(0.88, 0, 0.015, 0), UDim2.new(0.1, 0, 0.065, 0),
		THEME.buttonDanger)
	closeBtn.ZIndex = 22
	local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0,10); cc2.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)

	-- Tab 列
	local tabBar = createFrame(panel,
		UDim2.new(0, 0, 0.085, 0), UDim2.new(1, 0, 0.09, 0),
		Color3.fromRGB(10, 10, 20), 0)
	tabBar.ZIndex = 22

	-- 格狀捲動區（佔剩餘空間）
	local gridScroll, gridLayout = makeGridScroll(panel, UDim2.new(0, 0, 0, 0))  -- 大小稍後設定
	gridScroll.Position = UDim2.new(0, 0, 0.185, 0)
	gridScroll.Size = UDim2.new(1, 0, 0.815, 0)

	-- 動態 cell 大小（依面板寬度計算，3 欄）
	-- 使用固定像素 cell 大小，讓格子在各解析度下適中
	gridLayout.CellSize = UDim2.new(0, 130, 0, 150)
	gridLayout.FillDirectionMaxCells = 4

	local function clearGrid()
		for _, c in ipairs(gridScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
	end

	-- ── 貓咪 tab ────────────────────────────────────────────────
	local function showCatsTab()
		clearGrid()
		local catalog = getFunction("GetShopCatalog"):InvokeServer()
		local currentCatId = playerData.currentCat or "whiteCat"

		-- 把白貓也加進來（免費起始貓）
		local allCats = {{ id="whiteCat", displayName="白貓", description="起始免費貓咪", price=0 }}
		for _, cat in ipairs(catalog or {}) do
			table.insert(allCats, cat)
		end

		for i, cat in ipairs(allCats) do
			local owned = (cat.id == "whiteCat") or (playerData.ownedCats and playerData.ownedCats[cat.id])
			local isActive = currentCatId == cat.id
			local emoji = ICON_EMOJI[cat.id] or "🐱"
			local bgColor = ICON_COLORS[cat.id] or Color3.fromRGB(80, 80, 120)

			local badgeText, badgeColor
			if isActive then
				badgeText = "▶ 使用中"
				badgeColor = Color3.fromRGB(40, 160, 80)
			elseif owned then
				badgeText = "已擁有"
				badgeColor = Color3.fromRGB(50, 100, 180)
			else
				badgeText = cat.price .. " RB"
				badgeColor = Color3.fromRGB(160, 90, 10)
			end

			buildIconCard(gridScroll, i, {
				id = cat.id,
				emoji = emoji,
				name = cat.displayName,
				badgeText = badgeText,
				badgeColor = badgeColor,
				bgColor = bgColor,
				dimmed = not owned and not isActive,
				onClick = function()
					local desc = cat.description or ""
					if isActive then
						UIManager.showToast("目前使用中：" .. cat.displayName, Color3.fromRGB(100, 220, 120))
					elseif owned then
						showDetailPopup({
							title = cat.displayName,
							emoji = emoji,
							desc = desc,
							priceText = "已擁有",
							btnText = "切換使用",
							btnColor = Color3.fromRGB(50, 120, 210),
							onConfirm = function()
								getRemote("SelectCat"):FireServer(cat.id)
								UIManager.showToast("切換至 " .. cat.displayName, Color3.fromRGB(100, 200, 255))
								task.delay(0.3, function() UIManager.openShopPanel("cats") end)
							end,
						})
					else
						showDetailPopup({
							title = cat.displayName,
							emoji = emoji,
							desc = desc,
							priceText = cat.price .. " Robux",
							btnText = "購買 " .. cat.price .. " RB",
							btnColor = Color3.fromRGB(200, 110, 10),
							onConfirm = function()
								getRemote("PurchaseCat"):FireServer(cat.id)
							end,
						})
					end
				end,
			})
		end
	end

	-- ── 裝備 tab（商城：只顯示購買，已擁有請至背包穿戴） ─────────
	local function showEquipTab()
		clearGrid()
		local ownedItems = getFunction("GetOwnedItems"):InvokeServer()
		local slotOrder = {
			{ id="collar", name="項圈" },
			{ id="hat",    name="帽子" },
			{ id="weapon", name="武器" },
		}
		local order = 0
		for _, slotDef in ipairs(slotOrder) do
			local slotId = slotDef.id
			local slotName = slotDef.name
			local items = EquipmentData.getItemsBySlot(slotId)
			table.sort(items, function(a, b) return a.price < b.price end)
			for _, item in ipairs(items) do
				order += 1
				local owned = ownedItems[item.id] == true
				local emoji = ICON_EMOJI[item.id] or "📦"
				local bgColor = ICON_COLORS[slotId] or Color3.fromRGB(80, 80, 120)

				local atkStr = item.statBonus.attack ~= 0 and string.format("ATK%+d ", item.statBonus.attack) or ""
				local defStr = item.statBonus.defense ~= 0 and string.format("DEF%+d ", item.statBonus.defense) or ""
				local hpStr  = item.statBonus.maxHp   ~= 0 and string.format("HP%+d ",  item.statBonus.maxHp)  or ""
				local spdStr = item.statBonus.speed   ~= 0 and string.format("SPD%+d ", item.statBonus.speed)  or ""
				local statsText = (atkStr .. defStr .. hpStr .. spdStr):gsub(" $", "")

				local badgeText = owned and "✓ 已購買" or (item.price .. " 金")
				local badgeColor = owned and Color3.fromRGB(40, 110, 180) or Color3.fromRGB(50, 130, 50)

				buildIconCard(gridScroll, order, {
					id = item.id,
					emoji = emoji,
					name = "[" .. slotName .. "] " .. item.displayName,
					badgeText = badgeText,
					badgeColor = badgeColor,
					bgColor = bgColor,
					dimmed = owned,  -- 已擁有變暗（示意不可重複購買）
					onClick = function()
						if owned then
							showDetailPopup({
								title = item.displayName,
								emoji = emoji,
								desc = item.description,
								stats = statsText,
								priceText = "已購買 — 請至🎒背包穿戴",
								btnText = nil,
								btnColor = Color3.fromRGB(50, 50, 80),
							})
						else
							showDetailPopup({
								title = item.displayName,
								emoji = emoji,
								desc = item.description,
								stats = statsText,
								priceText = item.price .. " 金幣",
								btnText = "購買（" .. item.price .. " 金）",
								btnColor = Color3.fromRGB(50, 150, 60),
								onConfirm = function()
									getRemote("BuyEquipment"):FireServer(item.id)
									task.delay(0.3, function() UIManager.openShopPanel("equip") end)
								end,
							})
						end
					end,
				})
			end
		end
	end

	-- ── 合成 tab ────────────────────────────────────────────────
	local function showSynthesisTab()
		clearGrid()
		local specialCats = {
			"shadowCat", "flameCat", "frostCat", "thunderCat",
			"sakuraCat", "orangeCat", "calicoCat", "tuxedoCat",
		}
		for i, catId in ipairs(specialCats) do
			local cat = CatData.getCatById(catId)
			if not cat then continue end
			local frags = cachedFragments[catId] or 0
			local owned = playerData.ownedCats and playerData.ownedCats[catId]
			local emoji = ICON_EMOJI[catId] or "✨"
			local bgColor = ICON_COLORS[catId] or Color3.fromRGB(80, 80, 120)
			local pct = frags / 10

			local badgeText, badgeColor
			if owned then
				badgeText = "✓ 已擁有"
				badgeColor = Color3.fromRGB(40, 140, 80)
			elseif frags >= 10 then
				badgeText = "可合成！"
				badgeColor = Color3.fromRGB(140, 40, 200)
			else
				badgeText = string.format("%d/10", frags)
				badgeColor = Color3.fromRGB(50, 60, 100)
			end

			buildIconCard(gridScroll, i, {
				id = catId,
				emoji = emoji,
				name = cat.displayName,
				badgeText = badgeText,
				badgeColor = badgeColor,
				bgColor = bgColor,
				dimmed = not owned and frags == 0,
				onClick = function()
					showDetailPopup({
						title = cat.displayName,
						emoji = emoji,
						desc = cat.description,
						priceText = owned and "已擁有" or string.format("碎片 %d / 10", frags),
						btnText = frags >= 10 and "立即合成！" or nil,
						btnColor = Color3.fromRGB(150, 50, 220),
						onConfirm = (not owned and frags >= 10) and function()
							getRemote("SynthesizeCat"):FireServer(catId)
							task.delay(0.5, function() UIManager.openShopPanel("synth") end)
						end or nil,
						fragData = { current = frags, max = 10 },
					})
				end,
			})
		end
	end

	-- ── Tab 按鈕 ────────────────────────────────────────────────
	local tabs = {
		{ name = "🐱 貓咪", key = "cats",  fn = showCatsTab },
		{ name = "⚔ 裝備",  key = "equip", fn = showEquipTab },
		{ name = "✨ 合成",  key = "synth", fn = showSynthesisTab },
	}

	local activeTabColor   = Color3.fromRGB(50, 70, 160)
	local inactiveTabColor = Color3.fromRGB(20, 20, 40)
	local tabBtns: { [string]: TextButton } = {}

	local function activateTab(key: string)
		for k, btn in pairs(tabBtns) do
			btn.BackgroundColor3 = k == key and activeTabColor or inactiveTabColor
		end
	end

	for i, tab in ipairs(tabs) do
		local btn = createButton(tabBar, tab.name,
			UDim2.new((i - 1) / 3, 2, 0, 2), UDim2.new(1 / 3, -4, 1, -4),
			inactiveTabColor)
		btn.TextSize = 14
		btn.ZIndex = 23
		local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 8); tc.Parent = btn
		tabBtns[tab.key] = btn
		btn.MouseButton1Click:Connect(function()
			activateTab(tab.key)
			tab.fn()
		end)
	end

	local defaultKey = startTab or "cats"
	local defaultFn = showCatsTab
	for _, tab in ipairs(tabs) do
		if tab.key == defaultKey then defaultFn = tab.fn; break end
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
	-- 大型全螢幕升級橫幅
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(1, 0, 0, 0)
	banner.Position = UDim2.new(0, 0, 0.35, 0)
	banner.BackgroundColor3 = Color3.fromRGB(20, 10, 0)
	banner.BackgroundTransparency = 0.15
	banner.BorderSizePixel = 0
	banner.ZIndex = 50
	banner.Parent = screenGui

	-- 閃光邊框（金色）
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 30)
	stroke.Thickness = 3
	stroke.Parent = banner

	-- 主文字：LEVEL UP!
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 0, 60)
	titleLbl.Position = UDim2.new(0, 0, 0, 6)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "✨  LEVEL UP!  ✨"
	titleLbl.TextScaled = true
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextColor3 = Color3.fromRGB(255, 230, 60)
	titleLbl.TextStrokeColor3 = Color3.fromRGB(180, 100, 0)
	titleLbl.TextStrokeTransparency = 0.2
	titleLbl.ZIndex = 51
	titleLbl.Parent = banner

	-- 副文字：等級數字
	local levelLbl = Instance.new("TextLabel")
	levelLbl.Size = UDim2.new(1, 0, 0, 44)
	levelLbl.Position = UDim2.new(0, 0, 0, 68)
	levelLbl.BackgroundTransparency = 1
	levelLbl.Text = "🐾  Lv. " .. newLevel .. "  🐾"
	levelLbl.TextScaled = true
	levelLbl.Font = Enum.Font.GothamBold
	levelLbl.TextColor3 = Color3.new(1, 1, 1)
	levelLbl.TextStrokeTransparency = 0.4
	levelLbl.ZIndex = 51
	levelLbl.Parent = banner

	-- 動態調整橫幅高度（兩行文字 + 內距）
	banner.Size = UDim2.new(1, 0, 0, 120)

	-- 進場動畫：從透明縮放到全尺寸
	banner.BackgroundTransparency = 1
	titleLbl.TextTransparency = 1
	levelLbl.TextTransparency = 1

	TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(titleLbl, TweenInfo.new(0.30), { TextTransparency = 0 }):Play()
	TweenService:Create(levelLbl, TweenInfo.new(0.30), { TextTransparency = 0 }):Play()

	-- 停留 2.5 秒後淡出
	task.delay(2.5, function()
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.30, 0) }):Play()
		TweenService:Create(titleLbl, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		local t = TweenService:Create(levelLbl, TweenInfo.new(0.5), { TextTransparency = 1 })
		t:Play()
		t.Completed:Connect(function() banner:Destroy() end)
	end)
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
		bg.ZIndex = 6
		applyCorner(bg, 10)
		applyStroke(bg, THEME.panelStroke, 1.2, 0.3)
		applyGradient(bg, Color3.fromRGB(58, 66, 104), Color3.fromRGB(34, 40, 70), 90)

		local nameLabel = createLabel(bg, skill.displayName,
			UDim2.new(0, 0, 0, 0),
			UDim2.new(1, 0, 0.5, 0), 11)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.TextColor3 = THEME.textPrimary
		nameLabel.ZIndex = 7

		local keyLabel = createLabel(bg, (keys[slotIndex] or tostring(slotIndex)),
			UDim2.new(0, 0, 0.5, 0),
			UDim2.new(1, 0, 0.5, 0), 14)
		keyLabel.TextXAlignment = Enum.TextXAlignment.Center
		keyLabel.TextColor3 = Color3.fromRGB(255, 226, 145)
		keyLabel.ZIndex = 7

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
		Color3.fromRGB(8, 10, 18), 0.42)
	overlay.Name = "DeathOverlay"
	overlay.ZIndex = 10
	applyGradient(overlay, Color3.fromRGB(10, 12, 22), Color3.fromRGB(24, 8, 12), 90)

	local deathLabel = createLabel(overlay, "你已陣亡...",
		UDim2.new(0.25, 0, 0.38, 0),
		UDim2.new(0.5, 0, 0.1, 0), 36)
	deathLabel.ZIndex = 11
	deathLabel.TextColor3 = Color3.fromRGB(255, 136, 146)
	deathLabel.TextStrokeTransparency = 0.18
	deathLabel.TextStrokeColor3 = Color3.fromRGB(60, 12, 24)

	-- 重生按鈕
	local btn = Instance.new("TextButton")
	btn.Name = "RespawnButton"
	btn.Size = UDim2.new(0, 200, 0, 52)
	btn.Position = UDim2.new(0.5, -100, 0.52, 0)
	btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	btn.BorderSizePixel = 0
	btn.Text = "重生"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 22
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.ZIndex = 11
	btn.AutoButtonColor = true
	btn.Parent = overlay
	applyCorner(btn, 12)
	applyStroke(btn, Color3.fromRGB(255, 120, 140), 1.4, 0.25)
	applyGradient(btn, Color3.fromRGB(220, 80, 96), Color3.fromRGB(150, 40, 52), 90)

	btn.MouseButton1Click:Connect(function()
		local remoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
		local respawnEvent = remoteEvents:WaitForChild("RequestRespawn") :: RemoteEvent
		respawnEvent:FireServer()
	end)
end

function UIManager.hideDeathScreen()
	local overlay = screenGui and screenGui:FindFirstChild("DeathOverlay")
	if overlay then overlay:Destroy() end
end

-- ── 浮動通知 ─────────────────────────────────────────────────────

function UIManager.showToast(message: string, color: Color3?)
	if not toastLabel then return end
	toastLabel.Text = message
	toastLabel.TextColor3 = color or THEME.textPrimary
	toastLabel.TextStrokeTransparency = 0.35
	toastLabel.TextStrokeColor3 = Color3.fromRGB(12, 16, 28)
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

-- ── 背包面板（管理已擁有裝備的穿戴/卸下） ────────────────────────────

function UIManager.openInventoryPanel()
	local playerData = getFunction("GetPlayerData"):InvokeServer()
	if not playerData then return end
	local ownedItems = getFunction("GetOwnedItems"):InvokeServer()
	cachedEquipment = playerData.equipment or {}

	-- 底框
	local overlay = createFrame(screenGui,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
		Color3.new(0, 0, 0), 0.5)
	overlay.ZIndex = 20

	local panel = createFrame(overlay,
		UDim2.new(0.04, 0, 0.04, 0), UDim2.new(0.92, 0, 0.92, 0),
		Color3.fromRGB(14, 18, 26), 0.04)
	panel.ZIndex = 21
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 18)
	panelCorner.Parent = panel

	-- 標題
	local titleLbl = createLabel(panel, "🎒 背包 — 裝備管理",
		UDim2.new(0.03, 0, 0.01, 0), UDim2.new(0.7, 0, 0.07, 0), 22)
	titleLbl.ZIndex = 22

	local closeBtn = createButton(panel, "✕",
		UDim2.new(0.88, 0, 0.015, 0), UDim2.new(0.1, 0, 0.065, 0),
		Color3.fromRGB(160, 40, 40))
	closeBtn.ZIndex = 22
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,10); cc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)

	-- 目前裝備槽位顯示（頂部三格）
	local slotBar = createFrame(panel,
		UDim2.new(0.02, 0, 0.09, 0), UDim2.new(0.96, 0, 0.14, 0),
		Color3.fromRGB(10, 14, 24), 0.15)
	slotBar.ZIndex = 22
	local slotCorner = Instance.new("UICorner"); slotCorner.CornerRadius = UDim.new(0,10); slotCorner.Parent = slotBar

	local SLOTS = {
		{ id="collar", name="項圈", emoji="🔗" },
		{ id="hat",    name="帽子", emoji="🎩" },
		{ id="weapon", name="武器", emoji="⚔️" },
	}

	-- 格狀物品區（下方）
	local gridScroll, gridLayout = makeGridScroll(panel, UDim2.new(0,0,0,0))
	gridScroll.Position = UDim2.new(0, 0, 0.245, 0)
	gridScroll.Size = UDim2.new(1, 0, 0.755, 0)
	gridLayout.CellSize = UDim2.new(0, 130, 0, 150)
	gridLayout.FillDirectionMaxCells = 4

	-- 刷新整個面板（裝備操作後呼叫）
	local slotFrames: { [string]: Frame } = {}

	local function refreshSlotBar()
		for _, sf in pairs(slotFrames) do sf:Destroy() end
		slotFrames = {}
		for i, slotDef in ipairs(SLOTS) do
			local sf = createFrame(slotBar,
				UDim2.new((i-1)/3 + 0.01, 0, 0.05, 0),
				UDim2.new(0.32, 0, 0.9, 0),
				Color3.fromRGB(22, 28, 44), 0.1)
			sf.ZIndex = 23
			local sfc = Instance.new("UICorner"); sfc.CornerRadius = UDim.new(0,8); sfc.Parent = sf
			slotFrames[slotDef.id] = sf

			local equippedId = cachedEquipment[slotDef.id]
			local equippedItem = equippedId and EquipmentData.getItemById(equippedId)

			local slotEmoji = equippedItem and (ICON_EMOJI[equippedId] or slotDef.emoji) or slotDef.emoji
			local slotText = equippedItem and equippedItem.displayName or ("— " .. slotDef.name .. " —")
			local slotColor = equippedItem and Color3.fromRGB(100, 200, 120) or Color3.fromRGB(120, 120, 140)

			local eLbl = Instance.new("TextLabel")
			eLbl.Size = UDim2.new(0.3, 0, 1, 0)
			eLbl.BackgroundTransparency = 1
			eLbl.Text = slotEmoji
			eLbl.TextScaled = true
			eLbl.Font = Enum.Font.GothamBold
			eLbl.TextColor3 = Color3.new(1,1,1)
			eLbl.ZIndex = 24
			eLbl.Parent = sf

			local nLbl = createLabel(sf, slotText,
				UDim2.new(0.32, 0, 0.1, 0), UDim2.new(0.66, 0, 0.8, 0), 12)
			nLbl.TextColor3 = slotColor
			nLbl.Font = Enum.Font.GothamBold
			nLbl.TextScaled = true
			nLbl.ZIndex = 24
		end
	end

	local function refreshGrid()
		for _, c in ipairs(gridScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end

		-- 統計所有已擁有物品（依槽位排序）
		local slotOrder = { "collar", "hat", "weapon" }
		local order = 0

		-- 先顯示「無物品」提示（若背包空）
		local hasAny = false
		for _ in pairs(ownedItems) do hasAny = true; break end

		if not hasAny then
			local hint = createFrame(gridScroll,
				UDim2.new(0.1, 0, 0.3, 0), UDim2.new(0.8, 0, 0.4, 0),
				Color3.fromRGB(20, 20, 40), 0.2)
			hint.ZIndex = 23
			local hintLbl = createLabel(hint, "背包是空的\n前往🛒商城購買裝備",
				UDim2.new(0.05, 0, 0.2, 0), UDim2.new(0.9, 0, 0.6, 0), 16)
			hintLbl.TextXAlignment = Enum.TextXAlignment.Center
			hintLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
			hintLbl.Font = Enum.Font.Gotham
			hintLbl.TextWrapped = true
			hintLbl.ZIndex = 24
			return
		end

		for _, slotId in ipairs(slotOrder) do
			local items = EquipmentData.getItemsBySlot(slotId)
			table.sort(items, function(a, b) return a.price < b.price end)
			for _, item in ipairs(items) do
				if not ownedItems[item.id] then continue end
				order += 1
				local equipped = cachedEquipment[slotId] == item.id
				local emoji = ICON_EMOJI[item.id] or "📦"
				local bgColor = ICON_COLORS[slotId] or Color3.fromRGB(80, 80, 120)

				local atkStr = item.statBonus.attack ~= 0 and string.format("ATK%+d ", item.statBonus.attack) or ""
				local defStr = item.statBonus.defense ~= 0 and string.format("DEF%+d ", item.statBonus.defense) or ""
				local hpStr  = item.statBonus.maxHp   ~= 0 and string.format("HP%+d ",  item.statBonus.maxHp)  or ""
				local spdStr = item.statBonus.speed   ~= 0 and string.format("SPD%+d ", item.statBonus.speed)  or ""
				local statsText = (atkStr .. defStr .. hpStr .. spdStr):gsub(" $", "")

				local badgeText = equipped and "✓ 裝備中" or "點擊裝備"
				local badgeColor = equipped and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(60, 80, 160)

				buildIconCard(gridScroll, order, {
					id = item.id,
					emoji = emoji,
					name = item.displayName,
					badgeText = badgeText,
					badgeColor = badgeColor,
					bgColor = bgColor,
					dimmed = false,
					onClick = function()
						if equipped then
							showDetailPopup({
								title = item.displayName,
								emoji = emoji,
								desc = item.description,
								stats = statsText,
								priceText = "裝備中 — " .. (slotId == "collar" and "項圈" or slotId == "hat" and "帽子" or "武器") .. "槽",
								btnText = "卸下",
								btnColor = Color3.fromRGB(160, 40, 40),
								onConfirm = function()
									getRemote("UnequipItem"):FireServer(slotId)
									cachedEquipment[slotId] = nil
									refreshSlotBar()
									refreshGrid()
								end,
							})
						else
							showDetailPopup({
								title = item.displayName,
								emoji = emoji,
								desc = item.description,
								stats = statsText,
								priceText = "點擊確認裝備",
								btnText = "裝備",
								btnColor = Color3.fromRGB(50, 130, 220),
								onConfirm = function()
									getRemote("EquipItem"):FireServer(item.id)
									cachedEquipment[slotId] = item.id
									refreshSlotBar()
									refreshGrid()
								end,
							})
						end
					end,
				})
			end
		end
	end

	refreshSlotBar()
	refreshGrid()
end

-- 向後相容：舊流程仍可能呼叫 openEquipPanel，統一導向新背包面板
function UIManager.openEquipPanel()
	UIManager.openInventoryPanel()
end

return UIManager
