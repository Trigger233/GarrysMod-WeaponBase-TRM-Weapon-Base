ATTACHMENT.Base = "att_base"
ATTACHMENT.UnderBarrel = true

function ATTACHMENT:ChangeWeaponStats(weapon)
    weapon.underbarrel = true
    weapon.Secondary = {}
    weapon.Secondary.RPM = 100
end