local task_charge = {}
task_charge.Name = "Charge"
task_charge.Priority = 255

function task_charge:CanBeSet(weapon)
    return true
end

function task_charge:OnSet(weapon)
    weapon:AddFlag("TriggerPulled")
    local stat = weapon.Primary.Trigger
    if not stat then
        weapon:TrySetTask("PrimaryFire")
        return
    end

    if stat.Sound then
        weapon:EmitSound(stat.Sound)
    end

    if weapon.Animations.Charge then
        weapon:SetNextAnimationTime(0)
        weapon:PlayAnimation(weapon:ChooseAnim("Charge"))
    end

    weapon:SetNextPrimaryFire(CurTime() + (stat.Time or 0))
end

function task_charge:Think(cycle, weapon)
    if (! weapon.Primary.Automatic) and weapon:HasFlag("TriggerPulled")
    then
        weapon:TrySetTask("PrimaryFire")
    end


    if weapon.Primary.Trigger.Type == "Tap" then
    end
end

SWEP:RegisterTask(task_charge)
