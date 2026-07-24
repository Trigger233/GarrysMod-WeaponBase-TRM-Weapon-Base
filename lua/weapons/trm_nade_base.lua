SWEP.Base = "trm_melee_base"
SWEP.IsNade = true
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "grenade"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.Projectile = "ent_trm_projectile_grenade"
SWEP.Primary.Velocity = 1200

SWEP.Slot = 4
SWEP.Primary.Delay = 0.5
DEFINE_BASECLASS(SWEP.Base)
function SWEP:PrimaryAttack()
    if self:CanPrimaryAttack() then
        self:TrySetTask("Nade_PreThrow")
    end
end

function SWEP:CanPrimaryAttack()
    if self:Ammo1() == 0 then
        return false
    end

    return BaseClass.CanPrimaryAttack(self)
end

function SWEP:CanSprint()
    return not string.find(self.Tasks[self:GetCurrentTask()].Name,"Throw")
end

function SWEP:Throw(tbl)
    if not SERVER then return end
    local speed = tbl.Velocity

    local nade = ents.Create(self.Projectile)
    nade:Spawn()
    nade:SetPos(self:GetShootPos())
    nade:SetAngles(self:GetAimVector():Angle())
    nade:SetOwner(self)
    nade:Activate()
    nade:Fire("SetTimer", 3, 0, self:GetOwner(), self)
    local phys = nade:GetPhysicsObject()
    timer.Simple(0, function()
        if IsValid(phys) then
            phys:SetMass(1)
            phys:Wake()
            phys:SetVelocityInstantaneous(self:GetAimVector() * 1200) -- 用 Instantaneous 更可靠
        end
    end)
end

function SWEP:Deploy()
    if self:Ammo1() == 0 then
        self:Remove()
    end
    BaseClass.Deploy(self)
end

function SWEP:Equip(newowner)
     if newowner:IsPlayer() and newowner:GetAmmoCount(self:GetPrimaryAmmoType()) == 0 or newowner:HasWeapon(self:GetClass()) then
        newowner:GiveAmmo(game.GetAmmoMax(self:GetPrimaryAmmoType()), self:GetPrimaryAmmoType(), false)
    end
end

function SWEP:EquipAmmo(ply)
    ply:GiveAmmo(1, self:GetPrimaryAmmoType(), false)
end