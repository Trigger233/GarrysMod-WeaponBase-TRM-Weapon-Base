function SWEP:DoBolt(a)
    self:ResetChamberRound(a)
end

function SWEP:ResetChamberRound(amount)
    if not amount then
        amount = self.Primary.Chamber > 0 and self.Primary.Chamber or 1
    end

    self:SetChamberAmmo(amount or 1)
end

function SWEP:ResetChamberRound2(amount)
    if not amount then
        amount = self.Secondary.Chamber
    end

    self:SetSecondaryChamberAmmo(amount)
end

function SWEP:CanRechamber()
    local ply = self:GetOwner()
    if ply:IsPlayer() then
        if ply:KeyDown(IN_ATTACK) then return false end
    end

    return self:GetNextPrimaryFire() <= CurTime() and not self:IsEmpty() and self.Primary.BoltAction
end

function SWEP:ResetBrustCount()
    self:SetBrustCount(self.Primary.BrustNum)
end
