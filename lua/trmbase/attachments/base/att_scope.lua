ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

if CLIENT then
    CreateClientConVar("trm_scope_rt", "1", true, false, "Draw RT texture scopes on optic accessory models.")
    CreateClientConVar("trm_scope_overlay", "1", true, false, "Draw TRM magnified scope overlay.")
end

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
    att.Sight = att.Sight or {}
    return att.Scope
end

local function IsLocalWeapon(wep)
    return CLIENT and IsValid(wep) and wep:IsCarriedByLocalPlayer()
end

local function FindActiveScopeAttachment(wep)
    if not IsLocalWeapon(wep) then return nil end

    for _, entry in pairs(wep.CurrentAttachments or {}) do
        local att = entry and entry.Class and BASE_TRM_ATTS and BASE_TRM_ATTS[entry.Class]
        if att and att.Scope then
            wep.TRM_ActiveScopeAttachment = att
            return att
        end
    end

    wep.TRM_ActiveScopeAttachment = nil
    return nil
end

local function GetAimAlpha(att, wep)
    local scope = GetScopeConfig(att)
    local aimDelta = wep.GetAimDelta and wep:GetAimDelta() or 1
    local drawAt = scope.DrawAt or 0.35
    if aimDelta <= drawAt then return 0 end
    return math.Clamp((aimDelta - drawAt) / (1 - drawAt), 0, 1)
end

local function DrawTexturedCircle(x, y, radius, segments, textureRotate)
    local verts = {}
    segments = segments or 128
    textureRotate = math.rad(textureRotate or 0)

    local rotCos = math.cos(textureRotate)
    local rotSin = math.sin(textureRotate)

    table.insert(verts, { x = x, y = y, u = 0.5, v = 0.5 })
    for i = 0, segments do
        local r = math.rad((i / segments) * 360)
        local cx = math.cos(r)
        local cy = math.sin(r)
        local u = cx * rotCos - cy * rotSin
        local v = cx * rotSin + cy * rotCos

        table.insert(verts, {
            x = x + cx * radius,
            y = y + cy * radius,
            u = 0.5 + u * 0.5,
            v = 0.5 + v * 0.5
        })
    end

    surface.DrawPoly(verts)
end

local function DrawReticle2D(att, scope, x, y, radius, alpha)
    local ret = att.Sight or {}
    local retMat = ret.Material or scope.ReticleMaterial or fallbackReticle
    local retColor = ret.Color or Color(255, 255, 255)
    local lineColor = scope.ReticleLineColor or Color(8, 8, 8, 245)
    local retSize = scope.ReticleSize or ret.ReticleSize or math.min(radius * 1.45, ret.Size or radius * 1.25)

    if scope.UseMaterialReticle == true and retMat then
        surface.SetMaterial(retMat)
        surface.SetDrawColor(retColor.r, retColor.g, retColor.b, (retColor.a or 255) * alpha)
        surface.DrawTexturedRectRotated(x, y, retSize, retSize, ret.Rotate or scope.ReticleRotate or 0)
        return
    end

    local gap = radius * 0.035
    local fineLen = radius * 0.2
    local postStart = radius * 0.55
    local postLen = radius * 0.18
    local thick = math.max(1, math.floor(radius * 0.004))
    local postThick = math.max(2, math.floor(radius * 0.012))

    surface.SetDrawColor(lineColor.r, lineColor.g, lineColor.b, (lineColor.a or 245) * alpha)
    surface.DrawRect(x - thick * 0.5, y - gap - fineLen, thick, fineLen)
    surface.DrawRect(x - thick * 0.5, y + gap, thick, fineLen)
    surface.DrawRect(x - gap - fineLen, y - thick * 0.5, fineLen, thick)
    surface.DrawRect(x + gap, y - thick * 0.5, fineLen, thick)
    surface.DrawRect(x - thick * 0.5, y - thick * 0.5, thick, thick)

    surface.DrawRect(x - postStart - postLen, y - postThick * 0.5, postLen, postThick)
    surface.DrawRect(x + postStart, y - postThick * 0.5, postLen, postThick)
    surface.DrawRect(x - postThick * 0.5, y + postStart, postThick, postLen)
end

local function DrawScopeEdge(x, y, radius, alpha)
    surface.SetDrawColor(0, 0, 0, 255 * alpha)
    for i = 0, 10 do
        surface.DrawCircle(x, y, radius + i, 0, 0, 0, 255 * alpha)
    end

    surface.SetDrawColor(255, 255, 255, 32 * alpha)
    surface.DrawCircle(x, y, radius - 5, 255, 255, 255, 32 * alpha)
    surface.DrawCircle(x, y, radius - 11, 255, 255, 255, 18 * alpha)
end

local function DrawCheapScopeOverlay(att, wep)
    if not CLIENT or GetConVar("trm_scope_overlay"):GetBool() == false then return end

    local scope = GetScopeConfig(att)
    if scope.ScreenOverlay == false then return end

    local alpha = GetAimAlpha(att, wep)
    if alpha <= 0 then return end

    local screenSize = scope.ScreenSize or scope.Size or (att.Sight and att.Sight.Size) or 420
    if scope.ScreenScale then
        screenSize = math.min(ScrW(), ScrH()) * scope.ScreenScale
    end

    local radius = screenSize * 0.5
    local x = ScrW() * 0.5 + (scope.ScreenOffset and scope.ScreenOffset.x or 0)
    local y = ScrH() * 0.5 + (scope.ScreenOffset and scope.ScreenOffset.y or 0)
    local backdropAlpha = scope.BackdropAlpha or 235

    surface.SetDrawColor(0, 0, 0, backdropAlpha * alpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())

    draw.NoTexture()
    surface.SetDrawColor(0, 0, 0, 255 * alpha)
    DrawTexturedCircle(x, y, radius + 34, scope.Segments or 144, 0)
    surface.SetDrawColor(8, 8, 8, 245 * alpha)
    DrawTexturedCircle(x, y, radius + 17, scope.Segments or 144, 0)

    surface.SetMaterial(scope.CheapMaterial or cheapScopeMat)
    surface.SetDrawColor(190, 210, 205, (scope.LensAlpha or 42) * alpha)
    DrawTexturedCircle(x, y, radius, scope.Segments or 128, scope.TextureRotate or scope.ScreenRotate or 0)

    DrawReticle2D(att, scope, x, y, radius, alpha)
    DrawScopeEdge(x, y, radius, alpha)
end

local function HasMaterialNeedle(mat, needles)
    local lower = string.lower(mat or "")
    for _, needle in ipairs(needles) do
        if string.find(lower, needle, 1, true) then return true end
    end

    return false
end

local function ApplyScopeLensMaterials(att, wep, model)
    if not CLIENT or not IsLocalWeapon(wep) or not IsValid(model) then return end

    local scope = GetScopeConfig(att)
    if scope.ModelLensRT ~= true then return end
    local scopedIn = GetAimAlpha(att, wep) > 0.01

    local lensKey = tostring(att.Name)
        .. ":" .. tostring(scope.ModelLensRT)
        .. ":" .. tostring(scope.HideScopeGlass)
        .. ":" .. tostring(scope.HideReticleMaterial)
        .. ":" .. tostring(scopedIn)

    if model.TRM_ScopeLensApplied and model.TRM_ScopeLensKey == lensKey then return end

    for index, mat in ipairs(model:GetMaterials() or {}) do
        if HasMaterialNeedle(mat, scopeBlockerNeedles)
            or (scope.HideScopeGlass ~= false and HasMaterialNeedle(mat, scopeGlassNeedles))
            or (scope.HideReticleMaterial == true and HasMaterialNeedle(mat, scopeReticleNeedles)) then
            model:SetSubMaterial(index - 1, "!trm_scope_hidden_lens")
        elseif HasMaterialNeedle(mat, scopeLensNeedles) then
            model:SetSubMaterial(index - 1, scopedIn and "effects/trm_scope_rt" or "!trm_scope_hidden_lens")
        end
    end

    model.TRM_ScopeLensApplied = true
    model.TRM_ScopeLensKey = lensKey
end

local function GetScopeRT(att, wep)
    local scope = GetScopeConfig(att)
    local size = scope.RTSize or 768
    local name = "trm_scope_rt_" .. wep:EntIndex() .. "_" .. tostring(att.Name or "optic")

    if not att._ScopeRT or att._ScopeRTSize ~= size then
        att._ScopeRT = GetRenderTarget(name, size, size)
        att._ScopeRTSize = size
        att._ScopeMaterial = CreateMaterial(name .. "_mat", "UnlitGeneric", {
            ["$basetexture"] = att._ScopeRT:GetName(),
            ["$model"] = "1",
            ["$translucent"] = "1",
            ["$vertexalpha"] = "1",
            ["$vertexcolor"] = "1",
            ["$nocull"] = "1"
        })
    end

    return att._ScopeRT, att._ScopeMaterial
end

local function RenderScopeView(att, wep)
    if not CLIENT then return nil end

    local owner = wep:GetOwner()
    if not IsValid(owner) then return nil end

    local scope = GetScopeConfig(att)

    local rt = GetScopeRT(att, wep)
    if not rt then return nil end

    local size = scope.RTSize or 768
    local baseFOV = owner:GetFOV()
    if baseFOV <= 0 then baseFOV = GetConVar("fov_desired"):GetInt() end

    local mag =  scope.Zoom or 1
    local fov =  math.Clamp(baseFOV / mag, 1, 90)
    local eyeAng = owner:EyeAngles() + wep:GetClientVisualRecoil()
    local eyePos = owner:EyePos() + eyeAng:Forward() * (scope.CameraForward or 0)
    wep.TRM_RenderingScopeRT = true
    TRM_SCOPE_RENDERING_RT = wep

    render.PushRenderTarget(rt)
        render.Clear(0, 0, 0, 255, true, true)
        local ok, err = xpcall(function()
            render.RenderView({
                x = 0,
                y = 0,
                w = size,
                h = size,
                aspectratio = 1,
                origin = eyePos,
                angles = eyeAng,
                fov = fov,
                drawviewmodel = false,
                drawhud = false,
                dopostprocess = false,
                znear = scope.ZNear or 1,
                zfar = scope.ZFar or 30000
            })
        end, debug.traceback)
    render.PopRenderTarget()

    wep.TRM_RenderingScopeRT = false
    TRM_SCOPE_RENDERING_RT = nil
    if not ok then
        ErrorNoHalt("[TRM] Scope RT render failed: " .. tostring(err) .. "\n")
        return nil
    end

    if scopeRTLensMat then
        scopeRTLensMat:SetTexture("$basetexture", rt)
    end

    return select(2, GetScopeRT(att, wep))
end

local function DrawRTCircleAtAttachment(att, wep, model, rtmat)
    if not CLIENT or not IsLocalWeapon(wep) or not IsValid(model) or not rtmat then return end

    local scope = GetScopeConfig(att)

    local attachName =  scope.Align or "scope_origin"
    local attachID = model:LookupAttachment(attachName)
    if not attachID or attachID <= 0 then return end

    local data = model:GetAttachment(attachID)
    if not data then return end

    local alpha = GetAimAlpha(att, wep)
    if alpha <= 0 then return end

    local radius = scope.RTAttachmentRadius or scope.LensRadius or 1.05
    local segments = scope.RTAttachmentSegments or 72
    local center = data.Pos
        + data.Ang:Forward() * (scope.RTAttachmentOffset or 0)
        + data.Ang:Right() * (scope.RTAttachmentRightOffset or 0)
        + data.Ang:Up() * (scope.RTAttachmentUpOffset or 0)
    local right = data.Ang:Right()
    local up = data.Ang:Up()
    local function uv(cx, cy)
        local rot = math.rad(scope.RTTextureRotate or 0)
        if rot ~= 0 then
            local rotCos = math.cos(rot)
            local rotSin = math.sin(rot)
            local rx = cx * rotCos - cy * rotSin
            local ry = cx * rotSin + cy * rotCos

            cx = rx
            cy = ry
        end

        local u = 0.5 + cx * 0.5
        local v = 0.5 - cy * 0.5


        return u, v
    end

    render.SetMaterial(rtmat)
    mesh.Begin(MATERIAL_TRIANGLES, segments)
        for i = 0, segments - 1 do
            local a0 = (i / segments) * math.pi * 2
            local a1 = ((i + 1) / segments) * math.pi * 2
            local c0 = math.cos(a0)
            local s0 = math.sin(a0)
            local c1 = math.cos(a1)
            local s1 = math.sin(a1)
            local u0, v0 = uv(c0, s0)
            local u1, v1 = uv(c1, s1)
            local p0 = center + right * c0 * radius + up * s0 * radius
            local p1 = center + right * c1 * radius + up * s1 * radius

            mesh.Position(center)
            mesh.TexCoord(0, 0.5, 0.5)
            mesh.Color(255, 255, 255, 255 * alpha)
            mesh.AdvanceVertex()

            mesh.Position(p0)
            mesh.TexCoord(0, u0, v0)
            mesh.Color(255, 255, 255, 255 * alpha)
            mesh.AdvanceVertex()

            mesh.Position(p1)
            mesh.TexCoord(0, u1, v1)
            mesh.Color(255, 255, 255, 255 * alpha)
            mesh.AdvanceVertex()
        end
    mesh.End()

    if scope.DrawAttachmentReticle == false then return end

    local color = scope.AttachmentReticleColor or Color(0, 0, 0, 235)
    local gap = radius * (scope.AttachmentReticleGap or 0.045)
    local len = radius * (scope.AttachmentReticleLength or 0.48)
    local post = radius * (scope.AttachmentReticlePost or 0.7)
    local reticlePos = center + data.Ang:Forward() * (scope.AttachmentReticleOffset or 0.025)

    if scope.UseAttachmentReticleMaterial == true then
        local ret = att.Sight or {}
        local mat = ret.Material or scope.ReticleMaterial
        if mat then
            local retSize = radius * (scope.AttachmentReticleMaterialScale or 1.65)
            local retRight = right * retSize
            local retUp = up * retSize

            render.SetMaterial(mat)
            mesh.Begin(MATERIAL_QUADS, 1)
                mesh.Position(reticlePos - retRight - retUp)
                mesh.TexCoord(0, 0, 1)
                mesh.Color(255, 255, 255, 255 * alpha)
                mesh.AdvanceVertex()

                mesh.Position(reticlePos + retRight - retUp)
                mesh.TexCoord(0, 1, 1)
                mesh.Color(255, 255, 255, 255 * alpha)
                mesh.AdvanceVertex()

                mesh.Position(reticlePos + retRight + retUp)
                mesh.TexCoord(0, 1, 0)
                mesh.Color(255, 255, 255, 255 * alpha)
                mesh.AdvanceVertex()

                mesh.Position(reticlePos - retRight + retUp)
                mesh.TexCoord(0, 0, 0)
                mesh.Color(255, 255, 255, 255 * alpha)
                mesh.AdvanceVertex()
            mesh.End()
        end

        return
    end

    render.SetColorMaterial()
    render.DrawLine(reticlePos - right * len, reticlePos - right * gap, color, true)
    render.DrawLine(reticlePos + right * gap, reticlePos + right * len, color, true)
    render.DrawLine(reticlePos + up * gap, reticlePos + up * len, color, true)
    render.DrawLine(reticlePos - up * gap, reticlePos - up * post, color, true)

    
end

function ATTACHMENT:Render(wep, model)
        if CLIENT and TRM_ScopePiP and TRM_ScopePiP.RenderScopeAttachment then
            return TRM_ScopePiP.RenderScopeAttachment(wep, model, self)
        end

        if IsValid(model) then
            model:DrawModel()
        end
end
function ATTACHMENT:DrawScopeHUD(wep)
    if not IsLocalWeapon(wep) then return end

    local scope = GetScopeConfig(self)
    RenderScopeView(self, wep)

    DrawCheapScopeOverlay(self, wep)
end

function ATTACHMENT:GetScopeMagnification()
    local scope = GetScopeConfig(self)
    return scope.Zoom or 1
end

if CLIENT and not TRM_SCOPE_HUD_HOOK then
    TRM_SCOPE_HUD_HOOK = true

    hook.Add("HUDPaint", "TRM_ARC9StyleScopeOverlay", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetActiveWeapon()
        local att = FindActiveScopeAttachment(wep)
        if not att or not att.DrawScopeHUD then return end

        att:DrawScopeHUD(wep)
    end)
end
