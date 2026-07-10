ATTACHMENT.Name = "att_flashhider_base"
ATTACHMENT.Base = "att_base"
ATTACHMENT.Selectable = true

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Effects.Muzzle.ParticleEffect =   weapon.Effects.Muzzle.ParticleSuppressed  
end