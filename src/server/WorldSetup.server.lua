local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- ── 輔助函數 ──────────────────────────────────────────────────────

local function makePart(props: {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: BrickColor?,
	material: Enum.Material?,
	transparency: number?,
	anchored: boolean?,
	parent: Instance,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Anchored = props.anchored ~= false
	p.Size = props.size
	p.CFrame = props.cframe
	p.BrickColor = props.color or BrickColor.new("Medium grey")
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.parent
	return p
end

local function makeTree(pos: Vector3, height: number?)
	local h = height or (math.random(6, 10))
	local folder = Instance.new("Folder")
	folder.Name = "Tree"
	folder.Parent = workspace
	makePart({
		name = "Trunk",
		size = Vector3.new(1.2, h, 1.2),
		cframe = CFrame.new(pos + Vector3.new(0, h / 2, 0)),
		color = BrickColor.new("Reddish brown"),
		material = Enum.Material.Wood,
		parent = folder,
	})
	makePart({
		name = "Leaves",
		size = Vector3.new(h * 0.85, h * 0.75, h * 0.85),
		cframe = CFrame.new(pos + Vector3.new(0, h + h * 0.28, 0)),
		color = BrickColor.new("Bright green"),
		material = Enum.Material.Grass,
		parent = folder,
	})
end

-- ── 地板（縮小版地圖：600×600） ─────────────────────────────────
makePart({
	name = "Baseplate",
	size = Vector3.new(700, 20, 700),
	cframe = CFrame.new(0, -10, 0),
	color = BrickColor.new("Medium green"),
	material = Enum.Material.Grass,
	parent = workspace,
})

-- ── 生成點 ────────────────────────────────────────────────────────
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "SpawnLocation"
spawnLocation.Anchored = true
spawnLocation.Size = Vector3.new(8, 1, 8)
spawnLocation.CFrame = CFrame.new(0, 0.5, 0)
spawnLocation.BrickColor = BrickColor.new("Bright blue")
spawnLocation.Material = Enum.Material.SmoothPlastic
spawnLocation.Transparency = 0.2
spawnLocation.Duration = 0
spawnLocation.Parent = workspace

-- ── 安全區（出生點廣場 + 整個商城區域） ────────────────────────────
-- 對應 NPCManager.SAFE_ZONES：
--   出生點圓形：半徑 55（含整個廣場與路徑起點）
--   商城矩形：X=-42~42, Z=10~72（完整包含三棟建築）
--
-- 視覺設計：淡青綠色低透明地板（SmoothPlastic，不用 Neon）
--           BillboardGui 文字標示，不用 Neon 光板

local SAFE_FLOOR_COLOR   = BrickColor.new("Mint")       -- 薄荷青綠
local SAFE_FLOOR_ALPHA   = 0.72                          -- 半透明，能看到草地紋路
local SAFE_FLOOR_MAT     = Enum.Material.SmoothPlastic

-- 出生點安全區地板（X=-55~55, Z=-55~55 的矩形近似圓）
makePart({
	name = "SafeFloor_Spawn",
	size = Vector3.new(110, 0.4, 110),
	cframe = CFrame.new(0, 0.15, 0),
	color = SAFE_FLOOR_COLOR,
	material = SAFE_FLOOR_MAT,
	transparency = SAFE_FLOOR_ALPHA,
	parent = workspace,
})

-- 商城安全區地板（X=-42~42, Z=10~72，寬 84 深 62）
makePart({
	name = "SafeFloor_Shop",
	size = Vector3.new(84, 0.4, 62),
	cframe = CFrame.new(0, 0.15, 41),
	color = SAFE_FLOOR_COLOR,
	material = SAFE_FLOOR_MAT,
	transparency = SAFE_FLOOR_ALPHA,
	parent = workspace,
})

-- 安全區文字標示（出生點廣場，懸浮中央偏高）
do
	local anchor = makePart({
		name = "SafeTextAnchor_Spawn",
		size = Vector3.new(0.1, 0.1, 0.1),
		cframe = CFrame.new(0, 0.1, -8),
		color = BrickColor.new("Really black"),
		transparency = 1,
		parent = workspace,
	})
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 280, 0, 52)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 80
	bb.Parent = anchor

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 0.28
	lbl.BackgroundColor3 = Color3.fromRGB(10, 60, 40)
	lbl.Text = "🛡  安全區域  —  怪物無法進入"
	lbl.TextColor3 = Color3.fromRGB(140, 255, 180)
	lbl.TextStrokeTransparency = 0.3
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 17
	lbl.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = lbl
end

-- 安全區文字標示（商城區入口）
do
	local anchor = makePart({
		name = "SafeTextAnchor_Shop",
		size = Vector3.new(0.1, 0.1, 0.1),
		cframe = CFrame.new(0, 0.1, 15),
		color = BrickColor.new("Really black"),
		transparency = 1,
		parent = workspace,
	})
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 46)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 70
	bb.Parent = anchor

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 0.28
	lbl.BackgroundColor3 = Color3.fromRGB(10, 60, 40)
	lbl.Text = "🛡  商城區域  —  安全地帶"
	lbl.TextColor3 = Color3.fromRGB(140, 255, 180)
	lbl.TextStrokeTransparency = 0.3
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 17
	lbl.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = lbl
end

-- ── 三大戰鬥區域（圍繞生成點，左→右 = 最低階→最高階） ────────────
--   玩偶區（最簡單）：生成點左方 X = -150
--   野貓區（中等）  ：生成點前方 Z = -150（俯視圖上方）
--   野人區（最難）  ：生成點右方 X = +150

local zones: { {
	name: string,
	subLabel: string,
	center: Vector3,
	size: Vector3,
	color: BrickColor,
	labelColor: Color3,
} } = {
	{
		name = "🎪 玩偶區",
		subLabel = "初學者區域 · Lv.1~20",
		center = Vector3.new(-150, 0.3, 0),
		size = Vector3.new(120, 0.6, 120),
		color = BrickColor.new("Bright yellow"),
		labelColor = Color3.fromRGB(255, 230, 50),
	},
	{
		name = "🐱 野貓區",
		subLabel = "進階區域 · Lv.20~50",
		center = Vector3.new(0, 0.3, -150),
		size = Vector3.new(120, 0.6, 120),
		color = BrickColor.new("Bright orange"),
		labelColor = Color3.fromRGB(255, 160, 40),
	},
	{
		name = "💀 野人區",
		subLabel = "高難度區域 · Lv.50+",
		center = Vector3.new(150, 0.3, 0),
		size = Vector3.new(120, 0.6, 120),
		color = BrickColor.new("Bright red"),
		labelColor = Color3.fromRGB(255, 90, 90),
	},
}

for _, zone in ipairs(zones) do
	-- 地面色塊（保留，標示戰鬥範圍）
	makePart({
		name = zone.name,
		size = zone.size,
		cframe = CFrame.new(zone.center),
		color = zone.color,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.55,
		parent = workspace,
	})

	-- 高空光柱（細長半透明柱，從地面延伸到天空）
	local pillarHeight = 120
	makePart({
		name = zone.name .. "_Pillar",
		size = Vector3.new(4, pillarHeight, 4),
		cframe = CFrame.new(zone.center + Vector3.new(0, pillarHeight / 2, 0)),
		color = zone.color,
		material = Enum.Material.Neon,
		transparency = 0.82,
		parent = workspace,
	})

	-- 高空錨點 Part（不可見，BillboardGui 的掛載點）
	local signAnchor = makePart({
		name = zone.name .. "_SignAnchor",
		size = Vector3.new(0.1, 0.1, 0.1),
		cframe = CFrame.new(zone.center + Vector3.new(0, 90, 0)),
		color = BrickColor.new("Really black"),
		transparency = 1,
		parent = workspace,
	})

	-- 大型區域標示牌（高空，面向四方 AlwaysOnTop）
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 380, 0, 110)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 500  -- 遠距也看得到
	billboard.Parent = signAnchor

	-- 背景
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Parent = billboard
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 12)
	bgCorner.Parent = bg

	-- 名稱文字
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = zone.name
	nameLbl.TextColor3 = zone.labelColor
	nameLbl.TextStrokeTransparency = 0.1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = true
	nameLbl.Parent = billboard

	-- 副標題（等級範圍提示）
	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.new(1, 0, 0.38, 0)
	subLbl.Position = UDim2.new(0, 0, 0.58, 0)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = zone.subLabel or ""
	subLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	subLbl.TextStrokeTransparency = 0.4
	subLbl.Font = Enum.Font.Gotham
	subLbl.TextScaled = true
	subLbl.Parent = billboard
end

-- ── 短路徑（生成點 → 各區域） ────────────────────────────────────
local function makePath(from: Vector3, to: Vector3, width: number, color: BrickColor?)
	local mid = (from + to) / 2
	local len = (to - from).Magnitude
	local cf = CFrame.lookAt(mid, to) * CFrame.Angles(0, math.pi / 2, 0)
	makePart({
		name = "Path",
		size = Vector3.new(len, 0.5, width),
		cframe = cf * CFrame.new(0, -0.2, 0),
		color = color or BrickColor.new("Sand yellow"),
		material = Enum.Material.Ground,
		parent = workspace,
	})
end

-- 生成點 → 玩偶區（向左）
makePath(Vector3.new(-20, 0, 0), Vector3.new(-90, 0, 0), 12)
-- 生成點 → 野貓區（向前）
makePath(Vector3.new(0, 0, -20), Vector3.new(0, 0, -90), 12)
-- 生成點 → 野人區（向右）
makePath(Vector3.new(20, 0, 0), Vector3.new(90, 0, 0), 12)

-- ── 樹木裝飾（緊湊版） ───────────────────────────────────────────

-- 生成點四角樹叢
local cornerTrees: { Vector3 } = {
	Vector3.new(-30, 0,  30), Vector3.new( 30, 0,  30),
	Vector3.new(-30, 0, -30), Vector3.new( 30, 0, -30),
	Vector3.new(-50, 0,  10), Vector3.new( 50, 0,  10),
	Vector3.new(-10, 0,  50), Vector3.new( 10, 0,  50),
}
for _, pos in ipairs(cornerTrees) do makeTree(pos) end

-- 玩偶區周圍樹（左側）
for i = 1, 10 do
	local angle = (i / 10) * math.pi * 2
	makeTree(Vector3.new(-150 + math.cos(angle) * 80, 0, math.sin(angle) * 80))
end

-- 野貓區周圍樹（前方）
for i = 1, 10 do
	local angle = (i / 10) * math.pi * 2
	makeTree(Vector3.new(math.cos(angle) * 80, 0, -150 + math.sin(angle) * 80))
end

-- 野人區周圍樹（右側）
for i = 1, 10 do
	local angle = (i / 10) * math.pi * 2
	makeTree(Vector3.new(150 + math.cos(angle) * 80, 0, math.sin(angle) * 80), math.random(8, 12))
end

-- ── 邊界牆 ────────────────────────────────────────────────────────
local wallDefs: { { pos: Vector3, size: Vector3 } } = {
	{ pos = Vector3.new(  0, 15, -310), size = Vector3.new(640, 30, 6) }, -- 北牆
	{ pos = Vector3.new(  0, 15,  310), size = Vector3.new(640, 30, 6) }, -- 南牆
	{ pos = Vector3.new(-310, 15,   0), size = Vector3.new(6, 30, 640) }, -- 西牆
	{ pos = Vector3.new( 310, 15,   0), size = Vector3.new(6, 30, 640) }, -- 東牆
}
for i, w in ipairs(wallDefs) do
	makePart({
		name = "Wall_" .. i,
		size = w.size,
		cframe = CFrame.new(w.pos),
		color = BrickColor.new("Dark stone grey"),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.6,
		parent = workspace,
	})
end

-- ── 商店攤位（出生點南方，Z = +40，三棟並排） ───────────────────────
--   商城（貓咪）：X = -18  黃金色
--   裝備店：      X =   0  鐵藍色
--   合成台：      X = +18  紫色

local shopDefs: { {
	name: string,
	label: string,
	emoji: string,
	actionKey: string,
	pos: Vector3,
	bodyColor: BrickColor,
	roofColor: BrickColor,
	promptText: string,
} } = {
	{
		name = "ShopBuilding",
		label = "🛒 貓咪商城",
		emoji = "🐱",
		actionKey = "OpenShop",
		pos = Vector3.new(-18, 0, 40),
		bodyColor = BrickColor.new("Bright yellow"),
		roofColor = BrickColor.new("Bright orange"),
		promptText = "開啟貓咪商城",
	},
	{
		name = "EquipBuilding",
		label = "⚔ 裝備商店",
		emoji = "🗡",
		actionKey = "OpenEquip",
		pos = Vector3.new(0, 0, 40),
		bodyColor = BrickColor.new("Bright blue"),
		roofColor = BrickColor.new("Dark blue"),
		promptText = "開啟裝備商店",
	},
	{
		name = "SynthBuilding",
		label = "✨ 合成台",
		emoji = "🔮",
		actionKey = "OpenSynth",
		pos = Vector3.new(18, 0, 40),
		bodyColor = BrickColor.new("Bright violet"),
		roofColor = BrickColor.new("Dark indigo"),
		promptText = "開啟合成台",
	},
}

for _, def in ipairs(shopDefs) do
	local folder = Instance.new("Folder")
	folder.Name = def.name
	folder.Parent = workspace

	-- 底座平台
	local base = makePart({
		name = "Base",
		size = Vector3.new(14, 0.5, 12),
		cframe = CFrame.new(def.pos + Vector3.new(0, 0.25, 0)),
		color = BrickColor.new("Medium stone grey"),
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- 主體牆
	local body = makePart({
		name = "Body",
		size = Vector3.new(12, 6, 10),
		cframe = CFrame.new(def.pos + Vector3.new(0, 3.5, 0)),
		color = def.bodyColor,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})

	-- 屋頂（棱形）
	local roof = makePart({
		name = "Roof",
		size = Vector3.new(14, 2, 12),
		cframe = CFrame.new(def.pos + Vector3.new(0, 7.5, 0)),
		color = def.roofColor,
		material = Enum.Material.SmoothPlastic,
		parent = folder,
	})
	roof.Shape = Enum.PartType.Block

	-- 門牌（正面嵌入牆壁，純裝飾，不掛 BillboardGui 避免疊文字）
	makePart({
		name = "Sign",
		size = Vector3.new(8, 1.6, 0.3),
		cframe = CFrame.new(def.pos + Vector3.new(0, 5.8, -5.15)),
		color = BrickColor.new("Really black"),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.15,
		parent = folder,
	})

	-- 高空獨立錨點（屋頂上方 +10 格，避免與建築本體重疊）
	local signAnchor = makePart({
		name = "ShopSignAnchor",
		size = Vector3.new(0.1, 0.1, 0.1),
		cframe = CFrame.new(def.pos + Vector3.new(0, 18, 0)),
		color = BrickColor.new("Really black"),
		transparency = 1,
		parent = folder,
	})

	-- 看板 BillboardGui（掛在高空錨點，向下 0 偏移，遠距也清晰）
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ShopBillboard"
	billboard.Size = UDim2.new(0, 260, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 120
	billboard.Parent = signAnchor

	-- 背景框
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Parent = billboard
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 10)
	bgCorner.Parent = bg

	-- 大圖示（上半）
	local emojiLbl = Instance.new("TextLabel")
	emojiLbl.Size = UDim2.new(1, 0, 0.46, 0)
	emojiLbl.BackgroundTransparency = 1
	emojiLbl.Text = def.emoji
	emojiLbl.TextScaled = true
	emojiLbl.Font = Enum.Font.GothamBold
	emojiLbl.TextColor3 = Color3.new(1, 1, 1)
	emojiLbl.TextStrokeTransparency = 0.1
	emojiLbl.Parent = billboard

	-- 名稱文字（下半）
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0.44, 0)
	nameLbl.Position = UDim2.new(0, 0, 0.52, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = def.label
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.TextStrokeTransparency = 0.3
	nameLbl.Parent = billboard

	-- ProximityPrompt（放在 Body 上）
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ObjectText = def.label
	prompt.ActionText = def.promptText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0
	-- 用 Attribute 讓客戶端識別開哪個介面
	prompt:SetAttribute("ShopAction", def.actionKey)
	prompt.Parent = body
end

-- ── 光照 ──────────────────────────────────────────────────────────
Lighting.Brightness = 2.5
Lighting.ClockTime = 14
Lighting.FogEnd = 600
Lighting.FogColor = Color3.fromRGB(180, 210, 230)
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(70, 70, 80)
Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 110)

local sky = Instance.new("Sky")
sky.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.3
bloom.Size = 24
bloom.Threshold = 0.95
bloom.Parent = Lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(180, 210, 255)
atmosphere.Decay = Color3.fromRGB(80, 100, 140)
atmosphere.Glare = 0.1
atmosphere.Haze = 1.5
atmosphere.Parent = Lighting
