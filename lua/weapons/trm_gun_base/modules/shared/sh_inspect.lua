concommand.Add("trmbase_weaponinspect", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base") then
        if wep:CanInspect() then
            wep:TrySetTask("Inspect")
        end
    end
end)



function SWEP:CanInspect()
    local task = self:GetCurrentTaskName()
    local taskStr = task or ""
    return (taskStr == "Idle" or taskStr == "Rechamber" or string.find(taskStr, "Sprint")) and
        (self.Animations.Inspect or self.Animations.Inspect_Empty) and
        not string.find(self:GetPlayingSequence(), "Inspect")
end

function SWEP:IsInspecting()
    return string.find(self:GetPlayingSequence(), "Inspect")
end
