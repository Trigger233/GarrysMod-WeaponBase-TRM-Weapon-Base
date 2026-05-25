ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

if CLIENT then
    CreateClientConVar("trm_scope_rt", "0", true, false, "Experimental TRM RT scopes. Keep 0 for ARC9-style cheap scopes.")
    CreateClientConVar("trm_scope_overlay", "1", true, false, "Draw TRM magnified scope overlay.")
end

local fallbackReticle = Material("models/weapons/tfa_ins2/optics/aimpoint_reticule")
local cheapScopeMat = CLIENT and Material("models/weapons/tfa_ins2/optics/optic_lense") or nil

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

    surface.SetMaterial(scope.CheapMaterial or cheapScopeMat)
    surface.SetDrawColor(190, 210, 205, (scope.LensAlpha or 42) * alpha)
    DrawTexturedCircle(x, y, radius, scope.Segments or 128, scope.TextureRotate or scope.ScreenRotate or 0)

    DrawReticle2D(att, scope, x, y, radius, alpha)
    DrawScopeEdge(x, y, radius, alpha)
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
            ["$translucent"] = "1",
            ["$vertexalpha"] = "1",
            ["$vertexcolor"] = "1",
            ["$nocull"] = "1"
        })
    end

    return att._ScopeRT, att._ScopeMaterial
end

local function RenderScopeView(att, wep)
    if not CLIENT or GetConVar("trm_scope_rt"):GetBool() == false then return nil end

    local owner = wep:GetOwner()
    if not IsValid(owner) then return nil end

    local scope = GetScopeConfig(att)
    local rt = GetScopeRT(att, wep)
    if not rt then return nil end

    local size = scope.RTSize or 768
    local baseFOV = owner:GetFOV()
    if baseFOV <= 0 then baseFOV = GetConVar("fov_desired"):GetInt() end

    local mag = scope.Magnification or scope.Zoom or att.Magnification or 4
    local fov = scope.FOV or math.Clamp(baseFOV / mag, 5, 45)
    local eyeAng = owner:EyeAngles()

    render.PushRenderTarget(rt)
        render.Clear(0, 0, 0, 255, true, true)
        render.RenderView({
            x = 0,
            y = 0,
            w = size,
            h = size,
            aspectratio = 1,
            origin = owner:EyePos() + eyeAng:Forward() * (scope.CameraForward or 1),
            angles = eyeAng,
            fov = fov,
            drawviewmodel = false,
            drawhud = false,
            dopostprocess = false,
            znear = scope.ZNear or 4,
            zfar = scope.ZFar or 30000
        })
    render.PopRenderTarget()

    return select(2, GetScopeRT(att, wep))
end

function ATTACHMENT:Render(wep, model)
    if IsValid(model) then
        model:DrawModel()
    end

    if IsLocalWeapon(wep) then
        wep.TRM_ActiveScopeAttachment = self
    end
end

function ATTACHMENT:DrawScopeHUD(wep)
    if not IsLocalWeapon(wep) then return end

    local scope = GetScopeConfig(self)
    if GetConVar("trm_scope_rt"):GetBool() and scope.UseRT == true then
        RenderScopeView(self, wep)
    end

    DrawCheapScopeOverlay(self, wep)
end

function ATTACHMENT:GetScopeMagnification()
    local scope = GetScopeConfig(self)
    return scope.Magnification or scope.Zoom or self.Magnification or 1
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
