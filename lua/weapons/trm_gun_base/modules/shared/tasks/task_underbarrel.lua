local task_in = {}

task_in.Name = "UnderBarrel_In"
function task_in:CanBeSet(weapon)
    return (weapon:GetNextPrimaryFire() < UnPredictedCurTime() and weapon.underbarrel)
end

function task_in:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    weapon:SetUnderbarrel(true)

    if weapon.NoIK then
        weapon:PlayAnimation("UnderBarrel_In")
        return
    end

    weapon:PlayIKAnimation("In", true)
end

function task_in:Think(cycle, weapon)
    weapon:TrySetTask("UnderBarrel")
end

SWEP:RegisterTask(task_in)

local task_out = {}

task_out.Name = "UnderBarrel_Out"

function task_out:CanBeSet(weapon)
    return true
end

function task_out:OnSet(weapon)
    weapon:SetUnderbarrel(false)
    weapon:SetNextAnimationTime(0)

    if weapon.NoIK then
        weapon:PlayAnimation("UnderBarrel_Out",true)
        return
    end
    weapon:PlayIKAnimation("Out", true)
end

function task_out:Think(cycle, weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task_out)


local task_idle = {}

task_idle.Name = "UnderBarrel"

function task_idle:CanBeSet(wep)
    return true
end

function task_idle:OnSet(wep)
    if wep:GetNextPrimaryFire() < UnPredictedCurTime() then
        if wep.NoIK then
            wep:PlayAnimation("UnderBarrel_Idle")
            return
        end

        wep:PlayIKAnimation("Idle", false)
    end
end

function task_idle:Think(cycle, wep)
end

SWEP:RegisterTask(task_idle)

local task_reload = {}

task_reload.Name = "UnderBarrel_Reload"

function task_reload:CanBeSet(weapon)
    if weapon:Ammo2() == 0 then
        weapon:TrySetTask("UnderBarrel_Out")
        return false
    end



    return weapon:CanReload2()
end

function task_reload:OnSet(w)
    w:SetNextAnimationTime(0)
    if w.NoIK then
        w:PlayAnimation("UnderBarrel_Reload",true)
        return
    end

    w:PlayIKAnimation("Reload", true)
end

function task_reload:Think(c, w)
    if w:GetNextPrimaryFire() < CurTime() then
        w:TrySetTask("UnderBarrel")
    end
end

SWEP:RegisterTask(task_reload)

local task_fire = {}
task_fire.Name = "UnderbarrelFire"
function task_fire:CanBeSet(w)
    return w:CanSecondaryFire()
end

function task_fire:OnSet(weapon)
    weapon:DoUnderbarrelAttack()
end

function task_fire:Think(c, w)
end

SWEP:RegisterTask(task_fire)
