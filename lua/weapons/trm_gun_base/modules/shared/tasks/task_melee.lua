local task = {}
task.Name = "Melee"
task.Priority = 200

function task:CanBeSet(weapon)
    return weapon:CanMelee()
end

function task:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    if weapon:IsEmpty() and weapon.Animations.Melee_Empty then
        weapon:PlayAnimation("Melee_Empty", true)
    elseif weapon.Animations.Melee then
        weapon:PlayAnimation("Melee", true)
    end
end

function task:Think(cycle, weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task)
