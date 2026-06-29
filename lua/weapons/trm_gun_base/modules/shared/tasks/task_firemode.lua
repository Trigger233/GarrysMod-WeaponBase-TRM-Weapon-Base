local task = {}
task.Name = "Firemode"
task.Priority = 100

function task:CanBeSet(weapon)
    return weapon:IsAnimFinished() and weapon.Firemode and true or false
end

function task:OnSet(weapon)
    local stat = weapon.Firemode
    if stat then
        local max = #stat
        local index = weapon:GetFiremodeIndex()
        if index >= max then
            index = 1
        else
            index = index + 1
        end
        weapon:SetFiremodeIndex(index)
        local info = stat[index]
        if info and info.Animation and weapon.Animations[info.Animation] then
            weapon:SetNextAnimationTime(0)
            weapon:PlayAnimation(weapon:ChooseAnim(info.Animation), true)
        else
            weapon:EmitSound("Weapon_AR2.Empty")
        end
        weapon:FireModeStat(index)
        net.Start("TRMBase_FiremodeCall")
        net.WriteInt(index, 4)
        net.WriteEntity(weapon)
        net.Send(weapon:GetOwner())
    end
    weapon:TrySetTask("Idle")
end

function task:Think(cycle, weapon)
    return true
end

SWEP:RegisterTask(task)
