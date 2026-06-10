local task = {}

task.Name = "Idle"

task.Priority = 1

function task:CanBeSet(weapon)
    return true
end

function task:Think(cycle,weapon)
    if weapon:GetUnderbarrel() then
        weapon:TrySetTask("UnderBarrel")
        return
    end
    weapon:PlayAnimation(weapon:ChooseAnim("Idle"))
end

function task:OnSet(weapon)
end

SWEP:RegisterTask(task)