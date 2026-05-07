-- CatVisualData.lua
-- 定義高質感 3D 資產配置 (PBR & MeshPart 導向)

local CatVisualData = {}

--[[
    架構說明：
    - baseSuit: 用於 Layered Clothing 的基礎皮毛套裝 (WrapLayer)
    - headMesh: 貓咪高模頭部 MeshID
    - headTexture: 臉部與頭部貼圖
    - tailMesh: 貓咪尾巴 MeshID
    - surfaceAppearance: PBR 材質映射 (ColorMap, NormalMap, RoughnessMap, MetalnessMap)
]]

-- 預設預留位 ID (實作時請替換為實際匯入的 Asset ID)
local PLACEHOLDER_MESH = "rbxassetid://0" -- 待替換為實際 MeshID
local PLACEHOLDER_TEX  = "rbxassetid://0" -- 待替換為實際 TextureID

CatVisualData.cats = {
	whiteCat = {
		name = "白貓",
		baseColor = Color3.fromRGB(255, 255, 255),
		baseSuitAssetId = "rbxassetid://91532946724584",
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808", -- 還原為可靠 Mesh ID 模式
		-- 支援動態表情切換
		faces = {
			idle = PLACEHOLDER_TEX,
			blink = PLACEHOLDER_TEX,
			combat = PLACEHOLDER_TEX,
		}
	},
	shadowCat = {
		name = "暗影貓",
		baseColor = Color3.fromRGB(50, 50, 70),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	flameCat = {
		name = "烈焰貓",
		baseColor = Color3.fromRGB(255, 80, 0),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	frostCat = {
		name = "冰霜貓",
		baseColor = Color3.fromRGB(180, 230, 255),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	thunderCat = {
		name = "雷霆貓",
		baseColor = Color3.fromRGB(255, 240, 100),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	sakuraCat = {
		name = "櫻花貓",
		baseColor = Color3.fromRGB(255, 200, 220),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	orangeCat = {
		name = "橘貓",
		baseColor = Color3.fromRGB(255, 160, 60),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	calicoCat = {
		name = "三花貓",
		baseColor = Color3.fromRGB(240, 220, 200),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
	tuxedoCat = {
		name = "賓士貓",
		baseColor = Color3.fromRGB(30, 30, 30),
		headMeshId = "rbxassetid://1635970808",
		headTextureId = PLACEHOLDER_TEX,
		tailMeshId = "rbxassetid://1635970808",
		faces = { idle = PLACEHOLDER_TEX, combat = PLACEHOLDER_TEX }
	},
}

-- 保留舊有的顏色映射供向下相容使用
CatVisualData.colors = {}
for id, data in pairs(CatVisualData.cats) do
	CatVisualData.colors[id] = data.baseColor
end

return CatVisualData
