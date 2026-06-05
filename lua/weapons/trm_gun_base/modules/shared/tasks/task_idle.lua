local task = {}

task.Name = "Idle"

task.Priority = 1

function task:CanBeSet(weapon)
    return true
end

function task:Think(cycle,weapon)
    weapon:PlayAnimation(weapon:ChooseAnim("Idle"))
end

function task:OnSet(weapon)
end

SWEP:RegisterTask(task)