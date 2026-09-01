ATTACHMENT.Base = "att_grenade_base"
ATTACHMENT.Name = "Spread Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.SpecialAmmo = "ent_trm_projectile_grenade_spread"
    weapon.Primary.Damage = weapon.Primary.Damage * 0.25
    weapon.PrintName = weapon.PrintName .. " Spread-Bomb"
end
