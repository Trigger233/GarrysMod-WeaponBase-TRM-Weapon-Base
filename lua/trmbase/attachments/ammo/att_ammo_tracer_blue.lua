ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Blue Tracer"
ATTACHMENT.Category = "att_ammo"
function ATTACHMENT:Stats(weapon)
    weapon.HUDElement.Bullet = Color(98, 239, 255, 255)
    weapon.Effects.Muzzle.Tracer.Name = "TRM_Tracer_Matin_Blue"
    weapon.Effects.Muzzle.ParticleEffect = "TRM_MuzzleFlash_Blue"
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
