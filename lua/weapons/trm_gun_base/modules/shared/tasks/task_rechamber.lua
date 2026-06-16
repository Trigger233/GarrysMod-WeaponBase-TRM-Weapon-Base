local task = {}
task.Name = "Rechamber"
task.Priority = 200

function task:CanBeSet(weapon)
    local owner = weapon:GetOwner()
    return weapon:IsAnimFinished() and weapon:CanRechamber() and weapon:GetChamberAmmo() <= 0 and not (  owner and owner:KeyDown(IN_ATTACK) and not weapon.Primary.Automatic)
end

function task:OnSet(weapon)
    if weapon.Animations.Rechamber and not weapon:IsEmpty() then
        weapon:PlayAnimation("Rechamber",true)
        --local delay = 60/ weapon.Primary.RPM
    end
end

function task:Think(cycle, weapon)
    weapon:TrySetTask("Idle")
end

SWEP:RegisterTask(task)
