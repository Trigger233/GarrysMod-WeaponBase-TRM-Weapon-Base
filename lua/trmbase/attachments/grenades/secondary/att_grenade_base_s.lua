ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Grenade"
ATTACHMENT.Category = "att_underbarrel_grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade"
end
