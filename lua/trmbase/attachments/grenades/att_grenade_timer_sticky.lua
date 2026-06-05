ATTACHMENT.Base = "att_grenade_timer"
ATTACHMENT.Name = "Sticky Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.SpecialAmmo = "ent_trm_projectile_grenade_sticky"
    weapon.Primary.Damage = weapon.Primary.Damage * 0.9
end
