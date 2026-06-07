function SWEP:CanBePickedUpByNPCs()
    return true
end

function SWEP:GetNPCBulletSpread()
    return 4
end

function SWEP:GetNPCBurstSettings()
    return 1, 5, (60 / self.Primary.RPM)
end

function SWEP:GetNPCRestTimes()
    return 0.3, 0.6
end

function SWEP:NPCShoot_Primary(pos, dir)
    if CurTime() > self:GetNextPrimaryFire() then
        if self.Primary.SpecialAmmo == -1 then
            self:FirePrimaryBullet()
        else
            self:FireProjectile()
        end
        
        self:SetNextFireTime(60 / self.Primary.RPM)
    end
end

function SWEP:Primary_NPC_ProjectileCalc(owner, target)
    local startpos = owner:GetShootPos()
    local targetpos = target:GetPos() + target:OBBCenter()
    local targetspeed = target:GetVelocity()
    local ownerspeed = owner:GetVelocity()

    local muzzleSpeed = self.Primary.Velocity or self.Primary.Speed or 1200
    local gravity = (GetConVar("sv_gravity"):GetInt() or 800) * 1.1

    local aimpos = targetpos
    local finalPitch = 0
    local finalYaw = 0

    -- 直接瞄准的基础角度
    local baseAng = (targetpos - startpos):Angle()

    -- 迭代 4 次
    for i = 1, 4 do
        local horizDist = math.sqrt((aimpos.x - startpos.x) ^ 2 + (aimpos.y - startpos.y) ^ 2)
        local dz = aimpos.z - startpos.z -- 高度差（正=目标更高，负=目标更低）

        if horizDist < 5 then
            break
        end

        local dirToTarget = (aimpos - startpos):GetNormalized()
        local relativeSpeed = muzzleSpeed + ownerspeed:Dot(dirToTarget)

        if relativeSpeed <= 0 then break end

        -- 抛物线公式（包含高度差）
        local v2 = relativeSpeed * relativeSpeed
        local v4 = v2 * v2
        local g = gravity
        local d = horizDist
        local h = dz -- 高度差

        local sqrtTerm = v4 - g * (g * d * d + 2 * h * v2)

        if sqrtTerm >= 0 then
            local tanTheta = (v2 - math.sqrt(sqrtTerm)) / (g * d)
            local angleRad = math.atan(tanTheta)
            -- 角度范围：目标越高，角度越大；目标越低，角度越小（甚至负角）
            angleRad = math.Clamp(angleRad, math.rad(-15), math.rad(75))
            finalPitch = angleRad

            -- 飞行时间
            local travelTime = d / (relativeSpeed * math.cos(angleRad))

            -- 预测目标位置（提前量）
            aimpos = targetpos + targetspeed * travelTime

            -- 水平差角
            local aimAng = (aimpos - startpos):Angle()
            finalYaw = aimAng.yaw - baseAng.yaw
        else
            break
        end
    end

    -- 返回差角（pitch：抬高/压低，yaw：左右偏）
    return Angle(-math.deg(finalPitch), finalYaw, 0)
end
