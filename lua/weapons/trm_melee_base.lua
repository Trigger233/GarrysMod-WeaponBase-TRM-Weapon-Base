SWEP.Base = "trm_gun_base"
DEFINE_BASECLASS(SWEP.Base)
--WIP
SWEP.Primary.Attacks = {}
SWEP.Primary.Ammo = -1
SWEP.Primary.NumBullets = 1
SWEP.Secondary.Attacks = {}

SWEP.Primary.ClipSize = -1

function SWEP:GetCurrentSpread()
    return 0.05
end