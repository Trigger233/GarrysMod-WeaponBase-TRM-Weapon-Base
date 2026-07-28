ATTACHMENT.Base = "att_base"
ATTACHMENT.Name = "Blue Tracer"
ATTACHMENT.Category = "att_ammo"
function ATTACHMENT:Stats(weapon)
    weapon.HUDElement.Bullet = Color(98, 239, 255, 255)
    weapon.Effects.Muzzle.Tracer.Name = "trm_tracer_b"
end
