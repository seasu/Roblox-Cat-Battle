-- CatLocomotion.client.lua
-- 模擬四足貓咪步態：對角步法 + 身體起伏 + 低重心
-- 放在 StarterCharacterScripts（LocalScript，每次角色生成自動執行）

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local character  = script.Parent
local humanoid   = character:WaitForChild("Humanoid") :: Humanoid
local hrp        = character:WaitForChild("HumanoidRootPart") :: BasePart

-- ── 設定 ─────────────────────────────────────────────────────────

-- 貓咪低重心（R6 預設 HipHeight=2，貓咪壓低到 1.2）
humanoid.HipHeight = 1.2

-- ── Motor6D 取得工具 ─────────────────────────────────────────────

-- 快取各關節（R6/R15 雙支援）
local motors: { [string]: Motor6D } = {}

local function cacheMotors()
	-- R6
	local torso = character:FindFirstChild("Torso")
	if torso then
		for _, name in ipairs({"Right Arm", "Left Arm", "Right Leg", "Left Leg"}) do
			local m = torso:FindFirstChild(name)
			if m and m:IsA("Motor6D") then motors[name] = m end
		end
	end
	-- R15 上半身
	local upper = character:FindFirstChild("UpperTorso")
	if upper then
		for _, name in ipairs({"RightShoulder", "LeftShoulder"}) do
			local m = upper:FindFirstChild(name)
			if m and m:IsA("Motor6D") then motors[name] = m end
		end
	end
	-- R15 下半身
	local lower = character:FindFirstChild("LowerTorso")
	if lower then
		local m = lower:FindFirstChild("Root")
		if m and m:IsA("Motor6D") then motors["Root"] = m end
	end
	local ruLeg = character:FindFirstChild("RightUpperLeg")
	if ruLeg then
		local m = ruLeg:FindFirstChild("RightHip")
		if m and m:IsA("Motor6D") then motors["RightHip"] = m end
	end
	local luLeg = character:FindFirstChild("LeftUpperLeg")
	if luLeg then
		local m = luLeg:FindFirstChild("LeftHip")
		if m and m:IsA("Motor6D") then motors["LeftHip"] = m end
	end
end

cacheMotors()

-- 判斷 R6 還是 R15
local isR6 = character:FindFirstChild("Torso") ~= nil

-- R6 根關節（身體起伏用）
if isR6 then
	local hrpRootJoint = hrp:FindFirstChild("RootJoint")
	if hrpRootJoint and hrpRootJoint:IsA("Motor6D") then
		motors["RootJoint"] = hrpRootJoint
	end
end

-- ── 步態參數 ─────────────────────────────────────────────────────

local WALK_FREQ      = 3.5   -- 步頻（Hz），越高越快
local RUN_FREQ       = 6.0   -- 跑步步頻
local STRIDE_ARM     = 0.65  -- 手臂擺動幅度（弧度）
local STRIDE_LEG     = 0.75  -- 腿部擺動幅度
local BODY_BOB_AMP   = 0.06  -- 身體上下起伏幅度（弧度）
local SIDE_LEAN_AMP  = 0.04  -- 左右微幅傾斜
local SPEED_THRESH   = 0.5   -- 低於此速度視為靜止

-- 靜止時手臂微微往前傾（貓蹲伏姿態）
local IDLE_ARM_LEAN  = 0.30  -- 弧度（向前傾）
local IDLE_LEG_LEAN  = 0.20

-- ── 平滑插值工具 ─────────────────────────────────────────────────

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- ── 攻擊動畫互斥 ─────────────────────────────────────────────────
-- CombatClient 設置 _G.catSwingActive = true 時，手臂讓出控制權

-- ── 步態狀態 ─────────────────────────────────────────────────────

local phase = 0.0          -- 全局步態相位（0~1 循環）
local smoothSpeed = 0.0    -- 平滑後的移動速度

-- 各關節目前的 Transform 角度（用於平滑過渡）
local angles = {
	rightArm = 0.0,
	leftArm  = 0.0,
	rightLeg = 0.0,
	leftLeg  = 0.0,
	bodyBob  = 0.0,
	sideLean = 0.0,
}

-- ── 主迴圈 ───────────────────────────────────────────────────────

local connection: RBXScriptConnection?

connection = RunService.Heartbeat:Connect(function(dt: number)
	-- 角色已不存在時停止
	if not character.Parent then
		if connection then connection:Disconnect() end
		return
	end

	-- 取得移動速度
	local vel = hrp.AssemblyLinearVelocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	smoothSpeed = lerp(smoothSpeed, speed, math.min(dt * 12, 1))

	local isMoving = smoothSpeed > SPEED_THRESH
	local isRunning = smoothSpeed > 8
	local freq = isRunning and RUN_FREQ or WALK_FREQ

	-- 更新相位
	if isMoving then
		phase = (phase + dt * freq) % 1.0
	else
		-- 靜止時相位緩慢歸零（貓咪蹲伏待機姿態）
		phase = lerp(phase, 0, dt * 4)
	end

	local p = phase * math.pi * 2  -- 轉換為弧度 0~2π

	-- ── 計算目標角度 ─────────────────────────────────────────────

	local targetAngles: { [string]: number }

	if isMoving then
		-- 對角步法（Trot）：右前+左後 同相，左前+右後 反相
		-- 右手向後擺時右腿向前踢（對角），給人四肢交替感
		local strideA = (isRunning and STRIDE_ARM * 1.2 or STRIDE_ARM)
		local strideL = (isRunning and STRIDE_LEG * 1.2 or STRIDE_LEG)
		local bob     = math.sin(p * 2) * BODY_BOB_AMP  -- 身體每步起伏兩次
		local lean    = math.sin(p)     * SIDE_LEAN_AMP

		targetAngles = {
			rightArm = -math.sin(p)          * strideA,  -- 右手前後擺
			leftArm  =  math.sin(p)          * strideA,  -- 左手反相
			rightLeg = -math.sin(p + math.pi) * strideL, -- 右腿（與左手同相）
			leftLeg  =  math.sin(p + math.pi) * strideL, -- 左腿（與右手同相）
			bodyBob  = bob,
			sideLean = lean,
		}
	else
		-- 靜止蹲伏：手臂微向前傾，腿微彎（貓咪蹲姿）
		targetAngles = {
			rightArm = IDLE_ARM_LEAN,
			leftArm  = IDLE_ARM_LEAN,
			rightLeg = IDLE_LEG_LEAN,
			leftLeg  = IDLE_LEG_LEAN,
			bodyBob  = 0,
			sideLean = 0,
		}
	end

	-- 平滑插值到目標角度
	local smoothFactor = math.min(dt * 18, 1)
	for k, v in pairs(targetAngles) do
		angles[k] = lerp(angles[k], v, smoothFactor)
	end

	-- ── 套用到 Motor6D ──────────────────────────────────────────

	-- 攻擊時不碰手臂（讓 CombatClient 的揮手動畫獨占）
	local swingActive = _G.catSwingActive == true

	if isR6 then
		-- R6 手臂
		if not swingActive then
			local mRA = motors["Right Arm"]
			if mRA then
				mRA.Transform = CFrame.Angles(angles.rightArm, 0, -0.08)
			end
			local mLA = motors["Left Arm"]
			if mLA then
				mLA.Transform = CFrame.Angles(angles.leftArm, 0, 0.08)
			end
		end
		-- R6 腿
		local mRL = motors["Right Leg"]
		if mRL then
			mRL.Transform = CFrame.Angles(angles.rightLeg, 0, 0)
		end
		local mLL = motors["Left Leg"]
		if mLL then
			mLL.Transform = CFrame.Angles(angles.leftLeg, 0, 0)
		end
	else
		-- R15 手臂
		if not swingActive then
			local mRS = motors["RightShoulder"]
			if mRS then
				mRS.Transform = CFrame.Angles(angles.rightArm, 0, -0.06)
			end
			local mLS = motors["LeftShoulder"]
			if mLS then
				mLS.Transform = CFrame.Angles(angles.leftArm, 0, 0.06)
			end
		end
		-- R15 腿
		local mRH = motors["RightHip"]
		if mRH then
			mRH.Transform = CFrame.Angles(angles.rightLeg, 0, 0)
		end
		local mLH = motors["LeftHip"]
		if mLH then
			mLH.Transform = CFrame.Angles(angles.leftLeg, 0, 0)
		end
	end

	-- 身體起伏與側傾：透過 Torso（R6）或 UpperTorso（R15）的 Motor6D.Transform 控制
	-- 這比直接修改 HRP.CFrame 更安全（不干擾物理）
	local bodyBobAngle  = angles.bodyBob
	local bodySideAngle = angles.sideLean

	if isR6 then
		local rootJoint = motors["RootJoint"]
		if rootJoint then
			rootJoint.Transform = CFrame.Angles(bodyBobAngle * 0.4, 0, bodySideAngle)
		end
	else
		-- R15：LowerTorso 由 HRP 的 "Root" Motor6D 控制
		local rootM = motors["Root"]
		if rootM then
			rootM.Transform = CFrame.Angles(bodyBobAngle * 0.4, 0, bodySideAngle)
		end
	end
end)

-- 角色死亡時清理
humanoid.Died:Connect(function()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	-- 重置所有 Motor6D Transform
	for _, m in pairs(motors) do
		m.Transform = CFrame.identity
	end
	humanoid.HipHeight = 2  -- 恢復預設
end)
