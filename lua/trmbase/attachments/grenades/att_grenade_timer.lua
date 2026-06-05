ATTACHMENT.Base = "att_grenade_base"
ATTACHMENT.Name = "Timer Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.SpecialAmmo = "ent_trm_projectile_grenade_timer"
    weapon.Primary.Damage = weapon.Primary.Damage * 1.5
end
