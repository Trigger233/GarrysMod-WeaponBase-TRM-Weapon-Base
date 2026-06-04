ATTACHMENT.Name = "Suppressor Sec"
ATTACHMENT.Base = "att_suppressor"
ATTACHMENT.Category = "att_muzzle"
ATTACHMENT.Model = Model("models/trm_attachments/muzzle/a_suppressor_sec.mdl")

function ATTACHMENT:ChangeWeaponStats(weapon)
    BASE_TRM_ATTS[self.Base]:ChangeWeaponStats(weapon)
    weapon.Primary.Damage = weapon.Primary.Damage * 0.95
    weapon.Aim.Time = weapon.Aim.Time * 1.1
    weapon.Recoil.AdsMultiplier = weapon.Recoil.AdsMultiplier * 0.5

end