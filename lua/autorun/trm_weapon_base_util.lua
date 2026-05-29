module("trm_weapon_base_util",package.seeall)


function util.IsTRMBase(weapon)
    return IsValid(weapon) and (weapon.IsTRMWeapon)
end

function trm_weapon_base_util.IsDucking(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local height = ply:EyePos().z - ply:GetPos().z
    return height <= 32 or ply:KeyDown(IN_DUCK)
end

CreateConVar("trmbase_load_attachment_on_pickup",1,{FCVAR_ARCHIVE})

hook.Add("PostDrawTranslucentRenderables", "test", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
end)