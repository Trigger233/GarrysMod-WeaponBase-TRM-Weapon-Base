ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Grenade"
ATTACHMENT.Category = "att_ammo_grenade"
function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Primary.SpecialAmmo = "ent_trm_projectile_grenade"
end
