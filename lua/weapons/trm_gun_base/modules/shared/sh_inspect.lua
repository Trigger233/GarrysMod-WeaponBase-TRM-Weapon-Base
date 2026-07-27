concommand.Add("trmbase_weaponinspect", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.IsTRMWeapon then
        if wep:CanInspect() then
            wep:TrySetTask("Inspect")
        end
    end
end)



function SWEP:CanInspect()
    local task = self:GetCurrentTaskName()
    local taskStr = task or ""
    if self:GetNextPrimaryFire() > CurTime() then
        return false
    end

    return (taskStr == "Idle" or taskStr == "Rechamber" or string.find(taskStr, "Sprint")) and
        (self.Animations.Inspect or self.Animations.Inspect_Empty) 
end

function SWEP:IsInspecting()
    return string.find(self:GetPlayingSequence(), "Inspect")
end
