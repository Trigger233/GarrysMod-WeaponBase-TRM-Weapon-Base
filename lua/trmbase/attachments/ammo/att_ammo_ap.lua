ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Armor-piercing"
ATTACHMENT.Category = "att_ammo"
function ATTACHMENT:Stats(w)
    w.Primary.Damage = w.Primary.Damage * 0.6
    w.Bullet.Penetration.ArmorPenetrateDamage = w.Bullet.Penetration.ArmorPenetrateDamage + 0.8
    w.PrintName = w.PrintName .. " Armor-piercing "
    w.HUDElement.Bullet = Color(50, 248, 255, 255)
end

function ATTACHMENT:BulletCallback(attacker, tr, dmginfo)
    if not tr or not tr.HitPos or not tr.Entity then return end
    local effect = EffectData()
    effect:SetOrigin(tr.HitPos)
    effect:SetNormal(tr.HitNormal)
    effect:SetAngles(tr.HitNormal:Angle())
    effect:SetMagnitude(1)
    effect:SetScale(1)
    effect:SetRadius(10)
    effect:SetFlags(0)
    util.Effect("AR2Impact", effect)
end
