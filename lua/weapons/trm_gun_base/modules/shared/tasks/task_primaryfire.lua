local task_charge = {}
task_charge.Name = "Charge"
task_charge.Priority = 255

function task_charge:CanBeSet(weapon)
    return true
end

function task_charge:OnSet(weapon)
end

function task_charge:Think(cycle, weapon)
    local stat = weapon.Primary.Trigger
    if not stat then
        weapon:TrySetTask("PrimaryFire")
        return
    end
    if stat.Sound and not weapon.s_TriggerSound then
        weapon:EmitSound(stat.Sound)
        weapon.s_TriggerSound = true
    end
    if stat.Time > 0 and weapon.m_NextFireTime == nil then
        weapon.m_NextFireTime = CurTime() + stat.Time
    end
    weapon:PlayAnimation(weapon:ChooseAnim("Charge"), true)
    weapon:SetNextPrimaryFire(weapon.m_NextFireTime)
    weapon:SetNextAnimationTime(weapon.m_NextFireTime)
    
    local owner = weapon:GetOwner()
    if not IsValid(owner) then return end
    if weapon.m_NextFireTime and CurTime() >= weapon.m_NextFireTime then
        if not weapon.Primary.Automatic then
            weapon.m_NextFireTime = nil
            weapon.s_TriggerSound = false
        end
        if stat.Type == "Hold" and not owner:KeyDown(IN_ATTACK) then
            weapon:TrySetTask("Idle")
        elseif stat.Type == "Release" and owner:KeyDown(IN_ATTACK) then

        else
            weapon:SetNextAnimationTime(0)
            weapon:TrySetTask("PrimaryFire")
        end
    end
end

SWEP:RegisterTask(task_charge)

local task_fire = {}
task_fire.Name = "PrimaryFire"
task_fire.Priority = 255

function task_fire:CanBeSet(weapon)
    return true
end

function task_fire:OnSet(weapon)
    if not IsFirstTimePredicted() then return end
    local aim = weapon:GetAimDelta() > 0.5 and true or false
    if weapon:Clip1() == 1 and weapon.Animations.Fire_Last then
        if aim and weapon.Animations.Iron_Fire_Last then
            weapon:PlayAnimation("Iron_Fire_Last")
        else
            weapon:PlayAnimation("Fire_Last")
        end
    elseif weapon.Animations.Fire then
        if aim and weapon.Animations.Iron_Fire then
            weapon:PlayAnimation("Iron_Fire", false)
        else
            weapon:PlayAnimation("Fire", false)
        end
    end

    if weapon.Primary.SpecialAmmo == -1 or not weapon.Primary.SpecialAmmo then
        weapon:FirePrimaryBullet()
    else
        weapon:FireProjectile()
    end

    weapon:SetNextPrimaryFire(CurTime() + 60 / weapon.Primary.RPM)
end

function task_fire:Think(cycle, weapon)
    return true
end

SWEP:RegisterTask(task_fire)
