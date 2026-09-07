

local task_fire = {}
task_fire.Name = "PrimaryFire"
task_fire.Priority = 255

function task_fire:CanBeSet(weapon)
    return weapon:CanPrimaryFire()
end

function task_fire:OnSet(weapon)
    weapon:SetNextAnimationTime(0)

    local anim = "Fire"
    if weapon.Animations.Fire_Last and weapon:Clip1() == 1 then
        anim = "Fire_Last"
    end

    weapon:PlayAnimation(weapon:ChooseAnim(anim))
    weapon:PlayerGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, weapon.HoldTypes[weapon:GetCurrentHoldType()].Attack)


    if weapon.Primary.SpecialAmmo == -1 or not weapon.Primary.SpecialAmmo then
        weapon:FirePrimaryBullet()
    else
        weapon:FireProjectile()
    end
    weapon:SetSprayRound(weapon:GetSprayRound() + 1)
    weapon:HandleReverb()
    weapon:DoFireSound()

    weapon:DoVisualRecoil()

    if weapon.Primary.BrustEnabled then
        if weapon:GetBrustCount() > 0 then
            weapon:SetBrustCount(weapon:GetBrustCount() - 1)
        end

        if weapon:GetBrustCount() == 0 then
            weapon:SetBrustCount(weapon.Primary.BrustNum)
            weapon:TrySetTask("Idle")
            weapon:SetNextPrimaryFire(CurTime() + weapon.Primary.BrustDelay)
            return true
        end
    end

    if weapon.Primary.BoltAction then
        weapon:TrySetTask("Rechamber")
    end



    local NextTime = CurTime() + 60 / weapon.Primary.RPM
    weapon:SetNextAnimationTime(NextTime)
    weapon:SetNextPrimaryFire(NextTime)
    hook.Run("TRM_PostPrimaryFire", weapon)
end

function task_fire:Think(cycle, weapon)
    if weapon.Primary.BrustEnabled and weapon:GetBrustCount() > 0 then
        if weapon:CanPrimaryFire() then
            weapon:TrySetTask("PrimaryFire")
        end
        return false
    end
    if ! game.SinglePlayer() then
        weapon:HandleReverb()
        weapon:DoFireSound()
    end
    weapon:TrySetTask("Idle")
    return true
end

SWEP:RegisterTask(task_fire)
