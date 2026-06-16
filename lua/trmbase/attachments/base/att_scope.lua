ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "att_optic"
ATTACHMENT.Description = "The Base for Magnified Optics"
ATTACHMENT.Selectable = false

function ATTACHMENT:Render(wep, model)
    if wep:IsCarriedByLocalPlayer() then
        wep:RenderScopeSight(model, self)
    end

    if IsValid(model) then
        model:DrawModel()
    end
end

function ATTACHMENT:Remove(weapon,model)

end

function ATTACHMENT:RTCode(weapon,size)
    
end