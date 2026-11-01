function SWEP:Holster(weapon)
    if (IsValid(weapon) && weapon != self && weapon != self:GetOwner()) then
        if (self:IsCurrentTask("Deploy")) then
            return true
        end

        self:SetNextWeapon(weapon)
    else
        self:SetNextWeapon(NULL)
    end

    if not string.find(self:GetStatus(), "Holster") then
        self:TrySetTask("Holster")
    end

    local bHolster = self:GetCanSwitch() || ! IsValid(weapon) || weapon:GetSlot() == self:GetSlot()
    if !bHolster then return false end

    if (CLIENT) then
        if IsValid(TRM_AttachMenu_Instance) then
            TRM_AttachMenu_Instance:Close()
        end
        self:CleanupFlashLights()
    else
        self:RemoveShield()
    end

    return true
end

function SWEP:Deploy()
    self:GetOwner():SetSaveValue("m_flNextAttack", 0)
    self:BuildCustomizedGun()
    self:GetViewModel().m_CustomDelta = 1
    self:TrySetTask("Deploy")
    self:SetCanSwitch(false)
    self:SetAimDelta(0)


    return true
end

