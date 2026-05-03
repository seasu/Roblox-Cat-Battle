local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CombatClient = {}

local localPlayer = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local useSkillEvent = remoteEvents:WaitForChild("UseSkill") :: RemoteEvent

-- 目前技能列映射：slot -> skillId（由 GameClient 在初始化後設置）
CombatClient.skillSlots = {} :: { string }

-- 快捷鍵對應（第 2–6 槽）
local KEY_BINDINGS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.Q] = 2,
	[Enum.KeyCode.E] = 3,
	[Enum.KeyCode.R] = 4,
	[Enum.KeyCode.F] = 5,
	[Enum.KeyCode.T] = 6,
}

local function getMouseTarget(): (string?, Vector3?)
	local camera = workspace.CurrentCamera
	local mouse = localPlayer:GetMouse()
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100)
	if not result then return nil, nil end

	local hit = result.Instance
	local npcModel = hit:FindFirstAncestorWhichIsA("Model")
	if npcModel then
		local idValue = npcModel:FindFirstChild("InstanceId")
		if idValue then
			return (idValue :: StringValue).Value, result.Position
		end
	end
	return nil, result.Position
end

function CombatClient.attemptBasicAttack()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local instanceId, hitPos = getMouseTarget()
	if instanceId then
		useSkillEvent:FireServer("BasicSwipe", instanceId)
		if hitPos then
			CombatClient.showDamageNumber(hitPos, "?", false)
		end
	end
end

function CombatClient.activateSkill(slotIndex: number)
	local skillId = CombatClient.skillSlots[slotIndex]
	if not skillId then return end

	local instanceId, _ = getMouseTarget()
	useSkillEvent:FireServer(skillId, instanceId)
end

function CombatClient.showDamageNumber(position: Vector3, damage: number | string, isCrit: boolean)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Parent = workspace
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Parent = billboard
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(damage)
	label.Font = Enum.Font.GothamBold
	label.TextSize = isCrit and 28 or 20
	label.TextColor3 = isCrit and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 80)
	label.TextStrokeTransparency = 0.3

	-- 向上飄移並淡出
	local tweenPart = TweenService:Create(part,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = position + Vector3.new(0, 4, 0) })
	local tweenLabel = TweenService:Create(label,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 })

	tweenPart:Play()
	tweenLabel:Play()

	game:GetService("Debris"):AddItem(part, 1.6)
end

function CombatClient.onSkillResult(
	skillId: string,
	targets: { string },
	damage: number,
	cooldown: number,
	extra: string?
)
	local UIManager = require(script.Parent.UIManager)
	UIManager.updateSkillCooldown(skillId, cooldown)
end

function CombatClient.onNPCDied(instanceId: string)
	-- 清除場景上對應的 NPC BillboardGui
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("StringValue") and obj.Name == "InstanceId" and obj.Value == instanceId then
			local model = obj.Parent
			if model then
				model:Destroy()
			end
			break
		end
	end
end

function CombatClient.init()
	-- 滑鼠左鍵攻擊
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			CombatClient.attemptBasicAttack()
			return
		end

		local slotIndex = KEY_BINDINGS[input.KeyCode]
		if slotIndex then
			CombatClient.activateSkill(slotIndex)
		end
	end)

	-- 手機觸控
	UserInputService.TouchTap:Connect(function(touchPositions: { Vector2 }, gameProcessed: boolean)
		if gameProcessed then return end
		CombatClient.attemptBasicAttack()
	end)
end

return CombatClient
