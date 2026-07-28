ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "FMJ"
ATTACHMENT.Category = "att_ammo"
function ATTACHMENT:Stats(w)
    w.Primary.Damage = w.Primary.Damage * 0.8
    w.Bullet.Penetration.ArmorPenetrateDamage = w.Bullet.Penetration.ArmorPenetrateDamage + 0.2
    w.Bullet.Penetration.Max = w.Bullet.Penetration.Max + 2
    w.PrintName = w.PrintName .. " FMJ "
    w.HUDElement.Bullet = Color(200, 253, 255, 255)
end

