if SERVER then
	util.AddNetworkString("TRMBase_TracerEffect")
end

local math = math

function SWEP:CanPrimaryFire()
	-- local seq =	self:GetPlayingSequence()
	if self.Primary.BoltAction and self.Animations.Rechamber and self:GetChamberAmmo() <= 0 and not self:IsEmpty() and self:GetNextPrimaryFire() <= CurTime() then
		return false
	end

	if self:GetSprintDelta() > 0.2 then
		return false
	end

	if string.find(self:GetPlayingSequence(), "Holster") then
		return false
	end

	if self.Primary.BrustEnabled and self:GetBrustCount() <= 0 then
		return false
	end

	return (not self:IsEmpty() and (self:GetNextPrimaryFire() <= UnPredictedCurTime()))
end

local cvar_bullet = CreateConVar("trmbase_sv_physical_bullet", 0, FCVAR_ARCHIVE, "", 0, 1)
local cvar_shake = CreateConVar("trmbase_sv_mod_shake", 1, FCVAR_ARCHIVE, "", 0, 10)
local tick = engine.TickInterval


function SWEP:FirePrimaryBullet()
	if (not IsFirstTimePredicted()) then return end
	if game.SinglePlayer() and CLIENT then
		self:MuzzleEffects()
	else
		self:CallOnClient("MuzzleEffects")
	end

	if self.Effects.Shell.Primary then
		self:DoShell()
	end

	local owner = self:GetOwner()
	local eyeAng = owner:EyeAngles()
	local aimDir = self:GetAimVector()

	--Shake
	-- self:ApplyShake()

	self:SetPenetrationCount(self.Bullet.Penetration.Max)

	if IsFirstTimePredicted() and SERVER then
		local spread = Vector(self:GetSpreadHorizonal(), self:GetSpreadVertical(), 0) * self:GetCurrentSpread()
		if not cvar_bullet:GetBool() then
			local bullet = {
				Attacker = self:GetOwner(),
				Inflictor = self,
				Num = self.Primary.NumBullets,
				Src = self:GetShootPos(),
				Dir = self:GetAimVector(),
				Distance = self.Primary.Range,
				Spread = spread,
				Tracer = 0,
				--HullSize = 1 ,
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
			hook.Run("TRM_PreFireBullet", bullet)
			owner:FireBullets(bullet)
		else
			for i = 1, self.Primary.NumBullets do
				local AimDirNew   = Vector(aimDir)
				local spreadScale = self:GetCurrentSpread() * 50
				local angleOffset = Angle(
					math.Rand(-1, 1) * self:GetSpreadVertical() * spreadScale,
					math.Rand(-1, 1) * self:GetSpreadHorizonal() * spreadScale,
					0
				)
				local AimDirNew   = aimDir:Angle()
				AimDirNew:Add(angleOffset)
				AimDirNew = AimDirNew:Forward()
				local bullet = ents.Create("trm_bullet")
				bullet:SetOwner(self)
				hook.Run("TRM_PreFIrePhysicalBullet", bullet)
				local start = self:GetShootPos()
				local angle = owner:IsPlayer() and
					(owner:GetEyeTraceNoCursor().HitPos - start):Angle() - owner:GetAimVector():Angle() or Angle(0, 0, 0)

				bullet:SetPos(start) -- 从枪口前方一点的位置发射，避免穿模

				bullet:SetAngles(AimDirNew:Angle() + angle)
				bullet:Spawn()
				local phys = bullet:GetPhysicsObject()
			end
		end
	end


	self:DoRecoil()
	self:DoSpread()
	self:SetLastFireTime(UnPredictedCurTime())
	self:SetClip1(self:Clip1() - 1)

	if self.Primary.BoltAction then
		local amount = self:GetChamberAmmo()
		amount = math.max(amount - 1, 0)
		self:SetChamberAmmo(amount)
	end



	--self:TrySetTask("Idle")
end

function SWEP:GetPrimaryProjBulletSpeed()
	return 4000000
end

function SWEP:FireProjectile()
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

	local owner = self:GetOwner()
	local eyeAng = owner:EyeAngles()
	local aimDir = self:GetAimVector()

	-- self:ApplyShake()

	if owner:IsNPC() and IsValid(owner:GetEnemy()) then
		local DirLength = aimDir:Length()
		local Ang = aimDir:Angle()
		local additive = self:NPC_ProjectileCalc(owner, owner:GetEnemy(), self.Primary.Velocity)
		--print(additive)
		Ang:Add(additive)
		aimDir = Ang:Forward() * DirLength
	end


	local AimDirNew   = Vector(aimDir)
	local spreadScale = self:GetCurrentSpread() * 50
	local angleOffset = Angle(
		math.Rand(-1, 1) * self:GetSpreadVertical() * spreadScale,
		math.Rand(-1, 1) * self:GetSpreadHorizonal() * spreadScale,
		0
	)
	local AimDirNew   = aimDir:Angle()
	AimDirNew:Add(angleOffset)
	AimDirNew = AimDirNew:Forward()
	if SERVER and self.Primary.SpecialAmmo != -1 then
		local proj = ents.Create(self.Primary.SpecialAmmo)
		proj:SetPos(owner:GetShootPos())
		proj:SetAngles(AimDirNew:Angle())
		proj:Spawn()
		proj:SetOwner(self)
		local phys = proj:GetPhysicsObject()


		if IsValid(phys) then
			phys:Wake()
			phys:SetVelocityInstantaneous(aimDir * self.Primary.Velocity + owner:GetVelocity())
		end
	end

	self:DoFireSound()
	self:DoRecoil()
	self:DoSpread()
	self:SetLastFireTime(UnPredictedCurTime())
	self:SetClip1(self:Clip1() - 1)

	if self.Primary.BoltAction and self.Animations.Rechamber then
		local amount = self:GetChamberAmmo()
		amount = math.max(amount - 1, 0)
		self:SetChamberAmmo(amount)
	end
	--self:TrySetTask("Idle")
end

function SWEP:DoImpactEffect(tr, dmgType)
	self:CallOnClient("DoImpactEffect")

	self:ImpactEffects(tr, dmgType)
	return false
end

function SWEP:ImpactEffects(tr, type)
	for slot, entry in pairs(self.CurrentAttachments or {}) do
		if entry and entry.Class and BASE_TRM_ATTS[entry.Class] and BASE_TRM_ATTS[entry.Class].DoImpactEffect then
			BASE_TRM_ATTS[entry.Class]:DoImpactEffect(tr, type)
		end
	end
end

function SWEP:SetNextFireTime(t)
	self:SetNextPrimaryFire(CurTime() + t)
	self:SetNextSecondaryFire(CurTime() + t)
end

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
		-- 获取当前进度
		progress = self:GetVisualRecoilProgress() or 0
		-- 调用自定义函数
		progPitch, progYaw, progBack = self.VisualRecoil.Functional.Func(
			self,
			progress
		)

		-- 累加进度（每次开火增加）
		progress = math.Clamp(
			progress + self.VisualRecoil.Functional.Increase,
			0, 1
		)
		self:SetVisualRecoilProgress(progress)
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


	local baseBack = math.Rand(self.VisualRecoil.Backward[1], self.VisualRecoil.Backward[2]) * AdsScale
	backforward = backforward + (baseBack + progBack) * cvar_VisualRecoil:GetFloat()
	-- 限制最大值
	if self.VisualRecoil.Backward[3] and backforward > self.VisualRecoil.Backward[3] then
		backforward = self.VisualRecoil.Backward[3]
	end

	self:SetVisualRecoilBackward(self:GetVisualRecoilBackward() + backforward)
end


function SWEP:Recover()
	if CLIENT then return end

	

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
		backforward = self:GetVisualRecoilBackward()
		backforward = math.Approach(backforward, 0, 1 / delay)
		self:SetVisualRecoilBackward(backforward)
	end

	--func vrecoil
	if self.VisualRecoil.Functional then
		progress = self:GetVisualRecoilProgress() or 0
		local recover = self.VisualRecoil.Functional.Recover or 0.3
		progress = math.max(0, progress - recover * ft)
		self:SetVisualRecoilProgress(progress)
	end

	--functional recoil
	local current = self:GetRecoilProgress()
	if Curtime - last > self.Recoil.Functional.RecoverDelay then
		current = math.Clamp(current - self.Recoil.Functional.Recover, 0, 1)
		self:SetRecoilProgress(current)
	end

	--spread
	if Curtime - last > (self.Spread.Delay or 0) then
		local spread = self:GetSpread()
			local min , max = self.Spread.Base, self.Spread.Max
	if min > max then
		min , max = max ,min
	end
		spread = math.Clamp(spread - self.Spread.Recover * FrameTime(), self.Spread.Base, self.Spread.Max)
		self:SetSpread(spread)
	end

	---Recoil Spray
	self:SetRecoil(Lerp(ft * self.Recoil.Recover or 1, self:GetRecoil(), 1))
end

local cvar_recoil = CreateConVar("trmbase_sv_mod_recoil", 1, FCVAR_ARCHIVE, "", 0, 10)
local ShakeDirection = 1

function SWEP:DoRecoil()
	local owner = self:GetOwner()
	if not IsFirstTimePredicted() then return end
	local Recoil    = Angle(0, 0, 0)
	local stats     = self.Recoil
	local delay     = 60 / self.Primary.RPM

	Recoil          = Angle(0, 0, 0)
	local AdsScale  = Lerp(self:GetAimDelta(), 1, stats.AdsMultiplier)

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

	Recoil:Mul(self:GetRecoilMultiplier())
	Recoil:Mul(self:GetRecoil())
	self:SetRecoil(self:GetRecoil() + 1)
	Recoil:Normalize()
	
	--owner:SetViewPunchVelocity( Recoil * 10)
	--owner:ViewPunch(Recoil)
	if owner:IsPlayer() then
		local kickDown = stats.KickDown
		owner:ViewPunch(Recoil * kickDown * 0.4 + Angle(0, 0, stats.Shake) * ShakeDirection * 3)
		ShakeDirection = -ShakeDirection
		--owner:SetViewPunchVelocity(owner:GetViewPunchVelocity() * 1.1)
		owner:SetEyeAngles(owner:EyeAngles() + Recoil * (1 - kickDown) * 0.02)
	end
end



function SWEP:GetRecoilMultiplier()
	local base = cvar_recoil:GetFloat()
	if self:HasFlag("BipodDeployed") then
		base = base * 0.1
	end
	local override = hook.Run("TRMBase_GetRecoilMultiplier", self, base)
	return override or base
end

function SWEP:DoSpread()
	local base = self:GetSpread()
	local min , max = self.Spread.Base, self.Spread.Max
	if min > max then
		min , max = max ,min
	end

	base = math.Clamp(base + self.Spread.Increase, min, max)
	self:SetSpread(base)
end

function SWEP:GetCurrentSpread()
	local baseSpread = self:GetSpread()
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

function SWEP:GetShootPos()
	local owner = self:GetOwner()
	local pos = owner:GetShootPos()

	if not owner:IsPlayer() then
		return pos
	end
	local ang = self:GetAimVector():Angle()
	local aim = self:GetAimDelta()

	local muzoffset = LerpVector(aim, self.ShootPosOffset, self.ShootPosOffsetAim)


	pos:Add(muzoffset.x * ang:Right() + muzoffset.y * ang:Forward() + muzoffset.z * ang:Up())
	return pos
end

function SWEP:GetAimVector()
	local owner = self:GetOwner()
	local aimVector = owner:GetAimVector()
	if owner:IsNPC() then
		return aimVector
	end


	local ang = owner:EyeAngles()
	local punch = owner:GetViewPunchAngles()
	local velo = owner:GetViewPunchVelocity()
	ang:Add(self:GetVisualRecoil())
	ang:Add(punch * 1)
	--ang:Add(velo * tick())
	--ang:Normalize()
	--print(ang, "punch :",punch)
	return ang:Forward() * aimVector:Length()
end
