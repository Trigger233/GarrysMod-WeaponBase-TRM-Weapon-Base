local task_in = {}
task_in.Name = "AdsIn"
task_in.Priority = 100

function task_in:CanBeSet(weapon)
    return (weapon:CanAim() )
end

function task_in:OnSet(weapon)
        weapon:PlayAnimation(weapon:ChooseAnim("Ads_In"), true)
        weapon:SetNextFireTime(0)
        weapon:SetNextAnimationTime(CurTime() + weapon:GetAimTime())
end

function task_in:Think(cycle, weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task_in)

local task_out = {}
task_out.Name = "AdsOut"
task_out.Priority = 100

function task_out:CanBeSet(weapon)
    return true
end

function task_out:OnSet(weapon)
        weapon:SetNextAnimationTime(0)
        weapon:PlayAnimation(weapon:ChooseAnim("Ads_Out"), true)
        weapon:SetNextFireTime(0)
        weapon:SetNextAnimationTime(CurTime() + weapon:GetAimTime())
end

function task_out:Think(cycle, weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task_out)
