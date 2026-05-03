local CatVisualData = {}

CatVisualData.colors = {
	whiteCat = Color3.fromRGB(245, 245, 245),
	shadowCat = Color3.fromRGB(55, 55, 70),
	flameCat = Color3.fromRGB(255, 120, 60),
	frostCat = Color3.fromRGB(170, 225, 255),
	thunderCat = Color3.fromRGB(255, 235, 120),
	sakuraCat = Color3.fromRGB(255, 185, 220),
	orangeCat = Color3.fromRGB(255, 170, 80),
	calicoCat = Color3.fromRGB(230, 200, 170),
	tuxedoCat = Color3.fromRGB(40, 40, 40),
}

CatVisualData.marks = {
	tuxedoCat = {
		{ name = "CatMark_Tuxedo", size = Vector3.new(0.7, 0.6, 0.1), offset = Vector3.new(0, -0.15, -0.62), color = Color3.fromRGB(245, 245, 245) },
	},
	calicoCat = {
		{ name = "CatMark_CalicoA", size = Vector3.new(0.35, 0.35, 0.1), offset = Vector3.new(-0.25, 0.1, -0.62), color = Color3.fromRGB(255, 155, 80) },
		{ name = "CatMark_CalicoB", size = Vector3.new(0.35, 0.35, 0.1), offset = Vector3.new(0.25, -0.05, -0.62), color = Color3.fromRGB(40, 40, 40) },
	},
	orangeCat = {
		{ name = "CatMark_Orange", size = Vector3.new(0.9, 0.18, 0.1), offset = Vector3.new(0, 0.28, -0.62), color = Color3.fromRGB(255, 130, 40) },
	},
	whiteCat = {
		{ name = "CatMark_WhiteNose", size = Vector3.new(0.45, 0.25, 0.1), offset = Vector3.new(0, -0.05, -0.62), color = Color3.fromRGB(255, 200, 210) },
	},
	shadowCat = {
		{ name = "CatMark_Shadow", size = Vector3.new(0.8, 0.12, 0.1), offset = Vector3.new(0, 0.25, -0.62), color = Color3.fromRGB(120, 90, 220) },
	},
	flameCat = {
		{ name = "CatMark_Flame", size = Vector3.new(0.25, 0.45, 0.1), offset = Vector3.new(0, 0.1, -0.62), color = Color3.fromRGB(255, 80, 30) },
	},
	frostCat = {
		{ name = "CatMark_Frost", size = Vector3.new(0.8, 0.14, 0.1), offset = Vector3.new(0, -0.15, -0.62), color = Color3.fromRGB(210, 245, 255) },
	},
	thunderCat = {
		{ name = "CatMark_Thunder", size = Vector3.new(0.2, 0.45, 0.1), offset = Vector3.new(-0.1, 0.05, -0.62), color = Color3.fromRGB(255, 235, 80) },
	},
	sakuraCat = {
		{ name = "CatMark_Sakura", size = Vector3.new(0.6, 0.2, 0.1), offset = Vector3.new(0, -0.2, -0.62), color = Color3.fromRGB(255, 220, 240) },
	},
}

return CatVisualData
