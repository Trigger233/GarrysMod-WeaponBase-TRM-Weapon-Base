if SERVER then
    AddCSLuaFile()
end

ENT.Base = "ent_trm_projectile_grenade"

-- 爆炸参数
ENT.Range = 150  -- 无衰减范围（单位内满伤）
ENT.Radius = 250 -- 最大影响范围
ENT.Timer = 3
--Trail
ENT.TrailColor = Color(159, 255, 167)
--Sound
ENT.TickingSound = Sound("weapons/grenade/tick1.wav")
ENT.TickTime = 1

DEFINE_BASECLASS(ENT.Base)

function ENT:Initialize()
    BaseClass.Initialize(self)

    self.m_NextTick = 0
end

function ENT:PhysicsCollide(data, phys)
    self:CollisionDamage(data, phys)
end

function ENT:Think()
    -- 定时爆炸
    local time = CurTime()
    self:WarnNPC()

    if time - self.m_NextTick > 0 then
        self:EmitSound(self.TickingSound, SNDLVL_GUNFIRE, 100, 1, CHAN_WEAPON, FL_GRENADE)
        if time - self.m_SpawnTime > (self.Timer * 0.25) then
            self.TickTime = math.max(self.TickTime * 0.75, 0.15)
        end
        self.m_NextTick = time + self.TickTime
    end
    if time - self.m_SpawnTime > self.Timer then
        self:Explode()
        return
    end
end


function ENT:OnTakeDamage(number)
    self:Explode()
end