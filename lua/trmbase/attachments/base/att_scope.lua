ATTACHMENT.Base = "att_reticle"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

function ATTACHMENT:Render(wep, model)
    if wep:IsCarriedByLocalPlayer() then
        wep:RenderScopeSight(model, self)
    end 
    --self:ApplyReticleMaterial(wep, model, self.Sight)

    if IsValid(model) then
        model:DrawModel()
    end
end

function ATTACHMENT:Remove(weapon,model)

end

function ATTACHMENT:RTCode(weapon,size)
    
end