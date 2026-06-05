local task = {}

task.Name = "Deploy"

task.Priority = 105

function task:CanBeSet(weapon) 
    return true 
end

function task:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    if weapon:GetFirstDeployed() and weapon.Animations.Draw_First then
        weapon:PlayAnimation("Draw_First", true)
        weapon:SetFirstDeployed(false)
    else
        weapon:PlayAnimation("Draw", true)
    end
end
function task:Think(cycle,weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task)
