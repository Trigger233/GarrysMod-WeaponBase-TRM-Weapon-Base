local task = {}

task.Name = "Idle"

task.Priority = 1

function task:CanBeSet(weapon)
    return not (string.find(weapon:GetStatus(), "Holster"))
end

function task:Think(cycle, weapon)
    if weapon:GetUnderbarrel() then
        weapon:TrySetTask("UnderBarrel")
        return
    end
    if cycle >= 0.90 then
        weapon:PlayAnimation(weapon:ChooseAnim("Idle"))
    end
end

function task:OnSet(weapon)
end

SWEP:RegisterTask(task)
