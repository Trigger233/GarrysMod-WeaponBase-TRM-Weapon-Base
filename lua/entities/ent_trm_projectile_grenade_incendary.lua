AddCSLuaFile()

ENT.Name = "Incendary Grenade"
ENT.Base = "ent_trm_projectile_grenade"
ENT.Timer = 10
ENT.TrailColor = Color(255,0,0)
DEFINE_BASECLASS(ENT.Base)

ENT.Radius = 255

function ENT:Initialize()
    BaseClass.Initialize(self)
    self.m_Trigger = false
    self.m_NextRemove = CurTime() + self.Timer
    self.m_NextDamage = 0
end

function ENT:PhysicsCollide(data, phys)
    if self.m_Trigger then return end
    self.m_Trigger = true
    self.m_NextRemove = CurTime() + self.Timer
    self.m_NextDamage = CurTime() + 0.5 -- 延迟0.5秒开始烧
end

function ENT:IncendaryEffect()
    -- 火焰特效
    local effect = EffectData()
    effect:SetOrigin(self:GetPos())
    effect:SetScale(self.Radius)
    effect:SetMagnitude(self.Radius)
    effect:SetEntity(self)
    util.Effect("Explosion", effect)
end

function ENT:DoDamage()
    if not SERVER then return end
    local owner = self:GetOwner()
    local targets = ents.FindInSphere(self:GetPos(), self.Radius)
    for _, target in ipairs(targets) do
        if not IsValid(target) then continue end
        if not (target:IsNPC() or target:IsPlayer()) then continue end

        -- 射线检测（是否被墙挡住）
        local trace = util.TraceLine({
            start = self:GetPos() + self:OBBCenter(),
            endpos = target:GetPos() + target:OBBCenter(),
            filter = { self, target },
            mask = MASK_SOLID
        })

        if trace.Hit and trace.Entity ~= target then
            continue
        end

        -- 造成伤害
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(self:GetOwner() or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamage(owner.Primary.Damage * 0.1 )
        dmginfo:SetDamageType(DMG_BURN)
        target:TakeDamageInfo(dmginfo)
        target:Ignite(1,3)
    end
end

function ENT:Think()
    if not self.m_Trigger then return end

    -- 每0.5秒造成一次伤害
    if CurTime() >= self.m_NextDamage then
        self.m_NextDamage = CurTime() + 0.5
        self:IncendaryEffect() -- 每次伤害时播放火焰特效
        self:DoDamage()
    end

    if SERVER and CurTime() > self.m_NextRemove then
        SafeRemoveEntity(self)
    end
end
