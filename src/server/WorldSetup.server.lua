local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- 地板
local baseplate = Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Anchored = true
baseplate.Size = Vector3.new(512, 20, 512)
baseplate.CFrame = CFrame.new(0, -10, 0)
baseplate.BrickColor = BrickColor.new("Medium green")
baseplate.Material = Enum.Material.Grass
baseplate.TopSurface = Enum.SurfaceType.Smooth
baseplate.BottomSurface = Enum.SurfaceType.Smooth
baseplate.Parent = workspace

-- 玩家生成點
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "SpawnLocation"
spawnLocation.Anchored = true
spawnLocation.Size = Vector3.new(10, 1, 10)
spawnLocation.CFrame = CFrame.new(0, 0.5, 0)
spawnLocation.BrickColor = BrickColor.new("Bright blue")
spawnLocation.Material = Enum.Material.SmoothPlastic
spawnLocation.Transparency = 0.3
spawnLocation.Duration = 0
spawnLocation.Parent = workspace

-- 區域地板標示
local zones: { { name: string, center: Vector3, size: Vector3, color: BrickColor } } = {
	{
		name = "玩偶區",
		center = Vector3.new(35, 0.3, 10),
		size = Vector3.new(80, 1, 30),
		color = BrickColor.new("Bright yellow"),
	},
	{
		name = "野貓區",
		center = Vector3.new(35, 0.3, 40),
		size = Vector3.new(80, 1, 30),
		color = BrickColor.new("Bright orange"),
	},
	{
		name = "野人區",
		center = Vector3.new(35, 0.3, 70),
		size = Vector3.new(80, 1, 30),
		color = BrickColor.new("Bright red"),
	},
}

for _, zone in ipairs(zones) do
	local tile = Instance.new("Part")
	tile.Name = zone.name
	tile.Anchored = true
	tile.Size = zone.size
	tile.CFrame = CFrame.new(zone.center)
	tile.BrickColor = zone.color
	tile.Material = Enum.Material.SmoothPlastic
	tile.Transparency = 0.4
	tile.TopSurface = Enum.SurfaceType.Smooth
	tile.BottomSurface = Enum.SurfaceType.Smooth
	tile.Parent = workspace

	-- 區域名稱牌
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = tile

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = zone.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.Parent = billboard
end

-- 邊界牆（防止玩家跑出地圖）
local wallConfigs: { { pos: Vector3, size: Vector3 } } = {
	{ pos = Vector3.new(0, 15, -60),  size = Vector3.new(200, 30, 4) },   -- 北牆
	{ pos = Vector3.new(0, 15, 100),  size = Vector3.new(200, 30, 4) },   -- 南牆
	{ pos = Vector3.new(-100, 15, 20), size = Vector3.new(4, 30, 160) },  -- 西牆
	{ pos = Vector3.new(120, 15, 20), size = Vector3.new(4, 30, 160) },   -- 東牆
}

for i, cfg in ipairs(wallConfigs) do
	local wall = Instance.new("Part")
	wall.Name = "Wall_" .. i
	wall.Anchored = true
	wall.Size = cfg.size
	wall.CFrame = CFrame.new(cfg.pos)
	wall.BrickColor = BrickColor.new("Dark grey")
	wall.Material = Enum.Material.SmoothPlastic
	wall.Transparency = 0.7
	wall.Parent = workspace
end

-- 基本光照設定
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.FogEnd = 500
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(80, 80, 80)

-- 天空盒
local sky = Instance.new("Sky")
sky.Parent = Lighting
