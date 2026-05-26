if SERVER then return end

TRM_ScopePiP = TRM_ScopePiP or {}

local P = TRM_ScopePiP

local function hasNeedle(text, needles)
    text = string.lower(tostring(text or ""))

    for _, needle in ipairs(needles or {}) do
        if string.find(text, string.lower(needle), 1, true) then
            return true
        end
    end

    return false
end

local function safeMat(path, flags)
    local mat = Material(path, flags or "smooth noclamp")
    if mat and not mat:IsError() then return mat end
    return nil
end

local inactiveLensMaterialName = "trm_elcan_pip_inactive_lens"
local inactiveLensMaterial = CreateMaterial(inactiveLensMaterialName, "VertexLitGeneric", {
    ["$basetexture"] = "color/black",
    ["$model"] = "1",
    ["$selfillum"] = "1",
    ["$color2"] = "[0.015 0.018 0.018]",
    ["$nocull"] = "1",
    ["$nodecal"] = "1"
})

function P.EnsureRenderTarget()
    local size = P.GetResolution()

    if P.RT and P.SceneRT and P.RTSize == size and P.RTMaterial then
        return P.RT, P.RTMaterial, P.RTMaterialName
    end

    local rtName = P.Config.RTNamePrefix .. tostring(size)
    local sceneRTName = P.Config.RTNamePrefix .. "scene_" .. tostring(size)
    local matName = P.Config.MaterialNamePrefix .. tostring(size)

    P.RT = GetRenderTarget(rtName, size, size)
    P.SceneRT = GetRenderTarget(sceneRTName, size, size)
    P.RTSize = size
    P.RTMaterialName = matName
    P.RTMaterial = CreateMaterial(matName, "VertexLitGeneric", {
        ["$basetexture"] = P.RT:GetName(),
        ["$model"] = "1",
        ["$selfillum"] = "1",
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$nocull"] = "1",
        ["$nodecal"] = "1"
    })

    P.RTMaterialFallback = CreateMaterial(matName .. "_unlit", "UnlitGeneric", {
        ["$basetexture"] = P.RT:GetName(),
        ["$model"] = "1",
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$nocull"] = "1",
        ["$nodecal"] = "1"
    })

    P.SceneMaterial = CreateMaterial(matName .. "_scene", "UnlitGeneric", {
        ["$basetexture"] = P.SceneRT:GetName(),
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$nocull"] = "1",
        ["$nodecal"] = "1"
    })

    P.Arc9RTMaterial = safeMat("effects/arc9/rt")
    P.Arc9CheapMaterial = safeMat("effects/arc9/rt_cheap")
    P.ReticleMaterial = safeMat(P.Config.ReticleMaterial) or safeMat(P.Config.FallbackReticle)
    P.MaskMaterial = safeMat(P.Config.MaskMaterial)
    P.LensOverlayMaterial = safeMat(P.Config.LensOverlayMaterial)
    P.ShadowMaterial = safeMat("arc9/shadow2")

    P.DebugPrint("created RT", rtName, matName)

    return P.RT, P.RTMaterial, P.RTMaterialName
end

function P.GetAttachmentProfile(att, class)
    local profile = P.Config.ScopeProfiles and P.Config.ScopeProfiles[class] or nil
    local out = {}

    out.Class = class
    out.FOV = (att and (att.PiPFOV or att.ElcanPiPFOV)) or (profile and profile.FOV) or 14
    out.LensNeedles = (att and (att.PiPLensMaterialNeedles or att.ElcanPiPLensMaterialNeedles)) or
        (profile and profile.LensNeedles) or P.Config.LensNeedles
    out.Reticle =  tostring(att.Scope.Material) or P.Config.FallbackReticle
    
    out.FlipX = (att and att.PiPFlipX)
    if out.FlipX == nil then out.FlipX = profile and profile.FlipX or false end
    out.FlipY = (att and att.PiPFlipY)
    if out.FlipY == nil then out.FlipY = profile and profile.FlipY or false end
    out.LensRadius = (att and att.PiPLensRadius) or (profile and profile.LensRadius) or P.Config.DefaultLensRadius
    out.ReticleRadius = (att and att.PiPReticleRadius) or (profile and profile.ReticleRadius) or
        P.Config.DefaultReticleRadius
    out.ReticleOffset = (att and att.PiPReticleOffset) or (profile and profile.ReticleOffset) or
        P.Config.DefaultReticleOffset
    out.EdgeSoftness = (att and att.PiPEdgeSoftness) or (profile and profile.EdgeSoftness) or
        P.Config.DefaultEdgeSoftness
    out.EdgeAlpha = (att and att.PiPEdgeAlpha) or (profile and profile.EdgeAlpha) or 170
    out.CounterRollScale = (att and att.PiPCounterRollScale) or (profile and profile.CounterRollScale) or 0
    out.CounterRollMax = (att and att.PiPCounterRollMax) or (profile and profile.CounterRollMax) or 0
    out.CounterRollSmooth = (att and att.PiPCounterRollSmooth) or (profile and profile.CounterRollSmooth) or 16

    return out
end

function P.GetScopeAttachmentEntry(wep)
    if not IsValid(wep) then return nil end
    if not wep.CurrentAttachments then return nil end

    for slot, entry in pairs(wep.CurrentAttachments) do
        if entry and entry.Class == P.Config.ElcanClass then
            local att = BASE_TRM_ATTS and BASE_TRM_ATTS[entry.Class]
            return entry, att, slot
        end
    end

    return nil
end

function P.GetPiPAttachmentEntry(wep)
    if not IsValid(wep) then return nil end
    if not wep.CurrentAttachments then return nil end

    for slot, entry in pairs(wep.CurrentAttachments) do
        local class = entry and entry.Class
        local att = class and BASE_TRM_ATTS and BASE_TRM_ATTS[class]
        local profile = class and P.Config.ScopeProfiles and P.Config.ScopeProfiles[class]

        if att and att.Scope then
            return entry, att, slot, P.GetAttachmentProfile(att, class)
        end
    end

    return nil
end

function P.HasElcanEquipped(wep)
    local entry, att = P.GetScopeAttachmentEntry(wep)
    return entry ~= nil and att ~= nil and att.HasPiP == true
end

function P.HasPiPEquipped(wep)
    local entry, att = P.GetPiPAttachmentEntry(wep)
    return entry ~= nil and att ~= nil
end

function P.IsWeaponCustomizing(wep)
    if IsValid(TRM_AttachMenu_Instance) then return true end
    if IsValid(wep) and wep.GetTask and wep:GetTask() == "Task_Customize" then return true end
    return false
end

function P.IsPlayerAimingWithElcan(ply, wep)
    if not P.GetBool("enable", true) then return false end
    if P.ForceTest then return P.HasPiPEquipped(wep) end
    if not IsValid(ply) or not ply:Alive() then return false end
    if not IsValid(wep) or wep ~= ply:GetActiveWeapon() then return false end
    if P.IsWeaponCustomizing(wep) then return false end
    if not P.HasPiPEquipped(wep) then return false end

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return false end

    local aim = wep.GetAimDelta and wep:GetAimDelta() or 0
    return aim >= P.Config.AimThreshold
end

function P.FindLensIndex(model, att)
    if not IsValid(model) then return nil end

    if model.TRM_ScopePiPLensIndex ~= nil then
        return model.TRM_ScopePiPLensIndex, model.TRM_ScopePiPLensMaterial
    end

    local profile = P.GetAttachmentProfile(att, att and att.ClassName)
    local lensNeedles = profile.LensNeedles or P.Config.LensNeedles
    local skipNeedles = P.Config.SkipNeedles

    for index, matName in ipairs(model:GetMaterials() or {}) do
        if hasNeedle(matName, lensNeedles) and not hasNeedle(matName, skipNeedles) then
            model.TRM_ScopePiPLensIndex = index - 1
            model.TRM_ScopePiPLensMaterial = matName
            return model.TRM_ScopePiPLensIndex, matName
        end
    end

    model.TRM_ScopePiPLensIndex = false
    return nil
end

function P.ApplyLensMaterial(model, att)
    local _, _, materialName = P.EnsureRenderTarget()
    if not materialName then return false end

    local lensIndex = P.FindLensIndex(model, att)
    if lensIndex == nil or lensIndex == false then return false end

    model:SetSubMaterial(lensIndex, "!" .. materialName)
    model.TRM_ScopePiPApplied = true
    model.TRM_ScopePiPInactive = false
    return true
end

function P.ApplyInactiveLensMaterial(model, att)
    if not IsValid(model) then return false end

    local lensIndex = P.FindLensIndex(model, att)
    if lensIndex == nil or lensIndex == false then return false end

    model:SetSubMaterial(lensIndex, "!" .. inactiveLensMaterialName)
    model.TRM_ScopePiPApplied = true
    model.TRM_ScopePiPInactive = true
    return true
end

function P.ResetModel(model)
    if not IsValid(model) then return end

    if model.TRM_ScopePiPApplied then
        local index = model.TRM_ScopePiPLensIndex
        if index ~= nil and index ~= false then
            model:SetSubMaterial(index, nil)
        end
    end

    model.TRM_ScopePiPApplied = false
    model.TRM_ScopePiPInactive = false
end

function P.RegisterElcanModel(wep, model, att)
    if not IsValid(wep) or not IsValid(model) then return end

    P.ActiveWeapon = wep
    P.ActiveModel = model
    P.ActiveAttachment = att
    P.LastSeen = CurTime()
end

function P.GetCamera(ply, wep, entry, att, model)
    local pos = ply:EyePos()
    local ang = ply:EyeAngles()

    if IsValid(model) and att and att.Scope and att.Scope.Align then
        local attachmentId = model:LookupAttachment(att.Scope.Align)
        if attachmentId and attachmentId > 0 then
            local data = model:GetAttachment(attachmentId)
            if data then
                pos = data.Pos
                ang = data.Ang
            end
        end
    end

    local offsetPos = (att and att.Scope and att.Scope.RTOffset) or Vector(0, 0, 0)
    local offsetAng = (att and att.Scope and att.Scope.RTAngle) or Angle(0, 0, 0)
    if isvector(offsetPos) then
        pos = pos + ang:Forward() * offsetPos.x + ang:Right() * offsetPos.y + ang:Up() * offsetPos.z
    end

    if isangle(offsetAng) then
        ang = Angle(ang.p + offsetAng.p, ang.y + offsetAng.y, ang.r + offsetAng.r)
    end

    return pos, ang
end

function P.DrawTexturedCircle(x, y, radius, segments, flipX, flipY, textureRotate)
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
        local tx = cx * rotCos - cy * rotSin
        local ty = cx * rotSin + cy * rotCos
        local u = 0.5 + tx * 0.5
        local v = 0.5 + ty * 0.5

        if flipX then u = 1 - u end
        if flipY then v = 1 - v end

        table.insert(verts, {
            x = x + cx * radius,
            y = y + cy * radius,
            u = u,
            v = v
        })
    end

    surface.DrawPoly(verts)
end

function P.GetScopeTextureRoll(wep, profile)
    if not profile then return 0 end

    local swayRoll = 0
    if IsValid(wep) and wep.m_SwayAngle then
        swayRoll = wep.m_SwayAngle.roll or 0
    end

    local maxRoll = profile.CounterRollMax or 0
    local target = swayRoll * (profile.CounterRollScale or 0)
    if maxRoll > 0 then
        target = math.Clamp(target, -maxRoll, maxRoll)
    end

    local smooth = profile.CounterRollSmooth or 16
    P.SmoothedTextureRoll = Lerp(math.Clamp(RealFrameTime() * smooth, 0, 1), P.SmoothedTextureRoll or target, target)

    return P.SmoothedTextureRoll or 0
end

function P.DrawRing(x, y, innerRadius, outerRadius, segments)
    segments = segments or 128

    for i = 0, segments - 1 do
        local a1 = math.rad((i / segments) * 360)
        local a2 = math.rad(((i + 1) / segments) * 360)
        local c1, s1 = math.cos(a1), math.sin(a1)
        local c2, s2 = math.cos(a2), math.sin(a2)

        surface.DrawPoly({
            { x = x + c1 * innerRadius, y = y + s1 * innerRadius },
            { x = x + c2 * innerRadius, y = y + s2 * innerRadius },
            { x = x + c2 * outerRadius, y = y + s2 * outerRadius },
            { x = x + c1 * outerRadius, y = y + s1 * outerRadius }
        })
    end
end

function P.DrawReticle(size, profile, textureRoll)
    if not P.GetBool("reticle", true) then return end

    local reticlePath = profile and profile.Reticle or P.Config.FallbackReticle
    local reticleMat = safeMat(reticlePath) or P.ReticleMaterial
    local radius = size * ((profile and profile.ReticleRadius) or P.Config.DefaultReticleRadius)
    local offset = (profile and profile.ReticleOffset) or P.Config.DefaultReticleOffset
    local x = size * (0.5 + (isvector(offset) and offset.x or 0))
    local y = size * (0.5 + (isvector(offset) and offset.y or 0))

    if reticleMat then
        surface.SetMaterial(reticleMat)
        surface.SetDrawColor(255, 255, 255, 210)
        P.DrawTexturedCircle(x, y, radius, 128, profile and profile.FlipX, profile and profile.FlipY, textureRoll)
        return
    end

    local thin = math.max(1, math.floor(size * 0.0025))
    local gap = size * 0.035
    local len = size * 0.19

    surface.SetDrawColor(10, 10, 10, 230)
    surface.DrawRect(x - thin * 0.5, y - gap - len, thin, len)
    surface.DrawRect(x - thin * 0.5, y + gap, thin, len)
    surface.DrawRect(x - gap - len, y - thin * 0.5, len, thin)
    surface.DrawRect(x + gap, y - thin * 0.5, len, thin)
end

function P.DrawLensBlend(size, profile)
    if not P.GetBool("mask", true) then return end

    local radius = size * ((profile and profile.LensRadius) or P.Config.DefaultLensRadius)
    local softness = size * ((profile and profile.EdgeSoftness) or P.Config.DefaultEdgeSoftness)
    local edgeAlpha = (profile and profile.EdgeAlpha) or 170
    local x = size * 0.5
    local y = size * 0.5

    draw.NoTexture()
    for i = 1, 24 do
        local t = i / 24
        local inner = radius + softness * ((i - 1) / 24)
        local outer = radius + softness * t
        local alpha = math.floor(edgeAlpha * (1 - t) ^ 1.65)
        surface.SetDrawColor(0, 0, 0, alpha)
        P.DrawRing(x, y, inner, outer, 128)
    end

    surface.SetDrawColor(0, 0, 0, 55)
    P.DrawRing(x, y, radius - softness * 0.18, radius + softness * 0.08, 160)
end

function P.RenderScopeView()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not P.IsPlayerAimingWithElcan(ply, wep) then return end

    local entry, att, _, profile = P.GetPiPAttachmentEntry(wep)
    if not entry or not att then return end

    local model = P.ActiveModel
    if not IsValid(model) and IsValid(entry.m_Model) then
        model = entry.m_Model
    end

    local rt = P.EnsureRenderTarget()
    if not rt then return end

    local fps = math.max(1 / RealFrameTime(), 144)
    local now = RealTime()
    if P.NextRender and now < P.NextRender then return end
    P.NextRender = now + (1 / fps) * 0.75

    local size = P.RTSize or P.GetResolution()
    local fov = math.Clamp(P.GetFloat("fov", profile and profile.FOV or att.ElcanPiPFOV or 14), 5, 45)
    local origin, angles = P.GetCamera(ply, wep, entry, att, model)
    local textureRoll = P.GetScopeTextureRoll(wep, profile)


    wep.TRM_RenderingScopeRT = true
    TRM_SCOPE_RENDERING_RT = wep
    P.Rendering = true

    render.PushRenderTarget(P.SceneRT)
    render.Clear(0, 0, 0, 255, true, true)
    render.SetAmbientLight(0, 0, 0)

    local ok, err = xpcall(function()
        render.RenderView({
            x = 0,
            y = 0,
            w = size,
            h = size,
            origin = origin,
            angles = angles,
            fov = fov,
            aspectratio = 1,
            drawviewmodel = false,
            drawhud = false,
            dopostprocess = false,
            znear = 4,
            zfar = 30000
        })
    end, debug.traceback)
    if not ok then
        P.DebugPrint(err)
    end
    render.PopRenderTarget()

    render.PushRenderTarget(rt)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
    local radius = size * ((profile and profile.LensRadius) or P.Config.DefaultLensRadius)
    surface.SetMaterial(P.SceneMaterial)
    surface.SetDrawColor(255, 255, 255, 255)
    P.DrawTexturedCircle(size * 0.5, size * 0.5, radius, 160, profile and profile.FlipX, profile and profile.FlipY,
        textureRoll)
    P.DrawLensBlend(size, profile)
    P.DrawReticle(size, profile, textureRoll)
    cam.End2D()
    render.PopRenderTarget()

    P.Rendering = false
    wep.TRM_RenderingScopeRT = nil
    TRM_SCOPE_RENDERING_RT = nil
end

hook.Add("PreRender", "TRM_ScopePiP_UpdateRT", function()
    if P.Rendering then return end
    P.RenderScopeView()
end)

hook.Add("Think", "TRM_ScopePiP_SmoothAutoRecoil", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    local _, _, _, profile = P.GetPiPAttachmentEntry(wep)
    if not profile then return end
end)
