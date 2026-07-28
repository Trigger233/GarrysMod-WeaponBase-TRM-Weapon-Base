if not CLIENT then return end

function SWEP:DrawWeaponSelection(x, y, w, h, alpha)
    surface.SetMaterial(self.WepSelectIcon)
    surface.SetDrawColor(Color(255, 255, 255, alpha))
    surface.DrawTexturedRect(x, y, w, h)
end


