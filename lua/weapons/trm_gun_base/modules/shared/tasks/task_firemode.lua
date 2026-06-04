local task = {}
task.Name = "Firemode"
task.Priority = 100

function task:CanBeSet(weapon)
    return weapon:IsAnimFinished() and weapon.Firemode and true or false
end

function task:OnSet(weapon)
    local stat = weapon.Firemode
    if stat and weapon:IsAnimFinished() then
        local max = #stat
        local index = weapon:GetFiremodeIndex()
        if index >= max then
            index = 1
        else
            index = index + 1
        end
        weapon:SetFiremodeIndex(index)
        local info = stat[index]
        if info and info.Animation then
            weapon:SetNextAnimationTime(0)
            weapon:PlayAnimation(weapon:ChooseAnim(info.Animation), true)
        end
        weapon:FireModeStat(index)
        net.Start("TRMBase_FiremodeCall")
        net.WriteInt(index, 8)
        net.WriteEntity(weapon)
        net.Send(weapon:GetOwner())
    end
end

function task:Think(cycle, weapon)
    return true
end

SWEP:RegisterTask(task)
