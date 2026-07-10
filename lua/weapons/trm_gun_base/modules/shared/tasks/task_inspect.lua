local task = {}
task.Name = "Inspect"
task.Priority = 100

function task:CanBeSet(weapon)
    return weapon:CanInspect()
end

function task:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    if weapon:IsEmpty() and weapon.Animations.Inspect_Empty then
        weapon:PlayAnimation("Inspect_Empty")
    elseif weapon.Animations.Inspect then
        weapon:PlayAnimation("Inspect")
    end

end

function task:Think(cycle, weapon)
    if cycle > 0.99 then
    weapon:TrySetTask("Idle")
    end
end

SWEP:RegisterTask(task)
