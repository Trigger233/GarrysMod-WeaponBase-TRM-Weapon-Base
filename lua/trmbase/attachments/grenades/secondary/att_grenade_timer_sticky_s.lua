ATTACHMENT.Base = "att_grenade_base_s"
ATTACHMENT.Name = "Sticky Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade_sticky"
    weapon.Secondary.Damage = weapon.Secondary.Damage * 0.9
    weapon.PrintName = weapon.PrintName .. " Sticky"
end
