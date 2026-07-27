SWEP.Base = "trm_gun_base"
--WIP
SWEP.IsMeleeWeapon = 1
SWEP.Slot = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Chamber = 1
SWEP.Category = "TRM Weapons"
SWEP.Primary.Attacks = {}
SWEP.Primary.Ammo = ""
SWEP.Primary.Delay = 0.5
SWEP.Primary.NumBullets = 1
SWEP.Secondary.Attacks = {}

SWEP.Primary.ClipSize = -1

SWEP.Animations = {}
SWEP.Attachments = {}

DEFINE_BASECLASS(SWEP.Base)

function SWEP:SetupDataTables()
    BaseClass.SetupDataTables(self)
end

function SWEP:GetFiremodeName()
    return "Melee"
end

function SWEP:Recover()
    local Index = self:GetBrustCount()
    if Index ~= 1 and CurTime() > self:GetNextPrimaryFire() + self.Primary.Delay then
        self:ResetCombo()
    end
end

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self:ResetCombo()
end

function SWEP:CanPrimaryAttack()
    return self:GetNextPrimaryFire() <= CurTime()
end

function SWEP:PrimaryAttack()
    if self:CanPrimaryAttack() then
        self:TrySetTask("Melee_Attack")
    end
end

function SWEP:GetCurrentSpread()
    return 0.05
end

function SWEP:DoMeleeAttackDamage(tbl)
    if not tbl then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local startPos = owner:GetShootPos()
    local forward = owner:GetAimVector()
    local range = tbl.Range or 200
    local damage = tbl.Damage or 40
    local hullSize = tbl.HullSize or 5
    local endPos = startPos + forward * range
    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mins = Vector(-hullSize * 2, -hullSize, -0),
        maxs = Vector(hullSize * 2, hullSize, hullSize),
        mask = MASK_SHOT_HULL,
    })


    local dmginfo = DamageInfo()
    dmginfo:SetDamage(damage)
    dmginfo:SetAttacker(owner)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamageForce(forward * (self.Melee.Force or 10))
    dmginfo:SetDamageType(DMG_CLUB)

    if not tr.Hit then return end
    self:MeleeImpactEffects(tr)
    self:MeleeDoor(tr)



    local ent = tr.Entity
    if not (game.SinglePlayer() and CLIENT) then
        self:EmitSound(self.Melee.Sound)
    end


    if CLIENT then return end

    if IsValid(ent) then
        if ent.TakeDamageInfo then
            ent:TakeDamageInfo(dmginfo)
        end
    end

    local phys

    if ent:IsRagdoll() then
        phys = ent:GetPhysicsObjectNum(tr.PhysicsBone or 0)
    else
        phys = ent:GetPhysicsObject()
    end

    if IsValid(phys) then
        if ent:IsPlayer() or ent:IsNPC() then
            ent:SetVelocity(owner:GetAimVector() * damage * 0.5)
            phys:SetVelocity(phys:GetVelocity() + forward * damage * 0.5)
        else
            phys:ApplyForceOffset(forward * damage * 0.5, tr.HitPos)
        end
    end
end

function SWEP:CycleComboIndex()
    local Max = #self.Primary.Attack
    local current = self:GetBrustCount()
    self:SetBrustCount(current >= Max and 1 or current + 1)
end

function SWEP:ResetCombo()
    self:SetBrustCount(1)
end

function SWEP:CanInspect()
    return not self:IsInspecting() and (self:GetNextPrimaryFire() < CurTime())
end
