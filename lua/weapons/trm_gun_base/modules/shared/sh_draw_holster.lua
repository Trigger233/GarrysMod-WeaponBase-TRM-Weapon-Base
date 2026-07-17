function SWEP:Holster(weapon)



    if (IsValid(weapon) && weapon != self && weapon != self:GetOwner()) then
        if (self:IsCurrentTask("Deploy")) then
            return true
        end

        self:SetNextWeapon(weapon)
    else
        self:SetNextWeapon(NULL)
    end

    if not string.find(self:GetPlayingSequence(), "Holster") then
        self:TrySetTask("Holster")
    end

    if (CLIENT) then
        if IsValid(TRM_AttachMenu_Instance) then
            TRM_AttachMenu_Instance:Close()
        end
        self:CleanupFlashLights()
    end

    return self:GetCanSwitch() || ! IsValid(weapon) || weapon == self || weapon:GetSlot() == self:GetSlot()
end
