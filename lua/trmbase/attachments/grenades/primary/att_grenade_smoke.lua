ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Smoke Grenade"
ATTACHMENT.Category = "att_ammo_grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.SpecialAmmo = "ent_trm_projectile_grenade_smoke"
    weapon.PrintName = weapon.PrintName .. " Smokey"
end
