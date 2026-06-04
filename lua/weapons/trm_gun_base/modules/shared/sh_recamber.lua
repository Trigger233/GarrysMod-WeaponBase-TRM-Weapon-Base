
function SWEP:ResetChamberRound(amount)
    if not amount then
        amount = self.Primary.ChamberSize
    end
    
    self:SetChamberAmmo(amount)
end

function SWEP:CanRechamber()
    local seq = self.m_CurrentSequence or self:GetPlayingSequence()
    local task = self:GetCurrentTaskName() or ""
    if (string.find(seq, "Idle") or string.find(seq, "Rechamber") or string.find(task, "Sprint") or string.find(seq, "Sprint")) and not self:IsEmpty() then return true end
    return false 
end