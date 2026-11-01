ATTACHMENT.Base = "att_reticle"

function ATTACHMENT:GetLineMat()
    if not lineMat then
        lineMat = Material("trmbase/common/laser_line")
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
function ATTACHMENT:Render(wpn, model)

    model:DrawModel()

    if self.Sight and self.Sight.Material then
        BASE_TRM_ATTS["att_reticle"].RenderReticle(self,wpn, model, self.Sight)
    end   
    
    if CLIENT and wpn:IsCarriedByLocalPlayer() then
        BASE_TRM_ATTS["att_laser"].DoLaserRender(self, wpn, model, self.Laser)
        BASE_TRM_ATTS["att_laser"].DoFlashLight( self ,wpn, model, self.FlashLight)
    end

end
