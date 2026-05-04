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

-- ── 安全廣場（生成點周圍，小範圍） ──────────────────────────────
makePart({
	name = "SafeZone",
	size = Vector3.new(40, 0.5, 40),
	cframe = CFrame.new(0, 0.2, 0),
	color = BrickColor.new("Bright blue"),
	material = Enum.Material.SmoothPlastic,
	transparency = 0.8,
	parent = workspace,
})

-- ── 三大戰鬥區域（圍繞生成點，左→右 = 最低階→最高階） ────────────
--   玩偶區（最簡單）：生成點左方 X = -150
--   野貓區（中等）  ：生成點前方 Z = -150（俯視圖上方）
--   野人區（最難）  ：生成點右方 X = +150

local zones: { {
	name: string,
	center: Vector3,
	size: Vector3,
	color: BrickColor,
	labelColor: Color3,
} } = {
	{
		name = "【玩偶區】",
		center = Vector3.new(-150, 0.3, 0),
		size = Vector3.new(120, 0.6, 120),
		color = BrickColor.new("Bright yellow"),
		labelColor = Color3.fromRGB(255, 230, 50),
	},
	{
		name = "【野貓區】",
		center = Vector3.new(0, 0.3, -150),
		size = Vector3.new(120, 0.6, 120),
		color = BrickColor.new("Bright orange"),
		labelColor = Color3.fromRGB(255, 140, 30),
	},
	{
		name = "【野人區】",
		center = Vector3.new(150, 0.3, 0),
		size = Vector3.new(120, 0.6, 120),
		color = BrickColor.new("Bright red"),
		labelColor = Color3.fromRGB(255, 80, 80),
	},
}

for _, zone in ipairs(zones) do
	local tile = makePart({
		name = zone.name,
		size = zone.size,
		cframe = CFrame.new(zone.center),
		color = zone.color,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.55,
		parent = workspace,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 240, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 10, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = tile

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = zone.name
	label.TextColor3 = zone.labelColor
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 28
	label.Parent = billboard
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
