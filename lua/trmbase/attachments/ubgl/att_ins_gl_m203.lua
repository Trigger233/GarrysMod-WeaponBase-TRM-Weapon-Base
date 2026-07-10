ATTACHMENT.Name = "M203"
ATTACHMENT.Category = "att_underbarrel"
ATTACHMENT.Base = "att_base"
ATTACHMENT.Bonemerge = false
ATTACHMENT.Model = Model("models/trm_attachments/ubgl/m203_ins.mdl")
ATTACHMENT.Pos = Vector(-0, 0, 0)
ATTACHMENT.LHIK = true
ATTACHMENT.Selectable = false

function ATTACHMENT:Stats(weapon)
    weapon.underbarrel = true
    weapon.LHIK = true

    weapon.Secondary = {}
    weapon.Secondary.Sound = Sound("Weapon_SMG1.Double")
    weapon.Secondary.Damage = 200
    weapon.Secondary.Ammo = "smg1_grenade"
    weapon.Secondary.ClipSize = 1
    weapon.Secondary.Chamber = 0
    weapon.Secondary.Velocity = 1200
    weapon.Secondary.SpecialAmmo = "ent_trm_projectile_grenade"
end

ATTACHMENT.Animations = {
    ["Idle"] = {
        sequence = {"idle_armed"},
    },
    ["Reload"] = {
        sequence = {"reload"} ,
    },
    ["In"] = {
        sequence = {"to_armed"} ,
    },
    ["Out"] = {
        sequence = {"to_idle"}
    },
    ["Fire"] = {
        sequence = {"fire"}
    }
} 

--[[0 : idle
1 : idle_armed
2 : reload
3 : reload_fast
4 : fire
5 : to_armed
6 : to_idle
7 : sprint
囟X=]]
