if SERVER then return end

TRM_ScopePiP = TRM_ScopePiP or {}

local P = TRM_ScopePiP

function P.Cleanup()
    if IsValid(P.ActiveModel) then
        P.ResetModel(P.ActiveModel)
    end

    P.ActiveModel = nil
    P.ActiveWeapon = nil
    P.ActiveAttachment = nil
    P.NextRender = nil
end

hook.Add("Think", "TRM_ScopePiP_CleanupInactive", function()
    if not IsValid(P.ActiveModel) then return end

    local ply = LocalPlayer()
    local wep = IsValid(ply) and ply:GetActiveWeapon() or nil
    if not P.IsPlayerAimingWithElcan(ply, wep) then
        if IsValid(wep) and P.HasPiPEquipped and P.HasPiPEquipped(wep) then
            P.ApplyInactiveLensMaterial(P.ActiveModel, P.ActiveAttachment)
        else
            P.ResetModel(P.ActiveModel)
        end
    end

    if P.LastSeen and CurTime() - P.LastSeen > 2 then
        P.Cleanup()
    end
end)

hook.Add("OnEntityRemoved", "TRM_ScopePiP_CleanupRemoved", function(ent)
    if ent == P.ActiveModel or ent == P.ActiveWeapon then
        P.Cleanup()
    end
end)

hook.Add("PreCleanupMap", "TRM_ScopePiP_CleanupMap", P.Cleanup)
hook.Add("ShutDown", "TRM_ScopePiP_Shutdown", P.Cleanup)
hook.Add("OnReloaded", "TRM_ScopePiP_Reloaded", P.Cleanup)
