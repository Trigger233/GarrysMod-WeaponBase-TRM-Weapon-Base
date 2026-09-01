ATTACHMENT.Base = "att_grenade_timer_s"
ATTACHMENT.Name = "Incendary Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade_incendary"
    weapon.Secondary.Damage = weapon.Secondary.Damage * 0.5
    weapon.PrintName = weapon.PrintName .. " Incendary"
end
