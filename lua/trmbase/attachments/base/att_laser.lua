ATTACHMENT.Name = "att_laser"
ATTACHMENT.Category = nil 
ATTACHMENT.Base = "att_base"
ATTACHMENT.Selectable = true
ATTACHMENT.Laser = {
    Attach = "Laser" ,
    Color = Color(255,0,0,197) , 
    Width = 1 , 
    DotSize = 4 ,
}



function ATTACHMENT:Render(weapon, model)
    model:DrawModel()
    -- 先恢复基础材质
    render.SetMaterial(Material("debug/debugblank"))
    render.SetBlend(1)
    -- 再画激光
    
    self:DoLaserRender(weapon, model, self.Laser)
    
end



function ATTACHMENT:DoLaserRender(weapon , model , data )
    if not self.Laser then return end

    local LineMat = Material("sprites/physbeam")
    local DotMat = CreateMaterial("trmbase_laserdot", "UnLitGeneric", {
    ["$basetexture"] = "sun/overlay",
    ['$additive'] = 1,
    ['$vertexalpha'] = 1,
    ['$vertexcolor'] = 1,
    })  

    local attID = model:LookupAttachment(data.Attach)

    if attID <= 0 then return end
    local att = model:GetAttachment(attID)
    if not att then return end

    local tr = util.TraceLine({
        start = att.Pos + att.Ang:Forward() * -10,
        endpos = att.Pos + att.Ang:Forward() * 1000,
        filter = {weapon, weapon:GetOwner()},
        mask = MASK_SHOT
    })

    render.SetMaterial(LineMat)
    render.DrawBeam(att.Pos, tr.HitPos or tr.endpos, data.Width * math.random(0.1,1) , 0, 1, data.Color)

    if tr.Hit then
        render.SetMaterial(DotMat)
        render.DrawSprite(tr.HitPos, data.DotSize, data.DotSize, data.Color)
    end
    --print("laser")
end