local task = {}
task.Name = "Melee"
task.Priority = 200

function task:CanBeSet(weapon)
    return weapon:CanMelee()
end

function task:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    weapon:PlayerGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, weapon.HoldTypes[weapon:GetCurrentHoldType()].Melee)

    weapon:PlayAnimation(weapon:ChooseAnim("Melee"),true)

end

function task:Think(cycle, weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task)
