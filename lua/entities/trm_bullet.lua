AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Name = "Bullet"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.Projectile = {
    Gravity = 8.5, -- 子弹不受重力，设 0
}

ENT.Trail = {
    {
        color = Color(255, 187, 0) ,
        width1 = 20 ,
        width2 = 20 ,
        lifetime = 0.1 ,
        mat = "trails/laser"
    },
    {
        color = Color(255, 255, 255),
        width1 = 10,
        width2 = 1,
        lifetime = 1,
        mat = "trails/laser"
    },
}

ENT.bWhizz = false

ENT.Maxs = Vector(2, 2, 2) -- 碰撞盒大小
local meterToHu = 52.4934383


function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/ar2_grenade.mdl")
        self:PhysicsInitBox(Vector(-1, -1, -1), Vector(1, 1, 1))
        self:GetPhysicsObject():Wake()
        self:GetPhysicsObject():SetMaterial("default_silent")
        self:GetPhysicsObject():AddGameFlag(FVPHYSICS_NO_PLAYER_PICKUP)
        self:GetPhysicsObject():AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
        self:GetPhysicsObject():AddGameFlag(FVPHYSICS_HEAVY_OBJECT)
        self:GetPhysicsObject():EnableMotion(true)
        self:GetPhysicsObject():EnableDrag(false)
        self:GetPhysicsObject():SetMass(100)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        self:AddEFlags(EFL_NO_DAMAGE_FORCES)
        self:AddEFlags(EFL_DONTWALKON)
        self:AddEFlags(EFL_DONTBLOCKLOS)
        self:AddEFlags(EFL_NO_PHYSCANNON_INTERACTION)

        local phys = self:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
            phys:SetVelocityInstantaneous(self:GetAngles():Forward() * 1000 * meterToHu)
        end
        -- 记录武器和发射者
        self.Weapon = self:GetOwner() -- 注意：SetOwner 需要在 Spawn 前调用
        self.Attacker = self.Weapon:GetOwner()


        self.LastPos = self:GetPos()

        -- 3秒后自毁
        timer.Simple(10, function()
            if IsValid(self) then self:Remove() end
        end)
    end

    if SERVER then
        for _ , v in pairs(self.Trail) do
            util.SpriteTrail(self, 1, v.color or Color(255, 187, 0), true, v.width1 or 20, v.width2 or 1, v.lifetime or 0.1 ,
                2 / (v.width1 or 20 + v.width2 or 1),
                v.mat or "trails/laser")
        end
 
    end
end

local g = GetConVar("sv_gravity"):GetInt() or 600 -- Hu/s²
function ENT:PhysicsUpdate(phys)
    if not SERVER then return end
    if self.bCollided then return end

    -- -- 应用重力（如果需要）
    -- if self.Projectile.Gravity and self.Projectile.Gravity ~= 0 then
    phys:AddVelocity(Vector(0, 0, self.Projectile.Gravity))
    -- end

    local startPos = self.LastPos or self:GetPos()
    local endPos = phys:GetPos()

    -- 飞线检测（防止穿透）
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = { self, self.Attacker },
        mask = MASK_SHOT
    })

    if tr.Hit then
        self:Impact(tr, phys)
        return
    end

    self.LastPos = endPos
end

function ENT:Impact(tr, phys)
    if self.bCollided then return end
    self.bCollided = true
    local weapon = self:GetOwner()

    weapon:FireBullets({
        Attacker = weapon:GetOwner(),
        Num = 1,
        Tracer = 0,
        Src = self.LastPos,
        Damage = weapon.Primary.Damage * weapon.Primary.NumBullets,
        Dir = (phys:GetPos() - self.LastPos):GetNormalized(),
        HullSize = 0,

        IgnoreEntity = self,
        Callback = function(attacker, str, dmgInfo)
            dmgInfo:SetDamageType(DMG_BULLET)
            weapon:BulletCallback(attacker, str, dmgInfo)
        end
    })


    -- 播放命中音效
    self:EmitSound("weapons/bullet_impact.wav", 65, math.random(90, 110))

    self:Remove()
end

function ENT:PhysicsCollide(data, phys)

end

function ENT:Think()
    if (CLIENT) then
        if (! IsValid(GetViewEntity())) then
            return
        end

        local bInRadius = EyePos():DistToSqr(self:GetPos()) < 128 * 128

        if (bInRadius && ! self.bWhizz && self:GetOwner():GetOwner() != GetViewEntity()) then
            GetViewEntity():EmitSound("Bullets.DefaultNearmiss")
            self.bWhizz = true
        end
    end
end
