if not CLIENT then return end
local isModelApplyActiveScope = {}
local inActiveScopeLenMatName = "TRMBASE_scope_inactive_mat"
local inActiveScopeLenMaterial = CreateMaterial(inActiveScopeLenMatName, "VertexLitGeneric", {
    ["$basetexture"] = "color/black",
    ["$model"] = "1",
    ["$selfillum"] = "1",
    ["$color2"] = "[1 1 1]",
    ["$nocull"] = "1",
    ["$nodecal"] = "1"
})
local meterToHu = 52.4934383
local gravity = GetConVar("sv_gravity"):GetInt() or 600 -- Hu/s²

local zero_const = 14.5

SWEP.ZeroDistance = 50
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

function SWEP:Scroll(dir)
    local zoom = self.sight.zoom or false
    if not zoom then return end
    local owner = self:GetOwner()
    local needzero = GetConVar("trmbase_sv_physical_bullet")

    if owner:KeyDown(IN_WALK) and needzero:GetBool() then
        local shouldzero = self.ZeroDistance - dir * 25
        self.ZeroDistance = math.Clamp(shouldzero, 0, 500)
        --print(self.ZeroDistance)
        if shouldzero == self.ZeroDistance then
            surface.PlaySound("Weapon_Pistol.Empty")
        end

        return
    end

    local stat = self.sight

    local max = stat.MaxZoom or zoom
    local min = stat.MinZoom or zoom
    local shouldzoom = self.sight.zoom - dir * 0.5
    self.sight.zoom = math.Clamp(self.sight.zoom - dir * 0.5, min, max)

    if self.sight.zoom == shouldzoom then
        surface.PlaySound("Weapon_AR2.Empty")
    end
end

local Basefov = GetConVar("fov_desired"):GetInt()
local zoomscale = 1
local globalzoom = 1.7

function SWEP:GetScopeZoom()
    zoomscale = Lerp(RealFrameTime() * 10, zoomscale, self.sight and self.sight.zoom or zoomscale)
    return zoomscale
end

function SWEP:GetScopeZoomFov()
    return Basefov / math.pow(self:GetScopeZoom() * globalzoom, 1)
end

function SWEP:GetScopeResolution(att)
    return 1024
end

function SWEP:RenderScopeSight(model, att)
    if not IsValid(model) then return end

    local ply = LocalPlayer()

    if self:GetClientAimDelta() > 0.4 and IsValid(ply) then
        self:ApplyActiveScopeMaterial(model, att)
    else
        self:ApplyInActiveScopeMaterial(model, att)
    end
    --PrintTable(isModelApplyActiveScope)
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

    local _, _, matName = self:EnsureRenderTarget(att)
    for _, i in pairs(indexs) do
        model:SetSubMaterial(i, "!" .. matName) -- 关键：用 RT 材质名
    end
    isModelApplyActiveScope[model] = true
end

local oldRenderResolutionCache = 0
function SWEP:EnsureRenderTarget(att)
    local size = self:GetScopeResolution()

    if (self.RT and self.RTMaterialName and self.RTMaterial) and size == oldRenderResolutionCache then
        return self.RT, self.RTMaterial, self.RTMaterialName
    end

    oldRenderResolutionCache = size

    local rtName = "trmbase_pip_RTName_" .. self:EntIndex()
    local sceneRTName = "trmbase_pip_sceneRT_" .. self:EntIndex()
    local matName = "trmbase_pip_matName_" .. self:EntIndex()

    self.RT = GetRenderTarget(rtName, size, size)
    self.SceneRT = GetRenderTarget(sceneRTName, size, size)

    self.RTSize = size
    self.RTMaterialName = matName

    self.RTMaterial = CreateMaterial(matName, "VertexLitGeneric", {
        ["$basetexture"] = self.RT:GetName(),
        ["$model"] = "1",
        ["$selfillum"] = "1",
    })

    self._SceneMaterial = CreateMaterial(matName .. "_scene", "UnlitGeneric", {
        ["$basetexture"] = self.SceneRT:GetName(),
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
    })

    return self.RT, self.RTMaterial, self.RTMaterialName
end

local cvar_cheapscope = CreateClientConVar("trmbase_cl_cheapscope", 0, true, true, "", 0, 1)
function SWEP:RenderScopeView()
    for _, entry in pairs(self.CurrentAttachments) do
        if entry.m_Model and self.RT then
            if ! cvar_cheapscope:GetBool() then
                self:DoRTScope(entry.m_Model, BASE_TRM_ATTS[entry.Class])
            else
                self:DoCheapScope(entry.m_Model, BASE_TRM_ATTS[entry.Class])
            end
        end
    end
end

local additiveZero = Angle(0, 0, 0)
local nextRTUpdate = 0

function SWEP:DoRTScope(model, att)
    if not isModelApplyActiveScope[model] then
        return
    end

    local rt = self:EnsureRenderTarget(att)
    if not rt then return end
    local size = self:GetScopeResolution(att)

    local owner = self:GetOwner()
    additiveZero = LerpAngle(RealFrameTime() * 10, additiveZero, self:GetScopeZeroAngle())
    local recoil = Angle(self:GetVisualRecoil())

    local origin, angles = owner:EyePos(),
        self:GetOwner():EyeAngles() + recoil + additiveZero
    local zoomfov = self:GetScopeZoomFov()
    local reticleStats = att.Sight

    local fps = math.min(144, 1 / RealFrameTime())

    if CurTime() - nextRTUpdate < 0 then return end
    nextRTUpdate = CurTime() + (1 / fps) * 1

    render.PushRenderTarget(self.SceneRT)
    render.Clear(0, 0, 0, 0, true, true)
    render.SetAmbientLight(0, 0, 0)

    self:RTCode(size)
    if att.RTCode then
        att:RTCode(self, size)
    end
    render.RenderView({
        x = 0,
        y = 0,
        w = size,
        h = size,
        origin = origin,
        angles = angles,
        fov = zoomfov,
        aspectratio = 1,
        drawviewmodel = false,
        viewmodelfov = zoomfov,
        drawhud = false,
        dopostprocess = false,
        znear = 4,
    })

    render.PopRenderTarget()

    self:DrawThermal(self.SceneRT, att)

    render.PushRenderTarget(self.RT)
    render.Clear(0, 0, 0, 0, true, true)

    cam.Start2D()


    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self._SceneMaterial)
    surface.DrawTexturedRect(0, 0, size, size)

    self:RenderScopeReticle(model, att, reticleStats, size, self:GetScopeZoom())
    self:DrawParallax(model, size, att)

    cam.End2D()

    render.PopRenderTarget()
end

function SWEP:RTCode(size)
end

function SWEP:RenderScopeReticle(model, att, stat, rtSize, zoomScale)
    if not stat or not stat.Material then return end

    local centerX = rtSize / 2
    local centerY = rtSize / 2

    local sway, _ = self:Sway()

    local additive = cvar_cheapscope:GetBool() and self:GetClientVisualRecoil() + self:GetScopeZeroAngle() or
        Angle(0, 0, 0) + sway * 5
    local function AngleToPixel(num)
        return math.tan(math.rad(num))
    end

    centerX = centerX - AngleToPixel(additive.yaw) * ScrW() * zoomScale

    centerY = centerY + AngleToPixel(additive.p) * ScrH() * zoomScale

    local _size = stat.Size * 5 * (att.Scope.DynamicCrosshair and zoomScale or 1)
    surface.SetMaterial(stat.Material)
    surface.SetDrawColor(stat.Color or Color(255, 255, 255))

    surface.DrawTexturedRect(
        centerX - _size / 2,
        centerY - _size / 2,
        _size,
        _size
    )
end

local parallaxMat = Material("models/weapons/tfa_ins2/optics/parallax_mask", "smooth")
function SWEP:DrawParallax(model, rtSize, att)
    local centerX = rtSize / 2
    local centerY = rtSize / 2

    local sway, _ = self:Sway()

    local additive = sway
    local function AngleToPixel(num)
        return math.tan(math.rad(num))
    end

    centerX = centerX - AngleToPixel(additive.yaw) * ScrW()

    centerY = centerY + AngleToPixel(additive.p) * ScrH()

    local _size = rtSize * 1.05
    surface.SetMaterial(att.Scope.Parallax or parallaxMat)
    surface.SetDrawColor(Color(255, 255, 255))

    surface.DrawTexturedRect(
        centerX - _size / 2,
        centerY - _size / 2,
        _size,
        _size
    )
end

hook.Add("RenderScene", "TRMBASE_ScopeUpdate", function()
    if cvar_cheapscope:GetBool() then return end
    local ply = LocalPlayer()
    local _self = ply:GetActiveWeapon()
    if IsValid(_self) and _self.RenderScopeView then
        _self:RenderScopeView()
    end
end)



function SWEP:DoCheapScope(model, att)
    if not isModelApplyActiveScope[model] then
        return
    end

    local screen = render.GetRenderTarget()
    if screen and screen:GetName() == "_rt_resolvedfullframedepth" then return end

    local rt = self:EnsureRenderTarget(att)
    if not rt then return end
    local size = self:GetScopeResolution(att)

    additiveZero = LerpAngle(RealFrameTime() * 10, additiveZero, self:GetScopeZeroAngle())

    local reticleStats = att.Sight

    render.PushRenderTarget(self.SceneRT)
    render.Clear(0, 0, 0, 255, true, true)
    render.PopRenderTarget()

    render.CopyTexture(screen, self.SceneRT)

    self:DrawThermal(self.SceneRT, att)



    render.PushRenderTarget(self.RT)
    render.Clear(0, 0, 0, 0, true, true)

    cam.Start2D()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self._SceneMaterial)

    local w, h = ScrW(), ScrH()

    surface.DrawTexturedRect((-size * 0.5), 0, (w + size), h)

    self:RenderScopeReticle(model, att, reticleStats, size, self:GetScopeZoom())
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

    -- 画 NPC 到 Stencil（只标记，不画颜色）
    for _, v in ents.Iterator() do
        if v == self then continue end

        if IsValid(v) and v:Alive() and (v:IsNPC() or v:IsRagdoll()) and not v:GetNoDraw() then
            render.SetBlend(0) -- 透明绘制，只写 Stencil
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
