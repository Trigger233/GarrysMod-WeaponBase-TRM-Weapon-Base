ATTACHMENT.Name = "RMR"
ATTACHMENT.Category = "att_sight_pistol"
ATTACHMENT.Base = "att_reticle"
ATTACHMENT.Selectable = true

ATTACHMENT.Angles     = Angle(-180, 90, 180) 
ATTACHMENT.Pos        = Vector(1.5, 0, 0)
ATTACHMENT.Sight = {
    Pos = Vector(0.00,0, 0.85 ) ,
    Align = "1" ,
    Material = Material("models/weapons/trm_attachments/sight/eft_rmr/rmr_reticle") ,
    Size = 64 , 
    Color = Color(255,255,255),
    --HideMaterial = {2} , --Material Index
}

ATTACHMENT.Model = Model("models/trm_attachments/optic/v_rmr.mdl")

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Aim.Time = weapon.Aim.Time * 1.05
end