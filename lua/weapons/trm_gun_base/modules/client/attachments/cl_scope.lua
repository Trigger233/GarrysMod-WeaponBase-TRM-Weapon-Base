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
local needzero = GetConVar("trmbase_sv_physical_bullet")

local zero_const = 14.5

SWEP.ZeroDistance = 50
local cachescopezero = {}

function SWEP:GetScopeZeroAngle()
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

    if owner:KeyDown(IN_WALK) and needzero then
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
    local shouldzoom = self.sight.zoom - dir
    self.sight.zoom = math.Clamp(self.sight.zoom - dir, min, max)

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
    return 768
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

    local _, _, matName = self:EnsureRenderTarget(model, att)
    for _, i in pairs(indexs) do
        model:SetSubMaterial(i, "!" .. matName) -- 关键：用 RT 材质名
    end
    isModelApplyActiveScope[model] = true
end

local oldRenderResolutionCache = 0
function SWEP:EnsureRenderTarget(model, att)
    local size = self:GetScopeResolution()

    if (model.RT and model.RTMaterialName and model.RTMaterial) and size == oldRenderResolutionCache then
        return model.RT, model.RTMaterial, model.RTMaterialName
    end

    oldRenderResolutionCache = size

    local rtName = "trmbase_pip_RTName"
    local sceneRTName = "trmbase_pip_sceneRT"
    local matName = "trmbase_pip_matName"

    model.RT = GetRenderTarget(rtName, size, size)
    model.SceneRT = GetRenderTarget(sceneRTName, size, size)

    model.RTSize = size
    model.RTMaterialName = matName

    model.RTMaterial = CreateMaterial(matName, "VertexLitGeneric", {
        ["$basetexture"] = model.RT:GetName(),
        ["$model"] = "1",
        ["$selfillum"] = "1",
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$nocull"] = "1",
        ["$nodecal"] = "1"
    })



    model._SceneMaterial = CreateMaterial(matName .. "_scene", "UnlitGeneric", {
        ["$basetexture"] = model.SceneRT:GetName(),
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$nocull"] = "1",
        ["$nodecal"] = "1"
    })

    return model.RT, model.RTMaterial, model.RTMaterialName
end

function SWEP:RenderScopeView()
    for _, entry in pairs(self.CurrentAttachments) do
        if entry.m_Model and entry.m_Model.RT then
            self:RenderScopeViewAttachment(entry.m_Model, BASE_TRM_ATTS[entry.Class])
        end
    end
end

local additiveZero = Angle(0, 0, 0)
local nextRTUpdate = 0
function SWEP:RenderScopeViewAttachment(model, att)
    if not isModelApplyActiveScope[model] then
        return
    end

    local rt = self:EnsureRenderTarget(model, att)
    if not rt then return end
    local size = self:GetScopeResolution(att)

  --  local modelAttachment = model:GetAttachment(trm_utils.LookupAttachmentCached(model, att.Scope.Align))

    local owner = self:GetOwner()
    additiveZero = Lerp(RealFrameTime() * 10, additiveZero, self:GetScopeZeroAngle())

    local origin, angles =  owner:EyePos(),
        self:GetOwner():EyeAngles() + self:GetClientVisualRecoil() + additiveZero
    local zoomfov = self:GetScopeZoomFov()
    local scopeStats = att.Scope
    local reticleStats = att.Sight

    local fps = math.min(144, 1 / RealFrameTime())

    if CurTime() - nextRTUpdate < 0 then return end
    nextRTUpdate = CurTime() + (1 / fps) * 1

    render.PushRenderTarget(model.SceneRT)
    render.Clear(0, 0, 0, 255, true, true)
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
    --------Final Render
    render.PushRenderTarget(model.RT)

    render.Clear(0, 0, 0, 0, true, true)


    cam.Start2D()



    surface.SetDrawColor(255, 255, 255, 255)

    surface.SetMaterial(model._SceneMaterial)
    surface.DrawTexturedRect(0, 0, size, size)
    

    self:RenderScopeReticle(model, att, reticleStats, size, self:GetScopeZoom())
    cam.End2D()

    render.PopRenderTarget()
end

function SWEP:RTCode(size)
end

function SWEP:RenderScopeReticle(model, att, stat, rtSize, zoomScale)
    if not stat or not stat.Material then return end

    local centerX = rtSize / 2
    local centerY = rtSize / 2

    local _size = stat.Size * 5 * (att.Scope.DynamicCrosshair and zoomScale or 1)
    surface.SetMaterial(stat.Material)
    surface.SetDrawColor(stat.Color or Color(255, 255, 255))

    -- 如果准星是世界位置的（全息镜效果），需要投影到屏幕坐标
    -- 暂时简化为画在中心

    surface.DrawTexturedRect(
        centerX - _size / 2,
        centerY - _size / 2,
        _size,
        _size
    )
end

hook.Add("PreRender", "TRMBASE_ScopeUpdate", function()
    local ply = LocalPlayer()
    local _self = ply:GetActiveWeapon()
    if IsValid(_self) and _self.RenderScopeView then
        _self:RenderScopeView()
    end
end)
