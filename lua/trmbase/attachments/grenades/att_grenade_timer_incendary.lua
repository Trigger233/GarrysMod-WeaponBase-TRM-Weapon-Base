ATTACHMENT.Base = "att_grenade_timer"
ATTACHMENT.Name = "Incendary Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.SpecialAmmo = "ent_trm_projectile_grenade_incendary"
    weapon.Primary.Damage = weapon.Primary.Damage * 0.5
    weapon.PrintName = weapon.PrintName .. " Incendary"
end
