local task = {}
task.Name = "Holster"
task.Priority = 250

function task:CanBeSet(weapon)
    return true
end

function task:OnSet(weapon)
    weapon:SetNextAnimationTime(0)
    weapon:PlayAnimation("Holster", true)
end

function task:Think(cycle, weapon)
    local seq = weapon:GetPlayingSequence()
    if string.find(seq, "Holster") and weapon:GetNextPrimaryFire() < CurTime() or weapon.AltSwitch then
        if IsValid(weapon:GetNextWeapon()) then
            weapon:SetCanSwitch(true)
            if CLIENT and IsFirstTimePredicted() then
                input.SelectWeapon(weapon:GetNextWeapon())
            elseif SERVER then
                local ow = weapon:GetOwner()
                if IsValid(ow) then
                    ow:SendLua("input.SelectWeapon(Entity(" .. weapon:GetNextWeapon():EntIndex() .. "))")
                end
            end
        end
        weapon:TrySetTask("Idle")
        return true
    end
end

SWEP:RegisterTask(task)
