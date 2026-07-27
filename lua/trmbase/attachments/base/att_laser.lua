ATTACHMENT.Name = "att_laser"
ATTACHMENT.Category = nil
ATTACHMENT.Base = "att_base"
ATTACHMENT.Selectable = true

ATTACHMENT.Laser = {
    Attach = "Laser",
    Color = Color(255, 0, 0, 80),
    Width = 1,
    DotSize = 4,
}

ATTACHMENT.FlashLight = {
    Attach = "Laser",
}

-- 材质缓存（放在配件表上，不是 self）
local lineMat = nil
local dotMat = nil

function ATTACHMENT:GetLineMat()
    if not lineMat then
        lineMat = Material("sprites/physbeam")
    end
    return lineMat
end

function ATTACHMENT:GetDotMat()
    if not dotMat then
        dotMat = CreateMaterial("trmbase_laserdot", "UnLitGeneric", {
            ["$basetexture"] = "sun/overlay",
            ['$additive'] = 1,
            ['$vertexalpha'] = 1,
            ['$vertexcolor'] = 1,
            ["$alphatest"] = 1,
            ["$halflamberet"] = 1,
        })
    end
    return dotMat
end

require("trm_utils")
function ATTACHMENT:DoLaserRender(weapon, model, data)
    if not self.Laser then return end
    -- if weapon:GetAimDelta() > 0.2 and weapon.sight.zoom then return end
    if data.IR and !weapon:GetOwner():GetNW2Bool( "TRMCity_FlashlightOn")then return end


    local attID = model:LookupAttachment(data.Attach)
    if attID <= 0 then return end

    --model:InvalidateBoneCache()
    model:SetupBones()
    local att = trm_utils.GetFastAttachment(model, data.Attach)
    if not att then return end


    -- 缓存射线结果
    if not model._nextTrace or SysTime() > model._nextTrace then
        model._lastTrace = util.TraceLine({
            start = att.Pos + att.Ang:Forward() * -10,
            endpos = LerpVector(weapon:HasFlag("Tacsight") and not weapon:IsReloading() and weapon:GetAimDelta() or 0,
                att.Pos, weapon:GetShootPos()) + att.Ang:Forward() * 1000,
            --endpos = att.Pos + att.Ang:Forward() * 1000 ,
            filter = { weapon, weapon:GetOwner() },
            mask = MASK_SHOT
        })
        local updateFps = 60
        model._nextTrace = SysTime() + math.min(1 / updateFps, RealFrameTime())
    end

    local tr = model._lastTrace
    if not tr then return end
    local distance = tr.HitPos:Distance(tr.StartPos)
    local color = data.Color

    if distance < 10 then return end
    local scale = math.random(0.5, 1)
    render.SetMaterial(self:GetLineMat())
    render.DrawBeam(att.Pos, tr.HitPos or tr.endpos, data.Width * scale, 0, 1, color)
    if tr.Hit then
        render.SetMaterial(self:GetDotMat())
        render.DrawSprite(tr.HitPos, data.DotSize, data.DotSize, color)
    end
end

function ATTACHMENT:Render(weapon, model)
    model:DrawModel()
    if CLIENT and weapon:IsCarriedByLocalPlayer() then
        self:DoLaserRender(weapon, model, self.Laser)
        self:DoFlashLight(weapon, model, self.FlashLight)
    end
end

-- att_laser.lua
function ATTACHMENT:Stats(w)

end

function ATTACHMENT:DoFlashLight(weapon, model, data)
    if not weapon.flashlight then return end

    local attId = model:LookupAttachment(data.Attach)
    if attId <= 0 then return end
    local att = model:GetAttachment(attId)
    if not att then return end

    local pos = att.Pos + att.Ang:Forward() * -5
    local ang = att.Ang

    if weapon.DrawCustomizionFlashLight then
        weapon:DrawCustomizionFlashLight(pos, ang, self)
    end
end

function ATTACHMENT:Remove(weapon, model)
    model:Remove()
end
