if not CLIENT then return end
local isModelApplyActiveScope = {}
local inActiveScopeLenMatName = "TRMBASE_scope_inactive_mat"
local inActiveScopeLenMaterial = CreateMaterial(inActiveScopeLenMatName, "VertexLitGeneric", {
    ["$basetexture"] = "color/black",
    ["$model"] = "1",
    ["$selfillum"] = "1",
    ["$color2"] = "[0.015 0.018 0.018]",
    ["$nocull"] = "1",
    ["$nodecal"] = "1"
})




function SWEP:Scroll()
    local zoom = self.sight.zoom or false
    if not zoom then return end

    local stat = self.sight




    self.sight.zoom = 16
end

local Basefov = GetConVar("fov_desired"):GetInt()
local zoomscale = 1
local globalzoom = 1.7

function SWEP:GetScopeZoom(att)
    
    return self.sight.zoom or zoomscale
end

function SWEP:GetScopeZoomFov(att)
    return Basefov / math.pow(self:GetScopeZoom(att) * globalzoom , 2 )
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

    local _, _, matName = self:EnsureRenderTarget(model, att)
    for _, i in pairs(indexs) do
        model:SetSubMaterial(i, "!" .. matName) -- 关键：用 RT 材质名
    end
    isModelApplyActiveScope[model] = true
end

function SWEP:EnsureRenderTarget(model, att)
    local size = self:GetScopeResolution()

    if model.RT and model.RTMaterialName and model.RTMaterial then
        return model.RT, model.RTMaterial, model.RTMaterialName
    end

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




local nextRTUpdate = 0
function SWEP:RenderScopeViewAttachment(model, att)
    if not isModelApplyActiveScope[model] then
        return
    end

    local rt = self:EnsureRenderTarget(model, att)
    if not rt then return end
    if CurTime() - nextRTUpdate < 0 then return end
    nextRTUpdate = CurTime() + RealFrameTime() * 2
    local size = self:GetScopeResolution(att)
    local modelAttachment = trm_utils.GetFastAttachment(model, att.Scope.Align)

    local owner = self:GetOwner()

    local origin, angles = modelAttachment.Pos or owner:GetShootPos(), self:GetOwner():EyeAngles() + self:GetClientVisualRecoil()
    local zoomfov = self:GetScopeZoomFov(att)

    local scopeStats = att.Scope
    local reticleStats = att.Sight
    



    render.PushRenderTarget(model.SceneRT)
    render.Clear(0, 0, 0, 255, true, true)
    render.SetAmbientLight(0, 0, 0)

    self:RTCode(size, size)
    if att.RTCode then
        att:RTCode(self, size, size)
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
       -- zfar = 0
    })


    render.PopRenderTarget()
    --------Final Render
    render.PushRenderTarget(model.RT)
    
    render.Clear(0, 0, 0, 0, true, true)

    DrawMotionBlur(1, 1, RealFrameTime() * 1 )

    cam.Start2D()

    

    surface.SetDrawColor(255, 255, 255, 255)
    
    surface.SetMaterial(model._SceneMaterial)
    surface.DrawTexturedRect(0, 0, size, size)

    self:RenderScopeReticle(model, att, reticleStats, size)
    cam.End2D()

    render.PopRenderTarget()

end

function SWEP:RTCode(w, h)
end

function SWEP:RenderScopeReticle(model, att, stat, rtSize)
    if not stat or not stat.Material then return end

    local centerX = rtSize / 2
    local centerY = rtSize / 2
    
    local _size = stat.Size * 5
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

hook.Add("PostRender", "TRMBASE_ScopeUpdate", function()
    local ply = LocalPlayer()
    local _self = ply:GetActiveWeapon()
    if IsValid(_self) and _self.RenderScopeView then
        _self:RenderScopeView()
    end
end)

