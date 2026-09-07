local cvar_VisualRecoil = CreateConVar("trmbase_sv_mod_visual_recoil", 1, FCVAR_ARCHIVE, "", 0, 10)
local vrecoil = Angle(0, 0, 0)
local progress = 0
local backforward = 0

function SWEP:DoVisualRecoil()
	--暂时搁置
	vrecoil = self:GetVisualRecoil()
	local AdsScale = Lerp(self:GetAimDelta(), 1, self.VisualRecoil.AdsMultiplier)

	-- 基础随机抖动
	local basePitch = math.Rand(self.VisualRecoil.Vertical[1], self.VisualRecoil.Vertical[2]) * AdsScale
	local baseYaw = math.Rand(self.VisualRecoil.Horizonal[1], self.VisualRecoil.Horizonal[2]) * AdsScale

	local baseRoll = baseYaw * 0.3 * AdsScale

	-- ==========================================
	-- 程序化视觉后坐力（基于进度）
	-- ==========================================
	local progPitch, progYaw, progBack = 0, 0, 0
	if self.VisualRecoil.Functional and self.VisualRecoil.Functional.Func then
		local maxclip = self:GetMaxClip1()
		-- 获取当前进度
		progress = self:GetSprayRound() / (maxclip > 0 and maxclip or 30) or 0
		-- 调用自定义函数
		progPitch, progYaw, progBack = self.VisualRecoil.Functional.Func(
			self,
			progress
		)

		-- 应用倍率
		progPitch = progPitch * AdsScale
		progYaw = progYaw * AdsScale
		progBack = progBack * AdsScale
	end

	local totalP, totalY, totalRoll =
		-basePitch - progPitch,
		-baseYaw - progYaw,
		-baseRoll

	-- 合并基础抖动和程序化抖动

	vrecoil:Add(Angle(totalP, totalY, totalRoll) * cvar_VisualRecoil:GetFloat())


	self:SetVisualRecoil(vrecoil)
	-- ==========================================
	-- 视觉后坐力后退（Backward）
	-- ==========================================
end

function SWEP:Recover()
	if CLIENT then
		
		return
	end
	local owner = self:GetOwner()


	local last = self:GetLastFireTime()
	local Curtime = UnPredictedCurTime()
	local delay = 60 / self.Primary.RPM -- second
	local ft = FrameTime()
	--VRecoil(Angle)
	if Curtime - last > (self.VisualRecoil.RecoverDelay or 0) then
		local Vrecoil = self:GetVisualRecoil()
		Vrecoil = LerpAngle(ft * self.VisualRecoil.RecoverSpeed * 10, Vrecoil, Angle(0, 0, 0))
		self:SetVisualRecoil(Vrecoil)
		--VRecoil(Vector)
	end





	--spread
	if Curtime - last > (self.Spread.Delay or 0) then
		local spread = self:GetSpread()
		local min, max = self.Spread.Base, self.Spread.Max
		if min > max then
			min, max = max, min
		end
		spread = math.Clamp(spread - self.Spread.Recover * ft, self.Spread.Base, self.Spread.Max)
		self:SetSpread(spread)
	end

	---Recoil Spray
	local factor = math.Clamp(self.Recoil.Factor / (ft * 70), 0.01, 0.99)
	self:SetRecoilUp(self:GetRecoilUp() * factor)
	self:SetRecoilSide(self:GetRecoilSide() * factor)
	--
end

local cvar_recoil    = CreateConVar("trmbase_sv_mod_recoil", 1, FCVAR_ARCHIVE, "", 0, 10)
local ShakeDirection = 1
local RecoilUp       = 0
local RecoilSide     = 0
local ShakeAngle     = Angle()

function SWEP:DoRecoil()
	local owner = self:GetOwner()
	if not IsFirstTimePredicted() then return end
	math.randomseed(self.Recoil.Seed + self:GetSprayRound())
	local stats    = self.Recoil
	local aimdelta = self:GetAimDelta()
	local AdsScale = Lerp(aimdelta, 1, stats.AdsMultiplier)

	RecoilUp       = math.Rand(stats.Vertical[1], stats.Vertical[2]) * AdsScale
	RecoilSide     = math.Rand(stats.Horizonal[1], stats.Horizonal[2]) * AdsScale

	--functional
	if self.Recoil.Functional then
		local maxclip = self:GetMaxClip1()
		-- 获取当前进度
		progress = self:GetSprayRound() / (maxclip > 0 and maxclip or 30) or 0

		-- 修复：用 Functional.Func
		local func = stats.Functional.Func
		if func then
			local pitch, yaw = func(self, progress)
			RecoilUp = RecoilUp + pitch
			RecoilSide = RecoilSide + yaw
		end
	end

	local Shake = math.Rand(-1, 1) * self.Recoil.Shake
	RecoilUp = RecoilUp + Shake
	local mul = self:GetRecoilMultiplier()
	RecoilUp = RecoilUp * mul
	RecoilSide = RecoilSide * mul

	self:SetRecoilUp(RecoilUp)
	self:SetRecoilSide(RecoilSide)
	-- ----
	self:CallOnClient("DoViewModelShake")
end

function SWEP:GetRecoilMultiplier()
	local base = cvar_recoil:GetFloat() * 0.25
	if self:HasFlag("BipodDeployed") then
		base = base * 0.1
	end
	local override = hook.Run("TRMBase_GetRecoilMultiplier", self, base)
	return override or base
end

function SWEP:DoSpread()
	local base = self:GetSpread()
	local min, max = self.Spread.Base, self.Spread.Max
	if min > max then
		min, max = max, min
	end

	base = math.Clamp(base + self.Spread.Increase, min, max)
	self:SetSpread(base)
end

local cvar_spread = CreateConVar("trmbase_sv_spread", 1, FCVAR_ARCHIVE, "", 0, 10)

function SWEP:GetCurrentSpread()
	local baseSpread = self:GetSpread()

	baseSpread = baseSpread * cvar_spread:GetFloat()

	local aimDelta = self:GetAimDelta()
	local owner = self:GetOwner()
	local tac = self:HasFlag("Tacsight")
	if not IsValid(owner) then return baseSpread end
	if not owner.GetWalkSpeed then return baseSpread end
	local walkSpeed = owner:GetWalkSpeed()
	-- 移动扩散
	local vel = math.max(owner:GetVelocity():Length2DSqr() / 20000, 0)
	local moveMult = 1.0

	moveMult = math.max(self.Spread.MoveMultiplier * vel or 1.0, 1)

	baseSpread = baseSpread * moveMult

	-- 跳跃扩散（平滑过渡）
	local targetMult = owner:IsOnGround() and 1.0 or (self.Spread.AirMultiplier or 1.0)
	self.m_AirMult = self.m_AirMult or 1.0
	self.m_AirMult = Lerp(FrameTime() * 5, self.m_AirMult, targetMult)
	baseSpread = baseSpread * self.m_AirMult
	if not tac then
		if self.Aim.SpreadFollowPrimary then
			baseSpread = baseSpread * Lerp(aimDelta, 1, self.Aim.Spread / self.Spread.Base)
		else
			baseSpread = Lerp(aimDelta, baseSpread, self.Aim.Spread)
		end
	else
		baseSpread = Lerp(aimDelta, baseSpread, self.Spread.Base * 0.5)
	end

	baseSpread = math.Clamp(baseSpread, 0, self.Spread.Max)
	return baseSpread
end
