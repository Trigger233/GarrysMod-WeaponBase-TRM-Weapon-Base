if SERVER then return end

TRM_ScopePiP = TRM_ScopePiP or {}

local P = TRM_ScopePiP

function P.RenderScopeAttachment(wep, model, att)
    if not IsValid(model) then return end

    -- P.RegisterElcanModel(wep, model, att)

    local ply = LocalPlayer()
    local shouldApply = IsValid(ply) and P.IsPlayerAimingWithScope(ply, wep)

    if shouldApply then
        P.ApplyLensMaterial(model, att)
    else
        P.ApplyInactiveLensMaterial(model, att)
    end

    model:DrawModel()
end
