ATTACHMENT.Base = "att_grenade_base_s"
ATTACHMENT.Name = "Spread Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade_spread"
    weapon.Secondary.Damage = weapon.Secondary.Damage * 0.25
    weapon.PrintName = weapon.PrintName .. " Spread-Bomb"
end
