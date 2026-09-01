ATTACHMENT.Base = "att_reticle"


function ATTACHMENT:Render(wpn, model)
    if self.Sight and self.Sight.Material then
        BASE_TRM_ATTS["att_reticle"]:RenderReticle(wpn, model, self.Sight)
    end   
    
    if CLIENT and wpn:IsCarriedByLocalPlayer() then
        BASE_TRM_ATTS["att_laser"]:DoLaserRender(wpn, model, self.Laser)
        BASE_TRM_ATTS["att_laser"]:DoFlashLight(wpn, model, self.FlashLight)
    end

end
