
function SWEP:CanPrimaryFire()
	-- local seq =	self:GetPlayingSequence()
	if self.BoltAction and self.Animations.Rechamber and self:GetChamberAmmo() <= 0 and not self:IsEmpty() and self:GetNextPrimaryFire() <= CurTime( ) then
		return false
	end
	return (not self:IsEmpty() and (self:GetNextPrimaryFire() <= CurTime( ))  )  
end

function SWEP:Task_PrimaryFire()
	self:SetNextFireTime( 60 / self.Primary.RPM ) 
	local aim = self:GetAimDelta() > 0.5 and true or false 
	  
	if self:Clip1() == 1 and self.Animations.Fire_Last then
		if aim and self.Animations.Iron_Fire_Last then
			self:PlayAnimation("Iron_Fire_Last")
		else
			self:PlayAnimation( "Fire_Last")	
		end
	elseif self.Animations.Fire then
		if aim and self.Animations.Iron_Fire then
			self:PlayAnimation("Iron_Fire")
		else
			self:PlayAnimation( "Fire")	
		end
	end

	if (self.Primary.Special == -1 or not  self.Primary.Special )  then
		self:FirePrimaryBullet()
	else
		self:FireProjectile()
	end
	
	

	
	
end

function SWEP:DoFireSound()
	local slience = self.Primary.Slienced or false
	if slience and self.Primary.SliencedSound then
		self:EmitSound(self.Primary.SliencedSound,140,100,1,CHAN_WEAPON)
	elseif self.Primary.Sound then
		self:EmitSound(self.Primary.Sound,140,100,1,CHAN_WEAPON)
	end

	if self:Clip1() == 1 then
		self:EmitSound("weapons/pistol/pistol_empty.wav")
	end

end





function SWEP:FirePrimaryBullet()
	if (not IsFirstTimePredicted()) then return end
	self:DoFireSound()
	local owner = self:GetOwner()
	local eyeAng = owner:EyeAngles()
	local aimDir = owner:GetAimVector()

	--Shake
		if owner:IsPlayer() then
			local shake = self.Recoil.Shake * Lerp(	self:GetAimDelta() , 1 , self.Recoil.AdsMultiplier or 1 )
				shake = math.sin( 2 *  CurTime() / (60 / self.Primary.RPM)) * shake
				owner:SetViewPunchAngles(Angle(0,0,shake))
				owner:SetViewPunchVelocity(Angle(0,0,shake* 100))
		end
    
	
	

	--Visual Recoil
	if owner:IsPlayer() then
		local length = aimDir:Length()
		local dir = aimDir:Angle()
		dir:Add(self:GetVisualRecoil())
		aimDir = dir:Forward() * length
	end 

	local spread =  Vector(self:GetSpreadHorizonal()  ,self:GetSpreadVertical() , 0 ) * self:GetCurrentSpread()

	local bullet = {
		Attacker = self:GetOwner(),
		Num = self.Primary.NumBullets ,
        Src = owner:GetShootPos() ,
        Dir = aimDir,
        Distance = self.Primary.Range,
        Spread = spread ,
        Tracer = 0,
        Force = self.Primary.Force  ,
        Damage = self.Primary.Damage * self.Primary.NumBullets,
        AmmoType = self.Primary.Ammo ,
        Callback = function(attacker, tr, dmginfo)	
			self:BulletCallback(attacker, tr, dmginfo)
		end,
	}
	if not  owner:IsPlayer() then
		bullet.Spread =  0.0
		bullet.Damage = bullet.Damage * 1
	end
	-- if SERVER then
	owner:FireBullets(bullet  )
	-- end
	
	self:DoVisualRecoil()
	self:DoRecoil()
	self:DoSpread()
	self:SetLastFireTime(CurTime())
	self:SetClip1(self:Clip1() - 1)
	
	if self.BoltAction and self.Animations.Rechamber then
		local amount = self:GetChamberAmmo()
		amount = math.max(amount-1,0)
		self:SetChamberAmmo(amount	)
		
	end
	self:SetCurrentTask("Finished")
	if CLIENT or owner:IsNPC() then
		self:ShootEffects()
    elseif SERVER && game.SinglePlayer() then 
        self:CallOnClient("ShootEffects")
    end

end

function SWEP:DoImpactEffect(tr,dmgType)
	self:ImpactEffects(tr,dmgType)
	return false 
end

function SWEP:ImpactEffects(tr,type)
		
	if not self.CurrentAttachments then
		self.CurrentAttachments = {}
	end
	for slot , attClass in pairs(self.CurrentAttachments) do 
		if BASE_TRM_ATTS[attClass].DoImpactEffect then
			BASE_TRM_ATTS[attClass]:DoImpactEffect(ty,type)    
		end    
	end
end 


function SWEP:SetNextFireTime(t)
	self:SetNextPrimaryFire(CurTime() + t )
	self:SetNextSecondaryFire(CurTime() + t)
end

function SWEP:DoVisualRecoil()
	if not (SERVER and IsFirstTimePredicted()) then return end
	--暂时搁置
	
    -- 初始化
    if not self.m_VRecoil then
        self.m_VRecoil = self:GetVisualRecoil() or Angle(0,0,0)
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

	local totalP , totalY , totalBack = 
        -basePitch - progPitch,
        -baseYaw - progYaw,
        -baseRoll
    
    -- 合并基础抖动和程序化抖动
    self.m_VRecoil:Add(Angle( totalP , totalY , totalBack))
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
	--VRecoil(Angle)
	if CurTime() - last > (self.VisualRecoil.RecoverDelay or 0)  then
		self.m_VRecoil = self:GetVisualRecoil()
		self.m_VRecoil = LerpAngle( FrameTime() * self.VisualRecoil.RecoverSpeed * 10 , self.m_VRecoil , Angle(0,0,0)   )
		self:SetVisualRecoil(self.m_VRecoil)
		--VRecoil(Vector)
		self.m_VRecoilBack = self:GetVisualRecoilBackward()
		self.m_VRecoilBack = math.Approach(self.m_VRecoilBack , 0 , self.VisualRecoil.RecoverSpeed )
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
		current = math.Clamp(  current - self.Recoil.Functional.Recover ,0 ,1)
		self:SetRecoilProgress(current)
	end

	--spread
	if  CurTime() - last > (self.Spread.Delay or 0) then
		local spread = self:GetSpread()
		spread = math.Clamp(spread - self.Spread.Recover * FrameTime() , self.Spread.Base , self.Spread.Max )
		self:SetSpread(spread)
	end
end

function SWEP:DoRecoil()
	if  CLIENT  and not IsFirstTimePredicted()  then return end
	if not self.m_Recoil then
		self.m_Recoil = Angle(0,0,0)
	end
	local delay = 60 / self.Primary.RPM
	-- delay = 0.1
	self.m_Recoil = self:GetRecoil()
	local AdsScale = Lerp(self:GetAimDelta() , 1 , self.Recoil.AdsMultiplier ) * 1
	
	
	local Vertical  =	math.Rand( self.Recoil.Vertical[1],self.Recoil.Vertical[2] ) * AdsScale 
	local Horizonal = 	math.Rand( self.Recoil.Horizonal[1],self.Recoil.Horizonal[2] ) * AdsScale  
	
	
	self.m_Recoil:Set(Angle(  -Vertical ,Horizonal,0    ))

	--functional
	if self.Recoil.Functional then
    self.m_RecoilFunctionProgress = self:GetRecoilProgress()
    
    -- 修复：用 Functional.Func
    local func = self.Recoil.Functional.Func
    if func then
        local pitch, yaw = func(self, self.m_RecoilFunctionProgress)
        self.m_RecoilFunctionProgress = math.Clamp(
            self.m_RecoilFunctionProgress + self.Recoil.Functional.Increase,
            0, 1
        )
        self.m_Recoil:Add(Angle(pitch, yaw, 0))
        self:SetRecoilProgress(self.m_RecoilFunctionProgress)
    	end
	end
	self.m_Recoil:Normalize()

	self:SetRecoil(self.m_Recoil  )
	self:SetNextRecoil(CurTime( ) +  delay  ) 

end


function SWEP:DoCameraRecoil()
	if not (SERVER and IsFirstTimePredicted())  then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    local nextRecoil = self:GetNextRecoil()
    if CurTime() > nextRecoil then return end
    
    local delay = 60 / self.Primary.RPM
    local elapsed = delay - (nextRecoil - CurTime())
    local t = math.Clamp((elapsed / delay) ^ 0.5, 0, 1)
    
    local recoilAngle = self:GetRecoil()
    local kickDown =( self.Recoil.KickDown  or 0) * delay * 5 
    
    -- 简单的三段曲线：上升 → 下降 → 归零
    local strength
    if t < 0.5 then
        -- 阶段1：快速下降到 0 (t=0.3 时 strength=0)
        strength = 1 - (t / 0.5)
    elseif t < 0.7 then
        -- 阶段2：继续下降到负数 (t=0.6 时 strength=-kickDown)
        local t2 = (t - 0.2) / 0.2  -- 0→1
        strength = -kickDown * t2
    else
        -- 阶段3：回到 0 (t=1 时 strength=0)
        local t3 = (t - 0.7) / 0.3  -- 0→1
        strength = -kickDown * (1 - t3)
    end
    
    local current = Angle(
        recoilAngle.pitch * strength,
        recoilAngle.yaw * t,
        recoilAngle.roll * t
    )
    
    local eyeAngles = owner:EyeAngles()
    eyeAngles.pitch = eyeAngles.pitch + current.pitch
    eyeAngles.yaw = eyeAngles.yaw + current.yaw
    eyeAngles.roll = eyeAngles.roll + current.roll
    owner:SetEyeAngles(eyeAngles)
end

function SWEP:DoSpread()
	local base  =self:GetSpread()
	base = math.Clamp(base + self.Spread.Increase , self.Spread.Base , self.Spread.Max )   
	self:SetSpread(base)
end

-- 在 sh_primaryattack.lua 或 shared.lua 中添加
function SWEP:GetCurrentSpread()
    local baseSpread = self:GetSpread()
    local aimDelta = self:GetAimDelta()
	
	if not self:GetOwner():IsOnGround() then 
		baseSpread = baseSpread * 1.45 
	end

	if self.Aim.SpreadFollowPrimary then
		baseSpread = baseSpread * Lerp(aimDelta,1, self.Aim.Spread / self.Spread.Base  )
	else
		baseSpread = Lerp(aimDelta,baseSpread, self.Aim.Spread  )
	end
	  
	

    
    
    return baseSpread
end
