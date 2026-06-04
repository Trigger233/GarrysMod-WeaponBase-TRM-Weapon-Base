if SERVER then
	util.AddNetworkString("TRMBase_TracerEffect")
end


function SWEP:CanPrimaryFire()
	-- local seq =	self:GetPlayingSequence()
	if self.Primary.BoltAction and self.Animations.Rechamber and self:GetChamberAmmo() <= 0 and not self:IsEmpty() and self:GetNextPrimaryFire() <= CurTime() then
		return false
	end

	if self:GetSprintDelta() > 0.2 then
		return false
	end

	return (not self:IsEmpty() and (self:GetNextPrimaryFire() <= CurTime()))
end

if SERVER then
	AddCSLuaFile("include/trmbase_sound.lua")
else
	include("include/trmbase_sound.lua")
end
function SWEP:DoFireSound()
	local slience = self.Slienced and true or false
	local chan = CHAN_WPNFOLEY

	if slience and self.Primary.SliencedSound then
		self:EmitSound(self.Primary.SliencedSound, 140, 100, 1, chan)
	elseif self.Primary.Sound then
		self:EmitSound(self.Primary.Sound, 140, 100, 1, chan)
	end
	if self.Reverb then
		self:HandleReverb()
	end
	if self:Clip1() == 1 then
		self:EmitSound("weapons/pistol/pistol_empty.wav", 66, 100, 1, CHAN_ITEM)
	end
end

function SWEP:FirePrimaryBullet()
	if CLIENT then
		-- 枪焰：总是播（确保每次开火都有）
		self:DoMuzzleEffect()
		-- 弹壳：只在预测帧播（防重复）
		if self.Effects.Shell.Primary and IsFirstTimePredicted() then
			self:DoShell()
		end
	elseif SERVER && game.SinglePlayer() then
		self:CallOnClient("ShootEffects")
	end

	if (not IsFirstTimePredicted()) then return end


	self:DoFireSound()
	local owner = self:GetOwner()
	local eyeAng = owner:EyeAngles()
	local aimDir = owner:GetAimVector()

	--Shake
	if owner:IsPlayer() then
		if not self.r_shakeDir then
			self.r_shakeDir = 1
		end
		self.r_shakeDir = -self.r_shakeDir

		local shake = self.Recoil.Shake * Lerp(self:GetAimDelta(), 1, self.Recoil.AdsMultiplier or 1) * self.r_shakeDir

		owner:SetViewPunchAngles(Angle(0, 0, shake))
		owner:SetViewPunchVelocity(Angle(0, 0, shake * 100))
	end




	--Visual Recoil
	if owner:IsPlayer() then
		local length = aimDir:Length()
		local dir = aimDir:Angle()
		dir:Add(self:GetVisualRecoil())
		aimDir = dir:Forward() * length
	end

	local spread = Vector(self:GetSpreadHorizonal(), self:GetSpreadVertical(), 0) * self:GetCurrentSpread()
	local muzzle = self:GetAttachmentData("muzzle")
	local bullet = {
		Attacker = self:GetOwner(),
		Num = self.Primary.NumBullets,
		Src = owner:GetShootPos(),
		Dir = aimDir,
		Distance = self.Primary.Range,
		Spread = spread,
		Tracer = 0,
		Force = self.Primary.Force / self.Primary.NumBullets,
		Damage = self.Primary.Damage * self.Primary.NumBullets,
		AmmoType = self.Primary.Ammo,
		Callback = function(attacker, tr, dmginfo)
			self:BulletCallback(attacker, tr, dmginfo)
			-- 生成曳光弹
			if CLIENT and IsFirstTimePredicted() then
				-- 客户端预测（给自己看）
				self:DoTracer(owner:GetShootPos(), tr.HitPos)
			elseif SERVER then
				-- 服务器广播给所有玩家（包括自己）
				net.Start("TRMBase_TracerEffect")
				net.WriteEntity(self)
				net.WriteVector(owner:GetShootPos())
				net.WriteVector(tr.HitPos)
				net.Broadcast()
			end
		end,
	}
	if not owner:IsPlayer() then
		bullet.Spread = bullet.Spread * self.Aim.Spread
		bullet.Damage = bullet.Damage / bullet.Num
	end
	if SERVER and IsFirstTimePredicted() then
		owner:FireBullets(bullet)
	end

	self:DoVisualRecoil()
	self:DoRecoil()
	self:DoSpread()
	self:SetLastFireTime(CurTime())
	self:SetClip1(self:Clip1() - 1)

	if self.Primary.BoltAction and self.Animations.Rechamber then
		local amount = self:GetChamberAmmo()
		amount = math.max(amount - 1, 0)
		self:SetChamberAmmo(amount)
	end
	self:TrySetTask("Idle")
end

function SWEP:DoImpactEffect(tr, dmgType)
	self:CallOnClient("DoImpactEffect")

	self:ImpactEffects(tr, dmgType)
	return false
end

function SWEP:ImpactEffects(tr, type)
	for slot, entry in pairs(self.CurrentAttachments or {}) do
		if entry and entry.Class and BASE_TRM_ATTS[entry.Class].DoImpactEffect then
			BASE_TRM_ATTS[entry.Class]:DoImpactEffect(tr, type)
		end
	end
end

function SWEP:SetNextFireTime(t)
	self:SetNextPrimaryFire(CurTime() + t)
	self:SetNextSecondaryFire(CurTime() + t)
end

function SWEP:DoVisualRecoil()
	if not (SERVER and IsFirstTimePredicted()) then return end
	--暂时搁置

	-- 初始化
	if not self.m_VRecoil then
		self.m_VRecoil = self:GetVisualRecoil() or Angle(0, 0, 0)
	end

	if not self.m_VisualRecoilProgress then
		self.m_VisualRecoilProgress = 0
	end

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
		-- 获取当前进度
		self.m_VisualRecoilProgress = self:GetVisualRecoilProgress() or 0

		-- 调用自定义函数
		progPitch, progYaw, progBack = self.VisualRecoil.Functional.Func(
			self,
			self.m_VisualRecoilProgress
		)

		-- 累加进度（每次开火增加）
		self.m_VisualRecoilProgress = math.Clamp(
			self.m_VisualRecoilProgress + self.VisualRecoil.Functional.Increase,
			0, 1
		)
		self:SetVisualRecoilProgress(self.m_VisualRecoilProgress)

		-- 应用倍率
		progPitch = progPitch * AdsScale
		progYaw = progYaw * AdsScale
		progBack = progBack * AdsScale
	end

	local totalP, totalY, totalBack =
		-basePitch - progPitch,
		-baseYaw - progYaw,
		-baseRoll

	-- 合并基础抖动和程序化抖动
	self.m_VRecoil:Add(Angle(totalP, totalY, totalBack))
	--有问题，暂时搁置
	self:SetVisualRecoil(self.m_VRecoil)

	-- ==========================================
	-- 视觉后坐力后退（Backward）
	-- ==========================================
	if not self.m_VRecoilBack then
		self.m_VRecoilBack = 0
	end

	local baseBack = math.Rand(self.VisualRecoil.Backward[1], self.VisualRecoil.Backward[2]) * AdsScale
	self.m_VRecoilBack = self.m_VRecoilBack + baseBack + progBack

	-- 限制最大值
	if self.VisualRecoil.Backward[3] and self.m_VRecoilBack > self.VisualRecoil.Backward[3] then
		self.m_VRecoilBack = self.VisualRecoil.Backward[3]
	end

	self:SetVisualRecoilBackward(self.m_VRecoilBack)
end

function SWEP:Recover()
	if CLIENT then return end
	local last = self:GetLastFireTime()
	local delay = 60 / self.Primary.RPM -- second
	--VRecoil(Angle)
	if CurTime() - last > (self.VisualRecoil.RecoverDelay or 0) then
		self.m_VRecoil = self:GetVisualRecoil()
		self.m_VRecoil = LerpAngle(FrameTime() * self.VisualRecoil.RecoverSpeed * 10, self.m_VRecoil, Angle(0, 0, 0))
		self:SetVisualRecoil(self.m_VRecoil)
		--VRecoil(Vector)
		self.m_VRecoilBack = self:GetVisualRecoilBackward()
		self.m_VRecoilBack = math.Approach(self.m_VRecoilBack, 0, 1 / delay)
		self:SetVisualRecoilBackward(self.m_VRecoilBack)
	end

	--func vrecoil
	if self.VisualRecoil.Functional then
		local progress = self:GetVisualRecoilProgress() or 0
		local recover = self.VisualRecoil.Functional.Recover or 0.3
		progress = math.max(0, progress - recover * FrameTime())
		self:SetVisualRecoilProgress(progress)
	end

	--functional recoil
	local current = self:GetRecoilProgress()
	if CurTime() - last > self.Recoil.Functional.RecoverDelay then
		current = math.Clamp(current - self.Recoil.Functional.Recover, 0, 1)
		self:SetRecoilProgress(current)
	end

	--spread
	if CurTime() - last > (self.Spread.Delay or 0) then
		local spread = self:GetSpread()
		spread = math.Clamp(spread - self.Spread.Recover * FrameTime(), self.Spread.Base, self.Spread.Max)
		self:SetSpread(spread)
	end
end

function SWEP:DoRecoil()
	if CLIENT and not IsFirstTimePredicted() then return end
	local Recoil = Angle(0, 0, 0)
	local stats = self.Recoil
	local delay = 60 / self.Primary.RPM

	if stats.KickDown then
		delay = delay * (1 - stats.KickDown)
	end


	Recoil          = self:GetRecoil()
	local AdsScale  = Lerp(self:GetAimDelta(), 1, stats.AdsMultiplier) * 1

	local Vertical  = math.Rand(stats.Vertical[1], stats.Vertical[2]) * AdsScale
	local Horizonal = math.Rand(stats.Horizonal[1], stats.Horizonal[2]) * AdsScale

	Recoil:Set(Angle(-Vertical, Horizonal, 0))
	--functional
	if self.Recoil.Functional then
		local progress = self:GetRecoilProgress()

		-- 修复：用 Functional.Func
		local func = stats.Functional.Func
		if func then
			local pitch, yaw = func(self, progress)
			progress = math.Clamp(
				progress + self.Recoil.Functional.Increase,
				0, 1
			)
			Recoil:Add(Angle(pitch, yaw, 0))
			self:SetRecoilProgress(progress)
		end
	end
	Recoil:Normalize()

	self:SetRecoil(Recoil)
	self:SetNextRecoil(CurTime() + delay)
end

function SWEP:DoCameraRecoil()
	if not (SERVER and IsFirstTimePredicted()) then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	local eyeAngles = owner:EyeAngles()
	local delay = 60 / self.Primary.RPM
	local nextRecoil = self:GetNextRecoil()
	local isFiring = CurTime() - nextRecoil < delay
	local NextAngle = Angle(0, 0, 0)
	local stat = self.Recoil

	if not self.m_RecoilSum then
		self.m_RecoilSum = Angle(0, 0, 0)
		self.m_RecoilDelta = 0
		self.m_LastEyePitch = eyeAngles.pitch
	end

	-- 计算玩家压枪输入（视角向下移动的量）
	local playerPitchDelta = self.m_LastEyePitch - eyeAngles.pitch

	local current = self:GetRecoil()
	self.m_RecoilSum:Add(current)
	self.m_RecoilDelta = self.m_RecoilDelta + current.pitch
	self:SetRecoil(Angle(0, 0, 0))
	local t = math.Clamp((CurTime() - nextRecoil) / delay, 0, 1)
	if isFiring then
		-- 射击时：应用后坐力，然后用玩家压枪输入抵消
		NextAngle = self.m_RecoilSum * stat.Factor
		NextAngle.p = NextAngle.p + stat.KickDown * (t < 0.5 and t or 1 - t)
		self.m_RecoilSum:Add(-NextAngle)
		-- 玩家压枪抵消后坐力累积
		self.m_RecoilDelta = self.m_RecoilDelta - math.min(playerPitchDelta, 0)
	else
		-- 停火后：回正剩余的后坐力
		if self.m_RecoilDelta * (current.pitch > 0 and 1 or -1) > 0.1 then
			NextAngle.pitch = -self.m_RecoilDelta * stat.Recover
			self.m_RecoilDelta = self.m_RecoilDelta + NextAngle.pitch
		else
			self.m_RecoilDelta = 0
			self.m_RecoilSum = Angle(0, 0, 0)
		end
	end
	eyeAngles:Add(NextAngle)
	owner:SetEyeAngles(eyeAngles)

	-- 记录当前视角供下一帧使用
	self.m_LastEyePitch = eyeAngles.pitch
end

function SWEP:DoSpread()
	local base = self:GetSpread()
	base       = math.Clamp(base + self.Spread.Increase, self.Spread.Base, self.Spread.Max)
	self:SetSpread(base)
end

function SWEP:GetCurrentSpread()
	local baseSpread = self:GetSpread()
	local aimDelta = self:GetAimDelta()
	local owner = self:GetOwner()
	if not IsValid(owner) then return baseSpread end

	-- 移动扩散
	local vel = math.max(owner:GetVelocity():Length2D() / owner:GetWalkSpeed(), 0)
	local moveMult = 1.0

	moveMult = math.max(self.Spread.MoveMultiplier * vel or 1.0, 1)

	baseSpread = baseSpread * moveMult

	-- 跳跃扩散（平滑过渡）
	local targetMult = owner:IsOnGround() and 1.0 or (self.Spread.AirMultiplier or 1.0)
	self.m_AirMult = self.m_AirMult or 1.0
	self.m_AirMult = Lerp(FrameTime() * 5, self.m_AirMult, targetMult)
	baseSpread = baseSpread * self.m_AirMult

	if self.Aim.SpreadFollowPrimary then
		baseSpread = baseSpread * Lerp(aimDelta, 1, self.Aim.Spread / self.Spread.Base)
	else
		baseSpread = Lerp(aimDelta, baseSpread, self.Aim.Spread)
	end

	return baseSpread
end
