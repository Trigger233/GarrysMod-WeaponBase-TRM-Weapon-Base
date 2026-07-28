ATTACHMENT.Base = "att_bullet"
ATTACHMENT.Name = "Fire"
ATTACHMENT.Category = "att_ammo"

function ATTACHMENT:BulletCallback(attacker, tr, dmginfo)
    if tr and tr.Entity and tr.Entity.Ignite then
        local time = 2
        if tr.Entity:IsPlayer() then
            time= 0.25
        end
        tr.Entity:Ignite(time,3)
    end
end

function ATTACHMENT:Stats(weapon)
    weapon.Recoil.Vertical[2] = weapon.Recoil.Vertical[2] * 1.5
    weapon.Primary.Damage = weapon.Primary.Damage * 0.4
    weapon.Spread.Base = weapon.Spread.Base * 1.5

    weapon.PrintName = weapon.PrintName .. " FireBullets"
    weapon.HUDElement.Bullet = Color(252, 163, 30, 255)
end
function ATTACHMENT:DoImpactEffect(tr,type)
    if  not tr or not tr.HitPos then return end
    local effect = EffectData()
    effect:SetOrigin(tr.HitPos)
    effect:SetNormal(tr.HitNormal)
    effect:SetAngles(tr.HitNormal:Angle())
    effect:SetMagnitude(1)
    effect:SetScale(1)
    effect:SetRadius(10)
    effect:SetFlags(0)
    util.Effect("Sparks", effect)
end
