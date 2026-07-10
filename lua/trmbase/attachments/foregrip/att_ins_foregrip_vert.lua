ATTACHMENT.Name = "Foregrip"
ATTACHMENT.Category = "att_grip_vert"
ATTACHMENT.Base = "att_foregrip"
ATTACHMENT.Bonemerge = false
ATTACHMENT.Model = Model("models/trm_attachments/underbarrels/a_foregrip_sec.mdl")
ATTACHMENT.Pos = Vector(1, 0, 10)
ATTACHMENT.LHIK = true

function ATTACHMENT:ChangeWeaponStats(weapon)
    self:ScaleTableValue(weapon.VisualRecoil.Vertical, 0.5)
end
