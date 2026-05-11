module("trm_weapon_base_util",package.seeall)
function util.IsTRMBase(weapon)
    return IsValid(weapon) and (weapon.Base == "trm_gun_base" or weapon:GetClass() == "trm_gun_base")
end

function trm_weapon_base_util.IsDucking(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local height = ply:EyePos().z - ply:GetPos().z
    return height <= 32 or ply:KeyDown(IN_DUCK)
end
 