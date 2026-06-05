if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Model = Model("models/trm_attachments/projectile/a_projectile_m203.mdl")
ENT.ModelScale = 1
-- 爆炸参数
ENT.Range = 150  -- 无衰减范围（单位内满伤）
ENT.Radius = 250 -- 最大影响范围
ENT.SafeyTimer = 0.2
--Trail
ENT.TrailColor = Color(255, 255, 255)
function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetModelScale(self.ModelScale)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self.m_SpawnTime = CurTime()
    self.m_Exploded = false
    if SERVER then
        util.SpriteTrail(self, 0, self.TrailColor, false, 20, 15, 0.2, 16, "trails/laser")
    end
end

function ENT:Explode()
    if self.m_Exploded or not SERVER then return end
    self.m_Exploded = true

    local pos = self:GetPos()
    local owner = self:GetOwner()
    local radius = self.Radius or 200
    local damage = self.Damage or 100

    -- 创建爆炸实体（主要用来产生特效和冲击）
    local explosion = ents.Create("env_explosion")
    if IsValid(explosion) then
        explosion:SetPos(pos)
        explosion:SetOwner(IsValid(owner) and owner or self)
        explosion:Spawn()
        explosion:SetKeyValue("iMagnitude", owner.Primary.Damage) -- 不用它的伤害，我们自己处理
        explosion:SetKeyValue("iRadiusOverride", radius)
        explosion:Fire("Explode", 0, 0)
    end

    -- 手动处理伤害（支持距离衰减）
    local targets = ents.FindInSphere(pos, radius)
    for _, target in ipairs(targets) do
        if not IsValid(target) then continue end
        if not (target:IsNPC() or target:IsPlayer()) then continue end

        -- 射线检测（是否被遮挡）
        local trace = util.TraceLine({
            start = pos,
            endpos = target:GetPos(),
            filter = { self, target },
            mask = MASK_SOLID
        })

        if trace.Hit and trace.Entity ~= target then
            continue -- 被墙挡住，无伤害
        end

        local distance = target:GetPos():Distance(pos)
        local multiplier = self:GetDamageMultiplier(distance)

        if multiplier <= 0 then continue end

        local finalDamage = damage * multiplier
        local forceDir = (target:GetPos() - pos):GetNormalized()
        local force = forceDir * finalDamage * 200

        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(IsValid(owner) and owner or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamage(finalDamage)
        dmginfo:SetDamageForce(force)
        dmginfo:SetDamageType(DMG_BLAST)

        target:TakeDamageInfo(dmginfo)
    end

    -- 爆炸特效（额外增强）
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetNormal(Vector(0, 0, 1))
    effect:SetScale(radius / 100)
    util.Effect("Explosion", effect)

    -- 爆炸音效
    self:EmitSound("weapons/explode.wav")

    self:Remove()
end

-- 伤害倍率计算
function ENT:GetDamageMultiplier(distance)
    local range = self.Range or 100 -- 无衰减范围
    if distance <= range then
        return 1
    end
    local multiplier = 1 - (distance - range) / (self.Radius - self.Range)
    return math.max(multiplier, 0)
end

-- 碰撞时爆炸
function ENT:PhysicsCollide(data, phys)
    if CurTime() - self.m_SpawnTime < self.SafeyTimer then
        self.m_Exploded = true
        self:CollisionDamage(data, phys)
        return
    end
    if not self.m_Exploded then
        self:Explode()
    end
end

-- 定时自毁（防止卡地图）
function ENT:Think()
    if not SERVER then return end
    if self.m_SpawnTime and CurTime() - self.m_SpawnTime > 8 then
        self:Remove()
        return
    end
end

function ENT:OnRemove()
    if SERVER then
        SafeRemoveEntity(self)
    end
end

function ENT:CollisionDamage(data, phys)
    local hitEnt = data.HitEntity
    local hitPos = data.HitPos
    if IsValid(hitEnt) and hitEnt.TakeDamageInfo then
        local owner = self:GetOwner()
        local damage = self.ImpactDamage or 50 -- 物理撞击伤害

        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(IsValid(owner) and owner or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamage(damage)
        dmginfo:SetDamageForce(phys:GetVelocity():GetNormalized() * damage * 200)
        dmginfo:SetDamagePosition(hitPos)
        dmginfo:SetDamageType(DMG_CRUSH) -- 物理撞击伤害类型

        hitEnt:TakeDamageInfo(dmginfo)

        -- 播放撞击音效
        self:EmitSound("weapons/bullet_impact.wav", 65, math.random(90, 110))

        -- 榴弹弹开
        local vel = phys:GetVelocity()
        local normal = data.HitNormal
        local newVel = vel - 2 * vel:Dot(normal) * normal
        phys:SetVelocity(newVel * 1)

        return -- 不爆炸
    end
end
