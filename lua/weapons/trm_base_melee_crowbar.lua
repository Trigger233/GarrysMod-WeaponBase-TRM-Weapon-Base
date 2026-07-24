SWEP.Base = "trm_melee_base"

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.PrintName = "Crowbar"
SWEP.AltSwitch = true
SWEP.DisableIronsight = true

SWEP.Primary.Attack = {
    {
        Animation = "Attack1",
        Range = 50,
        HullSize = 5,
        Cycle = 0.1,
        Sound = Sound("Weapon_Crowbar.Single"),
    },
    {
        Animation = "Attack2",
        Range = 50,
        HullSize = 5,
        Cycle = 0.1,
        Sound = Sound("Weapon_Crowbar.Single"),
    }
}

SWEP.Animations = {
    ["Attack1"] = {
        sequence = { "Misscenter1" },
        RealLength = 0.5 ,
    },
    ['Attack2'] = {
        sequence = { "hitkill1" }
    },
    ["Draw"] = {
        sequence = { "draw" },
        RealLength = 0.5,
    },
    ["Idle"] = {
        sequence = { "idle01" }
    }
}
