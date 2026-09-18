ATTACHMENT.Base = "att_reticle"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

---@param model CSEnt
function ATTACHMENT:Render(wep, model)
    if wep:IsCarriedByLocalPlayer() then
        wep:RenderScopeSight(model, self)
    end
    self:ApplyReticleMaterial(wep, model, self.Sight)

    model:DrawModel()

    wep:DrawHoloSight(model, self, true, true)
end

function ATTACHMENT:RTCode(weapon, size)

end
