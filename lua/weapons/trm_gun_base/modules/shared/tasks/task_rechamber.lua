local task = {}
task.Name = "Rechamber"
task.Priority = 200
task.NoAutoIdle = true

function task:CanBeSet(weapon)
    return true
end

function task:OnSet(weapon)
    if weapon.Animations.Rechamber and not weapon:IsEmpty() then
        weapon:SetNextAnimationTime(0)
        weapon:PlayAnimation("Rechamber",true)
        local delay = 60/ weapon.Primary.RPM
        weapon:SetNextAnimationTime(CurTime() + delay)
        weapon:SetNextFireTime(delay)
    end
end

function task:Think(cycle, weapon)
    local owner = weapon:GetOwner()
    if owner and owner:KeyDown(IN_ATTACK) and weapon.Primary.Automatic then return end
    if cycle >= 0.98 then
        weapon:TrySetTask("Idle")
    end
end

SWEP:RegisterTask(task)
