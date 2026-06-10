ATTACHMENT.Name = "att_laser"
ATTACHMENT.Category = nil 
ATTACHMENT.Base = "att_base"
ATTACHMENT.Selectable = true

ATTACHMENT.Laser = {
    Attach = "Laser",
    Color = Color(255,0,0,197),
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
        })
    end
    return dotMat
end
require("trm_utils")
function ATTACHMENT:DoLaserRender(weapon, model, data)
    if not self.Laser then return end

    local attID = model:LookupAttachment(data.Attach)
    if attID <= 0 then return end
    
    local att = trm_utils.GetFastAttachment(model, data.Attach)
    if not att then return end

    -- 缓存射线结果
    if not self._nextTrace or CurTime() > self._nextTrace then
        self._lastTrace = util.TraceLine({
            start = att.Pos + att.Ang:Forward() * -10,
            endpos = att.Pos + att.Ang:Forward() * 1000,
            filter = {weapon, weapon:GetOwner()},
            mask = MASK_SHOT
        })
        local updateFps = 55
        self._nextTrace = CurTime() + math.min(1 / updateFps ,RealFrameTime() )
    end

    local tr = self._lastTrace
    if not tr then return end
    local distance = tr.HitPos:Distance(tr.StartPos)
    if distance < 10 then return end
    local scale = math.random(0.2,1)
    render.SetMaterial(self:GetLineMat())
    render.DrawBeam(att.Pos, tr.HitPos or tr.endpos, data.Width * scale, 0, 1, data.Color)
    if tr.Hit then
        render.SetMaterial(self:GetDotMat())
        render.DrawSprite(tr.HitPos, data.DotSize, data.DotSize, data.Color)
    end
end

function ATTACHMENT:Render(weapon, model)
    model:DrawModel()
    self:DoLaserRender(weapon, model, self.Laser)
    self:DoFlashLight(weapon,model,self.FlashLight)
end


function ATTACHMENT:Stats(w)
    if self.FlashLight then
        w.flashlight = true
    end
end

function ATTACHMENT:DoFlashLight(weapon, model, data)
    if not self.FlashLight then return end

    local attId = model:LookupAttachment(data.Attach)
    if attId <= 0 then return end
    local att = trm_utils.GetFastAttachment(model, data.Attach)
    if not att then return end

    local pos = att.Pos + att.Ang:Forward() * -5
    local ang = att.Ang

    if weapon.DrawCustomizionFlashLight then
        weapon:DrawCustomizionFlashLight(pos, ang,self)
    end
end
function ATTACHMENT:Remove(weapon,model)
    model:Remove()
end