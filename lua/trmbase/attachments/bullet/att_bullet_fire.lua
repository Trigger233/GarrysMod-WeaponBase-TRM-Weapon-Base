ATTACHMENT.Base = "att_bullet"
ATTACHMENT.Name = "Fire"
ATTACHMENT.Category = "att_bullet"

function ATTACHMENT:BulletCallback(attacker, tr, dmginfo)
    dmginfo:SetDamageType(DMG_BLAST)
    if tr and tr.Entity.Ignite then
        tr.Entity:Ignite(5,1)
    end
end

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Recoil.Vertical[2] = weapon.Recoil.Vertical[2] * 1.5
    weapon.Primary.Damage = weapon.Primary.Damage * 0.65
end

function ATTACHMENT:DoImpactEffect(tr,type)
    local effect = EffectData()
    effect:SetOrigin(tr.HitPos)
    effect:SetMagnitude(10)
    effect:SetScale(10)
    effect:SetFlags(0)
    util.Effect("Explosion",effect)

end