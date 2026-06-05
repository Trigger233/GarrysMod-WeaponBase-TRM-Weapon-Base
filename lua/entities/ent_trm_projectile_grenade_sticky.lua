if SERVER then
    AddCSLuaFile()
end

ENT.Base = "ent_trm_projectile_grenade_timer"

-- 爆炸参数
ENT.Range = 50   -- 无衰减范围（单位内满伤）
ENT.Radius = 250 -- 最大影响范围
ENT.Timer = 5
--Trail
ENT.TrailColor = Color(255, 233, 125)
--Sound
DEFINE_BASECLASS(ENT.Base)

function ENT:Initialize()
    BaseClass.Initialize(self)
end

function ENT:PhysicsCollide(data, phys)
    if self.m_Stuck then return end
    self.m_Stuck = true

    -- 停止飞行
    phys:EnableMotion(false)
    self:SetNotSolid(true)

    -- 粘附
    if IsValid(data.HitEntity) then
        self:SetParent(data.HitEntity)
        self:SetLocalPos(self:GetPos() - data.HitEntity:GetPos())
    end

    -- 粘附特效
    local effect = EffectData()
    effect:SetOrigin(data.HitPos)
    effect:SetNormal(data.HitNormal)
    effect:SetScale(1)
    util.Effect("cball_explode", effect)

    -- 音效
    self:EmitSound("weapons/sticky_attach.wav", 70, 100)

    -- 重启计时器（粘住后才开始倒计时）
    self.m_SpawnTime = CurTime()
    self.m_NextTick = CurTime() + 1
end
