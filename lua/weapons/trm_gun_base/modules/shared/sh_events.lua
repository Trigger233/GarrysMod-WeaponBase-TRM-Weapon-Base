require("trm_utils")
if (SERVER) then
    function SWEP:DoShell()
        if (IsFirstTimePredicted()) then
            self:CallOnClient("DoShell")
            return
        end
    end
end


hook.Add("PlayerSwitchFlashlight", "TRMBASE_FlashLight", function(ply, enabled)
    if ! enabled then return true end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not util.IsTRMBase(weapon) then return end



    if weapon.SwitchFlashLight and weapon.flashlight then
        weapon:SwitchFlashLight()
        return false
    end
end)


function SWEP:SwitchFlashLight()
    self:EmitSound("weapons/zoom.wav")
    self:ToggleFlag("FlashLightOn")
end

function SWEP:DropMagazine()
    if ! SERVER then return end
    self:CallOnClient("DoDropMagzineEffect")
    return
end


function SWEP:effect(Name)
    self:CallOnClient(Name) 
end