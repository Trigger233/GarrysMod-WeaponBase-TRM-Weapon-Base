concommand.Add("trmbase_weaponinspect", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.IsTRMWeapon then
        wep:TrySetTask("Inspect")
    end
end)




function SWEP:CanInspect()
    local task = self:GetCurrentTaskName()
    local taskStr = task or ""
    if self:GetNextPrimaryFire() > CurTime() then
        return false
    end

    if self:HasFlag("Aiming") then
        return false
    end

    if string.find(self:GetStatus() , "Inspect" ) then return false end

    return (taskStr == "Idle" or taskStr == "Rechamber" or string.find(taskStr, "Sprint")) and
        (self.Animations.Inspect or self.Animations.Inspect_Empty)
end

function SWEP:IsInspecting()
    return string.find(self:GetStatus(), "Inspect")
end
