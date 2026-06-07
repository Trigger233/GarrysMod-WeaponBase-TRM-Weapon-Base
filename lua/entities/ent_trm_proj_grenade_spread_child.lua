-- ent_trm_proj_grenade_spread_child.lua
AddCSLuaFile()

ENT.Base = "ent_trm_projectile_grenade"
ENT.Name = "Cluster Bomb Submunition"

DEFINE_BASECLASS(ENT.Base)
ENT.TrailColor = Color(150, 100, 150 , 255)
ENT.Radius = 150
ENT.Damage = 50
ENT.Timer = 5 -- 5秒后自毁

function ENT:Initialize()
    BaseClass.Initialize(self)
    self.m_NextRemove = CurTime() + self.Timer
end

function ENT:PhysicsCollide(data, phys)
    if self.m_Exploded then return end
    self:Explode()
end

function ENT:Explode()
    if self.m_Exploded then return end
    self.m_Exploded = true

    local pos = self:GetPos()
    local owner = self:GetOwner()

    -- 爆炸特效
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(self.Radius / 100)
    util.Effect("Explosion", effect)

    -- 伤害范围
    local targets = ents.FindInSphere(pos, self.Radius)
    for _, target in ipairs(targets) do
        if IsValid(target) and (target:IsNPC() or target:IsPlayer()) then
            local distance = target:GetPos():Distance(pos)
            local damage = owner.Primary.Damage * (1 - distance / self.Radius)

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker(IsValid(owner) and owner or self)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamage(damage)
            dmginfo:SetDamageType(DMG_BLAST)
            target:TakeDamageInfo(dmginfo)
        end
    end

    self:EmitSound("weapons/explode.wav")
    SafeRemoveEntity(self)
end

function ENT:Think()
    if SERVER and CurTime() > self.m_NextRemove then
        self:Explode()
    end
end
