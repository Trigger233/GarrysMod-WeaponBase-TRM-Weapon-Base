local task_in = {}

task_in.Name = "UnderBarrel_In"
function task_in:CanBeSet(weapon)
    return (weapon:IsAnimFinished() and weapon.underbarrel)
end

function task_in:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    weapon:SetUnderBarrel(true)
    weapon:PlayAnimation(weapon:ChooseAnim("UnderBarrel_In"), true)
end

function task_in:Think(cycle, weapon)
    weapon:TrySetTask("UnderBarrel")
end

SWEP:RegisterTask(task_in)

local task_out = {}

task_out.Name = "UnderBarrel_Out"

function task_out:CanBeSet(weapon)
    return weapon:IsAnimFinished()
end

function task_out:OnSet(weapon)
    weapon:SetUnderBarrel(false)
    weapon:SetNextAnimationTime(0)
    weapon:PlayAnimation(weapon:ChooseAnim("UnderBarrel_Out"), true)
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
    wep:PlayAnimation(wep:ChooseAnim("UnderBarrel"), false)
end

function task_idle:Think(cycle, wep)
    if cycle > 0.995 then
        wep:PlayAnimation(wep:ChooseAnim("UnderBarrel"), false)
    end
end

SWEP:RegisterTask(task_idle)

local task_reload = {}

task_reload.Name = "UnderBarrel_Reload"

function task_reload:CanBeSet(weapon)
    return weapon:CanReload2()
end

function task_reload:OnSet(w)
    w:SetNextAnimationTime(0)
    w:PlayAnimation(w:ChooseAnim("UnderBarrel_Reload", true), true)
end

function task_reload:Think(c, w)
    w:TrySetTask("UnderBarrel")
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
