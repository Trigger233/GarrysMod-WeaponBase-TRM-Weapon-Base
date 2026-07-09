require("trm_utils")
if (SERVER) then
    function SWEP:DoShell()
        if (SERVER and (IsFirstTimePredicted() or not game.SinglePlayer())) then
            self:CallOnClient("DoShell")
            return
        end
    end
end


hook.Add("PlayerSwitchFlashlight", "TRMBASE_FlashLight", function(ply, enabled)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end



    if weapon.SwitchFlashLight and weapon.flashlight then
        weapon:SwitchFlashLight()
        return false
    end
end)


function SWEP:SwitchFlashLight()
    self:EmitSound("weapons/zoom.wav")

    self:SetFlashLightOn(not self:GetFlashLightOn())
end
