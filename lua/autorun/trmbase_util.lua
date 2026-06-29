AddCSLuaFile()
module("trm_weapon_base_util", package.seeall)
trm_util = trm_util or {}

local IsTRMBaseCache = {}
local function getBase(weapon)
    IsTRMBaseCache[weapon:GetClass()] = IsTRMBaseCache[weapon:GetClass()]
        || weapons.IsBasedOn(weapon:GetClass(), "trm_gun_base")
    return IsTRMBaseCache[weapon:GetClass()]
end

function util.IsTRMBase(weapon)
    return IsValid(weapon) and (getBase(weapon))
end

function trm_weapon_base_util.IsDucking(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local height = ply:EyePos().z - ply:GetPos().z
    return height <= 32 or ply:KeyDown(IN_DUCK)
end

CreateConVar("trmbase_load_attachment_on_pickup", 1, { FCVAR_ARCHIVE })

if (CLIENT) then
    --used to reparent ents after a fullupdate
    local FullUpdateEntities = {}

    function trm_weapon_base_util.DealWithFullUpdate(ent)
        FullUpdateEntities[ent] = true
    end
end
