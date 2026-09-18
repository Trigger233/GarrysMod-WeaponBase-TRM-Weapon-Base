if not CLIENT then return end
local render = render
require("trm_utils")

local RecoilFactor = 0.1
local Basefov = GetConVar("fov_desired"):GetInt()
local zoomscale = 1
local globalzoom = 1

local oldRenderResolutionCache = 0
local rtsize = 2048
function SWEP:GetScopeResolution(att)
    return rtsize
end

local rtmat = GetRenderTarget("trm_rtmat", rtsize, rtsize)
local rtmat_cheap = GetRenderTarget("trm_rtmat_cheap", ScrW(), ScrH())
local rtmat_spare = GetRenderTarget("trm_rtmat_spare", rtsize, rtsize)
local matName = "trm_rt_mat"

local RTMaterial = CreateMaterial(matName .. "_scene", "UnlitGeneric", {
    ["$basetexture"] = rtmat:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1",
    ["$selfillum"] = "1",
    ["$color2"] = "[1.05 1.05 1.05]",
})
local RTMaterial_Cheap = CreateMaterial(matName .. "_cheap", "UnlitGeneric", {
    ["$basetexture"] = rtmat_cheap:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1",
    ["$smooth"] = "1",
    ["$selfillum"] = "0",
    ["$color2"] = "[1.05 1.05 1.05]",

})
local LenseMaterial = CreateMaterial(matName, "VertexLitGeneric", {
    ["$basetexture"] = rtmat_spare:GetName(),
    ["$model"] = "1",
    ["$nocull"] = "1",
    ["$selfillum"] = "1",
    ["$color2"] = "[1.05 1.05 1.05]",
    ["$vertexcolor"] = "0",
    ["$vertexalpha"] = "1",

})

local isModelApplyActiveScope = {}
local inActiveScopeLenMatName = "TRMBASE_scope_inactive_mat"
local inActiveScopeLenMaterial = CreateMaterial(inActiveScopeLenMatName, "VertexLitGeneric", {
    ["$basetexture"] = "color/black",
    ["$model"] = "1",
    ["$selfillum"] = "1",
    ["$color2"] = "[1 1 1]",
    ["$nodecal"] = "1",
})
local meterToHu = 52.4934383
local gravity = GetConVar("sv_gravity"):GetInt() or 600 -- Hu/s
local zero_const = 14.5
local cachescopezero = {}

function SWEP:GetScopeZeroAngle()
    local needzero = GetConVar("trmbase_sv_physical_bullet")
    if not needzero:GetBool() then
        return Angle(0, 0, 0)
    end

    local distance = self.ZeroDistance * meterToHu -- 默认100米归零

    if cachescopezero[distance] then
        return Angle(needzero:GetBool() and math.Clamp(cachescopezero[distance] or 0, 0, 45) or 0, 0, 0)
    end

    local speed = 1000 * meterToHu
    if not speed or speed <= 0 then return 0 end
    local angRad = 0.5 * math.asin(zero_const * gravity * distance / (speed * speed))
    local ang = math.deg(angRad)
    cachescopezero[distance] = ang
    return Angle(needzero:GetBool() and math.Clamp(ang, 0, 45) or 0, 0, 0)
end

local NextTime = 0

function SWEP:SwitchHybrid(ForceTurnOff)
    if self:GetOwner() ~= LocalPlayer() then
        return
    end
    net.Start("TRMBase_SwitchHybrid")
    net.WriteEntity(self)
    net.WriteBool(ForceTurnOff)
    net.SendToServer()
end

function SWEP:Scroll(dir)
    if SERVER then return end
    if self:HasFlag("Tacsight") then return end

    local stat = self.sight
    if not stat then return end
    local zoom = stat.zoom or false
    if not zoom then return end
    local owner = self:GetOwner()
    local needzero = GetConVar("trmbase_sv_physical_bullet")



    if (self.sight.HybridSight != nil or self:HasFlag("HybridOn")) and (SysTime() - self:GetBindState("scroll") > 0.25) then
        self:SwitchHybrid()
        surface.PlaySound("TRM_Weapon.SwitchSight")
        self:SetBindState("scroll", SysTime())
        return
    end

    if zoom != nil then
        if owner:KeyDown(IN_WALK) and needzero:GetBool() then
            local shouldzero = self.ZeroDistance - dir * 25
            self.ZeroDistance = math.Clamp(shouldzero, 0, 500)
            --print(self.ZeroDistance)
            if shouldzero == self.ZeroDistance then
                surface.PlaySound("TRM_Weapon.SwitchSight")
            end

            return
        end
        local max = stat.MaxZoom or zoom
        local min = stat.MinZoom or zoom
        local shouldzoom = self.sight.zoom - dir * 0.5
        self.sight.zoom = math.Clamp(self.sight.zoom - dir * 0.5, min, max)

        if self.sight.zoom == shouldzoom then
            surface.PlaySound("TRM_Weapon.SwitchSight")
        end
    end
end

function SWEP:GetScopeParam()
    if not self.sight or not self.sight.zoom then return end

    return Lerp((self.sight.zoom - self.sight.MinZoom) / (self.sight.MaxZoom - self.sight.MinZoom), 0, 1)
end

function SWEP:GetScopeZoom()
    zoomscale = Lerp(RealFrameTime() * 10, zoomscale, self.sight and self.sight.zoom or zoomscale)
    return zoomscale
end

function SWEP:GetScopeZoomFov()
    return Basefov / math.pow(self:GetScopeZoom() * globalzoom, 1)
end

function SWEP:RenderScopeSight(model, att)
    if not IsValid(model) then return end

    local ply = LocalPlayer()

    self:ApplyInActiveScopeMaterial(model, att)
end

local CacheScopeLenMaterialIndex = {}
local function findLenMaterialIndex(model, att)
    local modelName = model:GetModel()
    if not modelName then return nil end

    if CacheScopeLenMaterialIndex[modelName] then
        return CacheScopeLenMaterialIndex[modelName]
    end
    CacheScopeLenMaterialIndex[modelName] = {}
    for index, matName in pairs(model:GetMaterials()) do
        for _, needle in pairs(att.Scope.Lens) do
            if string.find(matName, needle) then
                table.insert(CacheScopeLenMaterialIndex[modelName], index - 1)
            end
        end
    end

    return CacheScopeLenMaterialIndex[modelName] or false
end

function SWEP:ApplyInActiveScopeMaterial(model, att)
    --print(1)
    local indexs = findLenMaterialIndex(model, att)
    if not indexs then return end

    for _, i in pairs(indexs) do
        model:SetSubMaterial(i, "!" .. inActiveScopeLenMatName) -- just nil
    end
    isModelApplyActiveScope[model] = false
end

function SWEP:ApplyActiveScopeMaterial(model, att)
    if isModelApplyActiveScope[model] then return end

    local indexs = findLenMaterialIndex(model, att)
    if not indexs then return end

    for _, i in pairs(indexs) do
        model:SetSubMaterial(i, "!" .. matName) -- 关键：用 RT 材质名
    end

    isModelApplyActiveScope[model] = true
end

local cvar_cheapscope = CreateClientConVar("trmbase_cl_cheapscope", 0, true, true, "", 0, 1)
function SWEP:RenderScopeView()
    for _, entry in pairs(self:GetAllAttachmentsInUse()) do
        local attData = BASE_TRM_ATTS[entry.Class]

        if ! attData then
            continue
        end
        local model = entry.m_Model
        if model and attData.Scope then
            if ! cvar_cheapscope:GetBool() then
                self:DoRTScope(model, attData)
            else
                self:DoCheapScope(model, attData)
            end
        end
    end
end

local additiveZero = Angle(0, 0, 0)
local nextRTUpdate = 0

function SWEP:DoRTScope(model, att)
    if self:GetAimDelta() < 0.1 then return end

    local size = self:GetScopeResolution(att)

    local owner = self:GetOwner()
    additiveZero = LerpAngle(RealFrameTime() * 10, additiveZero, self:GetScopeZeroAngle())

    local origin, angles = owner:EyePos(),
        self:GetOwner():EyeAngles() + additiveZero + self:GetClientVisualRecoil() * (1 * self:GetZoomRecoilFactor())
    local zoomfov = self:GetScopeZoomFov()
    local reticleStats = att.Sight

    if CurTime() - nextRTUpdate < 0 then return end
    if att.Scope and att.Scope.UpdateFps then
        local fps = math.min(att.Scope.UpdateFps or 144, 1 / RealFrameTime())
        nextRTUpdate = CurTime() + (1 / fps)
    end

    local W ,H = ScrW() ,ScrH()
    -------------------------------------
    render.PushRenderTarget(rtmat)
    render.Clear(0, 0, 0, 0, true, true)
    render.SetAmbientLight(0, 0, 0)

    

    render.RenderView({
        x = 0,
        y = 0,
        w = size,
        h = size,
        origin = origin,
        angles = angles,
        fov = zoomfov,
        aspectratio = W / H  ,
        drawviewmodel = false,
        viewmodelfov = zoomfov,
        drawhud = false,
        dopostprocess = false,
        znear = 4,
    })

    render.PopRenderTarget()
    self:RTCode(rtmat, size)
    if att.RTCode then
        att:RTCode(self, rtmat, size)
    end
    --------------------------------------
    self:DrawThermal(rtmat, att)

    render.PushRenderTarget(rtmat_spare)
    render.Clear(3, 3, 3, 0, true, true)

    cam.Start2D()


    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(RTMaterial)
    surface.DrawTexturedRect(0, 0, rtsize, rtsize)
    self:DrawParallax(model, size, att)

    cam.End2D()

    render.PopRenderTarget()
end

function SWEP:RTCode(rt, size)
end

local function AngleToPixel(num)
    return math.tan(math.rad(num))
end






local parallaxMat = Material("trmbase/common/parallax_mask", "smooth")
local ParallaxColor = Color(255, 255, 255, 100)
function SWEP:DrawParallax(model, rtSize, att)
    if att.Scope.DisableParallax then return end
    local centerX = rtSize / 2
    local centerY = rtSize / 2





    local _size = rtSize * (att.Scope.ParallaxSize or 1.4)
    surface.SetMaterial(att.Scope.Parallax or parallaxMat)
    surface.SetDrawColor(ParallaxColor)

    surface.DrawTexturedRect(
        centerX - _size / 2,
        centerY - _size / 2,
        _size,
        _size
    )
end

hook.Add("PreRender", "TRMBASE_ScopeUpdate", function()
    if cvar_cheapscope:GetBool() then return end
    local ply = LocalPlayer()
    local _self = ply:GetActiveWeapon()
    if IsValid(_self) and _self.RenderScopeView then
        _self:RenderScopeView()
    end
end)

function SWEP:GetZoomRecoilFactor()
    return math.Clamp(RecoilFactor * self:GetScopeZoom(), 0, 1)
end

local function DrawCheapScopeMaterial(wep, w, h, size, Zoom)
    local offset = wep:GetClientVisualRecoil()
    local factor = (1 - wep:GetZoomRecoilFactor()) * Zoom

    local x, y = 0, 0
    x = x + AngleToPixel(offset.y) * factor * (w / size)
    y = y - AngleToPixel(offset.p) * factor * (h / size)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(RTMaterial_Cheap)
    surface.DrawTexturedRect(x, y, ScrW(), ScrH())
end
function SWEP:DoCheapScope(model, att)
    local screen = render.GetRenderTarget()
    if screen and screen:GetName() == "_rt_resolvedfullframedepth" then return end

    local size = self:GetScopeResolution(att)


    local reticleStats = att.Sight

    render.PushRenderTarget(rtmat_cheap)
    render.Clear(255, 248, 248, 255, true, true)
    render.PopRenderTarget()


    render.CopyTexture(screen, rtmat_cheap)

    self:DrawThermal(rtmat_cheap, att)
    self:RTCode(rtmat_cheap, size)
    if att.RTCode then
        att:RTCode(self, rtmat_cheap, size)
    end


    render.PushRenderTarget(rtmat_spare)
    render.Clear(0, 0, 0, 0, true, true)

    cam.Start2D()
    local w, h = ScrW(), ScrH()
    DrawCheapScopeMaterial(self, w, h, size, self:GetScopeZoom())

    self:DrawParallax(model, size, att)
    cam.End2D()


    render.PopRenderTarget()
end

function SWEP:DrawThermal(tx, att)
    if not att.Scope or not att.Scope.Thermal then
        return
    end

    if not tx then
        tx = render.GetRenderTarget()
    end


    render.PushRenderTarget(tx)

    cam.Start3D(EyePos(), cvar_cheapscope:GetBool() and EyeAngles() or self:GetOwner():EyeAngles())
    -- 1. 用 Stencil 标记 NPC
    render.DepthRange(0.0, 1)

    render.SetStencilEnable(true)
    render.ClearStencil()

    local sw = ScrH()
    local sh = sw

    local sx = (ScrW() - sw) / 2
    local sy = (ScrH() - sh) / 2



    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetBlend(0) -- 透明绘制，只写 Stencil

    -- 画 NPC 到 Stencil（只标记，不画颜色）
    for _, v in ents.Iterator() do
        if v == self then continue end

        if IsValid(v) and v:Alive() and (v:IsNPC() or v:IsRagdoll()) and not v:GetNoDraw() then
            v:DrawModel()
        end
    end

    render.SetBlend(1)
    -- 2. 只在 Stencil 标记区域画热成像
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)

    -- 用 3D 空间画热成像覆盖（参考 mod 的 PostDrawTranslucentRenderables 思路）
    -- 方法A：画一个全屏四边形，但只在 Stencil 区域显示
    cam.Start2D()
    local color = att.Scope.Thermal or Color(38, 255, 0, 200)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawRect(0, 0, ScrW(), ScrH())
    cam.End2D()


    render.SetStencilEnable(false)
    cam.End3D()

    render.PopRenderTarget()
end

local Pos, Ang
---@param model CSEnt
function SWEP:DrawHoloSight(model, attTable, HideSightModel, IsScope)
    local screen = render.GetRenderTarget()
    if screen and screen:GetName() == "_rt_resolvedfullframedepth" then return end

    if self:GetAimDelta() < 0.5 then
        return
    end
    if ! attTable.Sight then return end
    local ret = attTable.Sight
    local ret2 = attTable.Scope
    local w, h = ScrW(), ScrH()
    if ret.Align then
        att = trm_utils.GetFastAttachment(model, ret.Align)
        if ! att then return end
        Pos = att.Pos
        Ang = att.Ang
    else
        Pos = EyePos()
        Ang = EyeAngles()
    end

    render.UpdateScreenEffectTexture()

    render.ClearStencil()
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(0)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilEnable(true)
    render.SetStencilReferenceValue(TRM_BASE_REF + 1)



    if HideSightModel then
        model:SetBodygroup(0, 1)
        model:DrawModel()
        model:SetBodygroup(0, 0)
    else
        model:DrawModel()
    end
    render.SetStencilCompareFunction(STENCIL_LESSEQUAL)

    cam.IgnoreZ(true)
    if IsScope then
        render.DrawTextureToScreen(rtmat_spare)
    end
    local size = ret.Size or 5.12

    if ret2 and ret2.DynamicCrosshair then
        size = size * self:GetScopeZoom()
    end

    local color = ret.Color or color_white

    if ! Ang then return end

    if IsScope then
        local offset = self:GetClientVisualRecoil()
        local factor = self:GetZoomRecoilFactor()
        Ang = Ang + offset * factor
    end

    local offset = Ang:Forward() * 100
    if ret.Offset then
        offset = offset + Ang:Right() * ret.Offset.x
        offset = offset + Ang:Up() * ret.Offset.y
    end
    local roll = -Ang.r + 180
    if ret.Rotate then
        roll = roll + ret.Rotate
    end

    local reticlePos = Pos + offset
    --size = size *( reticlePos:Distance(EyePos()) / 100)

    --debugoverlay.Sphere(reticlePos,4, 0, color_white, true)
    render.SetMaterial(ret.Material)
    render.DrawQuadEasy(reticlePos, Ang:Forward():GetNegated(), size, size, color, roll)
    cam.IgnoreZ(false)

    render.ClearStencil()



    render.SetStencilEnable(false)

    render.SetBlend(1)
end
