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
