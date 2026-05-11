ATTACHMENT.Name = "ANPEQ15"
ATTACHMENT.Model = Model("models/weapons/tfa_ins2/upgrades/a_laser_anpeq15.mdl")
ATTACHMENT.Category = "att_laser"
ATTACHMENT.Base = "att_laser"
ATTACHMENT.Angles = Angle(-90,0,180)
ATTACHMENT.Pos = Vector(3,1,0)

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.Spread.Base = weapon.Spread.Base * 0.90
    weapon.Spread.Increase = weapon.Spread.Increase * 0.5
    weapon.Aim.Time = weapon.Aim.Time * 0.8


end