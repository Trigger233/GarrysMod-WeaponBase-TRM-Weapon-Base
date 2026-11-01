local task = {}

task.Name = "Deploy"

task.Priority = 105

function task:CanBeSet(weapon) 
    return true 
end

function task:OnSet(weapon)
    weapon:PlayerGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, weapon.HoldTypes[weapon:GetCurrentHoldType()].Draw)
    weapon:SetNextAnimationTime(0)
    weapon:PlayAnimation("Draw", true)
    if weapon:GetFirstDeployed() and weapon.Animations.Draw_First then
        weapon:SetNextAnimationTime(0)
        weapon:PlayAnimation("Draw_First",false)
        weapon:SetFirstDeployed(false)
    end
end
function task:Think(cycle,weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task)
