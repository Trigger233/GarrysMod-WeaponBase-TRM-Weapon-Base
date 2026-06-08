ATTACHMENT.Base = "att_grenade_base_s"
ATTACHMENT.Name = "Timer Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade_timer"
    weapon.Secondary.Damage = weapon.Secondary.Damage * 1.5
    weapon.PrintName = weapon.PrintName .. " Timer-Bomb"
end
