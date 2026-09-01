ATTACHMENT.Base = "att_grenade_base_s"
ATTACHMENT.Name = "Smoke Grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade_smoke"
    weapon.PrintName = weapon.PrintName .. " Smokey"
end
