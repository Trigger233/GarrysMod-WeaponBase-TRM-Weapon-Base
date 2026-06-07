module("trm_weapon_base_util",package.seeall)
trm_util = trm_util or {}
local function getBase(weapon)
    if weapon.IsTRMWeapon then
        return true
    end
    if weapon.Base then
        return getBase(weapon.Base)
    end
    return false
end

function util.IsTRMBase(weapon)
    return IsValid(weapon) and (getBase(weapon))
end

function trm_weapon_base_util.IsDucking(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local height = ply:EyePos().z - ply:GetPos().z
    return height <= 32 or ply:KeyDown(IN_DUCK)
end

CreateConVar("trmbase_load_attachment_on_pickup",1,{FCVAR_ARCHIVE})

if (CLIENT) then
    --used to reparent ents after a fullupdate
    local FullUpdateEntities = {}
    
    function trm_weapon_base_util.DealWithFullUpdate(ent)
        FullUpdateEntities[ent] = true
    end

    hook.Add("PreRender", "trm_utilsFullUpdatePreRender", function()
        for ent, _ in pairs(FullUpdateEntities) do
            if (!IsValid(ent)) then
                FullUpdateEntities[ent] = nil
                continue
            end

            local fullUpdateParent = ent:GetInternalVariable("m_hNetworkMoveParent")

            if (!IsValid(ent:GetParent()) && IsValid(fullUpdateParent)) then
                ent:SetParent(fullUpdateParent)
            end
        end
    end)
end

