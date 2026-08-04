local task_in = {}
task_in.Name = "SprintIn"
task_in.Priority = 150

function task_in:CanBeSet(weapon)
    return true
end

function task_in:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    weapon:PlayAnimation(weapon:ChooseAnim("SprintIn"), true)
end

function task_in:Think(cycle, weapon)
    weapon:TrySetTask("Sprint")
end

SWEP:RegisterTask(task_in)

local task_sprint = {}
task_sprint.Name = "Sprint"
task_sprint.Priority = 150

function task_sprint:CanBeSet(weapon)
    return true
end

function task_sprint:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    if weapon.Animations.Sprint then
        weapon:PlayAnimation(weapon:ChooseAnim("Sprint"), true)
    end
end

function task_sprint:Think(cycle, weapon)
    if weapon.Animations.Sprint and weapon:GetNextPrimaryFire() < UnPredictedCurTime() then
        weapon:PlayAnimation(weapon:ChooseAnim("Sprint"), true)
    end

    local owner = weapon:GetOwner()
    if IsValid(owner) and (not owner:KeyDown(IN_SPEED) or not owner:OnGround()) then
        weapon:TrySetTask("SprintOut")
    end
end

SWEP:RegisterTask(task_sprint)

local task_out = {}
task_out.Name = "SprintOut"
task_out.Priority = 150

function task_out:CanBeSet(weapon)
    return true
end

function task_out:OnSet(weapon)
    weapon:SetNextFireTime(0.0)
    if weapon.Animations.SprintOut then
        weapon:PlayAnimation(weapon:ChooseAnim("SprintOut"))
    end
end

function task_out:Think(cycle, weapon)
    weapon:SetNextAnimationTime(0)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task_out)
