ATTACHMENT.Name = "Vertical Foregrip"
ATTACHMENT.Category = "att_underbarrel"
ATTACHMENT.Base = "att_foregrip"
ATTACHMENT.Bonemerge = false
ATTACHMENT.Model = Model("models/trm_attachments/underbarrels/a_foregrip_sec.mdl")
ATTACHMENT.Pos = Vector(-1, 0, 0)
ATTACHMENT.LHIK = true

function ATTACHMENT:ChangeWeaponStats(weapon)
    self:ScaleTableValue(weapon.VisualRecoil.Vertical, 0.5)
end
