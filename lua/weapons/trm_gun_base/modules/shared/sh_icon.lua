function SWEP:InitIcon()
    if not CLIENT then return end
    local class = self:GetClass()
    if not class then return end
    local mat = Material("entities/" .. class.."png")
    if CLIENT then
        self.WepSelectIcon = mat
    end
end
function SWEP:MakeIcon() 
    self:InitIcon()
end


 