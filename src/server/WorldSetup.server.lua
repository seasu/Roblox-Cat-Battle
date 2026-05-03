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
	local h = height or (math.random(8, 14))
	local folder = Instance.new("Folder")
	folder.Name = "Tree"
	folder.Parent = workspace

	makePart({
		name = "Trunk",
		size = Vector3.new(1.5, h, 1.5),
		cframe = CFrame.new(pos + Vector3.new(0, h / 2, 0)),
		color = BrickColor.new("Reddish brown"),
		material = Enum.Material.Wood,
		parent = folder,
	})
	makePart({
		name = "Leaves",
		size = Vector3.new(h * 0.9, h * 0.8, h * 0.9),
		cframe = CFrame.new(pos + Vector3.new(0, h + h * 0.3, 0)),
		color = BrickColor.new("Bright green"),
		material = Enum.Material.Grass,
		parent = folder,
	})
end

local function makeRock(pos: Vector3, size: Vector3?)
	local s = size or Vector3.new(math.random(3, 7), math.random(2, 4), math.random(3, 7))
	makePart({
		name = "Rock",
		size = s,
		cframe = CFrame.new(pos + Vector3.new(0, s.Y / 2, 0)) * CFrame.Angles(0, math.random() * math.pi, 0),
		color = BrickColor.new("Dark grey"),
		material = Enum.Material.Slate,
		parent = workspace,
	})
end

-- 在兩點之間建立道路
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

-- ── 地板 ──────────────────────────────────────────────────────────
makePart({
	name = "Baseplate",
	size = Vector3.new(2048, 20, 2048),
	cframe = CFrame.new(100, -10, 400),
	color = BrickColor.new("Medium green"),
	material = Enum.Material.Grass,
	parent = workspace,
})

-- ── 生成點 ────────────────────────────────────────────────────────
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "SpawnLocation"
spawnLocation.Anchored = true
spawnLocation.Size = Vector3.new(12, 1, 12)
spawnLocation.CFrame = CFrame.new(0, 0.5, 0)
spawnLocation.BrickColor = BrickColor.new("Bright blue")
spawnLocation.Material = Enum.Material.SmoothPlastic
spawnLocation.Transparency = 0.2
spawnLocation.Duration = 0
spawnLocation.Parent = workspace

-- ── 安全廣場（生成點周圍） ────────────────────────────────────────
makePart({
	name = "SafeZone",
	size = Vector3.new(80, 0.5, 80),
	cframe = CFrame.new(0, 0.2, 0),
	color = BrickColor.new("Bright blue"),
	material = Enum.Material.SmoothPlastic,
	transparency = 0.8,
	parent = workspace,
})

-- ── 三大戰鬥區域 ─────────────────────────────────────────────────

local zones: { {
	name: string,
	center: Vector3,
	size: Vector3,
	color: BrickColor,
	labelColor: Color3,
} } = {
	{
		name = "玩偶區",
		center = Vector3.new(0, 0.3, 300),
		size = Vector3.new(260, 0.6, 220),
		color = BrickColor.new("Bright yellow"),
		labelColor = Color3.fromRGB(255, 230, 50),
	},
	{
		name = "野貓區",
		center = Vector3.new(330, 0.3, 490),
		size = Vector3.new(280, 0.6, 240),
		color = BrickColor.new("Bright orange"),
		labelColor = Color3.fromRGB(255, 140, 30),
	},
	{
		name = "野人區",
		center = Vector3.new(-80, 0.3, 760),
		size = Vector3.new(300, 0.6, 280),
		color = BrickColor.new("Bright red"),
		labelColor = Color3.fromRGB(255, 80, 80),
	},
}

for _, zone in ipairs(zones) do
	-- 地板標示
	local tile = makePart({
		name = zone.name,
		size = zone.size,
		cframe = CFrame.new(zone.center),
		color = zone.color,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.55,
		parent = workspace,
	})

	-- 區域名稱牌（大型 BillboardGui）
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
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
	label.TextSize = 32
	label.Parent = billboard
end

-- ── 道路（連接各區域） ─────────────────────────────────────────────

-- 生成點 → 玩偶區
makePath(Vector3.new(0, 0, 50), Vector3.new(0, 0, 190), 18)
-- 玩偶區 → 野貓區
makePath(Vector3.new(80, 0, 330), Vector3.new(260, 0, 430), 16)
-- 玩偶區 → 野人區
makePath(Vector3.new(-30, 0, 390), Vector3.new(-60, 0, 650), 16)

-- ── 樹木裝飾 ─────────────────────────────────────────────────────

-- 生成點兩側樹林
local safeTreePositions: { Vector3 } = {
	Vector3.new(-60, 0, 30),  Vector3.new(60, 0, 30),
	Vector3.new(-80, 0, -20), Vector3.new(80, 0, -20),
	Vector3.new(-50, 0, 80),  Vector3.new(50, 0, 80),
	Vector3.new(-100, 0, 50), Vector3.new(100, 0, 50),
	Vector3.new(-120, 0, 10), Vector3.new(120, 0, 10),
}
for _, pos in ipairs(safeTreePositions) do makeTree(pos) end

-- 道路兩側隨機樹木
for i = 1, 30 do
	local z = math.random(100, 200)
	local side = math.random() > 0.5 and 25 or -25
	makeTree(Vector3.new(side + math.random(-5, 5), 0, z))
end

-- 野貓區周圍樹木
for i = 1, 20 do
	local angle = (i / 20) * math.pi * 2
	local r = math.random(150, 180)
	makeTree(Vector3.new(330 + math.cos(angle) * r, 0, 490 + math.sin(angle) * r))
end

-- 野人區周圍樹木（濃密叢林感）
for i = 1, 25 do
	local angle = (i / 25) * math.pi * 2
	local r = math.random(160, 200)
	makeTree(Vector3.new(-80 + math.cos(angle) * r, 0, 760 + math.sin(angle) * r), math.random(12, 18))
end

-- ── 岩石裝飾 ─────────────────────────────────────────────────────

local rockPositions: { Vector3 } = {
	Vector3.new(120, 0, 150), Vector3.new(-110, 0, 180),
	Vector3.new(200, 0, 380), Vector3.new(-180, 0, 350),
	Vector3.new(450, 0, 400), Vector3.new(500, 0, 550),
	Vector3.new(-250, 0, 700), Vector3.new(120, 0, 800),
	Vector3.new(50, 0, 500),  Vector3.new(-150, 0, 550),
}
for _, pos in ipairs(rockPositions) do
	makeRock(pos)
	-- 每個大石頭旁邊加幾個小石頭
	for _ = 1, math.random(1, 3) do
		makeRock(
			pos + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)),
			Vector3.new(math.random(1, 3), math.random(1, 2), math.random(1, 3))
		)
	end
end

-- ── 邊界牆 ────────────────────────────────────────────────────────
local wallDefs: { { pos: Vector3, size: Vector3 } } = {
	{ pos = Vector3.new(100, 20, -200),  size = Vector3.new(800, 40, 6) },  -- 南牆
	{ pos = Vector3.new(100, 20, 1000),  size = Vector3.new(800, 40, 6) },  -- 北牆
	{ pos = Vector3.new(-300, 20, 400),  size = Vector3.new(6, 40, 1200) }, -- 西牆
	{ pos = Vector3.new(500, 20, 400),   size = Vector3.new(6, 40, 1200) }, -- 東牆
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
Lighting.FogEnd = 800
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
