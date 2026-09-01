if not CLIENT then return end

local drawColor = color_white

function SWEP:DrawWeaponSelection(x, y, w, h, alpha)
    local material = self.WepSelectIcon

    

    if isnumber(material) then
        material =  Material(surface.GetTextureNameByID(material))
    elseif isstring(material) then
        material = Material(material)
    end

    if material:IsError() then return end

    surface.SetMaterial(material)
    drawColor.a = alpha
    surface.SetDrawColor(drawColor)
    surface.DrawTexturedRect(x, y, w, h)
end


