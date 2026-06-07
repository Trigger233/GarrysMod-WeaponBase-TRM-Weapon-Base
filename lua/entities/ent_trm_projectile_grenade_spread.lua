-- ent_trm_projectile_grenade_spread.lua
AddCSLuaFile()

ENT.Base = "ent_trm_projectile_grenade"
ENT.StartDelay = 0.35     -- 延迟多久开始抛撒
ENT.Timer = 1            -- 抛撒持续时间
ENT.SpreadPerTime = 15    -- 每次抛撒几个子弹药
ENT.SpreadInterval = 0.5 -- 抛撒间隔（秒）
ENT.SpreadRadius = 550   -- 抛撒半径
ENT.SpreadVelocity = 40 -- 子弹药初速度
ENT.SpreadSound = Sound("npc/scanner/scanner_scan1.wav")
ENT.TrailColor = Color(200,0,0)
DEFINE_BASECLASS(ENT.Base)

function ENT:Initialize()
    BaseClass.Initialize(self)
    self.m_NextTrigger = CurTime() + self.StartDelay
    self.m_NextSpawn = 0
    self.m_NextRemove = CurTime() + self.Timer + self.StartDelay + 2
    self.m_Spawned = 0
end

function ENT:Think()
    if not SERVER then return end

    local time = CurTime()

    -- 延迟后开始抛撒
    if time >= self.m_NextTrigger then
        if time - self.m_NextSpawn > 0  then
            self.m_NextSpawn = time + self.SpreadInterval
            self:EmitSound(self.SpreadSound)
            self:SpawnChildrenGrenade()
        end
    end

    if time > self.m_NextRemove then
        self:Explode()
        SafeRemoveEntity(self)
    end
end

function ENT:PhysicsCollide(data, phys)
    self:CollisionDamage(data, phys)
    -- 碰撞后不消失，继续在空中抛撒
end

function ENT:SpawnChildrenGrenade()
    local owner = self:GetOwner()
    local pos = self:GetPos()+ self:OBBCenter() + Vector(0, 0, 50)
    

    local effect = EffectData()
    effect:SetScale(self.SpreadRadius)
    effect:SetEntity(self)
    effect:SetOrigin(pos)
    util.Effect("cball_bounce", effect)



    local totalChildren = self.SpreadPerTime or 12 -- 子弹药数量

    for i = 1, totalChildren do
        local child = ents.Create("ent_trm_proj_grenade_spread_child")
        if not IsValid(child) then continue end

        -- 基础角度（均匀分布）
        local baseAngle = (360 / totalChildren) * i

        -- 添加随机偏移（让扩散更自然）
        local angle = baseAngle + math.random(-15, 15)
        local rad = math.rad(angle)

        -- 水平方向
        local horDir = Vector(math.cos(rad), math.sin(rad), 0)

        -- 向下角度（带随机）
        local downAngle = math.rad(math.random(30, 60))
        local finalDir = Vector(horDir.x, horDir.y, -math.tan(downAngle)):GetNormalized()

        -- 速度（带随机）
        local speed = self.SpreadRadius
        speed = speed * math.random(10, 240) / 100
        local velocity = finalDir * speed

        -- 起始位置轻微偏移
        local startPos = pos + horDir * 5

        child:SetPos(startPos)
        child:SetOwner(owner)
        child:Spawn()

        local physObj = child:GetPhysicsObject()
        if IsValid(physObj) then
            physObj:SetVelocity(velocity)
        end
    end
end
