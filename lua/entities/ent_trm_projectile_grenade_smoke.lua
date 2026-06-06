AddCSLuaFile()

ENT.Base = "ent_trm_projectile_grenade"
ENT.Name = "Smoke Grenade"

DEFINE_BASECLASS(ENT.Base)
ENT.TrailColor = Color(0,255,255)
ENT.Radius = 512
ENT.Timer = 10
ENT.SmokeSound = Sound("physics/metal/metal_chainlink_impact_soft3.wav")

if SERVER then
    util.AddNetworkString("TRM_SmokeGrenade")
end

local smokeimages = {
    "particle/smokesprites_0002", "particle/smokesprites_0003",
    "particle/smokesprites_0004", "particle/smokesprites_0005",
}

local function GetSmokeImage()
    return smokeimages[math.random(#smokeimages)]
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    self.m_Smoke = false
    self.m_NextRemove = CurTime() + self.Timer
end

local function sendsmoke(ent)
    if SERVER then
        net.Start("TRM_SmokeGrenade")
        net.WriteVector(ent:GetPos())
        net.WriteEntity(ent)
        net.Broadcast()
    end
end
function ENT:PhysicsCollide(data, phy)
    self.m_SmokeNext = 0
    if self.m_Smoke then return end
    self.m_Smoke = true
    self.m_NextRemove = CurTime() + self.Timer
    self.m_LoopSound =  self:StartLoopingSound(self.SmokeSound)
    self:CollisionDamage(data, phy)
    phy:EnableMotion(false)
    -- 通知客户端生成烟雾
    sendsmoke(self)
end

function ENT:Think()
    if not SERVER then return end
    local targets = ents.FindInSphere(self:GetPos(), self.Radius)
    
    for _, k in ipairs(targets) do
        if k:IsNPC() then
            k:SetSchedule(SCHED_STANDOFF)
        end
    end

    if CurTime() > self.m_NextRemove and SERVER then
        SafeRemoveEntity(self)
    end
end

-- 客户端接收消息并生成烟雾
if CLIENT then
    net.Receive("TRM_SmokeGrenade", function()
        local pos     = net.ReadVector()
        local ent     = net.ReadEntity()
        local emitter = ParticleEmitter(pos)
        if not emitter then return end

        for i = 1, 5 do
            local smoke = emitter:Add(GetSmokeImage(), pos)
            smoke:SetVelocity(VectorRand() * 50)
            smoke:SetStartAlpha(255)
            smoke:SetEndAlpha(0)
            smoke:SetStartSize(50)
            smoke:SetEndSize(ent.Radius)
            smoke:SetDieTime(ent.Timer)
            smoke:SetColor(255, 255, 255)
            smoke:SetAirResistance(20)
        end

        emitter:Finish()
    end)
end

function ENT:OnRemove()
    if self.m_LoopSound then
        self:StopLoopingSound(self.m_LoopSound)
    end
end
