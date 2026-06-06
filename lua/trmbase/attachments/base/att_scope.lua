ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

local fallbackReticle = Material("models/weapons/tfa_ins2/optics/aimpoint_reticule")
local cheapScopeMat = CLIENT and Material("models/weapons/tfa_ins2/optics/optic_lense") or nil
local scopeRTLensMat = CLIENT and Material("effects/trm_scope_rt") or nil
local hiddenScopeLensMat = CLIENT and CreateMaterial("trm_scope_hidden_lens", "UnlitGeneric", {
    ["$basetexture"] = "color/black",
    ["$model"] = "1",
    ["$translucent"] = "0",
    ["$alpha"] = "1",
    ["$vertexalpha"] = "1",
    ["$vertexcolor"] = "1",
    ["$nocull"] = "1",
    ["$nodecal"] = "1"
}) or nil

local scopeLensNeedles = { "lense_rt" }
local scopeGlassNeedles = { "optic_lense", "aimpoint_lense", "eotech_lense", "kobra_lense", "mosin_lense" }
local scopeReticleNeedles = { "elcan_reticule", "reticule" }
local scopeBlockerNeedles = { "parallax_mask" }

local function GetScopeConfig(att)
    att.Scope = att.Scope or {}
    return att.Scope
end


function ATTACHMENT:Render(wep, model)
    if CLIENT and TRM_ScopePiP and TRM_ScopePiP.RenderScopeAttachment and wep:IsCarriedByLocalPlayer() and not wep:GetOwner():ShouldDrawLocalPlayer() then
        return TRM_ScopePiP.RenderScopeAttachment(wep, model, self)
    end

    if IsValid(model) then
        model:DrawModel()
    end
end

function ATTACHMENT:GetScopeMagnification()
    local scope = GetScopeConfig(self)
    
    return scope.Zoom or 1
end
