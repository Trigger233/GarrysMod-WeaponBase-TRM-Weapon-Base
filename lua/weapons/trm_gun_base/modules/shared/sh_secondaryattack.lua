concommand.Add("+trmbase_switch_underbarrel", function(ply)
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) and util.IsTRMBase(weapon) then
        weapon:CycleUnderBarrel()
    end
end)

function SWEP:CycleUnderBarrel()
    if not self.underbarrel then return end
    local status = self:GetUnderBarrel()
    if not status then
        self:TrySetTask("UnderBarrel_In")
    else
        self:TrySetTask("UnderBarrel_Out")
    end
end

function SWEP:CanSecondaryFire()
    return self:GetNextSecondaryFire() <= CurTime() and self:Clip2() > 0
end

function SWEP:DoUnderbarrelAttack()
    self:SetNextAnimationTime(0)

    self:PlayAnimation(self:ChooseAnim("UnderBarrel_Fire"), false)

    if self.Secondary.SpecialAmmo == -1 then
        self:FireSecondaryBullet()
    else
        self:FireSecondaryProjectile()
    end

    self:SetNextSecondaryFire(CurTime() + 60 / (self.Secondary.RPM or 150))
end

function SWEP:FireSecondaryBullet()
    if (not IsFirstTimePredicted()) then return end

    local stat = self.Secondary
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
    local bullet = {
        Attacker = self:GetOwner(),
        Num = stat.NumBullets,
        Src = owner:GetShootPos(),
        Dir = aimDir,
        Distance = stat.Range,
        Spread = spread,
        Tracer = 0,
        Force = stat.Force / stat.NumBullets,
        Damage = stat.Damage * stat.NumBullets,
        AmmoType = stat.Ammo,
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
    self:EmitSound(self.Secondary.Sound)

    self:DoVisualRecoil()
    self:DoRecoil()
    self:DoSpread()
    self:SetLastFireTime(CurTime())

    if self.Secondary.BoltAction and self.Animations.UnderBarrel_Rechamber then
        local amount = self:GetSecondaryChamberAmmo()
        amount = math.max(amount - 1, 0)
        self:SetSecondaryChamberAmmo(amount)
    end


    self:SetClip2(self:Clip2() - 1)
    self:TrySetTask("UnderBarrel")
end

function SWEP:FireSecondaryProjectile()
    local owner = self:GetOwner()
    local eyeAng = owner:EyeAngles()
    local aimDir = owner:GetAimVector()

    if owner:IsPlayer() then
        if not self.r_shakeDir then
            self.r_shakeDir = 1
        end
        self.r_shakeDir = -self.r_shakeDir
        local shake = self.Recoil.Shake * Lerp(self:GetAimDelta(), 1, self.Recoil.AdsMultiplier or 1) * self.r_shakeDir
        owner:SetViewPunchAngles(Angle(0, 0, shake))
        owner:SetViewPunchVelocity(Angle(0, 0, shake * 100))
        local length = aimDir:Length()
        local dir = aimDir:Angle()
        dir:Add(self:GetVisualRecoil())
        aimDir = dir:Forward() * length
    end

    if owner:IsNPC() and IsValid(owner:GetEnemy()) then
        local DirLength = aimDir:Length()
        local Ang = aimDir:Angle()
        local additive = self:NPC_ProjectileCalc(owner, owner:GetEnemy(), self.Secondary.Velocity)
        --print(additive)
        Ang:Add(additive)
        aimDir = Ang:Forward() * DirLength
    end

    if SERVER and self:CanSecondaryFire() then
        local proj = ents.Create(self.Secondary.SpecialAmmo)
        proj:SetPos(owner:GetShootPos()) -- 从枪口前方一点的位置发射，避免穿模
        proj:SetAngles(aimDir:Angle())
        proj:Spawn()
        proj:SetOwner(self)
        local phys = proj:GetPhysicsObject()


        if IsValid(phys) then
            phys:Wake()
            phys:SetVelocity(aimDir * self.Secondary.Velocity + owner:GetVelocity())
        end
    end

    self:EmitSound(self.Secondary.Sound)

    self:DoVisualRecoil()
    self:DoRecoil()
    self:DoSpread()
    self:SetLastFireTime(CurTime())

    if self.Secondary.BoltAction and self.Animations.UnderBarrel_Rechamber then
        local amount = self:GetSecondaryChamberAmmo()
        amount = math.max(amount - 1, 0)
        self:SetSecondaryChamberAmmo(amount)
    end


    self:SetClip2(self:Clip2() - 1)
    self:TrySetTask("UnderBarrel")
end
